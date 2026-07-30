"""Background update watcher: systemd units and auto-reapply logic."""
from __future__ import annotations

from pathlib import Path

from host_runner import run_on_host
from marker_checker import check_markers
from state_manager import get_applied_patches

WATCH_LOG = Path("~/.local/state/deck-patcher/watch.log").expanduser()
SYSTEMD_UNIT_DIR = Path("~/.config/systemd/user").expanduser()

TIMER_UNIT = """\
[Unit]
Description=Deck Patcher periodic update check

[Timer]
OnBootSec=5min
OnUnitActiveSec=5min
Unit=deck-patcher-watch.service

[Install]
WantedBy=timers.target
"""

PATH_UNIT = """\
[Unit]
Description=Deck Patcher Steam directory watcher

[Path]
PathChanged={home}/.local/share/Steam/steamapps/
Unit=deck-patcher-watch.service

[Install]
WantedBy=default.target
""".format(home=Path("~").expanduser())

SERVICE_UNIT = """\
[Unit]
Description=Deck Patcher update check service
After=network-online.target

[Service]
Type=oneshot
ExecStart=flatpak run com.github.lovozeto.DeckPatcher --check-updates
StandardOutput=append:{log}
StandardError=append:{log}
""".format(log=WATCH_LOG)


def install_systemd_units() -> None:
    """Write the three systemd unit files and enable/start them."""
    SYSTEMD_UNIT_DIR.mkdir(parents=True, exist_ok=True)

    units: dict[str, str] = {
        "deck-patcher-watch.timer": TIMER_UNIT,
        "deck-patcher-watch.path": PATH_UNIT,
        "deck-patcher-watch.service": SERVICE_UNIT,
    }

    for unit_name, unit_content in units.items():
        unit_path = SYSTEMD_UNIT_DIR / unit_name
        unit_path.write_text(unit_content, encoding="utf-8")

    run_on_host(["systemctl", "--user", "daemon-reload"])

    for unit_name in ("deck-patcher-watch.timer", "deck-patcher-watch.path"):
        run_on_host(["systemctl", "--user", "enable", "--now", unit_name])


def run_check(notify: bool = True) -> dict[str, str]:
    """Check all applied patches' markers and auto-reapply eligible ones.

    Returns a dict of patch_id → result string ("ok", "reapplied", "outdated", "error").
    """
    # Import here to avoid circular dependency at module load time
    from patcher_engine import PatcherEngine
    from patch_registry import DEFAULT_REGISTRY_URL

    results: dict[str, str] = {}
    applied = get_applied_patches()

    if not applied:
        return results

    engine = PatcherEngine(registry_url=DEFAULT_REGISTRY_URL)

    for patch in applied:
        try:
            marker_results = check_markers(
                patch.markers,
                env_vars={"HOME": str(Path("~").expanduser())},
            )
            all_passed = all(m.passed for m in marker_results)

            if all_passed:
                results[patch.patch_id] = "ok"
                continue

            # Attempt auto-reapply if the patch supports it
            # TODO: fetch PatchMeta.auto_reapply from registry to decide
            apply_result = engine.reapply_patch(patch.patch_id, [patch.account_id])
            if apply_result.success:
                results[patch.patch_id] = "reapplied"
                if notify:
                    _send_notification(
                        "Patch re-applied",
                        f'"{patch.patch_id}" was automatically re-applied.',
                    )
            else:
                results[patch.patch_id] = "outdated"
                if notify:
                    _send_notification(
                        "Patch needs attention",
                        f'"{patch.patch_id}" markers failed. Open Deck Patcher to fix.',
                    )
        except Exception as exc:
            results[patch.patch_id] = f"error: {exc}"

    return results


def _send_notification(
    title: str,
    body: str,
    app_name: str = "Deck Patcher",
) -> None:
    """Send a desktop notification via notify-send on the host."""
    run_on_host(["notify-send", "--app-name", app_name, title, body])

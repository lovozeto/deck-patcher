"""Core patch application, revert, and setup logic."""
from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from backup_manager import create_backup, restore_backup
from host_runner import run_on_host
from marker_checker import check_markers
from patch_registry import PatchMeta, download_patch, fetch_index
from state_manager import (
    record_apply,
    record_revert,
    should_show_reapply_alert,
)
from steam_utils import get_steam_dir
from vdf_utils import add_shortcut


@dataclass
class ApplyResult:
    patch_id: str
    success: bool
    account_results: dict[str, bool] = field(default_factory=dict)
    error: str | None = None
    show_reapply_alert: bool = False


@dataclass
class RevertResult:
    patch_id: str
    success: bool
    account_results: dict[str, bool] = field(default_factory=dict)
    error: str | None = None


@dataclass
class SetupResult:
    success: bool
    steps_completed: list[str] = field(default_factory=list)
    error: str | None = None


class PatcherEngine:
    def __init__(
        self,
        registry_url: str,
        state_dir: Path | None = None,
    ) -> None:
        self._registry_url = registry_url
        self._state_dir = state_dir or Path("~/.local/share/deck-patcher").expanduser()
        self._patch_cache_dir = self._state_dir / "patches"

    def _get_patch_meta(self, patch_id: str) -> PatchMeta | None:
        """Retrieve PatchMeta for a given patch_id from the index."""
        patches = fetch_index(self._registry_url)
        for p in patches:
            if p.id == patch_id:
                return p
        return None

    def _build_env(
        self,
        patch_id: str,
        account_id: str,
    ) -> dict[str, str]:
        """Build the environment variables passed to apply/revert scripts."""
        steam_dir = get_steam_dir()
        patch_data_dir = self._patch_cache_dir / patch_id
        return {
            "STEAM_DIR": str(steam_dir),
            "STEAMID64": "",  # caller fills this if known
            "PATCH_DATA_DIR": str(patch_data_dir),
            "STATE_DIR": str(self._state_dir),
            "COMPAT_DIR": str(steam_dir / "steamapps" / "compatdata"),
            "GAME_DIR": "",  # caller fills this from InstalledGame.install_dir
            "USERDATA_ID": account_id,
        }

    def apply_patch(
        self,
        patch_id: str,
        account_ids: list[str],
    ) -> ApplyResult:
        """Apply a patch for each account in account_ids.

        Steps per account:
        1. Download patch files.
        2. Create backup.
        3. Run apply.sh via host_runner.
        4. On failure: run revert.sh; if that also fails, restore_backup.
        5. On success: record_apply + check_markers.
        After all accounts: check should_show_reapply_alert.
        """
        meta = self._get_patch_meta(patch_id)
        if meta is None:
            return ApplyResult(
                patch_id=patch_id,
                success=False,
                error=f"Patch '{patch_id}' not found in registry.",
            )

        try:
            download_patch(self._registry_url, patch_id, self._patch_cache_dir)
        except Exception as exc:  # noqa: BLE001
            return ApplyResult(
                patch_id=patch_id,
                success=False,
                error=f"Failed to download patch files: {exc}",
            )

        apply_script = self._patch_cache_dir / patch_id / "apply.sh"
        revert_script = self._patch_cache_dir / patch_id / "revert.sh"
        account_results: dict[str, bool] = {}

        for account_id in account_ids:
            env = self._build_env(patch_id, account_id)

            # Back up before any changes
            try:
                manifest = create_backup(patch_id, meta.modifications)
            except Exception:  # noqa: BLE001
                account_results[account_id] = False
                continue

            # Run apply.sh
            result = run_on_host([str(apply_script)], env=env)
            if result.returncode != 0:
                # Attempt revert
                revert_result = run_on_host([str(revert_script)], env=env)
                if revert_result.returncode != 0:
                    # Last resort: restore from backup
                    restore_backup(manifest)
                account_results[account_id] = False
                continue

            # Record success and verify markers
            record_apply(
                patch_id=patch_id,
                account_id=account_id,
                version=meta.version,
                backup_path=str(self._patch_cache_dir / patch_id),
            )
            check_markers(meta.markers, env_vars=env)
            account_results[account_id] = True

        overall_success = any(v for v in account_results.values())
        show_alert = overall_success and should_show_reapply_alert(patch_id)

        return ApplyResult(
            patch_id=patch_id,
            success=overall_success,
            account_results=account_results,
            show_reapply_alert=show_alert,
        )

    def revert_patch(
        self,
        patch_id: str,
        account_ids: list[str],
    ) -> RevertResult:
        """Revert a patch for each account by running revert.sh."""
        revert_script = self._patch_cache_dir / patch_id / "revert.sh"
        account_results: dict[str, bool] = {}

        for account_id in account_ids:
            env = self._build_env(patch_id, account_id)
            result = run_on_host([str(revert_script)], env=env)
            if result.returncode == 0:
                record_revert(patch_id=patch_id, account_id=account_id)
                account_results[account_id] = True
            else:
                account_results[account_id] = False

        return RevertResult(
            patch_id=patch_id,
            success=any(v for v in account_results.values()),
            account_results=account_results,
        )

    def reapply_patch(
        self,
        patch_id: str,
        account_ids: list[str],
    ) -> ApplyResult:
        """Revert then re-apply a patch. Used by the update watcher."""
        self.revert_patch(patch_id, account_ids)
        return self.apply_patch(patch_id, account_ids)

    def setup_app(
        self,
        patch_id: str,
        account_ids: list[str],
    ) -> SetupResult:
        """Run the full app setup wizard: install Flatpak, add shortcut, apply patch.

        Steps:
        1. Install the Flatpak specified in app_setup via flatpak install --user.
        2. Add a non-Steam shortcut to shortcuts.vdf for each account.
        3. Apply the bundled patch if present.
        """
        meta = self._get_patch_meta(patch_id)
        if meta is None:
            return SetupResult(success=False, error=f"Patch '{patch_id}' not found.")

        steps: list[str] = []
        app_setup: dict[str, Any] = meta.app_setup

        # Step 1: install Flatpak
        flatpak_id: str | None = app_setup.get("flatpak_id")
        if flatpak_id:
            result = run_on_host(
                [
                    "flatpak",
                    "install",
                    "--user",
                    "--noninteractive",
                    "flathub",
                    flatpak_id,
                ]
            )
            if result.returncode != 0:
                return SetupResult(
                    success=False,
                    steps_completed=steps,
                    error=f"flatpak install failed: {result.stderr}",
                )
            steps.append(f"installed_flatpak:{flatpak_id}")

        # Step 2: add shortcut
        shortcut_data: dict[str, Any] | None = app_setup.get("shortcut")
        if shortcut_data:
            for account_id in account_ids:
                try:
                    appid = add_shortcut(account_id, shortcut_data)
                    steps.append(f"added_shortcut:{account_id}:{appid}")
                except Exception as exc:  # noqa: BLE001
                    return SetupResult(
                        success=False,
                        steps_completed=steps,
                        error=f"add_shortcut failed for {account_id}: {exc}",
                    )

        # Step 3: apply bundled patch
        if app_setup.get("apply_patch", False):
            apply_result = self.apply_patch(patch_id, account_ids)
            if not apply_result.success:
                return SetupResult(
                    success=False,
                    steps_completed=steps,
                    error=f"patch apply failed: {apply_result.error}",
                )
            steps.append("applied_patch")

        return SetupResult(success=True, steps_completed=steps)

"""Deck Patcher — main entry point."""
from __future__ import annotations

import argparse
import sys
from pathlib import Path


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="deck-patcher",
        description="Community patch manager for Steam Deck",
    )
    parser.add_argument(
        "--check-updates",
        action="store_true",
        help="Run marker checks and auto-reapply without launching the GUI",
    )
    return parser.parse_args()


def _run_check() -> int:
    """Run the background update watcher check and return an exit code."""
    from update_watcher import run_check

    results = run_check(notify=True)
    for patch_id, status in results.items():
        print(f"{patch_id}: {status}")
    return 0


def _launch_gui() -> int:
    """Launch the Kirigami QML application.

    TODO: Switch from PyQt5 to PySide6/PyQt6 once the Flatpak base image
    ships Qt 6 bindings. For now this stub uses QtWidgets as a placeholder
    to keep the import chain valid.
    """
    try:
        # TODO: replace with PySide6 / PyQt6 once the base app supports Qt 6
        from PyQt5.QtCore import QUrl  # type: ignore[import-not-found]
        from PyQt5.QtQml import QQmlApplicationEngine  # type: ignore[import-not-found]
        from PyQt5.QtWidgets import QApplication  # type: ignore[import-not-found]
    except ImportError as exc:
        print(f"ERROR: Qt bindings not available: {exc}", file=sys.stderr)
        return 1

    from patch_registry import DEFAULT_REGISTRY_URL
    from patcher_engine import PatcherEngine
    from state_manager import get_applied_patches

    app = QApplication(sys.argv)
    app.setApplicationName("DeckPatcher")
    app.setOrganizationName("lovozeto")

    engine_obj = PatcherEngine(registry_url=DEFAULT_REGISTRY_URL)

    qml_engine = QQmlApplicationEngine()

    # Expose Python objects to QML
    ctx = qml_engine.rootContext()
    ctx.setContextProperty("patcherEngine", engine_obj)
    ctx.setContextProperty("appliedPatches", get_applied_patches())
    ctx.setContextProperty("registryUrl", DEFAULT_REGISTRY_URL)

    qml_main = Path(__file__).parent / "qml" / "main.qml"
    qml_engine.load(QUrl.fromLocalFile(str(qml_main)))

    if not qml_engine.rootObjects():
        print("ERROR: Failed to load main.qml", file=sys.stderr)
        return 1

    return int(app.exec_())


def main() -> int:
    args = _parse_args()
    if args.check_updates:
        return _run_check()
    return _launch_gui()


if __name__ == "__main__":
    sys.exit(main())

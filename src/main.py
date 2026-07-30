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
    """Launch the Kirigami QML application via PyQt6."""
    try:
        from PyQt6.QtCore import QUrl  # type: ignore[import-not-found]
        from PyQt6.QtQml import QQmlApplicationEngine  # type: ignore[import-not-found]
        from PyQt6.QtWidgets import QApplication  # type: ignore[import-not-found]
    except ImportError as exc:
        print(f"ERROR: Qt bindings not available: {exc}", file=sys.stderr)
        return 1

    from backend import DeckPatcherBackend

    app = QApplication(sys.argv)
    app.setApplicationName("DeckPatcher")
    app.setOrganizationName("lovozeto")

    backend = DeckPatcherBackend()

    qml_engine = QQmlApplicationEngine()

    ctx = qml_engine.rootContext()
    ctx.setContextProperty("backend", backend)

    qml_main = Path(__file__).parent / "qml" / "main.qml"
    qml_engine.load(QUrl.fromLocalFile(str(qml_main)))

    if not qml_engine.rootObjects():
        print("ERROR: Failed to load main.qml", file=sys.stderr)
        return 1

    return int(app.exec())


def main() -> int:
    args = _parse_args()
    if args.check_updates:
        return _run_check()
    return _launch_gui()


if __name__ == "__main__":
    sys.exit(main())

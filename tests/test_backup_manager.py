"""Tests for backup_manager.py."""
from __future__ import annotations

import json
import sys
from pathlib import Path
from unittest.mock import patch

import pytest

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

import backup_manager


@pytest.fixture(autouse=True)
def _redirect_backup_base(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(backup_manager, "BACKUP_BASE", tmp_path / "backups")


def test_create_backup_copies_file(tmp_path: Path) -> None:
    # Create a real file to back up
    source = tmp_path / "myfile.txt"
    source.write_text("original content")

    modifications = [{"target": str(source)}]
    manifest = backup_manager.create_backup("test-patch", modifications)

    assert manifest.patch_id == "test-patch"
    assert len(manifest.entries) == 1

    entry = manifest.entries[0]
    assert entry.pre_existing is True
    assert entry.was_symlink is False
    # The backup copy must exist and contain the original content
    assert Path(entry.backup_path).read_text() == "original content"


def test_restore_backup_restores_file(tmp_path: Path) -> None:
    source = tmp_path / "myfile.txt"
    source.write_text("original")

    modifications = [{"target": str(source)}]
    manifest = backup_manager.create_backup("test-patch", modifications)

    # Simulate the patch overwriting the file
    source.write_text("patched")

    restored = backup_manager.restore_backup(manifest)

    assert str(source) in restored
    assert source.read_text() == "original"


def test_manifest_written_correctly(tmp_path: Path) -> None:
    source = tmp_path / "config.cfg"
    source.write_text("value=1")

    modifications = [{"target": str(source)}]
    manifest = backup_manager.create_backup("my-patch", modifications)

    # Find the manifest JSON on disk
    backup_root = backup_manager.BACKUP_BASE / "my-patch" / manifest.timestamp
    manifest_path = backup_root / "rollback-manifest.json"

    assert manifest_path.exists()
    with open(manifest_path) as f:
        data = json.load(f)

    assert data["patch_id"] == "my-patch"
    assert len(data["entries"]) == 1
    assert data["entries"][0]["original_path"] == str(source)


def test_cleanup_keeps_last_n_backups(tmp_path: Path) -> None:
    # Create four fake backup directories
    patch_dir = backup_manager.BACKUP_BASE / "old-patch"
    patch_dir.mkdir(parents=True)
    for name in ["20260101T000000Z", "20260102T000000Z", "20260103T000000Z", "20260104T000000Z"]:
        (patch_dir / name).mkdir()

    backup_manager.cleanup_old_backups("old-patch", keep=2)

    remaining = sorted(d.name for d in patch_dir.iterdir())
    assert remaining == ["20260103T000000Z", "20260104T000000Z"]

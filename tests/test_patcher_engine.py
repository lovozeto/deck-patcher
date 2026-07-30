"""Tests for patcher_engine.py."""
from __future__ import annotations

import sys
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from patch_registry import PatchMeta
from patcher_engine import PatcherEngine


def _make_meta(patch_id: str = "test-patch") -> PatchMeta:
    return PatchMeta(
        id=patch_id,
        name="Test Patch",
        description="A test patch",
        game="Test Game",
        appid="12345",
        version="1.0.0",
        author="tester",
        category="fixes",
        type="game",
        tags=[],
        min_steamos="3.5",
        reversible=True,
        auto_reapply=False,
        requirements=[],
        markers=[],
        modifications=[{"target": "/tmp/fake-file"}],
        app_setup={},
    )


def _make_engine(tmp_path: Path) -> PatcherEngine:
    return PatcherEngine(
        registry_url="https://example.com/index.json",
        state_dir=tmp_path / "state",
    )


@pytest.fixture(autouse=True)
def _patch_state_file(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    import state_manager

    monkeypatch.setattr(state_manager, "STATE_FILE", tmp_path / "state.json")


def test_apply_patch_success(tmp_path: Path) -> None:
    engine = _make_engine(tmp_path)
    meta = _make_meta()

    # Create a fake apply.sh so host_runner has something to point at
    patch_dir = engine._patch_cache_dir / "test-patch"
    patch_dir.mkdir(parents=True)
    (patch_dir / "apply.sh").write_text("#!/bin/bash\nexit 0")
    (patch_dir / "revert.sh").write_text("#!/bin/bash\nexit 0")

    mock_run_ok = MagicMock(returncode=0, stdout="", stderr="")
    mock_manifest = MagicMock()
    mock_manifest.entries = []

    with (
        patch("patcher_engine.fetch_index", return_value=[meta]),
        patch("patcher_engine.download_patch"),
        patch("patcher_engine.create_backup", return_value=mock_manifest),
        patch("patcher_engine.run_on_host", return_value=mock_run_ok),
        patch("patcher_engine.record_apply"),
        patch("patcher_engine.check_markers", return_value=[]),
        patch("patcher_engine.should_show_reapply_alert", return_value=False),
        patch("patcher_engine.get_steam_dir", return_value=tmp_path / "steam"),
    ):
        result = engine.apply_patch("test-patch", ["account-1"])

    assert result.success is True
    assert result.account_results == {"account-1": True}
    assert result.error is None


def test_apply_patch_failure_triggers_rollback(tmp_path: Path) -> None:
    engine = _make_engine(tmp_path)
    meta = _make_meta()

    mock_run_fail = MagicMock(returncode=1, stdout="", stderr="apply failed")
    mock_manifest = MagicMock()
    mock_manifest.entries = []

    with (
        patch("patcher_engine.fetch_index", return_value=[meta]),
        patch("patcher_engine.download_patch"),
        patch("patcher_engine.create_backup", return_value=mock_manifest),
        patch("patcher_engine.run_on_host", return_value=mock_run_fail),
        patch("patcher_engine.restore_backup") as mock_restore,
        patch("patcher_engine.get_steam_dir", return_value=tmp_path / "steam"),
    ):
        result = engine.apply_patch("test-patch", ["account-1"])

    assert result.success is False
    assert result.account_results == {"account-1": False}
    # restore_backup called because revert.sh also returned non-zero
    mock_restore.assert_called_once_with(mock_manifest)


def test_revert_patch(tmp_path: Path) -> None:
    engine = _make_engine(tmp_path)

    mock_run_ok = MagicMock(returncode=0, stdout="", stderr="")

    with (
        patch("patcher_engine.run_on_host", return_value=mock_run_ok),
        patch("patcher_engine.record_revert") as mock_record,
        patch("patcher_engine.get_steam_dir", return_value=tmp_path / "steam"),
    ):
        result = engine.revert_patch("test-patch", ["account-1"])

    assert result.success is True
    assert result.account_results == {"account-1": True}
    mock_record.assert_called_once_with(patch_id="test-patch", account_id="account-1")


def test_multi_account_apply(tmp_path: Path) -> None:
    engine = _make_engine(tmp_path)
    meta = _make_meta()

    mock_run_ok = MagicMock(returncode=0, stdout="", stderr="")
    mock_manifest = MagicMock()
    mock_manifest.entries = []

    with (
        patch("patcher_engine.fetch_index", return_value=[meta]),
        patch("patcher_engine.download_patch"),
        patch("patcher_engine.create_backup", return_value=mock_manifest),
        patch("patcher_engine.run_on_host", return_value=mock_run_ok),
        patch("patcher_engine.record_apply"),
        patch("patcher_engine.check_markers", return_value=[]),
        patch("patcher_engine.should_show_reapply_alert", return_value=False),
        patch("patcher_engine.get_steam_dir", return_value=tmp_path / "steam"),
    ):
        result = engine.apply_patch("test-patch", ["account-1", "account-2"])

    assert result.success is True
    assert result.account_results["account-1"] is True
    assert result.account_results["account-2"] is True

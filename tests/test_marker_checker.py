"""Tests for marker_checker.py."""
from __future__ import annotations

import os
import sys
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

import marker_checker


ENV = {
    "HOME": "/home/deck",
    "STEAM_DIR": "/home/deck/.local/share/Steam",
    "COMPAT_DIR": "/home/deck/.local/share/Steam/steamapps/compatdata",
    "GAME_DIR": "/home/deck/.local/share/Steam/steamapps/common/TestGame",
    "USERDATA_ID": "123456789",
}


def test_file_exists_passes(tmp_path: Path) -> None:
    target = tmp_path / "myfile.txt"
    target.write_text("hello")

    markers = [{"type": "file_exists", "path": str(target)}]
    results = marker_checker.check_markers(markers, ENV)

    assert len(results) == 1
    assert results[0].passed is True
    assert results[0].marker_type == "file_exists"


def test_file_exists_fails(tmp_path: Path) -> None:
    markers = [{"type": "file_exists", "path": str(tmp_path / "missing.txt")}]
    results = marker_checker.check_markers(markers, ENV)

    assert results[0].passed is False
    assert results[0].actual == "missing"


def test_dir_exists(tmp_path: Path) -> None:
    sub = tmp_path / "subdir"
    sub.mkdir()

    markers = [{"type": "dir_exists", "path": str(sub)}]
    results = marker_checker.check_markers(markers, ENV)
    assert results[0].passed is True

    markers_missing = [{"type": "dir_exists", "path": str(tmp_path / "nope")}]
    results_missing = marker_checker.check_markers(markers_missing, ENV)
    assert results_missing[0].passed is False


def test_symlink_target_contains(tmp_path: Path) -> None:
    real_dir = tmp_path / "real"
    real_dir.mkdir()
    link = tmp_path / "link"
    link.symlink_to(real_dir)

    markers = [{"type": "symlink_target", "path": str(link), "target": "real"}]
    results = marker_checker.check_markers(markers, ENV)
    assert results[0].passed is True

    markers_wrong = [{"type": "symlink_target", "path": str(link), "target": "wrong"}]
    results_wrong = marker_checker.check_markers(markers_wrong, ENV)
    assert results_wrong[0].passed is False


def test_service_active_mocks_host_runner() -> None:
    mock_result = MagicMock()
    mock_result.returncode = 0
    mock_result.stdout = "active"
    mock_result.stderr = ""

    with patch("marker_checker.run_on_host", return_value=mock_result):
        markers = [{"type": "service_active", "service": "myservice.service"}]
        results = marker_checker.check_markers(markers, ENV)

    assert results[0].passed is True
    assert results[0].actual == "active"


def test_variable_expansion() -> None:
    env = {
        "HOME": "/home/deck",
        "STEAM_DIR": "/home/deck/.local/share/Steam",
        "COMPAT_DIR": "/compat",
        "GAME_DIR": "/gamedir",
    }
    result = marker_checker._expand_vars("$HOME/.config", env)
    assert result == "/home/deck/.config"

    result2 = marker_checker._expand_vars("$STEAM_DIR/config", env)
    assert result2 == "/home/deck/.local/share/Steam/config"

    result3 = marker_checker._expand_vars("$GAME_DIR/file.txt", env)
    assert result3 == "/gamedir/file.txt"

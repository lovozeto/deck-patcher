"""Tests for vdf_utils.py."""
from __future__ import annotations

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

import vdf_utils


def test_generate_non_steam_appid_deterministic() -> None:
    appid1 = vdf_utils.generate_non_steam_appid("/usr/bin/myapp", "My App")
    appid2 = vdf_utils.generate_non_steam_appid("/usr/bin/myapp", "My App")
    assert appid1 == appid2


def test_generate_non_steam_appid_correct_format() -> None:
    """The high bit (0x80000000) must always be set."""
    appid = vdf_utils.generate_non_steam_appid("/usr/bin/something", "Something")
    assert appid & 0x80000000 != 0, "High bit must be set for non-Steam shortcut IDs"
    # Must fit in an unsigned 32-bit integer
    assert 0 <= appid <= 0xFFFFFFFF


def test_text_vdf_round_trip(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    """Writing then reading a text VDF should reproduce the original data."""
    import steam_utils

    monkeypatch.setattr(steam_utils, "get_steam_dir", lambda: tmp_path)

    vdf_path = tmp_path / "test.vdf"
    original_data = {
        "Config": {
            "key1": "value1",
            "nested": {"a": "1", "b": "2"},
        }
    }

    vdf_utils.write_text_vdf(vdf_path, original_data)
    loaded = vdf_utils.read_text_vdf(vdf_path)

    assert loaded["Config"]["key1"] == "value1"
    assert loaded["Config"]["nested"]["a"] == "1"


def test_bak_created_before_write(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    """A .bak file must be created when overwriting an existing VDF file."""
    import steam_utils

    monkeypatch.setattr(steam_utils, "get_steam_dir", lambda: tmp_path)

    vdf_path = tmp_path / "data.vdf"
    original = {"root": {"val": "original"}}
    updated = {"root": {"val": "updated"}}

    vdf_utils.write_text_vdf(vdf_path, original)
    vdf_utils.write_text_vdf(vdf_path, updated)  # second write triggers .bak

    bak_path = Path(str(vdf_path) + ".bak")
    assert bak_path.exists(), ".bak file must be created on overwrite"
    bak_data = vdf_utils.read_text_vdf(bak_path)
    assert bak_data["root"]["val"] == "original"

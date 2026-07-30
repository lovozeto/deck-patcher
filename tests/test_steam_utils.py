"""Tests for steam_utils.py."""
from __future__ import annotations

import sys
from pathlib import Path
from unittest.mock import MagicMock, mock_open, patch

import pytest

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

import steam_utils


SAMPLE_LOGINUSERS = {
    "users": {
        "76561198000000001": {
            "PersonaName": "Alice",
            "MostRecent": "0",
        },
        "76561198000000002": {
            "PersonaName": "Bob",
            "MostRecent": "1",
        },
    }
}

SAMPLE_LIBRARYFOLDERS = {
    "libraryfolders": {
        "0": {
            "path": "/home/deck/.local/share/Steam",
            "apps": {"12345": "1"},
        }
    }
}

SAMPLE_APPMANIFEST = {
    "AppState": {
        "appid": "12345",
        "name": "Test Game",
        "installdir": "TestGame",
    }
}


@pytest.fixture()
def steam_dir(tmp_path: Path) -> Path:
    d = tmp_path / ".local" / "share" / "Steam"
    d.mkdir(parents=True)
    return d


def test_get_all_accounts_parses_loginusers(
    steam_dir: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setattr(steam_utils, "get_steam_dir", lambda: steam_dir)

    config = steam_dir / "config"
    config.mkdir()

    import vdf
    with open(config / "loginusers.vdf", "w") as f:
        vdf.dump(SAMPLE_LOGINUSERS, f)

    accounts = steam_utils.get_all_accounts()
    assert len(accounts) == 2
    names = {a.persona_name for a in accounts}
    assert names == {"Alice", "Bob"}


def test_get_active_account_most_recent(
    steam_dir: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setattr(steam_utils, "get_steam_dir", lambda: steam_dir)

    config = steam_dir / "config"
    config.mkdir(exist_ok=True)

    import vdf
    with open(config / "loginusers.vdf", "w") as f:
        vdf.dump(SAMPLE_LOGINUSERS, f)

    active = steam_utils.get_active_account()
    assert active.persona_name == "Bob"
    assert active.steam_id64 == "76561198000000002"


def test_get_installed_games_parses_appmanifests(
    steam_dir: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setattr(steam_utils, "get_steam_dir", lambda: steam_dir)

    steamapps = steam_dir / "steamapps"
    steamapps.mkdir()

    import vdf

    # Write libraryfolders.vdf
    with open(steamapps / "libraryfolders.vdf", "w") as f:
        vdf.dump(SAMPLE_LIBRARYFOLDERS, f)

    # Write an appmanifest
    with open(steamapps / "appmanifest_12345.acf", "w") as f:
        vdf.dump(SAMPLE_APPMANIFEST, f)

    games = steam_utils.get_installed_games()
    assert len(games) == 1
    assert games[0].appid == "12345"
    assert games[0].name == "Test Game"
    assert games[0].install_dir == "TestGame"

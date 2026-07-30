"""Tests for patch_registry.py."""
from __future__ import annotations

import json
import sys
import time
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

import patch_registry

SAMPLE_INDEX = [
    {
        "id": "proton-fix-1",
        "name": "Proton Fix 1",
        "description": "Fixes a Proton issue",
        "game": "Test Game",
        "appid": "12345",
        "version": "1.0.0",
        "author": "tester",
        "category": "fixes",
        "type": "game",
        "tags": ["proton"],
        "min_steamos": "3.5",
        "reversible": True,
        "auto_reapply": False,
        "requirements": [],
        "markers": [],
        "modifications": [],
        "app_setup": {},
    }
]

SAMPLE_README = "# Proton Fix 1\n\nThis fixes a known Proton issue."


@pytest.fixture(autouse=True)
def _redirect_cache(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    cache_dir = tmp_path / "cache"
    cache_dir.mkdir()
    monkeypatch.setattr(patch_registry, "_CACHE_DIR", cache_dir)
    monkeypatch.setattr(patch_registry, "_CACHE_INDEX", cache_dir / "index.json")


def _mock_response(data: object) -> MagicMock:
    resp = MagicMock()
    resp.raise_for_status = MagicMock()
    resp.json = MagicMock(return_value=data)
    resp.text = data if isinstance(data, str) else json.dumps(data)
    return resp


def test_fetch_index_parses_json() -> None:
    with patch("patch_registry.requests.get", return_value=_mock_response(SAMPLE_INDEX)):
        patches = patch_registry.fetch_index()

    assert len(patches) == 1
    p = patches[0]
    assert p.id == "proton-fix-1"
    assert p.name == "Proton Fix 1"
    assert p.reversible is True
    assert p.tags == ["proton"]


def test_fetch_index_caches_result(tmp_path: Path) -> None:
    with patch("patch_registry.requests.get", return_value=_mock_response(SAMPLE_INDEX)) as mock_get:
        patch_registry.fetch_index()
        patch_registry.fetch_index()  # second call should hit cache

    # requests.get must only be called once
    assert mock_get.call_count == 1


def test_cache_respected_within_ttl() -> None:
    cache_file = patch_registry._CACHE_INDEX
    cache_file.write_text(json.dumps(SAMPLE_INDEX), encoding="utf-8")
    # Touch with a very recent mtime (now)
    cache_file.touch()

    with patch("patch_registry.requests.get") as mock_get:
        patches = patch_registry.fetch_index()

    assert mock_get.call_count == 0
    assert patches[0].id == "proton-fix-1"


def test_cache_refreshed_after_ttl(monkeypatch: pytest.MonkeyPatch) -> None:
    cache_file = patch_registry._CACHE_INDEX
    cache_file.write_text(json.dumps(SAMPLE_INDEX), encoding="utf-8")

    # Pretend the TTL is 0 so cache is always stale
    monkeypatch.setattr(patch_registry, "_CACHE_TTL_SECONDS", 0)

    with patch("patch_registry.requests.get", return_value=_mock_response(SAMPLE_INDEX)) as mock_get:
        patch_registry.fetch_index()

    assert mock_get.call_count == 1


def test_fetch_readme() -> None:
    with patch("patch_registry.requests.get", return_value=_mock_response(SAMPLE_README)):
        readme = patch_registry.fetch_readme("proton-fix-1")

    assert "Proton Fix 1" in readme

"""Patch registry: fetch, cache, and download patches from the remote index."""
from __future__ import annotations

import json
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import requests

DEFAULT_REGISTRY_URL = (
    "https://raw.githubusercontent.com/lovozeto/deck-patches/main/index.json"
)
DEFAULT_README_URL = (
    "https://raw.githubusercontent.com/lovozeto/deck-patches/main/patches/{patch_id}/README.md"
)

_CACHE_DIR = Path("~/.local/share/deck-patcher/cache").expanduser()
_CACHE_INDEX = _CACHE_DIR / "index.json"
_CACHE_TTL_SECONDS = 3600  # 1 hour


@dataclass
class PatchMeta:
    id: str
    name: str
    description: str
    game: str
    appid: str
    version: str
    author: str
    category: str
    type: str
    tags: list[str] = field(default_factory=list)
    min_steamos: str = ""
    reversible: bool = True
    auto_reapply: bool = False
    requirements: list[str] = field(default_factory=list)
    markers: list[dict[str, Any]] = field(default_factory=list)
    modifications: list[dict[str, Any]] = field(default_factory=list)
    app_setup: dict[str, Any] = field(default_factory=dict)

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "PatchMeta":
        return cls(
            id=str(data.get("id", "")),
            name=str(data.get("name", "")),
            description=str(data.get("description", "")),
            game=str(data.get("game", "")),
            appid=str(data.get("appid", "")),
            version=str(data.get("version", "0.0.1")),
            author=str(data.get("author", "")),
            category=str(data.get("category", "")),
            type=str(data.get("type", "game")),
            tags=list(data.get("tags", [])),
            min_steamos=str(data.get("min_steamos", "")),
            reversible=bool(data.get("reversible", True)),
            auto_reapply=bool(data.get("auto_reapply", False)),
            requirements=list(data.get("requirements", [])),
            markers=list(data.get("markers", [])),
            modifications=list(data.get("modifications", [])),
            app_setup=dict(data.get("app_setup", {})),
        )


def _is_cache_valid() -> bool:
    if not _CACHE_INDEX.exists():
        return False
    age = time.time() - _CACHE_INDEX.stat().st_mtime
    return age < _CACHE_TTL_SECONDS


def fetch_index(repo_url: str = DEFAULT_REGISTRY_URL) -> list[PatchMeta]:
    """Fetch the patch index from the registry, respecting a 1-hour cache.

    Returns a list of PatchMeta objects.
    """
    if _is_cache_valid():
        with open(_CACHE_INDEX, encoding="utf-8") as f:
            raw: list[dict[str, Any]] = json.load(f)
        return [PatchMeta.from_dict(item) for item in raw]

    response = requests.get(repo_url, timeout=15)
    response.raise_for_status()
    raw = response.json()

    _CACHE_DIR.mkdir(parents=True, exist_ok=True)
    with open(_CACHE_INDEX, "w", encoding="utf-8") as f:
        json.dump(raw, f)

    return [PatchMeta.from_dict(item) for item in raw]


def fetch_readme(patch_id: str) -> str:
    """Fetch the README.md for a patch from GitHub raw."""
    url = DEFAULT_README_URL.format(patch_id=patch_id)
    response = requests.get(url, timeout=15)
    response.raise_for_status()
    return response.text


def download_patch(repo_url: str, patch_id: str, dest_dir: Path) -> None:
    """Download apply.sh, revert.sh, and README.md for a patch.

    Files are placed in dest_dir/<patch_id>/.
    """
    # Derive the base URL for patch files from the index URL
    # e.g. https://raw.githubusercontent.com/lovozeto/deck-patches/main/index.json
    # → https://raw.githubusercontent.com/lovozeto/deck-patches/main/patches/<id>/
    base = repo_url.rsplit("/", 1)[0]
    patch_base = f"{base}/patches/{patch_id}"

    target = dest_dir / patch_id
    target.mkdir(parents=True, exist_ok=True)

    for filename in ("apply.sh", "revert.sh", "README.md"):
        url = f"{patch_base}/{filename}"
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        out_path = target / filename
        out_path.write_bytes(response.content)
        if filename.endswith(".sh"):
            out_path.chmod(0o755)

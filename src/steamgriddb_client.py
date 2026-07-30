"""SteamGridDB API client for fetching and applying game artwork."""
from __future__ import annotations

import shutil
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from urllib.parse import quote

import requests

from steam_utils import get_steam_dir


@dataclass
class SteamGridDBGame:
    id: int
    name: str
    release_date: str | None
    steam_appid: int | None


@dataclass
class SteamGridDBImage:
    id: int
    url: str
    width: int
    height: int
    mime: str
    style: str


# Mapping from artwork_type to the filename suffix Steam uses
_ARTWORK_SUFFIX: dict[str, str] = {
    "grid": "p",       # portrait grid  → <appid>p.jpg
    "wide": "",        # wide grid       → <appid>.jpg
    "hero": "_hero",   # hero banner     → <appid>_hero.jpg
    "logo": "_logo",   # logo overlay    → <appid>_logo.png
    "icon": "_icon",   # icon            → <appid>_icon.ico
}

_ARTWORK_EXT: dict[str, str] = {
    "grid": ".jpg",
    "wide": ".jpg",
    "hero": ".jpg",
    "logo": ".png",
    "icon": ".ico",
}


class SteamGridDBClient:
    BASE_URL = "https://www.steamgriddb.com/api/v2"

    def __init__(self, api_key: str) -> None:
        self._api_key = api_key
        self._session = requests.Session()
        self._session.headers.update({"Authorization": f"Bearer {api_key}"})

    def _get(self, endpoint: str) -> dict[str, Any]:
        """Make an authenticated GET request to the SteamGridDB API."""
        url = f"{self.BASE_URL}/{endpoint.lstrip('/')}"
        response = self._session.get(url, timeout=15)
        response.raise_for_status()
        return dict(response.json())

    def search_game(self, query: str) -> list[SteamGridDBGame]:
        """Search SteamGridDB for games matching a query string."""
        data = self._get(f"search/autocomplete/{quote(query)}")
        results: list[SteamGridDBGame] = []
        for item in data.get("data", []):
            results.append(
                SteamGridDBGame(
                    id=int(item.get("id", 0)),
                    name=str(item.get("name", "")),
                    release_date=item.get("release_date"),
                    steam_appid=item.get("steam_appid"),
                )
            )
        return results

    def get_grids(self, game_id: int) -> list[SteamGridDBImage]:
        """Return portrait grid images for a game."""
        return self._get_images(f"grids/game/{game_id}")

    def get_heroes(self, game_id: int) -> list[SteamGridDBImage]:
        """Return hero banner images for a game."""
        return self._get_images(f"heroes/game/{game_id}")

    def get_logos(self, game_id: int) -> list[SteamGridDBImage]:
        """Return logo overlay images for a game."""
        return self._get_images(f"logos/game/{game_id}")

    def get_icons(self, game_id: int) -> list[SteamGridDBImage]:
        """Return icon images for a game."""
        return self._get_images(f"icons/game/{game_id}")

    def _get_images(self, endpoint: str) -> list[SteamGridDBImage]:
        data = self._get(endpoint)
        images: list[SteamGridDBImage] = []
        for item in data.get("data", []):
            images.append(
                SteamGridDBImage(
                    id=int(item.get("id", 0)),
                    url=str(item.get("url", "")),
                    width=int(item.get("width", 0)),
                    height=int(item.get("height", 0)),
                    mime=str(item.get("mime", "image/jpeg")),
                    style=str(item.get("style", "")),
                )
            )
        return images

    def download_artwork(self, url: str, dest_path: Path) -> None:
        """Download an image from a URL to dest_path."""
        dest_path.parent.mkdir(parents=True, exist_ok=True)
        response = self._session.get(url, timeout=30, stream=True)
        response.raise_for_status()
        with open(dest_path, "wb") as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)

    def save_artwork_to_steam(
        self,
        userdata_id: str,
        appid: int,
        artwork_type: str,
        image_path: Path,
    ) -> None:
        """Copy a locally downloaded image into Steam's grid directory.

        Steam naming convention:
          grid  → <appid>p.jpg
          wide  → <appid>.jpg
          hero  → <appid>_hero.jpg
          logo  → <appid>_logo.png
          icon  → <appid>_icon.ico
        """
        steam_dir = get_steam_dir()
        grid_dir = steam_dir / "userdata" / userdata_id / "config" / "grid"
        grid_dir.mkdir(parents=True, exist_ok=True)

        suffix = _ARTWORK_SUFFIX.get(artwork_type, "")
        ext = _ARTWORK_EXT.get(artwork_type, image_path.suffix)
        dest_name = f"{appid}{suffix}{ext}"
        dest = grid_dir / dest_name
        shutil.copy2(image_path, dest)

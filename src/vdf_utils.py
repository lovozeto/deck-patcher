"""VDF (Valve Data Format) read/write helpers and Steam shortcut utilities."""
from __future__ import annotations

import shutil
import zlib
from pathlib import Path
from typing import Any

import vdf  # type: ignore[import-untyped]

from steam_utils import get_steam_dir


def read_text_vdf(path: Path) -> dict[str, Any]:
    """Read a text-mode VDF file and return its contents as a dict."""
    with open(path, encoding="utf-8") as f:
        return dict(vdf.load(f))


def write_text_vdf(path: Path, data: dict[str, Any]) -> None:
    """Write a text-mode VDF file, creating a .bak backup first."""
    if path.exists():
        shutil.copy2(path, path.with_suffix(path.suffix + ".bak"))
    with open(path, "w", encoding="utf-8") as f:
        vdf.dump(data, f, pretty=True)


def read_binary_vdf(path: Path) -> dict[str, Any]:
    """Read a binary-mode VDF file (e.g. shortcuts.vdf) and return its contents."""
    with open(path, "rb") as f:
        return dict(vdf.binary_load(f))


def write_binary_vdf(path: Path, data: dict[str, Any]) -> None:
    """Write a binary-mode VDF file, creating a .bak backup first."""
    if path.exists():
        shutil.copy2(path, path.with_suffix(path.suffix + ".bak"))
    with open(path, "wb") as f:
        vdf.binary_dump(data, f)


def generate_non_steam_appid(exe: str, name: str) -> int:
    """Compute the non-Steam shortcut appid using Steam's own CRC32 algorithm.

    The high bit is always set (0x80000000) to distinguish from real appids.
    """
    crc = zlib.crc32(f'"{exe}"{name}'.encode()) & 0xFFFFFFFF
    return crc | 0x80000000


def add_shortcut(userdata_id: str, shortcut_data: dict[str, Any]) -> int:
    """Add a non-Steam shortcut to shortcuts.vdf for the given userdata_id.

    Returns the computed appid for the new shortcut.
    """
    steam_dir = get_steam_dir()
    shortcuts_path = steam_dir / "userdata" / userdata_id / "config" / "shortcuts.vdf"

    if shortcuts_path.exists():
        data = read_binary_vdf(shortcuts_path)
    else:
        shortcuts_path.parent.mkdir(parents=True, exist_ok=True)
        data = {"shortcuts": {}}

    shortcuts: dict[str, Any] = data.get("shortcuts", {})
    next_index = str(len(shortcuts))

    exe: str = str(shortcut_data.get("Exe", ""))
    app_name: str = str(shortcut_data.get("AppName", ""))
    appid = generate_non_steam_appid(exe, app_name)

    entry: dict[str, Any] = {"appid": appid, **shortcut_data}
    shortcuts[next_index] = entry
    data["shortcuts"] = shortcuts

    write_binary_vdf(shortcuts_path, data)
    return appid


def remove_shortcut(userdata_id: str, appid: int) -> None:
    """Remove a non-Steam shortcut by appid from shortcuts.vdf."""
    steam_dir = get_steam_dir()
    shortcuts_path = steam_dir / "userdata" / userdata_id / "config" / "shortcuts.vdf"

    if not shortcuts_path.exists():
        return

    data = read_binary_vdf(shortcuts_path)
    shortcuts: dict[str, Any] = data.get("shortcuts", {})

    updated: dict[str, Any] = {}
    new_index = 0
    for entry in shortcuts.values():
        if isinstance(entry, dict) and int(entry.get("appid", -1)) != appid:
            updated[str(new_index)] = entry
            new_index += 1

    data["shortcuts"] = updated
    write_binary_vdf(shortcuts_path, data)


def get_launch_options(userdata_id: str, appid: str) -> str:
    """Return the current launch options string for a game, or empty string."""
    steam_dir = get_steam_dir()
    localconfig_path = steam_dir / "userdata" / userdata_id / "config" / "localconfig.vdf"

    if not localconfig_path.exists():
        return ""

    data = read_text_vdf(localconfig_path)
    try:
        apps: dict[str, Any] = (
            data.get("UserLocalConfigStore", {})
            .get("Software", {})
            .get("Valve", {})
            .get("Steam", {})
            .get("apps", {})
        )
        return str(apps.get(appid, {}).get("LaunchOptions", ""))
    except (AttributeError, KeyError):
        return ""


def set_launch_options(userdata_id: str, appid: str, options: str) -> None:
    """Set the launch options string for a game in localconfig.vdf."""
    steam_dir = get_steam_dir()
    localconfig_path = steam_dir / "userdata" / userdata_id / "config" / "localconfig.vdf"

    if localconfig_path.exists():
        data = read_text_vdf(localconfig_path)
    else:
        localconfig_path.parent.mkdir(parents=True, exist_ok=True)
        data = {}

    # Navigate / create the nested path
    store: dict[str, Any] = data.setdefault("UserLocalConfigStore", {})
    software: dict[str, Any] = store.setdefault("Software", {})
    valve: dict[str, Any] = software.setdefault("Valve", {})
    steam: dict[str, Any] = valve.setdefault("Steam", {})
    apps: dict[str, Any] = steam.setdefault("apps", {})
    app_entry: dict[str, Any] = apps.setdefault(appid, {})
    app_entry["LaunchOptions"] = options

    write_text_vdf(localconfig_path, data)

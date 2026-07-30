"""Steam utilities: account discovery, installed games, process control."""
from __future__ import annotations

import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import vdf  # type: ignore[import-untyped]

from host_runner import run_on_host


@dataclass
class SteamAccount:
    steam_id64: str
    persona_name: str
    userdata_id: str


@dataclass
class InstalledGame:
    appid: str
    name: str
    install_dir: str


def get_steam_dir() -> Path:
    """Return the Steam installation directory.

    Raises FileNotFoundError if Steam is not installed.
    """
    steam_dir = Path("~/.local/share/Steam").expanduser()
    if not steam_dir.exists():
        raise FileNotFoundError(f"Steam directory not found at {steam_dir}")
    return steam_dir


def get_all_accounts() -> list[SteamAccount]:
    """Read loginusers.vdf and return all known Steam accounts."""
    steam_dir = get_steam_dir()
    loginusers_path = steam_dir / "config" / "loginusers.vdf"
    if not loginusers_path.exists():
        return []

    with open(loginusers_path, encoding="utf-8") as f:
        data: dict[str, Any] = vdf.load(f)

    accounts: list[SteamAccount] = []
    users_section: dict[str, Any] = data.get("users", {})
    for steam_id64, user_data in users_section.items():
        # userdata_id is the lower 32 bits of the 64-bit SteamID
        userdata_id = str(int(steam_id64) & 0xFFFFFFFF)
        accounts.append(
            SteamAccount(
                steam_id64=steam_id64,
                persona_name=str(user_data.get("PersonaName", "")),
                userdata_id=userdata_id,
            )
        )
    return accounts


def get_active_account() -> SteamAccount:
    """Return the account with the MostRecent flag set.

    Raises ValueError if no account has MostRecent set.
    """
    steam_dir = get_steam_dir()
    loginusers_path = steam_dir / "config" / "loginusers.vdf"

    with open(loginusers_path, encoding="utf-8") as f:
        data: dict[str, Any] = vdf.load(f)

    users_section: dict[str, Any] = data.get("users", {})
    for steam_id64, user_data in users_section.items():
        if str(user_data.get("MostRecent", "0")) == "1":
            userdata_id = str(int(steam_id64) & 0xFFFFFFFF)
            return SteamAccount(
                steam_id64=steam_id64,
                persona_name=str(user_data.get("PersonaName", "")),
                userdata_id=userdata_id,
            )

    raise ValueError("No active Steam account found (no MostRecent flag)")


def get_installed_games() -> list[InstalledGame]:
    """Parse libraryfolders.vdf and all appmanifest_*.acf files."""
    steam_dir = get_steam_dir()
    library_vdf = steam_dir / "steamapps" / "libraryfolders.vdf"
    if not library_vdf.exists():
        return []

    with open(library_vdf, encoding="utf-8") as f:
        data: dict[str, Any] = vdf.load(f)

    library_folders: list[Path] = [steam_dir / "steamapps"]
    folders_section: dict[str, Any] = data.get("libraryfolders", {})
    for folder_data in folders_section.values():
        if isinstance(folder_data, dict):
            folder_path = Path(str(folder_data.get("path", ""))) / "steamapps"
            if folder_path.exists():
                library_folders.append(folder_path)

    games: list[InstalledGame] = []
    for folder in library_folders:
        for manifest in folder.glob("appmanifest_*.acf"):
            try:
                with open(manifest, encoding="utf-8") as f:
                    manifest_data: dict[str, Any] = vdf.load(f)
                app_state: dict[str, Any] = manifest_data.get("AppState", {})
                appid = str(app_state.get("appid", ""))
                name = str(app_state.get("name", ""))
                install_dir = str(app_state.get("installdir", ""))
                if appid and name:
                    games.append(InstalledGame(appid=appid, name=name, install_dir=install_dir))
            except Exception:  # noqa: BLE001,S112
                continue

    return games


def is_steam_running() -> bool:
    """Return True if the steam process is currently running."""
    result = run_on_host(["pgrep", "-x", "steam"])
    return result.returncode == 0


def is_game_running(appid: str) -> bool:
    """Return True if the given Steam game (by appid) is currently running."""
    result = run_on_host(["pgrep", "-f", f"AppId={appid}"])
    return result.returncode == 0


def shutdown_steam() -> bool:
    """Send Steam the shutdown signal and poll until the process exits.

    Returns True if Steam exited within 30 seconds, False on timeout.
    """
    run_on_host(["steam", "-shutdown"])
    deadline = time.time() + 30
    while time.time() < deadline:
        if not is_steam_running():
            return True
        time.sleep(1)
    return False


def start_steam() -> None:
    """Start Steam in the background."""
    # Non-blocking: we fire and forget via host_runner
    import subprocess

    run_on_host(["steam"])
    # Note: subprocess.run blocks; for a true background launch the caller should
    # use threading or the Flatpak app's event loop. This stub fires the call and
    # returns; steam itself detaches from its parent on startup.
    _ = subprocess  # suppress unused-import lint; subprocess imported for clarity

"""Wrapper for running host commands from inside the Flatpak sandbox."""
from __future__ import annotations

import os
import subprocess


def is_in_flatpak() -> bool:
    return os.path.exists("/.flatpak-info")


def run_on_host(
    cmd: list[str],
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:
    """Run a command on the host system.

    Inside Flatpak uses flatpak-spawn --host; outside runs directly (for dev/testing).
    """
    if is_in_flatpak():
        full_cmd: list[str] = ["flatpak-spawn", "--host"]
        if env:
            for k, v in env.items():
                full_cmd.extend(["--env", f"{k}={v}"])
        full_cmd.extend(cmd)
    else:
        full_cmd = cmd

    return subprocess.run(full_cmd, capture_output=True, text=True, check=False)

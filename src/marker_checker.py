"""Marker checker: verify that a patch's expected conditions hold on the system."""
from __future__ import annotations

import os
from dataclasses import dataclass
from typing import Any

from host_runner import run_on_host
from vdf_utils import get_launch_options


@dataclass
class MarkerResult:
    marker_type: str
    path: str
    expected: str
    actual: str
    passed: bool


def _expand_vars(path: str, env_vars: dict[str, str]) -> str:
    """Replace known environment variable placeholders in a path string."""
    replacements = {
        "$STEAM_DIR": env_vars.get("STEAM_DIR", ""),
        "$COMPAT_DIR": env_vars.get("COMPAT_DIR", ""),
        "$GAME_DIR": env_vars.get("GAME_DIR", ""),
        "$HOME": env_vars.get("HOME", os.path.expanduser("~")),
    }
    for token, value in replacements.items():
        path = path.replace(token, value)
    return path


def check_markers(
    markers: list[dict[str, Any]],
    env_vars: dict[str, str],
) -> list[MarkerResult]:
    """Run each marker check and return a result for each.

    Supported marker types:
    - file_exists: checks that the expanded path exists as a file
    - dir_exists: checks that the expanded path exists as a directory
    - symlink_target: checks that os.readlink(path) contains marker["target"]
    - service_active: checks systemctl --user is-active <service>
    - launch_options_contains: checks localconfig.vdf LaunchOptions for a substring
    """
    results: list[MarkerResult] = []

    for marker in markers:
        marker_type: str = str(marker.get("type", ""))
        raw_path: str = str(marker.get("path", ""))
        expanded_path = _expand_vars(raw_path, env_vars)

        if marker_type == "file_exists":
            actual = "exists" if os.path.isfile(expanded_path) else "missing"
            results.append(
                MarkerResult(
                    marker_type=marker_type,
                    path=expanded_path,
                    expected="exists",
                    actual=actual,
                    passed=(actual == "exists"),
                )
            )

        elif marker_type == "dir_exists":
            actual = "exists" if os.path.isdir(expanded_path) else "missing"
            results.append(
                MarkerResult(
                    marker_type=marker_type,
                    path=expanded_path,
                    expected="exists",
                    actual=actual,
                    passed=(actual == "exists"),
                )
            )

        elif marker_type == "symlink_target":
            expected_target: str = str(marker.get("target", ""))
            try:
                link_dest = os.readlink(expanded_path)
                passed = expected_target in link_dest
                actual = link_dest
            except OSError:
                link_dest = ""
                passed = False
                actual = "(not a symlink)"
            results.append(
                MarkerResult(
                    marker_type=marker_type,
                    path=expanded_path,
                    expected=f"contains:{expected_target}",
                    actual=actual,
                    passed=passed,
                )
            )

        elif marker_type == "service_active":
            service: str = str(marker.get("service", raw_path))
            result = run_on_host(["systemctl", "--user", "is-active", service])
            passed = result.returncode == 0
            actual = result.stdout.strip() or result.stderr.strip()
            results.append(
                MarkerResult(
                    marker_type=marker_type,
                    path=service,
                    expected="active",
                    actual=actual,
                    passed=passed,
                )
            )

        elif marker_type == "launch_options_contains":
            userdata_id: str = str(env_vars.get("USERDATA_ID", ""))
            appid: str = str(marker.get("appid", ""))
            expected_substr: str = str(marker.get("contains", ""))
            launch_opts = get_launch_options(userdata_id, appid)
            passed = expected_substr in launch_opts
            results.append(
                MarkerResult(
                    marker_type=marker_type,
                    path=f"localconfig/{appid}/LaunchOptions",
                    expected=f"contains:{expected_substr}",
                    actual=launch_opts,
                    passed=passed,
                )
            )

        else:
            # Unknown marker type — record as failed
            results.append(
                MarkerResult(
                    marker_type=marker_type,
                    path=expanded_path,
                    expected="unknown",
                    actual="unknown_type",
                    passed=False,
                )
            )

    return results

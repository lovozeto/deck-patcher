"""Persistent state management for applied patches and activity log."""
from __future__ import annotations

import json
import os
import tempfile
from dataclasses import asdict, dataclass, field
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Literal

PatchStatus = Literal["not_applied", "applied", "outdated"]

STATE_FILE = Path("~/.local/share/deck-patcher/state.json").expanduser()


@dataclass
class ActivityEntry:
    timestamp: str
    action: str
    patch_id: str
    account_id: str
    version: str
    details: dict[str, Any] = field(default_factory=dict)


@dataclass
class AppliedPatch:
    patch_id: str
    version: str
    applied_at: str
    account_id: str
    backup_path: str
    markers: list[dict[str, Any]] = field(default_factory=list)
    last_reapply_prompt_at: str | None = None


def _load() -> dict[str, Any]:
    """Load state.json; return empty structure if the file does not exist."""
    if not STATE_FILE.exists():
        return {"applied": [], "activity": []}
    with open(STATE_FILE, encoding="utf-8") as f:
        return dict(json.load(f))


def _save(data: dict[str, Any]) -> None:
    """Write state.json atomically via a temp file + rename."""
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_path = tempfile.mkstemp(dir=STATE_FILE.parent, suffix=".tmp")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
        os.replace(tmp_path, STATE_FILE)
    except Exception:
        os.unlink(tmp_path)
        raise


def get_patch_status(patch_id: str, account_id: str | None = None) -> PatchStatus:
    """Return the application status of a patch (optionally per-account)."""
    data = _load()
    applied: list[dict[str, Any]] = data.get("applied", [])
    for entry in applied:
        if entry["patch_id"] != patch_id:
            continue
        if account_id is not None and entry["account_id"] != account_id:
            continue
        # TODO: compare stored version vs registry version to detect "outdated"
        return "applied"
    return "not_applied"


def record_apply(
    patch_id: str,
    account_id: str,
    version: str,
    backup_path: str,
) -> None:
    """Record a successful patch application."""
    data = _load()
    now = datetime.now(tz=timezone.utc).isoformat()

    applied: list[dict[str, Any]] = data.setdefault("applied", [])
    # Update or append
    for entry in applied:
        if entry["patch_id"] == patch_id and entry["account_id"] == account_id:
            entry["version"] = version
            entry["applied_at"] = now
            entry["backup_path"] = backup_path
            break
    else:
        applied.append(
            {
                "patch_id": patch_id,
                "version": version,
                "applied_at": now,
                "account_id": account_id,
                "backup_path": backup_path,
                "markers": [],
                "last_reapply_prompt_at": None,
            }
        )

    activity: list[dict[str, Any]] = data.setdefault("activity", [])
    activity.append(
        asdict(
            ActivityEntry(
                timestamp=now,
                action="apply",
                patch_id=patch_id,
                account_id=account_id,
                version=version,
            )
        )
    )
    _save(data)


def record_revert(patch_id: str, account_id: str) -> None:
    """Remove a patch from the applied list and log the revert action."""
    data = _load()
    now = datetime.now(tz=timezone.utc).isoformat()

    applied: list[dict[str, Any]] = data.get("applied", [])
    data["applied"] = [
        e
        for e in applied
        if not (e["patch_id"] == patch_id and e["account_id"] == account_id)
    ]

    activity: list[dict[str, Any]] = data.setdefault("activity", [])
    activity.append(
        asdict(
            ActivityEntry(
                timestamp=now,
                action="revert",
                patch_id=patch_id,
                account_id=account_id,
                version="",
            )
        )
    )
    _save(data)


def get_applied_patches() -> list[AppliedPatch]:
    """Return all currently applied patches across all accounts."""
    data = _load()
    result: list[AppliedPatch] = []
    for entry in data.get("applied", []):
        result.append(
            AppliedPatch(
                patch_id=entry["patch_id"],
                version=entry["version"],
                applied_at=entry["applied_at"],
                account_id=entry["account_id"],
                backup_path=entry["backup_path"],
                markers=entry.get("markers", []),
                last_reapply_prompt_at=entry.get("last_reapply_prompt_at"),
            )
        )
    return result


def get_activity_log() -> list[ActivityEntry]:
    """Return the full activity log in chronological order."""
    data = _load()
    result: list[ActivityEntry] = []
    for entry in data.get("activity", []):
        result.append(
            ActivityEntry(
                timestamp=entry["timestamp"],
                action=entry["action"],
                patch_id=entry["patch_id"],
                account_id=entry["account_id"],
                version=entry.get("version", ""),
                details=entry.get("details", {}),
            )
        )
    return sorted(result, key=lambda e: e.timestamp)


def get_reapply_count_today(patch_id: str) -> int:
    """Count re-apply actions for a patch within the last 24 hours."""
    cutoff = datetime.now(tz=timezone.utc) - timedelta(hours=24)
    count = 0
    for entry in get_activity_log():
        if entry.patch_id == patch_id and entry.action == "reapply":
            entry_time = datetime.fromisoformat(entry.timestamp)
            if entry_time >= cutoff:
                count += 1
    return count


def should_show_reapply_alert(patch_id: str) -> bool:
    """Return True when 2+ re-applies today AND no alert shown in the last 7 days."""
    if get_reapply_count_today(patch_id) < 2:
        return False

    data = _load()
    for entry in data.get("applied", []):
        if entry["patch_id"] == patch_id:
            last_prompt = entry.get("last_reapply_prompt_at")
            if last_prompt is None:
                return True
            last_prompt_time = datetime.fromisoformat(last_prompt)
            seven_days_ago = datetime.now(tz=timezone.utc) - timedelta(days=7)
            return last_prompt_time < seven_days_ago
    return False


def record_reapply_prompt(patch_id: str) -> None:
    """Record that the re-apply alert was shown right now for this patch."""
    data = _load()
    now = datetime.now(tz=timezone.utc).isoformat()
    for entry in data.get("applied", []):
        if entry["patch_id"] == patch_id:
            entry["last_reapply_prompt_at"] = now
    _save(data)

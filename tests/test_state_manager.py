"""Tests for state_manager.py."""
from __future__ import annotations

import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any
from unittest.mock import patch

import pytest

# Allow imports from src/
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

import state_manager


@pytest.fixture(autouse=True)
def _reset_state_file(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    """Redirect STATE_FILE to a temp directory for each test."""
    state_file = tmp_path / "state.json"
    monkeypatch.setattr(state_manager, "STATE_FILE", state_file)


def test_initial_state_is_empty() -> None:
    assert state_manager.get_applied_patches() == []
    assert state_manager.get_activity_log() == []


def test_record_apply_and_get_status() -> None:
    state_manager.record_apply("patch-a", "account-1", "1.0.0", "/tmp/backup")
    assert state_manager.get_patch_status("patch-a") == "applied"
    assert state_manager.get_patch_status("patch-a", "account-1") == "applied"
    assert state_manager.get_patch_status("patch-b") == "not_applied"


def test_record_revert_changes_status() -> None:
    state_manager.record_apply("patch-a", "account-1", "1.0.0", "/tmp/backup")
    state_manager.record_revert("patch-a", "account-1")
    assert state_manager.get_patch_status("patch-a", "account-1") == "not_applied"


def test_per_account_tracking() -> None:
    """Two accounts can have different statuses for the same patch."""
    state_manager.record_apply("patch-a", "account-1", "1.0.0", "/tmp/b1")
    # account-2 has not applied
    assert state_manager.get_patch_status("patch-a", "account-1") == "applied"
    assert state_manager.get_patch_status("patch-a", "account-2") == "not_applied"

    state_manager.record_apply("patch-a", "account-2", "1.0.0", "/tmp/b2")
    assert state_manager.get_patch_status("patch-a", "account-2") == "applied"


def test_activity_log_chronological() -> None:
    state_manager.record_apply("patch-a", "acc-1", "1.0.0", "/tmp/b")
    state_manager.record_apply("patch-b", "acc-1", "2.0.0", "/tmp/b")
    state_manager.record_revert("patch-a", "acc-1")

    log = state_manager.get_activity_log()
    assert len(log) == 3
    timestamps = [e.timestamp for e in log]
    assert timestamps == sorted(timestamps)


def test_reapply_count_today() -> None:
    """Reapply events within 24h are counted; older ones are not."""
    now = datetime.now(tz=timezone.utc)
    old = (now - timedelta(hours=25)).isoformat()
    recent = now.isoformat()

    raw_data: dict[str, Any] = {
        "applied": [],
        "activity": [
            {
                "timestamp": old,
                "action": "reapply",
                "patch_id": "patch-a",
                "account_id": "acc-1",
                "version": "1.0",
                "details": {},
            },
            {
                "timestamp": recent,
                "action": "reapply",
                "patch_id": "patch-a",
                "account_id": "acc-1",
                "version": "1.0",
                "details": {},
            },
            {
                "timestamp": recent,
                "action": "reapply",
                "patch_id": "patch-a",
                "account_id": "acc-1",
                "version": "1.0",
                "details": {},
            },
        ],
    }
    state_manager._save(raw_data)
    # old one is outside 24h → only 2 count
    assert state_manager.get_reapply_count_today("patch-a") == 2


def test_should_show_reapply_alert() -> None:
    """Alert triggers when 2+ re-applies and no recent prompt."""
    now = datetime.now(tz=timezone.utc)
    recent = now.isoformat()

    raw_data: dict[str, Any] = {
        "applied": [
            {
                "patch_id": "patch-a",
                "version": "1.0",
                "applied_at": recent,
                "account_id": "acc-1",
                "backup_path": "/tmp/b",
                "markers": [],
                "last_reapply_prompt_at": None,
            }
        ],
        "activity": [
            {
                "timestamp": recent,
                "action": "reapply",
                "patch_id": "patch-a",
                "account_id": "acc-1",
                "version": "1.0",
                "details": {},
            },
            {
                "timestamp": recent,
                "action": "reapply",
                "patch_id": "patch-a",
                "account_id": "acc-1",
                "version": "1.0",
                "details": {},
            },
        ],
    }
    state_manager._save(raw_data)
    assert state_manager.should_show_reapply_alert("patch-a") is True


def test_reapply_alert_cooldown() -> None:
    """No alert when a prompt was shown less than 7 days ago."""
    now = datetime.now(tz=timezone.utc)
    recent = now.isoformat()
    two_days_ago = (now - timedelta(days=2)).isoformat()

    raw_data: dict[str, Any] = {
        "applied": [
            {
                "patch_id": "patch-a",
                "version": "1.0",
                "applied_at": recent,
                "account_id": "acc-1",
                "backup_path": "/tmp/b",
                "markers": [],
                "last_reapply_prompt_at": two_days_ago,
            }
        ],
        "activity": [
            {
                "timestamp": recent,
                "action": "reapply",
                "patch_id": "patch-a",
                "account_id": "acc-1",
                "version": "1.0",
                "details": {},
            },
            {
                "timestamp": recent,
                "action": "reapply",
                "patch_id": "patch-a",
                "account_id": "acc-1",
                "version": "1.0",
                "details": {},
            },
        ],
    }
    state_manager._save(raw_data)
    assert state_manager.should_show_reapply_alert("patch-a") is False

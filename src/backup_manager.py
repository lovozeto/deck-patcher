"""Backup and rollback manager for patch modifications."""
from __future__ import annotations

import json
import shutil
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

BACKUP_BASE = Path("~/.local/share/deck-patcher/backups").expanduser()

_MIN_FREE_BYTES = 50 * 1024 * 1024  # 50 MB minimum free space


@dataclass
class BackupEntry:
    type: str                       # "file" | "dir" | "symlink"
    original_path: str
    backup_path: str
    pre_existing: bool              # False if the file didn't exist before the patch
    was_symlink: bool
    symlink_target: str | None = None


@dataclass
class RollbackManifest:
    patch_id: str
    timestamp: str
    entries: list[BackupEntry] = field(default_factory=list)


def _check_disk_space(required_bytes: int = _MIN_FREE_BYTES) -> None:
    """Raise RuntimeError if free disk space is below threshold."""
    usage = shutil.disk_usage(BACKUP_BASE.parent if not BACKUP_BASE.exists() else BACKUP_BASE)
    if usage.free < required_bytes:
        raise RuntimeError(
            f"Insufficient disk space for backup: {usage.free} bytes free, "
            f"{required_bytes} bytes required."
        )


def create_backup(patch_id: str, modifications: list[dict[str, Any]]) -> RollbackManifest:
    """Back up all files/dirs touched by a patch before applying it.

    Creates BACKUP_BASE/<patch_id>/<timestamp>/ and writes rollback-manifest.json.
    """
    BACKUP_BASE.mkdir(parents=True, exist_ok=True)
    _check_disk_space()

    timestamp = datetime.now(tz=timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    backup_dir = BACKUP_BASE / patch_id / timestamp
    backup_dir.mkdir(parents=True, exist_ok=True)

    manifest = RollbackManifest(patch_id=patch_id, timestamp=timestamp)

    for mod in modifications:
        target_str: str = str(mod.get("target", ""))
        if not target_str:
            continue
        target = Path(target_str)

        pre_existing = target.exists() or target.is_symlink()
        was_symlink = target.is_symlink()
        symlink_target: str | None = None

        if was_symlink:
            symlink_target = str(target.readlink())

        # Derive a relative backup path mirroring the original path
        # Strip leading slash to make it a valid relative path
        rel = target_str.lstrip("/")
        dest = backup_dir / rel

        entry_type = "symlink" if was_symlink else ("dir" if target.is_dir() else "file")

        if pre_existing:
            dest.parent.mkdir(parents=True, exist_ok=True)
            if was_symlink:
                # Record symlink — nothing to copy, we store the target in the manifest
                pass
            elif target.is_dir():
                shutil.copytree(target, dest, symlinks=True)
            else:
                shutil.copy2(target, dest)

        manifest.entries.append(
            BackupEntry(
                type=entry_type,
                original_path=target_str,
                backup_path=str(dest),
                pre_existing=pre_existing,
                was_symlink=was_symlink,
                symlink_target=symlink_target,
            )
        )

    # Write manifest JSON
    manifest_path = backup_dir / "rollback-manifest.json"
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(asdict(manifest), f, indent=2)

    return manifest


def restore_backup(manifest: RollbackManifest) -> list[str]:
    """Restore files from a rollback manifest.

    Returns a list of paths that were successfully restored.
    """
    restored: list[str] = []

    for entry in manifest.entries:
        original = Path(entry.original_path)
        backup = Path(entry.backup_path)

        try:
            # Remove whatever the patch left behind
            if original.is_symlink() or original.exists():
                if original.is_dir() and not original.is_symlink():
                    shutil.rmtree(original)
                else:
                    original.unlink()

            if not entry.pre_existing:
                # File didn't exist before the patch — leave it gone
                restored.append(entry.original_path)
                continue

            original.parent.mkdir(parents=True, exist_ok=True)

            if entry.was_symlink and entry.symlink_target is not None:
                original.symlink_to(entry.symlink_target)
            elif entry.type == "dir" and backup.exists():
                shutil.copytree(backup, original, symlinks=True)
            elif backup.exists():
                shutil.copy2(backup, original)

            restored.append(entry.original_path)
        except Exception:  # noqa: BLE001,S112
            # Best-effort restore; continue with remaining entries
            continue

    return restored


def cleanup_old_backups(patch_id: str, keep: int = 3) -> None:
    """Remove oldest backup directories for a patch, keeping the `keep` most recent."""
    patch_dir = BACKUP_BASE / patch_id
    if not patch_dir.exists():
        return

    backups = sorted(patch_dir.iterdir(), key=lambda p: p.name)
    to_delete = backups[: max(0, len(backups) - keep)]
    for old_backup in to_delete:
        shutil.rmtree(old_backup, ignore_errors=True)

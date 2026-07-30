"""Qt/QML bridge — exposes Python data and actions to the Kirigami frontend."""
from __future__ import annotations

from typing import Any

from PyQt6.QtCore import (  # type: ignore[import-not-found]
    QObject,
    pyqtProperty,
    pyqtSignal,
    pyqtSlot,
)

from patch_registry import DEFAULT_REGISTRY_URL, PatchMeta, fetch_index, fetch_readme
from patcher_engine import PatcherEngine
from state_manager import AppliedPatch, get_applied_patches
from steam_utils import SteamAccount, get_active_account, get_all_accounts


class DeckPatcherBackend(QObject):
    """Single object exposed to QML as `backend` context property.

    QML reads properties reactively via the notify signals.
    QML calls slots directly for user-triggered actions.
    """

    # Emitted when patch index or applied-patches state changes.
    dataChanged = pyqtSignal()
    # Emitted when the active Steam account changes.
    accountChanged = pyqtSignal()

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._engine = PatcherEngine(registry_url=DEFAULT_REGISTRY_URL)
        self._patches: list[PatchMeta] = []
        self._accounts: list[SteamAccount] = []
        self._active_account: SteamAccount | None = None
        self._applied: list[AppliedPatch] = []
        self._refresh()

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _refresh(self) -> None:
        """Reload all data from disk/network and emit change signals."""
        try:
            self._accounts = get_all_accounts()
        except Exception:  # noqa: BLE001
            self._accounts = []

        try:
            self._active_account = get_active_account()
        except Exception:  # noqa: BLE001
            self._active_account = None

        try:
            self._applied = get_applied_patches()
        except Exception:  # noqa: BLE001
            self._applied = []

        try:
            self._patches = fetch_index(DEFAULT_REGISTRY_URL)
        except Exception:  # noqa: BLE001
            self._patches = []

        self.accountChanged.emit()
        self.dataChanged.emit()

    def _active_id(self) -> str:
        return self._active_account.userdata_id if self._active_account else ""

    def _patch_status(self, patch_id: str) -> str:
        active = self._active_id()
        for ap in self._applied:
            if ap.patch_id == patch_id and ap.account_id == active:
                return "applied"
        return "not_applied"

    def _patch_to_dict(self, patch: PatchMeta) -> dict[str, Any]:
        return {
            "id": patch.id,
            "name": patch.name,
            "description": patch.description,
            "game": patch.game,
            "appid": patch.appid,
            "version": patch.version,
            "author": patch.author,
            "category": patch.category,
            "type": patch.type,
            "tags": patch.tags,
            "reversible": patch.reversible,
            "auto_reapply": patch.auto_reapply,
            "markers": patch.markers,
            "modifications": patch.modifications,
            "status": self._patch_status(patch.id),
        }

    # ------------------------------------------------------------------
    # Stats properties (used by Explore hero banner)
    # ------------------------------------------------------------------

    @pyqtProperty(int, notify=dataChanged)
    def totalCount(self) -> int:
        return len(self._patches)

    @pyqtProperty(int, notify=dataChanged)
    def appliedCount(self) -> int:
        return len({ap.patch_id for ap in self._applied})

    @pyqtProperty(int, notify=dataChanged)
    def outdatedCount(self) -> int:
        # Marker checks run asynchronously via the watcher service.
        # For now expose 0; a future slot will update this after a check pass.
        return 0

    @pyqtProperty(int, notify=accountChanged)
    def usersCount(self) -> int:
        return len(self._accounts)

    # ------------------------------------------------------------------
    # Account properties (used by sidebar footer and account selector)
    # ------------------------------------------------------------------

    @pyqtProperty(str, notify=accountChanged)
    def activeAccountName(self) -> str:
        return self._active_account.persona_name if self._active_account else ""

    @pyqtProperty(str, notify=accountChanged)
    def activeAccountId(self) -> str:
        return self._active_account.steam_id64 if self._active_account else ""

    @pyqtProperty(list, notify=accountChanged)
    def allAccounts(self) -> list[dict[str, str]]:
        return [
            {
                "name": a.persona_name,
                "steamId": a.steam_id64,
                "userdataId": a.userdata_id,
            }
            for a in self._accounts
        ]

    # ------------------------------------------------------------------
    # Patch list properties (used by shelves, Games, Apps, Manage pages)
    # ------------------------------------------------------------------

    @pyqtProperty(list, notify=dataChanged)
    def gameItems(self) -> list[dict[str, Any]]:
        """Unique games that have patches, with a patch list each."""
        seen: dict[str, dict[str, Any]] = {}
        for patch in self._patches:
            if patch.category != "game":
                continue
            key = patch.game
            if key not in seen:
                seen[key] = {"name": patch.game, "appid": patch.appid, "patch_count": 0, "patches": []}
            seen[key]["patch_count"] += 1
            seen[key]["patches"].append(self._patch_to_dict(patch))
        return list(seen.values())

    @pyqtProperty(list, notify=dataChanged)
    def appItems(self) -> list[dict[str, Any]]:
        """Unique apps that have patches, with a patch list each."""
        seen: dict[str, dict[str, Any]] = {}
        for patch in self._patches:
            if patch.category != "app":
                continue
            key = patch.game
            if key not in seen:
                seen[key] = {
                    "name": patch.game,
                    "appid": patch.appid,
                    "patch_count": 0,
                    "patches": [],
                    "installed": False,
                }
            seen[key]["patch_count"] += 1
            seen[key]["patches"].append(self._patch_to_dict(patch))
        return list(seen.values())

    @pyqtProperty(list, notify=dataChanged)
    def attentionItems(self) -> list[dict[str, Any]]:
        """Applied patches whose markers have failed (needs re-apply)."""
        return []

    @pyqtProperty(list, notify=dataChanged)
    def appliedItems(self) -> list[dict[str, Any]]:
        """All applied patches for the Manage page."""
        result: list[dict[str, Any]] = []
        patch_by_id = {p.id: p for p in self._patches}
        for ap in self._applied:
            meta = patch_by_id.get(ap.patch_id)
            row: dict[str, Any] = {
                "patch_id": ap.patch_id,
                "name": meta.name if meta else ap.patch_id,
                "game": meta.game if meta else "",
                "version": ap.version,
                "applied_at": ap.applied_at,
                "account_id": ap.account_id,
                "status": "applied",
            }
            result.append(row)
        return result

    # ------------------------------------------------------------------
    # Slots — user-triggered actions callable from QML
    # ------------------------------------------------------------------

    @pyqtSlot(result=None)
    def refresh(self) -> None:
        """Reload patch index and state from disk."""
        self._refresh()

    @pyqtSlot(str, result=str)
    def fetchReadme(self, patch_id: str) -> str:
        try:
            return fetch_readme(patch_id)
        except Exception as exc:  # noqa: BLE001
            return f"(Could not load README: {exc})"

    @pyqtSlot(str, list, result=dict)
    def applyPatch(self, patch_id: str, account_ids: list[str]) -> dict[str, Any]:
        result = self._engine.apply_patch(patch_id, account_ids)
        self._applied = get_applied_patches()
        self.dataChanged.emit()
        return {
            "success": result.success,
            "error": result.error or "",
            "showReapplyAlert": result.show_reapply_alert,
        }

    @pyqtSlot(str, list, result=dict)
    def revertPatch(self, patch_id: str, account_ids: list[str]) -> dict[str, Any]:
        result = self._engine.revert_patch(patch_id, account_ids)
        self._applied = get_applied_patches()
        self.dataChanged.emit()
        return {
            "success": result.success,
            "error": result.error or "",
        }

    @pyqtSlot(str, list, result=dict)
    def setupApp(self, patch_id: str, account_ids: list[str]) -> dict[str, Any]:
        result = self._engine.setup_app(patch_id, account_ids)
        self._applied = get_applied_patches()
        self.dataChanged.emit()
        return {
            "success": result.success,
            "steps": result.steps_completed,
            "error": result.error or "",
        }

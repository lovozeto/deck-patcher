import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

Kirigami.ScrollablePage {
    id: root
    title: "Manage"

    property var appliedPatches: backend.appliedItems
    property var addedApps: []
    property var activityLog: []

    ColumnLayout {
        width: parent.width
        spacing: Theme.spaceXxl

        // ── Section 1: Applied patches ──────────────────────────────────────
        Column {
            Layout.fillWidth: true
            spacing: Theme.spaceMd

            Text {
                text: "Applied patches"
                color: Theme.textPrimary
                font.pixelSize: Theme.typeSectionTitle
                font.weight: Font.Medium
            }

            Text {
                visible: root.appliedPatches.length === 0
                text: "No patches applied yet"
                color: Theme.textMuted
                font.pixelSize: Theme.typeBody
            }

            Repeater {
                model: root.appliedPatches
                delegate: Rectangle {
                    width: parent.width
                    height: patchCardCol.implicitHeight + Theme.spaceLg * 2
                    radius: Theme.radiusMd
                    color: Theme.bgSecondary
                    border.color: Theme.borderDefault
                    border.width: 1

                    Column {
                        id: patchCardCol
                        anchors {
                            fill: parent
                            margins: Theme.spaceLg
                        }
                        spacing: Theme.spaceSm

                        Row {
                            width: parent.width
                            spacing: Theme.spaceSm

                            Text {
                                text: modelData.name || modelData.patch_id || ""
                                color: Theme.textPrimary
                                font.pixelSize: Theme.typeCardTitle
                                font.weight: Font.Medium
                                width: parent.width - applyRow.width - Theme.spaceSm
                                elide: Text.ElideRight
                            }

                            Row {
                                id: applyRow
                                spacing: Theme.spaceSm

                                Button {
                                    text: "Re-apply"
                                    height: 32
                                    background: Rectangle {
                                        radius: Theme.radiusSm
                                        color: parent.hovered ? Theme.accentBg : "transparent"
                                        border.color: Theme.accent
                                        border.width: 1
                                    }
                                    contentItem: Text {
                                        text: parent.text
                                        color: Theme.accent
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: Theme.typeSmall
                                    }
                                    onClicked: {
                                        backend.applyPatch(modelData.patch_id, [modelData.account_id])
                                    }
                                }

                                Button {
                                    text: "Revert"
                                    height: 32
                                    background: Rectangle {
                                        radius: Theme.radiusSm
                                        color: parent.hovered ? Theme.dangerBg : "transparent"
                                        border.color: Theme.danger
                                        border.width: 1
                                    }
                                    contentItem: Text {
                                        text: parent.text
                                        color: Theme.danger
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: Theme.typeSmall
                                    }
                                    onClicked: {
                                        backend.revertPatch(modelData.patch_id, [modelData.account_id])
                                    }
                                }
                            }
                        }

                        // Per-account status
                        Row {
                            spacing: Theme.spaceXs

                            Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                color: Theme.accentBg

                                Text {
                                    anchors.centerIn: parent
                                    text: (modelData.account_id || "?").charAt(0).toUpperCase()
                                    color: Theme.accent
                                    font.pixelSize: Theme.typeSmall
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "v" + (modelData.version || "—") +
                                      " · Applied " + (modelData.applied_at || "")
                                color: Theme.textMuted
                                font.pixelSize: Theme.typeSmall
                            }
                        }
                    }
                }
            }
        }

        // ── Section 2: Added apps ──────────────────────────────────────────
        Column {
            Layout.fillWidth: true
            spacing: Theme.spaceMd

            Text {
                text: "Added apps"
                color: Theme.textPrimary
                font.pixelSize: Theme.typeSectionTitle
                font.weight: Font.Medium
            }

            Text {
                visible: root.addedApps.length === 0
                text: "No apps added yet"
                color: Theme.textMuted
                font.pixelSize: Theme.typeBody
            }

            Repeater {
                model: root.addedApps
                delegate: Rectangle {
                    width: parent.width
                    height: Theme.minTapTarget + Theme.spaceLg
                    radius: Theme.radiusMd
                    color: Theme.bgSecondary
                    border.color: Theme.borderDefault
                    border.width: 1

                    Row {
                        anchors {
                            fill: parent
                            margins: Theme.spaceMd
                        }
                        spacing: Theme.spaceMd

                        Rectangle {
                            width: 36
                            height: 36
                            anchors.verticalCenter: parent.verticalCenter
                            radius: Theme.radiusSm
                            color: Theme.bgTertiary

                            Text {
                                anchors.centerIn: parent
                                text: "📦"
                                font.pixelSize: 18
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            width: parent.width - 36 - Theme.spaceMd

                            Text {
                                text: modelData.name || ""
                                color: Theme.textPrimary
                                font.pixelSize: Theme.typeBody
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                // TODO: bind to per-account status: shortcut / artwork / patch
                                text: "Shortcut: — · Artwork: — · Patch: —"
                                color: Theme.textMuted
                                font.pixelSize: Theme.typeSmall
                            }
                        }
                    }
                }
            }
        }

        // ── Section 3: Activity log ─────────────────────────────────────────
        Column {
            Layout.fillWidth: true
            spacing: Theme.spaceMd

            Text {
                text: "Activity log"
                color: Theme.textPrimary
                font.pixelSize: Theme.typeSectionTitle
                font.weight: Font.Medium
            }

            Text {
                visible: root.activityLog.length === 0
                text: "No activity yet"
                color: Theme.textMuted
                font.pixelSize: Theme.typeBody
            }

            Repeater {
                model: root.activityLog
                delegate: _ActivityItem {
                    width: parent.width
                    entry: modelData
                }
            }
        }
    }

    // Expandable activity item
    component _ActivityItem: Column {
        property var entry: ({})
        property bool expanded: false
        spacing: 0

        Rectangle {
            width: parent.width
            height: Theme.minTapTarget
            color: parent.expanded ? Theme.bgSecondary : "transparent"
            radius: Theme.radiusSm

            Row {
                anchors {
                    fill: parent
                    margins: Theme.spaceSm
                }
                spacing: Theme.spaceMd

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        switch(entry.action) {
                            case "apply":   return "✓"
                            case "revert":  return "↩"
                            case "reapply": return "↻"
                            default:        return "·"
                        }
                    }
                    color: {
                        switch(entry.action) {
                            case "apply":   return Theme.success
                            case "revert":  return Theme.warning
                            case "reapply": return Theme.accent
                            default:        return Theme.textMuted
                        }
                    }
                    font.pixelSize: Theme.typeBody
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    width: parent.width - 24 - Theme.spaceMd - 60

                    Text {
                        text: (entry.action || "") + ": " + (entry.patch_id || "")
                        color: Theme.textPrimary
                        font.pixelSize: Theme.typeBody
                        elide: Text.ElideRight
                        width: parent.width
                    }
                    Text {
                        text: entry.timestamp || ""
                        color: Theme.textMuted
                        font.pixelSize: Theme.typeSmall
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: parent.parent.expanded ? "▲" : "▼"
                    color: Theme.textMuted
                    font.pixelSize: Theme.typeSmall
                    width: 20
                    horizontalAlignment: Text.AlignRight
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: parent.parent.expanded = !parent.parent.expanded
            }
        }

        // Expanded detail
        Rectangle {
            visible: parent.expanded
            width: parent.width
            height: detailText.implicitHeight + Theme.spaceMd * 2
            color: Theme.bgElevated
            radius: Theme.radiusSm

            Text {
                id: detailText
                anchors {
                    fill: parent
                    margins: Theme.spaceMd
                }
                text: "Account: " + (entry.account_id || "—") +
                      "\nVersion: " + (entry.version || "—") +
                      "\nDetails: " + JSON.stringify(entry.details || {})
                color: Theme.textSecondary
                font.pixelSize: Theme.typeSmall
                font.family: "monospace"
                wrapMode: Text.WordWrap
            }
        }
    }
}

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

Kirigami.ScrollablePage {
    id: root
    title: patch.name || "Patch"

    // Passed in by caller
    property var patch: ({})
    property var accounts: []
    property string readmeContent: "Loading…"

    // TODO: bind all data to patcherEngine context properties

    ColumnLayout {
        width: parent.width
        spacing: Theme.spaceLg

        // Breadcrumb navigation
        Row {
            spacing: Theme.spaceXs

            Text {
                text: patch.game || "Game"
                color: Theme.accent
                font.pixelSize: Theme.typeCaption

                MouseArea {
                    anchors.fill: parent
                    onClicked: pageStack.pop()
                }
            }
            Text {
                text: "›"
                color: Theme.textMuted
                font.pixelSize: Theme.typeCaption
            }
            Text {
                text: root.patch.name || "Patch"
                color: Theme.textMuted
                font.pixelSize: Theme.typeCaption
            }
        }

        // Header: patch name + version + author + action buttons
        Rectangle {
            Layout.fillWidth: true
            height: headerColumn.implicitHeight + Theme.spaceLg * 2
            radius: Theme.radiusLg
            color: Theme.bgSecondary
            border.color: Theme.borderDefault
            border.width: 1

            Column {
                id: headerColumn
                anchors {
                    fill: parent
                    margins: Theme.spaceLg
                }
                spacing: Theme.spaceSm

                Text {
                    text: root.patch.name || ""
                    color: Theme.textPrimary
                    font.pixelSize: Theme.typePageTitle
                    font.weight: Font.Medium
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Row {
                    spacing: Theme.spaceMd

                    Text {
                        text: "v" + (root.patch.version || "—")
                        color: Theme.textMuted
                        font.pixelSize: Theme.typeCaption
                        font.family: "monospace"
                    }
                    Text { text: "·"; color: Theme.textMuted; font.pixelSize: Theme.typeCaption }
                    Text {
                        text: root.patch.author || ""
                        color: Theme.textSecondary
                        font.pixelSize: Theme.typeCaption
                    }
                }

                // Tags bar
                Flow {
                    width: parent.width
                    spacing: Theme.spaceXs

                    // Type badge
                    _Tag {
                        label: root.patch.type || "game"
                        bgColor: Theme.accentBg
                        fgColor: Theme.accent
                    }

                    // Min SteamOS requirement
                    _Tag {
                        visible: root.patch.min_steamos !== ""
                        label: "SteamOS ≥ " + root.patch.min_steamos
                        bgColor: Theme.bgTertiary
                        fgColor: Theme.textSecondary
                    }

                    // Reversible badge
                    _Tag {
                        label: root.patch.reversible ? "Reversible" : "Irreversible"
                        bgColor: root.patch.reversible ? Theme.successBg : Theme.warningBg
                        fgColor: root.patch.reversible ? Theme.success : Theme.warning
                    }

                    // Auto-reapply badge
                    _Tag {
                        visible: root.patch.auto_reapply === true
                        label: "Auto re-apply"
                        bgColor: Theme.accentBg
                        fgColor: Theme.accent
                    }

                    // Custom tags
                    Repeater {
                        model: root.patch.tags || []
                        delegate: _Tag {
                            label: modelData
                            bgColor: Theme.bgElevated
                            fgColor: Theme.textSecondary
                        }
                    }
                }

                // Per-user status cards
                Repeater {
                    model: root.accounts
                    delegate: Rectangle {
                        width: parent.width
                        height: Theme.minTapTarget
                        radius: Theme.radiusMd
                        color: Theme.bgTertiary

                        Row {
                            anchors {
                                fill: parent
                                margins: Theme.spaceSm
                            }
                            spacing: Theme.spaceSm

                            Rectangle {
                                width: 28
                                height: 28
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 14
                                color: Theme.accentBg

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.persona_name
                                        ? modelData.persona_name.charAt(0).toUpperCase()
                                        : "?"
                                    color: Theme.accent
                                    font.pixelSize: Theme.typeSmall
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.persona_name || ""
                                color: Theme.textPrimary
                                font.pixelSize: Theme.typeBody
                            }

                            // TODO: bind to real status from patcherEngine
                            _Tag {
                                anchors.verticalCenter: parent.verticalCenter
                                label: "Not applied"
                                bgColor: Theme.bgElevated
                                fgColor: Theme.textMuted
                            }
                        }
                    }
                }

                // Apply button
                Button {
                    text: "Apply patch"
                    width: parent.width
                    height: Theme.minTapTarget
                    background: Rectangle {
                        radius: Theme.radiusMd
                        color: parent.hovered ? Theme.accent : Theme.accentBg
                        border.color: Theme.accent
                        border.width: 1
                    }
                    contentItem: Text {
                        text: parent.text
                        color: Theme.accent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: Theme.typeBody
                        font.weight: Font.Medium
                    }
                    onClicked: {
                        // TODO: show AccountSelector, then call patcherEngine.apply_patch
                    }
                }
            }
        }

        // Description / README
        Rectangle {
            Layout.fillWidth: true
            height: descCol.implicitHeight + Theme.spaceLg * 2
            radius: Theme.radiusLg
            color: Theme.bgSecondary
            border.color: Theme.borderDefault
            border.width: 1

            Column {
                id: descCol
                anchors {
                    fill: parent
                    margins: Theme.spaceLg
                }
                spacing: Theme.spaceSm

                Text {
                    text: "Description"
                    color: Theme.textPrimary
                    font.pixelSize: Theme.typeSectionTitle
                    font.weight: Font.Medium
                }
                Text {
                    text: root.readmeContent
                    color: Theme.textSecondary
                    font.pixelSize: Theme.typeBody
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
            }
        }

        // What this patch modifies
        Rectangle {
            Layout.fillWidth: true
            height: modsCol.implicitHeight + Theme.spaceLg * 2
            radius: Theme.radiusLg
            color: Theme.bgSecondary
            border.color: Theme.borderDefault
            border.width: 1
            visible: (root.patch.modifications || []).length > 0

            Column {
                id: modsCol
                anchors {
                    fill: parent
                    margins: Theme.spaceLg
                }
                spacing: Theme.spaceSm

                Text {
                    text: "What this patch modifies"
                    color: Theme.textPrimary
                    font.pixelSize: Theme.typeSectionTitle
                    font.weight: Font.Medium
                }

                Repeater {
                    model: root.patch.modifications || []
                    delegate: Row {
                        spacing: Theme.spaceSm
                        width: parent.width

                        Text {
                            text: {
                                switch(modelData.action) {
                                    case "symlink": return "🔗"
                                    case "write":   return "✏️"
                                    case "copy":    return "📋"
                                    case "delete":  return "🗑"
                                    default:        return "·"
                                }
                            }
                            font.pixelSize: Theme.typeBody
                        }
                        Text {
                            text: modelData.target || ""
                            color: Theme.textSecondary
                            font.pixelSize: Theme.typeBody
                            font.family: "monospace"
                            elide: Text.ElideMiddle
                            width: parent.width - 24 - Theme.spaceSm
                        }
                    }
                }
            }
        }

        // Verification markers
        Rectangle {
            Layout.fillWidth: true
            height: markersCol.implicitHeight + Theme.spaceLg * 2
            radius: Theme.radiusLg
            color: Theme.bgSecondary
            border.color: Theme.borderDefault
            border.width: 1
            visible: (root.patch.markers || []).length > 0

            Column {
                id: markersCol
                anchors {
                    fill: parent
                    margins: Theme.spaceLg
                }
                spacing: Theme.spaceSm

                Text {
                    text: "Verification markers"
                    color: Theme.textPrimary
                    font.pixelSize: Theme.typeSectionTitle
                    font.weight: Font.Medium
                }

                Repeater {
                    model: root.patch.markers || []
                    delegate: Row {
                        spacing: Theme.spaceSm
                        width: parent.width

                        // TODO: bind icon to live marker check result
                        Text {
                            text: "○"
                            color: Theme.textMuted
                            font.pixelSize: Theme.typeBody
                        }
                        Text {
                            text: modelData.type + ": " + (modelData.path || modelData.service || "")
                            color: Theme.textSecondary
                            font.pixelSize: Theme.typeSmall
                            font.family: "monospace"
                            elide: Text.ElideMiddle
                            width: parent.width - 20 - Theme.spaceSm
                        }
                    }
                }
            }
        }

        // Footer actions
        Row {
            Layout.fillWidth: true
            spacing: Theme.spaceMd

            Button {
                text: "Revert patch"
                visible: true // TODO: bind to isApplied
                height: Theme.minTapTarget
                width: (parent.width - Theme.spaceMd) / 2

                background: Rectangle {
                    radius: Theme.radiusMd
                    color: parent.hovered ? Theme.dangerBg : "transparent"
                    border.color: Theme.danger
                    border.width: 1
                }
                contentItem: Text {
                    text: parent.text
                    color: Theme.danger
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: Theme.typeBody
                }
                onClicked: {
                    // TODO: call patcherEngine.revert_patch
                }
            }

            Button {
                text: "Report an issue"
                height: Theme.minTapTarget
                width: (parent.width - Theme.spaceMd) / 2

                background: Rectangle {
                    radius: Theme.radiusMd
                    color: "transparent"
                    border.color: Theme.borderDefault
                    border.width: 1
                }
                contentItem: Text {
                    text: parent.text
                    color: Theme.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: Theme.typeBody
                }
                onClicked: {
                    // TODO: open PatchRequestSearch dialog or GitHub URL
                }
            }
        }
    }

    // Inline tag component
    component _Tag: Rectangle {
        property string label: ""
        property string bgColor: Theme.bgElevated
        property string fgColor: Theme.textSecondary

        height: 22
        width: tagText.width + Theme.spaceSm * 2
        radius: Theme.radiusPill
        color: bgColor

        Text {
            id: tagText
            anchors.centerIn: parent
            text: parent.label
            color: parent.fgColor
            font.pixelSize: Theme.typeSmall
        }
    }
}

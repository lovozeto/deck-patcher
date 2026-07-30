import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

Kirigami.Dialog {
    id: root
    title: "This patch keeps needing re-apply"

    property string patchId: ""
    property string patchName: ""
    property string gameName: ""
    property string steamosVersion: ""
    property int reapplyCount: 0
    property var failingMarkers: []
    property string issueUrl: ""

    property bool reportOpened: false

    standardButtons: Dialog.NoButton
    preferredWidth: 480
    preferredHeight: 520

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spaceMd

        Text {
            Layout.fillWidth: true
            text: "\"" + root.patchName + "\" has been re-applied " + root.reapplyCount +
                  " times today. This usually means a system update reverted the patch " +
                  "or there's a compatibility issue. The community would benefit from " +
                  "knowing about it."
            color: Theme.textSecondary
            font.pixelSize: Theme.typeBody
            wrapMode: Text.WordWrap
        }

        // Diagnostic info box
        Rectangle {
            Layout.fillWidth: true
            height: diagCol.implicitHeight + Theme.spaceLg * 2
            radius: Theme.radiusMd
            color: Theme.bgElevated
            border.color: Theme.borderDefault
            border.width: 1

            Column {
                id: diagCol
                anchors {
                    fill: parent
                    margins: Theme.spaceLg
                }
                spacing: Theme.spaceXs

                Repeater {
                    model: [
                        { label: "Patch",           value: root.patchName || root.patchId },
                        { label: "Game",            value: root.gameName },
                        { label: "SteamOS",         value: root.steamosVersion || "unknown" },
                        { label: "Re-applies today", value: String(root.reapplyCount) }
                    ]
                    delegate: Row {
                        spacing: Theme.spaceSm
                        Text {
                            text: modelData.label + ":"
                            color: Theme.textMuted
                            font.pixelSize: Theme.typeSmall
                            width: 120
                        }
                        Text {
                            text: modelData.value
                            color: Theme.textPrimary
                            font.pixelSize: Theme.typeSmall
                            font.family: "monospace"
                        }
                    }
                }

                Text {
                    visible: root.failingMarkers.length > 0
                    text: "Failing markers:"
                    color: Theme.textMuted
                    font.pixelSize: Theme.typeSmall
                    topPadding: Theme.spaceXs
                }

                Repeater {
                    model: root.failingMarkers
                    delegate: Text {
                        text: "  · " + (modelData.marker_type || "") + ": " + (modelData.path || "")
                        color: Theme.danger
                        font.pixelSize: Theme.typeSmall
                        font.family: "monospace"
                        width: parent.width
                        elide: Text.ElideMiddle
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Note: a GitHub account is required to file an issue. " +
                  "The report will pre-fill with the diagnostic info above."
            color: Theme.textMuted
            font.pixelSize: Theme.typeSmall
            wrapMode: Text.WordWrap
        }

        // Success toast (shown after browser opens)
        Rectangle {
            Layout.fillWidth: true
            visible: root.reportOpened
            height: 40
            radius: Theme.radiusMd
            color: Theme.successBg
            border.color: Theme.success
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "✓ GitHub opened — thank you for the report!"
                color: Theme.success
                font.pixelSize: Theme.typeBody
            }
        }

        // Buttons
        Row {
            Layout.fillWidth: true
            spacing: Theme.spaceMd

            Button {
                text: "No thanks"
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
                onClicked: root.close()
            }

            Button {
                text: "Report the issue"
                height: Theme.minTapTarget
                width: (parent.width - Theme.spaceMd) / 2

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
                    // TODO: call Qt.openUrlExternally(root.issueUrl) with pre-filled params
                    Qt.openUrlExternally(root.issueUrl || "https://github.com/lovozeto/deck-patches/issues/new")
                    root.reportOpened = true
                }
            }
        }
    }
}

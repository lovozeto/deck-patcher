import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

Kirigami.Dialog {
    id: root
    title: "This patch needs Steam closed"

    property string patchName: ""
    property string targetDescription: ""

    signal confirmed()

    standardButtons: Dialog.NoButton
    preferredWidth: 460
    preferredHeight: 400

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spaceMd

        // Amber warning block
        Rectangle {
            Layout.fillWidth: true
            height: amberText.implicitHeight + Theme.spaceLg * 2
            radius: Theme.radiusMd
            color: Theme.warningBg
            border.color: Theme.warning
            border.width: 1

            Text {
                id: amberText
                anchors {
                    fill: parent
                    margins: Theme.spaceLg
                }
                text: "⚠  Steam must be closed to apply this patch.\n\n" +
                      "While Steam is closed the trackpad will not work — " +
                      "use the touchscreen to interact with Deck Patcher. " +
                      "Steam will restart automatically when the patch is done."
                color: Theme.warning
                font.pixelSize: Theme.typeBody
                wrapMode: Text.WordWrap
            }
        }

        // Green checklist
        Rectangle {
            Layout.fillWidth: true
            height: checklistCol.implicitHeight + Theme.spaceLg * 2
            radius: Theme.radiusMd
            color: Theme.successBg
            border.color: Theme.success
            border.width: 1

            Column {
                id: checklistCol
                anchors {
                    fill: parent
                    margins: Theme.spaceLg
                }
                spacing: Theme.spaceSm

                Repeater {
                    model: [
                        "Target: " + (root.targetDescription || root.patchName),
                        "Backup will be created before any changes",
                        "Steam restarts automatically when done"
                    ]
                    delegate: Row {
                        spacing: Theme.spaceSm
                        Text {
                            text: "✓"
                            color: Theme.success
                            font.pixelSize: Theme.typeBody
                            font.weight: Font.Medium
                        }
                        Text {
                            text: modelData
                            color: Theme.textPrimary
                            font.pixelSize: Theme.typeBody
                        }
                    }
                }
            }
        }

        // Buttons
        Row {
            Layout.fillWidth: true
            spacing: Theme.spaceMd

            Button {
                text: "Cancel"
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
                text: "Close Steam and apply"
                height: Theme.minTapTarget
                width: (parent.width - Theme.spaceMd) / 2

                background: Rectangle {
                    radius: Theme.radiusMd
                    color: parent.hovered ? Theme.danger : Theme.dangerBg
                    border.color: Theme.danger
                    border.width: 1
                }
                contentItem: Text {
                    text: parent.text
                    color: Theme.danger
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: Theme.typeBody
                    font.weight: Font.Medium
                }
                onClicked: {
                    root.confirmed()
                    root.close()
                }
            }
        }
    }
}

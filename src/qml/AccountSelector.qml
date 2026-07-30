import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

Kirigami.Dialog {
    id: root
    title: "Add to Steam library"

    // TODO: bind to patcherEngine.accounts
    property var accounts: []
    property string activeAccountId: ""
    property var selectedAccountIds: []

    signal confirmed(var accountIds)

    standardButtons: Dialog.NoButton
    preferredWidth: 480
    preferredHeight: 420

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spaceMd

        Text {
            Layout.fillWidth: true
            text: "Select which Steam accounts should receive this shortcut:"
            color: Theme.textSecondary
            font.pixelSize: Theme.typeBody
            wrapMode: Text.WordWrap
        }

        // Account list
        Repeater {
            model: root.accounts
            delegate: Rectangle {
                Layout.fillWidth: true
                height: Theme.minTapTarget
                radius: Theme.radiusMd
                color: Theme.bgSecondary
                border.color: Theme.borderDefault
                border.width: 1

                property bool isChecked: true  // both checked by default

                Row {
                    anchors {
                        fill: parent
                        margins: Theme.spaceMd
                    }
                    spacing: Theme.spaceMd

                    CheckBox {
                        anchors.verticalCenter: parent.verticalCenter
                        checked: parent.parent.isChecked
                        onCheckedChanged: {
                            parent.parent.isChecked = checked
                            // Update selectedAccountIds
                            var ids = []
                            // TODO: collect checked IDs from all delegates
                            root.selectedAccountIds = ids
                        }
                    }

                    // Initials avatar
                    Rectangle {
                        width: 32
                        height: 32
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 16
                        color: modelData.steam_id64 === root.activeAccountId
                            ? Theme.accentBg
                            : Theme.bgElevated

                        Text {
                            anchors.centerIn: parent
                            text: modelData.persona_name
                                ? modelData.persona_name.charAt(0).toUpperCase()
                                : "?"
                            color: modelData.steam_id64 === root.activeAccountId
                                ? Theme.accent
                                : Theme.textSecondary
                            font.pixelSize: Theme.typeBody
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: modelData.persona_name || ""
                            color: Theme.textPrimary
                            font.pixelSize: Theme.typeBody
                        }
                        Text {
                            visible: modelData.steam_id64 === root.activeAccountId
                            text: "Active account"
                            color: Theme.accent
                            font.pixelSize: Theme.typeSmall
                        }
                    }
                }
            }
        }

        // Amber warning about Steam closing and trackpad loss
        Rectangle {
            Layout.fillWidth: true
            height: warningText.implicitHeight + Theme.spaceMd * 2
            radius: Theme.radiusMd
            color: Theme.warningBg
            border.color: Theme.warning
            border.width: 1

            Text {
                id: warningText
                anchors {
                    fill: parent
                    margins: Theme.spaceMd
                }
                text: "⚠  Steam will need to be closed to add the shortcut. " +
                      "The trackpad will not work during that time, but " +
                      "the touchscreen still works. Steam will restart automatically."
                color: Theme.warning
                font.pixelSize: Theme.typeSmall
                wrapMode: Text.WordWrap
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
                text: "Add to accounts"
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
                    // TODO: collect checked IDs before emitting
                    root.confirmed(root.selectedAccountIds)
                    root.close()
                }
            }
        }
    }
}

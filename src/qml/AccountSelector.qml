import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

Kirigami.Dialog {
    id: root
    title: "Add to Steam library"

    property var accounts: []
    property string activeAccountId: ""
    property var checkedIds: ({})

    function initCheckedIds() {
        var ids = {}
        for (var i = 0; i < accounts.length; i++) {
            ids[accounts[i].userdataId] = true
        }
        checkedIds = ids
    }

    Component.onCompleted: initCheckedIds()
    onAccountsChanged: initCheckedIds()

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

                Row {
                    anchors {
                        fill: parent
                        margins: Theme.spaceMd
                    }
                    spacing: Theme.spaceMd

                    CheckBox {
                        anchors.verticalCenter: parent.verticalCenter
                        checked: root.checkedIds[modelData.userdataId] !== false
                        onCheckedChanged: {
                            var ids = Object.assign({}, root.checkedIds)
                            ids[modelData.userdataId] = checked
                            root.checkedIds = ids
                        }
                    }

                    // Initials avatar
                    Rectangle {
                        width: 32
                        height: 32
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 16
                        color: modelData.steamId === root.activeAccountId
                            ? Theme.accentBg
                            : Theme.bgElevated

                        Text {
                            anchors.centerIn: parent
                            text: modelData.name
                                ? modelData.name.charAt(0).toUpperCase()
                                : "?"
                            color: modelData.steamId === root.activeAccountId
                                ? Theme.accent
                                : Theme.textSecondary
                            font.pixelSize: Theme.typeBody
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: modelData.name || ""
                            color: Theme.textPrimary
                            font.pixelSize: Theme.typeBody
                        }
                        Text {
                            visible: modelData.steamId === root.activeAccountId
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
                    var ids = []
                    var map = root.checkedIds
                    for (var key in map) {
                        if (map[key]) ids.push(key)
                    }
                    root.confirmed(ids)
                    root.close()
                }
            }
        }
    }
}

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

Kirigami.ScrollablePage {
    id: root
    title: game.name || "Game"

    // Passed in from GamesPage
    property var game: ({})
    // TODO: bind to Python patch list filtered by game.appid
    property var patches: []
    // TODO: bind to Python accounts list
    property var accounts: []

    ColumnLayout {
        width: parent.width
        spacing: Theme.spaceLg

        // Header: game artwork + name
        Rectangle {
            Layout.fillWidth: true
            height: 180
            radius: Theme.radiusLg
            color: Theme.bgSecondary
            border.color: Theme.borderDefault
            border.width: 1

            Row {
                anchors {
                    fill: parent
                    margins: Theme.spaceLg
                }
                spacing: Theme.spaceLg

                // Artwork placeholder
                Rectangle {
                    width: 120
                    height: 150
                    radius: Theme.radiusMd
                    color: Theme.bgTertiary

                    Text {
                        anchors.centerIn: parent
                        text: "🎮"
                        font.pixelSize: 48
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spaceSm
                    width: parent.width - 120 - Theme.spaceLg

                    Text {
                        text: root.game.name || ""
                        color: Theme.textPrimary
                        font.pixelSize: Theme.typePageTitle
                        font.weight: Font.Medium
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }
                    Text {
                        text: root.game.appid ? "AppID: " + root.game.appid : ""
                        color: Theme.textMuted
                        font.pixelSize: Theme.typeCaption
                        font.family: Theme.fontMono || "monospace"
                    }
                    Text {
                        text: root.patches.length + " patch" + (root.patches.length !== 1 ? "es" : "")
                        color: Theme.textSecondary
                        font.pixelSize: Theme.typeBody
                    }
                }
            }
        }

        // Patch list
        Text {
            text: "Available Patches"
            color: Theme.textPrimary
            font.pixelSize: Theme.typeSectionTitle
            font.weight: Font.Medium
            visible: root.patches.length > 0
        }

        Repeater {
            model: root.patches
            delegate: Rectangle {
                Layout.fillWidth: true
                height: patchColumn.implicitHeight + Theme.spaceLg * 2
                radius: Theme.radiusMd
                color: Theme.bgSecondary
                border.color: Theme.borderDefault
                border.width: 1

                Column {
                    id: patchColumn
                    anchors {
                        fill: parent
                        margins: Theme.spaceLg
                    }
                    spacing: Theme.spaceSm

                    Text {
                        text: modelData.name || modelData.id || ""
                        color: Theme.textPrimary
                        font.pixelSize: Theme.typeCardTitle
                        font.weight: Font.Medium
                        width: parent.width
                    }
                    Text {
                        text: modelData.description || ""
                        color: Theme.textSecondary
                        font.pixelSize: Theme.typeBody
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }

                    // Per-account status rows
                    Repeater {
                        model: root.accounts
                        delegate: Row {
                            spacing: Theme.spaceSm
                            width: parent.width

                            // Account initials avatar
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 14
                                color: Theme.accentBg

                                Text {
                                    anchors.centerIn: parent
                                    text: accountData.persona_name.charAt(0).toUpperCase()
                                    color: Theme.accent
                                    font.pixelSize: Theme.typeSmall
                                }
                            }

                            property var accountData: modelData

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.persona_name || ""
                                color: Theme.textPrimary
                                font.pixelSize: Theme.typeBody
                            }

                            // TODO: status badge — query patcherEngine for per-account status
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                height: 20
                                width: statusBadge.width + Theme.spaceSm * 2
                                radius: Theme.radiusPill
                                color: Theme.bgTertiary

                                Text {
                                    id: statusBadge
                                    anchors.centerIn: parent
                                    text: "Not applied"
                                    color: Theme.textMuted
                                    font.pixelSize: Theme.typeSmall
                                }
                            }
                        }
                    }

                    // Adaptive action button
                    Button {
                        text: root.accounts.length > 1
                            ? "Apply to all accounts"
                            : "Apply to account"
                        width: parent.width
                        height: Theme.minTapTarget

                        background: Rectangle {
                            radius: Theme.radiusMd
                            color: parent.hovered ? Theme.accent : Theme.accentBg
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
                            // TODO: call patcherEngine.apply_patch(modelData.id, accountIds)
                        }
                    }
                }
            }
        }

        // Empty state
        Item {
            Layout.fillWidth: true
            height: 120
            visible: root.patches.length === 0

            Column {
                anchors.centerIn: parent
                spacing: Theme.spaceSm

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No patches for this game yet"
                    color: Theme.textSecondary
                    font.pixelSize: Theme.typeBody
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "You can request one from the Explore page"
                    color: Theme.textMuted
                    font.pixelSize: Theme.typeCaption
                }
            }
        }
    }
}

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

Kirigami.ScrollablePage {
    id: root
    title: "Games"

    property var games: backend.gameItems

    ColumnLayout {
        width: parent.width
        spacing: Theme.spaceLg

        // Empty state
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            height: 200
            visible: root.games.length === 0

            Column {
                anchors.centerIn: parent
                spacing: Theme.spaceMd

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "🎮"
                    font.pixelSize: 48
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No game patches available"
                    color: Theme.textSecondary
                    font.pixelSize: Theme.typeSectionTitle
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Check back after syncing the patch registry"
                    color: Theme.textMuted
                    font.pixelSize: Theme.typeBody
                }
            }
        }

        // Games grid
        GridLayout {
            Layout.fillWidth: true
            columns: Math.max(1, Math.floor(parent.width / 200))
            rowSpacing: Theme.spaceMd
            columnSpacing: Theme.spaceMd
            visible: root.games.length > 0

            Repeater {
                model: root.games
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 180
                    radius: Theme.radiusLg
                    color: Theme.bgSecondary
                    border.color: Theme.borderDefault
                    border.width: 1

                    Column {
                        anchors {
                            fill: parent
                            margins: Theme.spaceMd
                        }
                        spacing: Theme.spaceSm

                        // Artwork placeholder
                        Rectangle {
                            width: parent.width
                            height: 100
                            radius: Theme.radiusMd
                            color: Theme.bgTertiary

                            Text {
                                anchors.centerIn: parent
                                text: "🎮"
                                font.pixelSize: 36
                            }
                        }

                        Text {
                            width: parent.width
                            text: modelData.name || ""
                            color: Theme.textPrimary
                            font.pixelSize: Theme.typeCardTitle
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "Click to see patches"
                            color: Theme.textMuted
                            font.pixelSize: Theme.typeSmall
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            // TODO: push GameDetailPage
                            pageStack.push(Qt.resolvedUrl("GameDetailPage.qml"),
                                           { game: modelData })
                        }
                    }
                }
            }
        }
    }
}

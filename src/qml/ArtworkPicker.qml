import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

// TODO: Kirigami.Dialog API — verify overlay/sheet availability for this Kirigami version
Kirigami.Dialog {
    id: root
    title: "Choose artwork"

    property int gameId: 0
    property int appid: 0
    property string userdata_id: ""
    // TODO: bind to SteamGridDBClient results via patcherEngine
    property var imagesByTab: ({
        "Hero": [],
        "Grid": [],
        "Logo": [],
        "Icon": [],
        "Wide": []
    })
    property int selectedImageId: -1
    property string selectedImageUrl: ""

    signal artworkApplied(string artworkType, string imageUrl)

    standardButtons: Dialog.NoButton
    preferredWidth: 640
    preferredHeight: 480

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spaceMd

        // Tab bar
        TabBar {
            id: tabBar
            Layout.fillWidth: true
            background: Rectangle { color: Theme.bgSecondary }

            Repeater {
                model: ["Hero", "Grid", "Logo", "Icon", "Wide"]
                delegate: TabButton {
                    text: modelData
                    background: Rectangle {
                        color: tabBar.currentIndex === index
                               ? Theme.accentBg
                               : "transparent"
                    }
                    contentItem: Text {
                        text: parent.text
                        color: tabBar.currentIndex === index
                               ? Theme.accent
                               : Theme.textSecondary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: Theme.typeBody
                    }
                }
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            Repeater {
                model: ["Hero", "Grid", "Logo", "Icon", "Wide"]
                delegate: Item {
                    property string artType: modelData
                    property var images: root.imagesByTab[modelData] || []

                    // Empty state
                    Text {
                        anchors.centerIn: parent
                        visible: images.length === 0
                        text: "No images found — tap a tab to load"
                        color: Theme.textMuted
                        font.pixelSize: Theme.typeBody
                    }

                    // Image grid
                    GridView {
                        anchors.fill: parent
                        visible: images.length > 0
                        model: images
                        cellWidth: 160
                        cellHeight: artType === "Hero" ? 90 : 140
                        clip: true

                        delegate: Rectangle {
                            width: GridView.view.cellWidth - Theme.spaceSm
                            height: GridView.view.cellHeight - Theme.spaceSm
                            radius: Theme.radiusMd
                            color: Theme.bgElevated
                            border.color: root.selectedImageId === modelData.id
                                          ? Theme.accent
                                          : Theme.borderDefault
                            border.width: root.selectedImageId === modelData.id ? 2 : 1

                            // Thumbnail placeholder
                            Rectangle {
                                anchors {
                                    fill: parent
                                    margins: Theme.spaceXs
                                }
                                radius: Theme.radiusSm
                                color: Theme.bgTertiary

                                Text {
                                    anchors.centerIn: parent
                                    text: "🖼"
                                    font.pixelSize: 24
                                    // TODO: replace with actual Image { source: modelData.url }
                                    //       once network image loading is confirmed working
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.selectedImageId = modelData.id
                                    root.selectedImageUrl = modelData.url
                                }
                            }
                        }
                    }
                }
            }
        }

        // Action buttons
        Row {
            Layout.fillWidth: true
            spacing: Theme.spaceMd

            Button {
                text: "Skip artwork"
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
                text: "Use selected"
                enabled: root.selectedImageId >= 0
                height: Theme.minTapTarget
                width: (parent.width - Theme.spaceMd) / 2

                background: Rectangle {
                    radius: Theme.radiusMd
                    color: parent.enabled
                        ? (parent.hovered ? Theme.accent : Theme.accentBg)
                        : Theme.bgElevated
                    border.color: parent.enabled ? Theme.accent : Theme.borderDefault
                    border.width: 1
                }
                contentItem: Text {
                    text: parent.text
                    color: parent.enabled ? Theme.accent : Theme.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: Theme.typeBody
                    font.weight: Font.Medium
                }
                onClicked: {
                    root.artworkApplied(
                        ["Hero", "Grid", "Logo", "Icon", "Wide"][tabBar.currentIndex],
                        root.selectedImageUrl
                    )
                    root.close()
                }
            }
        }
    }
}

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

Kirigami.Dialog {
    id: root
    title: "Request a patch"

    // TODO: bind to SteamGridDBClient search via patcherEngine
    property var searchResults: []
    property var selectedGame: null
    property string requestDescription: ""

    standardButtons: Dialog.NoButton
    preferredWidth: 540
    preferredHeight: 560

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spaceMd

        // Search field
        TextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: "Search for a game…"
            color: Theme.textPrimary
            font.pixelSize: Theme.typeBody

            background: Rectangle {
                radius: Theme.radiusMd
                color: Theme.bgElevated
                border.color: searchField.activeFocus ? Theme.accent : Theme.borderDefault
                border.width: 1
            }

            onTextChanged: {
                // TODO: debounce then call patcherEngine.steamgriddb.search_game(text)
            }
        }

        // Search results
        ListView {
            Layout.fillWidth: true
            height: 200
            clip: true
            model: root.searchResults

            delegate: Rectangle {
                width: ListView.view.width
                height: Theme.minTapTarget
                color: root.selectedGame && root.selectedGame.id === modelData.id
                    ? Theme.accentBg
                    : "transparent"
                radius: Theme.radiusMd
                border.color: root.selectedGame && root.selectedGame.id === modelData.id
                    ? Theme.accent
                    : "transparent"
                border.width: 1

                Row {
                    anchors {
                        fill: parent
                        margins: Theme.spaceMd
                    }
                    spacing: Theme.spaceMd

                    // Thumbnail placeholder
                    Rectangle {
                        width: 36
                        height: 36
                        anchors.verticalCenter: parent.verticalCenter
                        radius: Theme.radiusSm
                        color: Theme.bgTertiary

                        Text {
                            anchors.centerIn: parent
                            text: "🎮"
                            font.pixelSize: 18
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
                        Row {
                            spacing: Theme.spaceSm
                            Text {
                                text: modelData.release_date || ""
                                color: Theme.textMuted
                                font.pixelSize: Theme.typeSmall
                            }
                            Text {
                                visible: modelData.steam_appid != null
                                text: "AppID: " + (modelData.steam_appid || "")
                                color: Theme.textMuted
                                font.pixelSize: Theme.typeSmall
                                font.family: "monospace"
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.selectedGame = modelData
                }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.borderDefault
        }

        // "What should the patch fix?" text area
        Text {
            text: "What should the patch fix?"
            color: Theme.textSecondary
            font.pixelSize: Theme.typeBody
        }

        ScrollView {
            Layout.fillWidth: true
            height: 100

            TextArea {
                id: descriptionArea
                placeholderText: "Describe the problem the patch should solve…"
                color: Theme.textPrimary
                font.pixelSize: Theme.typeBody
                wrapMode: TextEdit.WordWrap
                background: Rectangle {
                    radius: Theme.radiusMd
                    color: Theme.bgElevated
                    border.color: descriptionArea.activeFocus ? Theme.accent : Theme.borderDefault
                    border.width: 1
                }
                onTextChanged: root.requestDescription = text
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
                text: "Open request on GitHub"
                enabled: root.selectedGame !== null && root.requestDescription.length > 0
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
                    // TODO: build issue URL with pre-filled title and body
                    var issueTitle = encodeURIComponent("Patch request: " + root.selectedGame.name)
                    var issueBody = encodeURIComponent(
                        "## Game\n" + root.selectedGame.name +
                        " (AppID: " + root.selectedGame.steam_appid + ")" +
                        "\n\n## What should the patch fix?\n" + root.requestDescription
                    )
                    var url = "https://github.com/lovozeto/deck-patches/issues/new" +
                              "?title=" + issueTitle + "&body=" + issueBody
                    Qt.openUrlExternally(url)
                    root.close()
                }
            }
        }
    }
}

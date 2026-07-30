import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

Kirigami.ScrollablePage {
    id: root
    title: "Explore"

    // TODO: replace with real models from Python context properties
    property var statsModel: [
        { label: "Available", value: "—" },
        { label: "Applied",   value: "—" },
        { label: "Outdated",  value: "—" },
        { label: "Users",     value: "—" }
    ]
    property var attentionPatches: []
    property var gameItems: []
    property var appItems: []

    ColumnLayout {
        width: parent.width
        spacing: Theme.spaceXxl

        // Hero banner — stats row
        Rectangle {
            Layout.fillWidth: true
            height: 100
            radius: Theme.radiusLg
            color: Theme.bgSecondary
            border.color: Theme.borderDefault
            border.width: 1

            Row {
                anchors.centerIn: parent
                spacing: 0

                Repeater {
                    model: root.statsModel
                    delegate: Item {
                        width: root.width / 4
                        height: 80

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spaceXs

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.value
                                color: Theme.accent
                                font.pixelSize: Theme.typePageTitle
                                font.weight: Font.Medium
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                color: Theme.textSecondary
                                font.pixelSize: Theme.typeCaption
                            }
                        }

                        // Divider between items (not after last)
                        Rectangle {
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            width: 1
                            height: 40
                            color: Theme.borderDefault
                            visible: index < root.statsModel.length - 1
                        }
                    }
                }
            }
        }

        // "Needs attention" section — only shown when there are patches to fix
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceSm
            visible: root.attentionPatches.length > 0

            Text {
                text: "Needs attention"
                color: Theme.warning
                font.pixelSize: Theme.typeSectionTitle
                font.weight: Font.Medium
            }

            Repeater {
                model: root.attentionPatches
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: Theme.minTapTarget
                    radius: Theme.radiusMd
                    color: Theme.warningBg
                    border.color: Theme.warning
                    border.width: 1

                    Row {
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            leftMargin: Theme.spaceMd
                            right: parent.right
                            rightMargin: Theme.spaceMd
                        }
                        spacing: Theme.spaceMd

                        Text {
                            text: "⚠"
                            color: Theme.warning
                            font.pixelSize: Theme.typeBody
                        }
                        Text {
                            text: modelData.name || modelData.id || "Unknown patch"
                            color: Theme.textPrimary
                            font.pixelSize: Theme.typeBody
                        }
                    }
                }
            }
        }

        // Game shelf
        _Shelf {
            Layout.fillWidth: true
            title: "Games"
            items: root.gameItems
            emptyText: "No game patches available yet"
            onItemClicked: function(item) {
                // TODO: push GameDetailPage with item
            }
        }

        // App shelf
        _Shelf {
            Layout.fillWidth: true
            title: "Apps"
            items: root.appItems
            emptyText: "No app setups available yet"
            onItemClicked: function(item) {
                // TODO: push AppDetailPage with item
            }
        }
    }

    // Internal shelf component (not exported as a separate file for simplicity)
    component _Shelf: ColumnLayout {
        property string title: ""
        property var items: []
        property string emptyText: ""
        signal itemClicked(var item)

        spacing: Theme.spaceSm

        Text {
            text: parent.title
            color: Theme.textPrimary
            font.pixelSize: Theme.typeSectionTitle
            font.weight: Font.Medium
        }

        // Empty state
        Text {
            visible: parent.items.length === 0
            text: parent.emptyText
            color: Theme.textMuted
            font.pixelSize: Theme.typeBody
        }

        // Horizontal scroll shelf
        ListView {
            Layout.fillWidth: true
            height: 140
            visible: parent.items.length > 0
            orientation: ListView.Horizontal
            spacing: Theme.spaceMd
            clip: true
            model: parent.items

            delegate: Rectangle {
                width: 120
                height: 140
                radius: Theme.radiusMd
                color: Theme.bgElevated
                border.color: Theme.borderDefault
                border.width: 1

                Column {
                    anchors {
                        fill: parent
                        margins: Theme.spaceSm
                    }
                    spacing: Theme.spaceXs

                    Rectangle {
                        width: parent.width
                        height: 80
                        radius: Theme.radiusSm
                        color: Theme.bgTertiary

                        Text {
                            anchors.centerIn: parent
                            text: "🎮"
                            font.pixelSize: 28
                        }
                    }

                    Text {
                        width: parent.width
                        text: modelData.name || ""
                        color: Theme.textPrimary
                        font.pixelSize: Theme.typeSmall
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                    }
                    Text {
                        text: (modelData.patch_count || 0) + " patches"
                        color: Theme.textMuted
                        font.pixelSize: Theme.typeMini
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: parent.parent.parent.parent.itemClicked(modelData)
                }
            }
        }
    }
}

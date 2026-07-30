import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

Kirigami.ScrollablePage {
    id: root
    title: "Apps"

    property var apps: backend.appItems

    ColumnLayout {
        width: parent.width
        spacing: Theme.spaceLg

        // Empty state
        Item {
            Layout.fillWidth: true
            height: 200
            visible: root.apps.length === 0

            Column {
                anchors.centerIn: parent
                spacing: Theme.spaceMd

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "📦"
                    font.pixelSize: 48
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No app setups available"
                    color: Theme.textSecondary
                    font.pixelSize: Theme.typeSectionTitle
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "App setups let you install non-Steam games as proper library entries"
                    color: Theme.textMuted
                    font.pixelSize: Theme.typeBody
                }
            }
        }

        // Apps grid
        GridLayout {
            Layout.fillWidth: true
            columns: Math.max(1, Math.floor(parent.width / 240))
            rowSpacing: Theme.spaceMd
            columnSpacing: Theme.spaceMd
            visible: root.apps.length > 0

            Repeater {
                model: root.apps
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 100
                    radius: Theme.radiusLg
                    color: Theme.bgSecondary
                    border.color: Theme.borderDefault
                    border.width: 1

                    Row {
                        anchors {
                            fill: parent
                            margins: Theme.spaceMd
                        }
                        spacing: Theme.spaceMd

                        // App icon placeholder
                        Rectangle {
                            width: 64
                            height: 64
                            anchors.verticalCenter: parent.verticalCenter
                            radius: Theme.radiusMd
                            color: Theme.bgTertiary

                            Text {
                                anchors.centerIn: parent
                                text: "📦"
                                font.pixelSize: 28
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spaceXs
                            width: parent.width - 64 - Theme.spaceMd

                            Text {
                                text: modelData.name || ""
                                color: Theme.textPrimary
                                font.pixelSize: Theme.typeCardTitle
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            // Install status badge
                            Rectangle {
                                height: 20
                                width: statusLabel.width + Theme.spaceSm * 2
                                radius: Theme.radiusPill
                                color: modelData.installed ? Theme.successBg : Theme.accentBg

                                Text {
                                    id: statusLabel
                                    anchors.centerIn: parent
                                    text: modelData.installed ? "Installed" : "Available"
                                    color: modelData.installed ? Theme.success : Theme.accent
                                    font.pixelSize: Theme.typeSmall
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            pageStack.push(Qt.resolvedUrl("AppDetailPage.qml"),
                                           { appItem: modelData })
                        }
                    }
                }
            }
        }
    }
}

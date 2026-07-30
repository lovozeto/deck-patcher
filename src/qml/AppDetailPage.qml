import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

Kirigami.ScrollablePage {
    id: root
    title: app.name || "App"

    // Passed in from AppsPage
    property var app: ({})
    // TODO: bind to Python accounts list
    property var accounts: []
    // TODO: bind to per-account setup status from patcherEngine
    property bool isFullySetUp: false

    ColumnLayout {
        width: parent.width
        spacing: Theme.spaceLg

        // Header: icon + name + install status
        Rectangle {
            Layout.fillWidth: true
            height: 120
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

                Rectangle {
                    width: 80
                    height: 80
                    anchors.verticalCenter: parent.verticalCenter
                    radius: Theme.radiusMd
                    color: Theme.bgTertiary

                    Text {
                        anchors.centerIn: parent
                        text: "📦"
                        font.pixelSize: 36
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spaceSm
                    width: parent.width - 80 - Theme.spaceLg

                    Text {
                        text: root.app.name || ""
                        color: Theme.textPrimary
                        font.pixelSize: Theme.typePageTitle
                        font.weight: Font.Medium
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }

                    Rectangle {
                        height: 24
                        width: installStatusText.width + Theme.spaceMd * 2
                        radius: Theme.radiusPill
                        color: root.isFullySetUp ? Theme.successBg : Theme.accentBg

                        Text {
                            id: installStatusText
                            anchors.centerIn: parent
                            text: root.isFullySetUp ? "Fully set up" : "Not set up"
                            color: root.isFullySetUp ? Theme.success : Theme.accent
                            font.pixelSize: Theme.typeCaption
                        }
                    }
                }
            }
        }

        // Setup wizard card — shown when not fully set up
        Rectangle {
            Layout.fillWidth: true
            visible: !root.isFullySetUp
            height: wizardColumn.implicitHeight + Theme.spaceLg * 2
            radius: Theme.radiusLg
            color: Theme.accentBg
            border.color: Theme.accent
            border.width: 1

            Column {
                id: wizardColumn
                anchors {
                    fill: parent
                    margins: Theme.spaceLg
                }
                spacing: Theme.spaceMd

                Text {
                    text: "Setup wizard"
                    color: Theme.accent
                    font.pixelSize: Theme.typeSectionTitle
                    font.weight: Font.Medium
                }
                Text {
                    text: root.app.description || "Set up this app on your Steam Deck."
                    color: Theme.textPrimary
                    font.pixelSize: Theme.typeBody
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
                Button {
                    text: "Start setup"
                    width: parent.width
                    height: Theme.minTapTarget

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
                        // TODO: call patcherEngine.setup_app(app.id, accountIds)
                        // then show AccountSelector dialog
                    }
                }
            }
        }

        // Per-account status rows
        Text {
            text: "Account status"
            color: Theme.textPrimary
            font.pixelSize: Theme.typeSectionTitle
            font.weight: Font.Medium
        }

        Repeater {
            model: root.accounts
            delegate: Rectangle {
                Layout.fillWidth: true
                height: Theme.minTapTarget + Theme.spaceSm
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

                    Rectangle {
                        width: 32
                        height: 32
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 16
                        color: Theme.accentBg

                        Text {
                            anchors.centerIn: parent
                            text: modelData.persona_name
                                ? modelData.persona_name.charAt(0).toUpperCase()
                                : "?"
                            color: Theme.accent
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
                            text: "Shortcut: —  Artwork: —  Patch: —"
                            color: Theme.textMuted
                            font.pixelSize: Theme.typeSmall
                            // TODO: bind to real per-account status from patcherEngine
                        }
                    }
                }
            }
        }
    }
}

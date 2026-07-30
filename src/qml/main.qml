import QtQuick 2.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami

// TODO: Verify Kirigami.ApplicationWindow API against the target runtime version.
// The GlobalDrawer header/footer properties may differ between Kirigami 2.x and 5.x.
Kirigami.ApplicationWindow {
    id: root
    title: "Deck Patcher"
    minimumWidth: 800
    minimumHeight: 500

    // Active account footer text — populated from Python context property
    // TODO: bind to patcherEngine.activeAccount once model is wired
    property string activeAccountName: "Loading…"
    property string activeAccountId: ""
    property int attentionCount: 0

    globalDrawer: Kirigami.GlobalDrawer {
        title: "Deck Patcher"
        titleIcon: "deck-patcher"
        modal: false
        width: Theme.sidebarWidth

        // Header: main navigation
        // TODO: Kirigami.Action icon names must match installed icon theme on SteamOS
        actions: [
            Kirigami.Action {
                text: "Explore"
                icon.name: "go-home"
                onTriggered: root.pageStack.replace(Qt.resolvedUrl("ExplorePage.qml"))
            },
            Kirigami.Action {
                text: "Games"
                icon.name: "input-gaming"
                onTriggered: root.pageStack.replace(Qt.resolvedUrl("GamesPage.qml"))
            },
            Kirigami.Action {
                text: "Apps"
                icon.name: "applications-all"
                onTriggered: root.pageStack.replace(Qt.resolvedUrl("AppsPage.qml"))
            },

            // Separator
            Kirigami.Action { separator: true },

            Kirigami.Action {
                text: "Manage"
                icon.name: "view-grid"
                // TODO: badge API may differ; check Kirigami.Action badge property availability
                // badge: root.attentionCount > 0 ? root.attentionCount : 0
                onTriggered: root.pageStack.replace(Qt.resolvedUrl("ManagePage.qml"))
            },
            Kirigami.Action {
                text: "Settings"
                icon.name: "settings-configure"
                onTriggered: root.pageStack.replace(Qt.resolvedUrl("SettingsPage.qml"))
            }
        ]

        // Footer: active account display
        footer: Item {
            height: Theme.minTapTarget
            width: parent.width

            Rectangle {
                anchors.fill: parent
                color: Theme.bgSecondary

                Row {
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        leftMargin: Theme.spaceMd
                        right: parent.right
                        rightMargin: Theme.spaceMd
                    }
                    spacing: Theme.spaceSm

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: Theme.accentBg

                        Text {
                            anchors.centerIn: parent
                            text: root.activeAccountName.length > 0
                                ? root.activeAccountName.charAt(0).toUpperCase()
                                : "?"
                            color: Theme.accent
                            font.pixelSize: Theme.typeCaption
                            font.weight: Font.Medium
                        }
                    }

                    Column {
                        spacing: 2
                        width: parent.width - 28 - Theme.spaceSm

                        Text {
                            text: root.activeAccountName
                            color: Theme.textPrimary
                            font.pixelSize: Theme.typeSmall
                            elide: Text.ElideRight
                            width: parent.width
                        }
                        Text {
                            text: root.activeAccountId
                            color: Theme.textMuted
                            font.pixelSize: Theme.typeMini
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }
                }
            }
        }
    }

    // Initial page
    pageStack.initialPage: Qt.resolvedUrl("ExplorePage.qml")
}

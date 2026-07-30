import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

Kirigami.ScrollablePage {
    id: root
    title: "Settings"

    // TODO: bind to patcherEngine settings object
    property string registryUrl: "https://raw.githubusercontent.com/lovozeto/deck-patches/main/index.json"
    property string steamGridDbKey: ""
    property bool autoCheck: true
    property int autoCheckIntervalMinutes: 5
    property var detectedAccounts: backend.allAccounts
    property string appVersion: "0.1.0"

    ColumnLayout {
        width: parent.width
        spacing: Theme.spaceXxl

        // ── Patch repository ──────────────────────────────────────────────
        _Section {
            Layout.fillWidth: true
            title: "Patch repository"

            ColumnLayout {
                width: parent.width
                spacing: Theme.spaceSm

                Text {
                    text: "Registry URL"
                    color: Theme.textSecondary
                    font.pixelSize: Theme.typeSmall
                }

                TextField {
                    Layout.fillWidth: true
                    text: root.registryUrl
                    color: Theme.textPrimary
                    font.pixelSize: Theme.typeBody
                    font.family: "monospace"

                    background: Rectangle {
                        radius: Theme.radiusMd
                        color: Theme.bgElevated
                        border.color: parent.activeFocus ? Theme.accent : Theme.borderDefault
                        border.width: 1
                    }

                    onTextChanged: root.registryUrl = text
                }

                Text {
                    text: "Default: https://raw.githubusercontent.com/lovozeto/deck-patches/main/index.json"
                    color: Theme.textMuted
                    font.pixelSize: Theme.typeSmall
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
            }
        }

        // ── SteamGridDB ───────────────────────────────────────────────────
        _Section {
            Layout.fillWidth: true
            title: "SteamGridDB"

            ColumnLayout {
                width: parent.width
                spacing: Theme.spaceSm

                Text {
                    text: "API key"
                    color: Theme.textSecondary
                    font.pixelSize: Theme.typeSmall
                }

                TextField {
                    Layout.fillWidth: true
                    text: root.steamGridDbKey
                    echoMode: TextInput.Password
                    color: Theme.textPrimary
                    font.pixelSize: Theme.typeBody
                    placeholderText: "sk-…"

                    background: Rectangle {
                        radius: Theme.radiusMd
                        color: Theme.bgElevated
                        border.color: parent.activeFocus ? Theme.accent : Theme.borderDefault
                        border.width: 1
                    }

                    onTextChanged: root.steamGridDbKey = text
                }

                // Link to get API key
                Row {
                    spacing: Theme.spaceXs

                    Text {
                        text: "Get a free API key at"
                        color: Theme.textMuted
                        font.pixelSize: Theme.typeSmall
                    }

                    Text {
                        text: "steamgriddb.com/profile/preferences/api"
                        color: Theme.accent
                        font.pixelSize: Theme.typeSmall

                        MouseArea {
                            anchors.fill: parent
                            onClicked: Qt.openUrlExternally("https://www.steamgriddb.com/profile/preferences/api")
                        }
                    }
                }
            }
        }

        // ── Auto-check ────────────────────────────────────────────────────
        _Section {
            Layout.fillWidth: true
            title: "Automatic updates"

            ColumnLayout {
                width: parent.width
                spacing: Theme.spaceMd

                Row {
                    width: parent.width

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Check for outdated patches automatically"
                        color: Theme.textPrimary
                        font.pixelSize: Theme.typeBody
                        width: parent.width - autoToggle.width
                    }

                    Switch {
                        id: autoToggle
                        anchors.verticalCenter: parent.verticalCenter
                        checked: root.autoCheck
                        onCheckedChanged: root.autoCheck = checked
                    }
                }

                Row {
                    visible: root.autoCheck
                    spacing: Theme.spaceMd

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Check every"
                        color: Theme.textSecondary
                        font.pixelSize: Theme.typeBody
                    }

                    SpinBox {
                        value: root.autoCheckIntervalMinutes
                        from: 1
                        to: 60
                        onValueChanged: root.autoCheckIntervalMinutes = value
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "minutes"
                        color: Theme.textSecondary
                        font.pixelSize: Theme.typeBody
                    }
                }
            }
        }

        // ── Detected Steam accounts ────────────────────────────────────────
        _Section {
            Layout.fillWidth: true
            title: "Detected Steam accounts"

            Column {
                width: parent.width
                spacing: Theme.spaceSm

                Text {
                    visible: root.detectedAccounts.length === 0
                    text: "No Steam accounts detected"
                    color: Theme.textMuted
                    font.pixelSize: Theme.typeBody
                }

                Repeater {
                    model: root.detectedAccounts
                    delegate: Rectangle {
                        width: parent.width
                        height: Theme.minTapTarget
                        radius: Theme.radiusMd
                        color: Theme.bgElevated

                        Row {
                            anchors {
                                fill: parent
                                margins: Theme.spaceMd
                            }
                            spacing: Theme.spaceMd

                            Rectangle {
                                width: 28
                                height: 28
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 14
                                color: Theme.accentBg

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.name
                                        ? modelData.name.charAt(0).toUpperCase()
                                        : "?"
                                    color: Theme.accent
                                    font.pixelSize: Theme.typeSmall
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
                                    text: modelData.steamId || ""
                                    color: Theme.textMuted
                                    font.pixelSize: Theme.typeSmall
                                    font.family: "monospace"
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── About ─────────────────────────────────────────────────────────
        _Section {
            Layout.fillWidth: true
            title: "About"

            Column {
                width: parent.width
                spacing: Theme.spaceSm

                _AboutRow { label: "Version";  value: root.appVersion }
                _AboutRow { label: "License";  value: "MIT" }

                Row {
                    spacing: Theme.spaceSm
                    Text { text: "Source:"; color: Theme.textMuted; font.pixelSize: Theme.typeBody }
                    Text {
                        text: "github.com/lovozeto/deck-patcher"
                        color: Theme.accent
                        font.pixelSize: Theme.typeBody
                        MouseArea {
                            anchors.fill: parent
                            onClicked: Qt.openUrlExternally("https://github.com/lovozeto/deck-patcher")
                        }
                    }
                }

                Row {
                    spacing: Theme.spaceSm
                    Text { text: "Patches:"; color: Theme.textMuted; font.pixelSize: Theme.typeBody }
                    Text {
                        text: "github.com/lovozeto/deck-patches"
                        color: Theme.accent
                        font.pixelSize: Theme.typeBody
                        MouseArea {
                            anchors.fill: parent
                            onClicked: Qt.openUrlExternally("https://github.com/lovozeto/deck-patches")
                        }
                    }
                }
            }
        }
    }

    component _Section: ColumnLayout {
        property string title: ""
        spacing: Theme.spaceSm

        Text {
            text: parent.title
            color: Theme.textPrimary
            font.pixelSize: Theme.typeSectionTitle
            font.weight: Font.Medium
        }

        Rectangle {
            Layout.fillWidth: true
            height: sectionContent.implicitHeight + Theme.spaceLg * 2
            radius: Theme.radiusLg
            color: Theme.bgSecondary
            border.color: Theme.borderDefault
            border.width: 1

            Item {
                id: sectionContent
                anchors {
                    fill: parent
                    margins: Theme.spaceLg
                }
                implicitHeight: childrenRect.height
            }
        }
    }

    component _AboutRow: Row {
        property string label: ""
        property string value: ""
        spacing: Theme.spaceSm
        Text { text: parent.label + ":"; color: Theme.textMuted; font.pixelSize: Theme.typeBody }
        Text { text: parent.value; color: Theme.textPrimary; font.pixelSize: Theme.typeBody }
    }
}

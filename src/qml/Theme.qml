pragma Singleton
import QtQuick 2.15

QtObject {
    // Backgrounds
    readonly property string bgPrimary: "#1a1a1e"
    readonly property string bgSecondary: "#222226"
    readonly property string bgTertiary: "#2a2a2e"
    readonly property string bgElevated: "#333338"

    // Borders
    readonly property string borderDefault: "#3a3a40"
    readonly property string borderStrong: "#4a4a50"

    // Text
    readonly property string textPrimary: "#e8e8ec"
    readonly property string textSecondary: "#a0a0a8"
    readonly property string textMuted: "#68686e"

    // Semantic colors
    readonly property string accent: "#5b8def"
    readonly property string accentBg: "rgba(91,141,239,0.12)"
    readonly property string success: "#4caf7c"
    readonly property string successBg: "rgba(76,175,124,0.12)"
    readonly property string warning: "#e0a040"
    readonly property string warningBg: "rgba(224,160,64,0.12)"
    readonly property string danger: "#e05050"
    readonly property string dangerBg: "rgba(224,80,80,0.12)"

    // Typography
    readonly property int typePageTitle: 20
    readonly property int typeSectionTitle: 16
    readonly property int typeCardTitle: 14
    readonly property int typeBody: 13
    readonly property int typeCaption: 12
    readonly property int typeSmall: 11
    readonly property int typeMini: 10
    readonly property int typeMono: 12

    // Spacing
    readonly property int spaceXs: 4
    readonly property int spaceSm: 8
    readonly property int spaceMd: 12
    readonly property int spaceLg: 16
    readonly property int spaceXl: 20
    readonly property int spaceXxl: 24

    // Components
    readonly property int radiusSm: 6
    readonly property int radiusMd: 8
    readonly property int radiusLg: 12
    readonly property int radiusPill: 10
    readonly property int minTapTarget: 44
    readonly property int sidebarWidth: 180
}

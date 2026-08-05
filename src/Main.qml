import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

ApplicationWindow
{
    id: window
    visible: true
    width: 1100
    height: 800
    minimumWidth: 560
    minimumHeight: 440
    title: "Neko Kernel Manager"
    Material.theme: Material.Dark
    Material.accent: palette.accent
    Material.primary: palette.bg
    font.family: "Inter"

    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint

    // Neko Wizard theme — minimal / flat / sharp.
    QtObject
    {
        id: palette
        function mix(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1.0) }

        readonly property color bg: theme.windowBg
        readonly property color surface: theme.cardBg
        readonly property color popoverBg: theme.popoverBg
        readonly property color surfaceHi: mix(theme.cardBg, theme.windowFg, 0.07)
        readonly property color currentLine: mix(theme.windowBg, theme.windowFg, 0.14)
        readonly property color borderHi: mix(theme.windowBg, theme.windowFg, 0.28)
        readonly property color selection: mix(theme.cardBg, theme.windowFg, 0.07)
        readonly property color fg: theme.windowFg
        readonly property color textSoft: mix(theme.windowFg, theme.windowBg, 0.25)
        readonly property color comment: mix(theme.windowFg, theme.windowBg, 0.45)
        readonly property color accent: theme.accentBg
        readonly property color accentHi: mix(theme.accentBg, theme.windowFg, 0.20)
        readonly property color accentFg: theme.accentFg
        readonly property color error: theme.errorBg
        readonly property color cyan: theme.accentBg
        readonly property color green: theme.accentBg
        readonly property color orange: "#ff9800"
        readonly property color pink: theme.errorBg
        readonly property color purple: theme.accentBg
    }

    // Title-bar button colours
    QtObject
    {
        id: dracula
        readonly property color bg: theme.headerbarBg
        readonly property color purple: theme.accentBg
        readonly property color red: theme.errorBg
        readonly property color yellow: palette.comment
        readonly property color green: palette.comment
    }

    // ── Resize edge handles for frameless window ──
    property int resizeMargin: 5

    // Bottom edge
    MouseArea
    {
        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
        height: resizeMargin; cursorShape: Qt.SizeVerCursor
        property point pressPos
        onPressed: (mouse) => pressPos = Qt.point(mouse.x, mouse.y)
        onPositionChanged: (mouse) => {
            var dy = mouse.y - pressPos.y
            window.height = Math.max(window.minimumHeight, window.height + dy)
        }
    }
    // Right edge
    MouseArea
    {
        anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.right: parent.right
        width: resizeMargin; cursorShape: Qt.SizeHorCursor
        property point pressPos
        onPressed: (mouse) => pressPos = Qt.point(mouse.x, mouse.y)
        onPositionChanged: (mouse) => {
            var dx = mouse.x - pressPos.x
            window.width = Math.max(window.minimumWidth, window.width + dx)
        }
    }
    // Left edge
    MouseArea
    {
        anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.left: parent.left
        width: resizeMargin; cursorShape: Qt.SizeHorCursor
        property point pressPos
        onPressed: (mouse) => pressPos = Qt.point(mouse.x, mouse.y)
        onPositionChanged: (mouse) => {
            var dx = mouse.x - pressPos.x
            window.x += dx
            window.width = Math.max(window.minimumWidth, window.width - dx)
        }
    }
    // Top edge
    MouseArea
    {
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
        height: resizeMargin; cursorShape: Qt.SizeVerCursor
        property point pressPos
        onPressed: (mouse) => pressPos = Qt.point(mouse.x, mouse.y)
        onPositionChanged: (mouse) => {
            var dy = mouse.y - pressPos.y
            window.y += dy
            window.height = Math.max(window.minimumHeight, window.height - dy)
        }
    }
    // Bottom-right corner
    MouseArea
    {
        anchors.bottom: parent.bottom; anchors.right: parent.right
        width: resizeMargin * 2; height: resizeMargin * 2; cursorShape: Qt.SizeFDiagCursor
        property point pressPos
        onPressed: (mouse) => pressPos = Qt.point(mouse.x, mouse.y)
        onPositionChanged: (mouse) => {
            var dx = mouse.x - pressPos.x; var dy = mouse.y - pressPos.y
            window.width = Math.max(window.minimumWidth, window.width + dx)
            window.height = Math.max(window.minimumHeight, window.height + dy)
        }
    }
    // Bottom-left corner
    MouseArea
    {
        anchors.bottom: parent.bottom; anchors.left: parent.left
        width: resizeMargin * 2; height: resizeMargin * 2; cursorShape: Qt.SizeBDiagCursor
        property point pressPos
        onPressed: (mouse) => pressPos = Qt.point(mouse.x, mouse.y)
        onPositionChanged: (mouse) => {
            var dx = mouse.x - pressPos.x; var dy = mouse.y - pressPos.y
            window.x += dx
            window.width = Math.max(window.minimumWidth, window.width - dx)
            window.height = Math.max(window.minimumHeight, window.height + dy)
        }
    }

    // Main Border and Background
    Rectangle
    {
        anchors.fill: parent
        color: palette.bg
        border.color: palette.currentLine
        border.width: 1
        radius: 0

        ColumnLayout
        {
            anchors.fill: parent
            anchors.margins: 2
            spacing: 0

            // ─── Header bar ───
            Rectangle
            {
                Layout.fillWidth: true
                height: 36
                color: dracula.bg

                Rectangle
                {
                    anchors.bottom: parent.bottom
                    width: parent.width; height: 1
                    color: palette.currentLine
                }

                MouseArea
                {
                    anchors.fill: parent
                    property point lastMousePos
                    onPressed: (mouse) => lastMousePos = Qt.point(mouse.x, mouse.y)
                    onPositionChanged: (mouse) =>
                    {
                        var delta = Qt.point(mouse.x - lastMousePos.x, mouse.y - lastMousePos.y)
                        window.x += delta.x
                        window.y += delta.y
                    }
                }

                RowLayout
                {
                    anchors.fill: parent
                    anchors.leftMargin: 15
                    anchors.rightMargin: 10

                    Text
                    {
                        text: qsTr("Neko Kernel Manager")
                        color: palette.comment
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        font.letterSpacing: 0.4
                    }

                    Item { Layout.fillWidth: true }

                    Row
                    {
                        spacing: 8
                        Layout.alignment: Qt.AlignVCenter

                        // Minimize
                        Rectangle
                        {
                            width: 12; height: 12; radius: 0; color: dracula.green
                            MouseArea { anchors.fill: parent; onClicked: window.showMinimized() }
                        }
                        // Maximize
                        Rectangle
                        {
                            width: 12; height: 12; radius: 0; color: dracula.yellow
                            MouseArea { anchors.fill: parent; onClicked: window.visibility === Window.Maximized ? window.showNormal() : window.showMaximized() }
                        }
                        // Close
                        Rectangle
                        {
                            width: 12; height: 12; radius: 0; color: dracula.red
                            MouseArea { anchors.fill: parent; onClicked: window.close() }
                        }
                    }
                }
            }

            // ─── Progress Bar (visible when loading/busy) ───
            Rectangle
            {
                Layout.fillWidth: true
                height: 4
                color: palette.currentLine
                visible: bridge.busy || bridge.progress > 0
                z: 99

                Rectangle
                {
                    id: progressBarFill
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * (Math.max(10, bridge.progress) / 100.0)
                    color: palette.accent
                    
                    Behavior on width {
                        NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
                    }
                }

                // Smooth pulse animation while busy
                SequentialAnimation on opacity {
                    running: bridge.busy
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.5; duration: 500; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.5; to: 1.0; duration: 500; easing.type: Easing.InOutSine }
                }
            }

            // ─── Main content surface ───
            Item
            {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle
                {
                    anchors.fill: parent
                    color: palette.bg
                }

                ColumnLayout
                {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // Top bar: brand · log button · status
                    RowLayout
                    {
                        Layout.fillWidth: true
                        spacing: 12

                        Image
                        {
                            id: logoImage; source: "qrc:/neko/Data/logo.png"
                            Layout.preferredWidth: 32; Layout.preferredHeight: 32
                            sourceSize: Qt.size(64, 64); smooth: true
                        }
                        Text
                        {
                            id: mainTitle
                            text: "Neko Kernel Manager"
                            color: palette.fg
                            font.pixelSize: 17; font.weight: Font.Bold; font.letterSpacing: -0.3
                            visible: window.width >= 760
                        }

                        Item { Layout.fillWidth: true }

                        // Active kernel chip
                        Rectangle
                        {
                            visible: bridge.activeKernelVersion !== ""
                            implicitWidth: activeLabel.implicitWidth + 16; implicitHeight: 24; radius: 0
                            color: palette.surface; border.color: palette.accent; border.width: 1
                            Text
                            {
                                id: activeLabel
                                anchors.centerIn: parent
                                text: qsTr("Running: %1").arg(bridge.activeKernelVersion)
                                color: palette.accent; font.pixelSize: 10; font.bold: true
                            }
                        }

                        // Log button
                        Button
                        {
                            id: logBtn; text: qsTr("Logs")
                            hoverEnabled: true
                            ToolTip
                            {
                                id: logTip
                                visible: logBtn.hovered
                                delay: 400
                                text: qsTr("View system logs and operation output")
                                contentItem: Text { text: logTip.text; font.pixelSize: 11; color: palette.fg }
                                background: Rectangle { color: palette.popoverBg; border.color: palette.currentLine; border.width: 1; radius: 4 }
                            }
                            contentItem: Text
                            {
                                text: logBtn.text; font.bold: true; font.pixelSize: 11; color: palette.fg
                                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle
                            {
                                implicitHeight: 28; implicitWidth: 70; radius: 0
                                color: logBtn.hovered ? palette.surfaceHi : palette.surface
                                border.color: palette.currentLine
                            }
                            onClicked: logModal.open()
                        }
                    }

                    // Divider under top bar
                    Rectangle { Layout.fillWidth: true; height: 1; color: palette.currentLine }

                    // ─── Kernels View ───
                    ColumnLayout
                    {
                        spacing: 8
                        Layout.fillWidth: true; Layout.fillHeight: true

                        RowLayout
                        {
                            Layout.fillWidth: true
                            spacing: 12

                            ColumnLayout
                            {
                                Layout.fillWidth: true
                                spacing: 2
                                Text
                                {
                                    text: qsTr("Installed & Available Kernels"); color: palette.fg; font.pixelSize: 16; font.weight: Font.Bold; font.letterSpacing: -0.2
                                    Layout.fillWidth: true; elide: Text.ElideRight
                                }
                                Text
                                {
                                    text: qsTr("Install or remove kernels from the official Void repositories, or purge old versions.")
                                    color: palette.comment; font.pixelSize: 11
                                    Layout.fillWidth: true; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
                                }
                            }

                            // Search / filter
                            TextField
                            {
                                id: kernelSearch
                                Layout.preferredWidth: 220; Layout.minimumWidth: 120
                                placeholderText: qsTr("Search kernels…")
                                color: palette.fg; font.pixelSize: 12
                                verticalAlignment: TextInput.AlignVCenter
                                leftPadding: 10; rightPadding: 10
                                background: Rectangle
                                {
                                    implicitHeight: 28; radius: 0
                                    color: palette.bg
                                    border.color: kernelSearch.activeFocus ? palette.accent : palette.currentLine
                                }
                            }

                            Button
                            {
                                id: purgeBtn; text: qsTr("Purge Old Kernels"); enabled: !bridge.busy
                                opacity: enabled ? 1.0 : 0.4
                                hoverEnabled: true
                                ToolTip
                                {
                                    id: purgeTip
                                    visible: purgeBtn.hovered
                                    delay: 400
                                    text: qsTr("Remove old, unused kernel versions (vkpurge) to free disk space")
                                    contentItem: Text { text: purgeTip.text; font.pixelSize: 11; color: palette.fg }
                                    background: Rectangle { color: palette.popoverBg; border.color: palette.currentLine; border.width: 1; radius: 4 }
                                }
                                contentItem: Text
                                {
                                    text: purgeBtn.text; font.bold: true; font.pixelSize: 11; color: purgeBtn.enabled ? palette.accentFg : palette.comment
                                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle
                                {
                                    implicitHeight: 28; implicitWidth: 140; radius: 0
                                    color: !purgeBtn.enabled ? palette.currentLine :
                                    (purgeArea.pressed ? Qt.darker(palette.error, 1.2) :
                                    (purgeArea.containsMouse ? Qt.lighter(palette.error, 1.1) : palette.error))

                                    MouseArea
                                    {
                                        id: purgeArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        enabled: purgeBtn.enabled
                                        onClicked: if (purgeBtn.enabled) purgeBtn.clicked()
                                    }
                                }
                                onClicked: bridge.vkpurge()
                            }

                            Button
                            {
                                id: dkmsBtn; text: qsTr("Manage DKMS"); enabled: !bridge.busy
                                opacity: enabled ? 1.0 : 0.4
                                hoverEnabled: true
                                ToolTip
                                {
                                    id: dkmsTip
                                    visible: dkmsBtn.hovered
                                    delay: 400
                                    text: qsTr("View, install, and remove DKMS kernel modules")
                                    contentItem: Text { text: dkmsTip.text; font.pixelSize: 11; color: palette.fg }
                                    background: Rectangle { color: palette.popoverBg; border.color: palette.currentLine; border.width: 1; radius: 4 }
                                }
                                contentItem: Text
                                {
                                    text: dkmsBtn.text; font.bold: true; font.pixelSize: 11; color: dkmsBtn.enabled ? palette.accentFg : palette.comment
                                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle
                                {
                                    implicitHeight: 28; implicitWidth: 120; radius: 0
                                    color: !dkmsBtn.enabled ? palette.currentLine : (dkmsArea.pressed ? Qt.darker(palette.accent, 1.2) : (dkmsArea.containsMouse ? Qt.lighter(palette.accent, 1.1) : palette.accent))
                                    MouseArea
                                    {
                                        id: dkmsArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        enabled: dkmsBtn.enabled
                                        onClicked: if (dkmsBtn.enabled) dkmsBtn.clicked()
                                    }
                                }
                                onClicked: {
                                    bridge.updateDkmsModules()
                                    dkmsModal.open()
                                }
                            }
                        }

                        // Kernel grid with empty / loading state
                        Item
                        {
                            Layout.fillWidth: true; Layout.fillHeight: true

                            ScrollView
                            {
                                id: kernelScroll
                                anchors.fill: parent
                                clip: true
                                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                                GridView
                                {
                                    id: kernelGrid
                                    width: kernelScroll.availableWidth; height: contentHeight
                                    cellWidth: width / Math.max(1, Math.floor(width / 200))
                                    cellHeight: 132
                                    model: kernelSearch.text.trim().length === 0 ? bridge.kernels
                                           : bridge.kernels.filter(function(k) { return (k.name || "").toLowerCase().indexOf(kernelSearch.text.trim().toLowerCase()) !== -1 })
                                    interactive: false

                                    delegate: Rectangle
                                    {
                                        id: kernelDelegate
                                        width: kernelGrid.cellWidth - 10; height: kernelGrid.cellHeight - 10
                                        radius: 0
                                        color: kCardHover.hovered ? palette.surfaceHi : palette.surface
                                        border.color: palette.currentLine
                                        border.width: 1

                                        HoverHandler { id: kCardHover }

                                        readonly property bool isDefault: modelData.installed && bridge.defaultKernel !== "" && (bridge.defaultKernel === modelData.version || bridge.defaultKernel.indexOf(modelData.version) !== -1 || bridge.defaultKernel.indexOf(modelData.name) !== -1)
                                        readonly property bool isRunning: modelData.installed && bridge.activeKernelVersion !== "" && (bridge.activeKernelVersion === modelData.version || bridge.activeKernelVersion.indexOf(modelData.version) !== -1 || modelData.version.indexOf(bridge.activeKernelVersion) !== -1 || (modelData.name.indexOf("manual") !== -1 && bridge.activeKernelVersion.indexOf(modelData.version) !== -1))

                                        ColumnLayout
                                        {
                                            anchors.centerIn: parent
                                            width: parent.width - 16
                                            spacing: 6

                                            Rectangle
                                            {
                                                Layout.alignment: Qt.AlignHCenter
                                                width: 38; height: 38; radius: 0
                                                color: palette.bg
                                                Image
                                                {
                                                    anchors.centerIn: parent
                                                    source: "qrc:/neko/Data/logo.png"
                                                    width: 22; height: 22; fillMode: Image.PreserveAspectFit
                                                }
                                                Rectangle
                                                {
                                                    anchors.bottom: parent.bottom; anchors.right: parent.right
                                                    width: 12; height: 12; radius: 0
                                                    color: isRunning ? palette.orange : (modelData.installed ? palette.accent : palette.comment)
                                                    border.color: palette.bg; border.width: 2
                                                }
                                            }

                                            ColumnLayout
                                            {
                                                Layout.fillWidth: true; spacing: 1
                                                Text
                                                {
                                                    text: modelData.name
                                                    color: palette.fg; font.bold: true; font.pixelSize: 11
                                                    Layout.alignment: Qt.AlignHCenter; Layout.fillWidth: true
                                                    horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                                                }
                                                Text
                                                {
                                                    text: modelData.version || ""
                                                    color: palette.comment; font.pixelSize: 9
                                                    Layout.alignment: Qt.AlignHCenter; Layout.fillWidth: true
                                                    horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                                                }
                                            }

                                            RowLayout
                                            {
                                                Layout.alignment: Qt.AlignHCenter
                                                spacing: 4

                                                // ── Installed kernel actions ──
                                                RowLayout
                                                {
                                                    spacing: 4
                                                    visible: modelData.installed

                                                    // Running indicator
                                                    Rectangle
                                                    {
                                                        implicitWidth: 54; implicitHeight: 22; radius: 0
                                                        color: palette.orange
                                                        visible: isRunning
                                                        Text
                                                        {
                                                            anchors.centerIn: parent; text: qsTr("Running"); font.bold: true; font.pixelSize: 8; color: "#ffffff"
                                                        }
                                                    }

                                                    // Default boot indicator
                                                    Rectangle
                                                    {
                                                        implicitWidth: 54; implicitHeight: 22; radius: 0
                                                        color: palette.accent
                                                        visible: isDefault
                                                        Text
                                                        {
                                                            anchors.centerIn: parent; text: qsTr("Default"); font.bold: true; font.pixelSize: 8; color: palette.accentFg
                                                        }
                                                    }

                                                    // Set Default button (only if not already default)
                                                    Button
                                                    {
                                                        id: setDefBtn
                                                        visible: modelData.installed && !isDefault
                                                        enabled: !bridge.busy
                                                        contentItem: Text
                                                        {
                                                            text: qsTr("Set Default"); font.bold: true; font.pixelSize: 8; color: palette.fg
                                                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                                        }
                                                        background: Rectangle
                                                        {
                                                            implicitWidth: 64; implicitHeight: 22; radius: 0
                                                            color: setDefBtn.hovered ? palette.surfaceHi : palette.bg
                                                            border.color: palette.currentLine
                                                        }
                                                        onClicked: bridge.setDefaultKernel(modelData.version)
                                                    }

                                                    // Remove button (hidden if kernel is currently running)
                                                    Button
                                                    {
                                                        id: removeBtn
                                                        visible: modelData.installed && !isRunning
                                                        enabled: !bridge.busy
                                                        contentItem: Text
                                                        {
                                                            text: "✕"
                                                            font.bold: true
                                                            font.pixelSize: 13
                                                            color: removeBtn.hovered ? palette.error : palette.comment
                                                            horizontalAlignment: Text.AlignHCenter
                                                            verticalAlignment: Text.AlignVCenter
                                                        }
                                                        background: Rectangle
                                                        {
                                                            implicitWidth: 24
                                                            implicitHeight: 22
                                                            radius: 3
                                                            color: removeBtn.hovered ? palette.surfaceHi : "transparent"
                                                        }
                                                        ToolTip
                                                        {
                                                            id: removeTip
                                                            visible: removeBtn.hovered
                                                            delay: 300
                                                            text: qsTr("Uninstall kernel")
                                                            contentItem: Text { text: removeTip.text; font.pixelSize: 11; color: palette.fg }
                                                            background: Rectangle { color: palette.popoverBg; border.color: palette.currentLine; border.width: 1; radius: 4 }
                                                        }
                                                    }
                                                }

                                                // ── Not installed: Install button ──
                                                Button
                                                {
                                                    id: installBtn
                                                    visible: !modelData.installed
                                                    enabled: !bridge.busy
                                                    contentItem: Text
                                                    {
                                                        text: qsTr("Install"); font.bold: true; font.pixelSize: 10; color: palette.accentFg
                                                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                                    }
                                                    background: Rectangle
                                                    {
                                                        implicitWidth: 90; implicitHeight: 22; radius: 0
                                                        color: installBtn.enabled ? palette.accent : palette.currentLine
                                                    }
                                                    onClicked: bridge.installKernel(modelData.name)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Shown when the grid has no items
                            ColumnLayout
                            {
                                anchors.centerIn: parent
                                spacing: 6
                                visible: kernelGrid.count === 0
                                Text
                                {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: bridge.busy ? qsTr("Loading kernels…")
                                          : (kernelSearch.text.trim().length > 0 ? qsTr("No matches") : qsTr("No kernels found"))
                                    color: palette.textSoft; font.pixelSize: 14; font.weight: Font.Medium
                                }
                                Text
                                {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: bridge.busy ? qsTr("Querying the Void repositories")
                                          : (kernelSearch.text.trim().length > 0
                                             ? qsTr("No kernel matches \u201c%1\u201d").arg(kernelSearch.text.trim())
                                             : qsTr("No kernels available"))
                                    color: palette.comment; font.pixelSize: 11
                                }
                            }
                        }
                    }

                    // Footer divider
                    Rectangle
                    {
                        Layout.fillWidth: true; Layout.topMargin: 6
                        height: 1; color: palette.currentLine
                    }

                    // Footer
                    RowLayout
                    {
                        Layout.fillWidth: true
                        ColumnLayout
                        {
                            spacing: 2
                            Text
                            {
                                text: qsTr("STATUS: %1").arg(bridge.busy ? qsTr("BUSY") : qsTr("READY"))
                                color: bridge.busy ? palette.accent : palette.comment
                                font.bold: true; font.pixelSize: 10; font.letterSpacing: 0.5
                            }
                            Text
                            {
                                text: bridge.statusMessage; color: bridge.statusIsError ? palette.pink : palette.comment
                                font.pixelSize: 11; visible: bridge.statusMessage !== ""
                            }
                        }
                        Item { Layout.fillWidth: true }
                        Text
                        {
                            text: qsTr("Neko-Kernel-Manager v1.3.0"); color: palette.comment; font.pixelSize: 10; opacity: 0.5
                        }
                    }
                }
            }
        }
    }

    // ─── Log Modal ───
    Popup
    {
        id: logModal
        x: (window.width - width) / 2; y: (window.height - height) / 2
        width: Math.min(600, window.width - 40); height: Math.min(400, window.height - 40)
        modal: true; focus: true
        background: Rectangle
        {
            color: palette.surface; radius: 0; border.color: palette.currentLine; border.width: 1
        }

        ColumnLayout
        {
            anchors.fill: parent; anchors.margins: 10; spacing: 8
            RowLayout
            {
                Layout.fillWidth: true
                Text
                {
                    text: qsTr("System Logs & Operations"); color: palette.fg; font.bold: true; font.pixelSize: 14
                }
                Item { Layout.fillWidth: true }
                Button
                {
                    text: qsTr("Clear"); onClicked: bridge.clearLogs()
                    background: Rectangle
                    {
                        implicitWidth: 60; implicitHeight: 22; radius: 0; color: palette.bg; border.color: palette.currentLine
                    }
                    contentItem: Text
                    {
                        text: parent.text; color: palette.comment; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                }
                Button
                {
                    text: qsTr("Close"); onClicked: logModal.close()
                    background: Rectangle
                    {
                        implicitWidth: 60; implicitHeight: 22; radius: 0; color: palette.accent
                    }
                    contentItem: Text
                    {
                        text: parent.text; color: palette.accentFg; font.bold: true; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                }
            }
            Rectangle
            {
                Layout.fillWidth: true; Layout.fillHeight: true; color: palette.bg; radius: 0; border.color: palette.currentLine
                ScrollView
                {
                    anchors.fill: parent; anchors.margins: 8; clip: true
                    TextArea
                    {
                        id: logArea
                        text: bridge.logs; readOnly: true; color: palette.textSoft
                        font.family: "0xProto Nerd Font Mono"; font.pixelSize: 11
                        textFormat: TextEdit.RichText
                        background: null
                        wrapMode: TextEdit.Wrap
                        cursorVisible: false
                        onTextChanged: {
                            cursorPosition = text.length
                            if (parent && parent.contentHeight) {
                                parent.contentY = parent.contentHeight
                            }
                        }
                    }
                }
            }
        }
    }

    // ─── DKMS Modal ───
    Popup
    {
        id: dkmsModal
        x: (window.width - width) / 2; y: (window.height - height) / 2
        width: Math.min(700, window.width - 40); height: Math.min(500, window.height - 40)
        modal: true; focus: true
        background: Rectangle
        {
            color: palette.surface; radius: 0; border.color: palette.currentLine; border.width: 1
        }

        ColumnLayout
        {
            anchors.fill: parent; anchors.margins: 12; spacing: 10
            RowLayout
            {
                Layout.fillWidth: true
                Text
                {
                    text: qsTr("DKMS Module Management"); color: palette.fg; font.bold: true; font.pixelSize: 14
                }
                Item { Layout.fillWidth: true }
                Button
                {
                    id: autoinstallBtn
                    text: qsTr("Autoinstall Modules"); enabled: !bridge.busy
                    opacity: enabled ? 1.0 : 0.4
                    background: Rectangle { implicitWidth: 140; implicitHeight: 24; radius: 3; color: autoinstallBtn.enabled ? palette.accent : palette.currentLine }
                    contentItem: Text { text: autoinstallBtn.text; color: autoinstallBtn.enabled ? palette.accentFg : palette.comment; font.bold: true; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    onClicked: bridge.autoinstallDkms()
                }
                Button
                {
                    id: dkmsRefreshBtn
                    text: qsTr("Refresh"); enabled: !bridge.busy
                    opacity: enabled ? 1.0 : 0.4
                    onClicked: bridge.updateDkmsModules()
                    background: Rectangle { implicitWidth: 70; implicitHeight: 24; radius: 3; color: palette.bg; border.color: palette.currentLine }
                    contentItem: Text { text: dkmsRefreshBtn.text; color: dkmsRefreshBtn.enabled ? palette.fg : palette.comment; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Button
                {
                    text: qsTr("Close"); onClicked: dkmsModal.close()
                    background: Rectangle { implicitWidth: 70; implicitHeight: 24; radius: 3; color: palette.bg; border.color: palette.currentLine }
                    contentItem: Text { text: parent.text; color: palette.fg; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
            }

            Rectangle
            {
                Layout.fillWidth: true; Layout.fillHeight: true; color: palette.bg; radius: 0; border.color: palette.currentLine
                ScrollView
                {
                    anchors.fill: parent; anchors.margins: 6; clip: true
                    ListView
                    {
                        id: dkmsListView
                        anchors.fill: parent
                        model: bridge.dkmsModules
                        spacing: 8
                        clip: true
                        delegate: Rectangle
                        {
                            width: dkmsListView.width; height: 60; color: palette.surface; border.color: palette.currentLine; border.width: 1
                            RowLayout
                            {
                                anchors.fill: parent; anchors.margins: 10
                                spacing: 12
                                ColumnLayout
                                {
                                    spacing: 2
                                    Text
                                    {
                                        text: modelData.name + " (" + modelData.version + ")"; color: palette.fg; font.bold: true; font.pixelSize: 12
                                    }
                                    Text
                                    {
                                        text: modelData.isDkmsPackage 
                                              ? (modelData.packageInstalled ? qsTr("XBPS Package: Installed (Unregistered in DKMS)") : qsTr("XBPS Package: Available in Repo"))
                                              : qsTr("Kernel: %1 | Arch: %2").arg(modelData.kernel).arg(modelData.arch)
                                        color: palette.comment; font.pixelSize: 10
                                    }
                                }
                                Item { Layout.fillWidth: true }
                                Rectangle
                                {
                                    implicitWidth: 90; implicitHeight: 20
                                    color: modelData.status === "installed" ? "#223322" : (modelData.status === "unregistered" ? "#222233" : "#332222")
                                    border.color: modelData.status === "installed" ? palette.accent : (modelData.status === "unregistered" ? palette.cyan : palette.pink); border.width: 1
                                    Text
                                    {
                                        anchors.centerIn: parent; text: modelData.status
                                        color: modelData.status === "installed" ? palette.accent : (modelData.status === "unregistered" ? palette.cyan : palette.pink)
                                        font.pixelSize: 9; font.bold: true
                                    }
                                }
                                Button
                                {
                                    id: moduleActionBtn
                                    enabled: !bridge.busy
                                    opacity: enabled ? 1.0 : 0.4
                                    text: (modelData.status === "installed" || modelData.status === "unregistered") ? qsTr("Remove") : qsTr("Install")
                                    background: Rectangle 
                                    { 
                                        implicitWidth: 80; implicitHeight: 24; radius: 3
                                        color: !moduleActionBtn.enabled ? palette.currentLine :
                                               ((modelData.status === "installed" || modelData.status === "unregistered") ? 
                                                (moduleActionBtn.hovered ? Qt.lighter(palette.error, 1.1) : palette.error) : 
                                                (moduleActionBtn.hovered ? Qt.lighter(palette.accent, 1.1) : palette.accent)) 
                                    }
                                    contentItem: Text 
                                    { 
                                        text: moduleActionBtn.text; color: moduleActionBtn.enabled ? palette.accentFg : palette.comment; font.bold: true; font.pixelSize: 10
                                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter 
                                    }
                                    onClicked: {
                                        if (moduleActionBtn.enabled) {
                                            if (modelData.status === "installed" || modelData.status === "unregistered") {
                                                bridge.removeDkmsModule(modelData.name, modelData.version, modelData.kernel)
                                            } else {
                                                bridge.installDkmsModule(modelData.name, modelData.version, modelData.kernel)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        bridge.updateKernels()
        bridge.updateDkmsModules()
        bridge.updateDefaultKernel()
    }
}
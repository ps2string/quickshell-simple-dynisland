import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: root

    // Fonts
    readonly property string fontText: "SF Pro Text, SF Pro Display, SF Pro, sans-serif"
    readonly property string fontIcon: "JetBrainsMono Nerd Font, JetBrainsMono NF, monospace"

    // Color Palette & Matugen Integration
    property color colorBg: "#0c0c0e"
    property color colorFg: "#ffffff"
    property color colorMuted: "#8e8e93"
    property color colorPrimary: "#007aff"
    property color colorBorder: "#222228"

    FileView {
        id: matugenFile
        path: (Quickshell.env("HOME") || "") + "/.cache/matugen/colors.json"
        watchChanges: true
        onFileChanged: parseColors()
        onTextChanged: parseColors()
        Component.onCompleted: parseColors()

        function parseColors() {
            // FIXED: Using text property instead of text() method call
            let raw = matugenFile.text || ""; 
            if (!raw) return;
            try {
                let json = JSON.parse(raw);
                let c = json.colors || json;
                if (c) {
                    if (c.surface_container) root.colorBg = c.surface_container;
                    else if (c.surface) root.colorBg = c.surface;

                    if (c.on_surface) root.colorFg = c.on_surface;
                    if (c.on_surface_variant) root.colorMuted = c.on_surface_variant;
                    if (c.primary) root.colorPrimary = c.primary;
                    if (c.outline_variant) root.colorBorder = c.outline_variant;
                    else if (c.outline) root.colorBorder = c.outline;
                }
            } catch(e) {}
        }
    }

    // FIXED: Changed list to var so JavaScript array prototypes (like .find) work
    readonly property var playerList: Mpris.players.values
    readonly property MprisPlayer activePlayer: {
        if (!playerList || playerList.length === 0) return null;
        let playing = playerList.find(p => p && (p.isPlaying || p.playbackState === MprisPlaybackState.Playing));
        return playing !== undefined ? playing : playerList[0];
    }

    readonly property bool isPlaying: activePlayer !== null && activePlayer.playbackState === MprisPlaybackState.Playing
    readonly property string currentTrack: activePlayer ? (activePlayer.trackTitle || "") : ""
    readonly property string currentArtist: activePlayer ? (activePlayer.trackArtist || "") : ""

    // Persistent Album Artwork Latching (Firefox/Floorp Fix)
    property string currentArtUrl: ""
    property string lastTrackTitle: ""

    Timer {
        id: artFetchTimer
        interval: 1000 
        repeat: false
        onTriggered: {
            if (root.activePlayer) {
                let raw = root.activePlayer.trackArtUrl || "";
                if (raw !== "") {
                    root.currentArtUrl = root.formatArtUrl(raw);
                } else {
                    root.currentArtUrl = "";
                }
            } else {
                root.currentArtUrl = "";
            }
        }
    }

    Connections {
        target: root.activePlayer
        ignoreUnknownSignals: true
        function onTrackArtUrlChanged() { root.syncArtwork(); }
        function onPostTrackChanged() { root.syncArtwork(); }
        function onTrackChanged() { root.syncArtwork(); }
    }

    onActivePlayerChanged: syncArtwork()

    function syncArtwork() {
        if (!activePlayer) {
            currentArtUrl = "";
            lastTrackTitle = "";
            return;
        }

        let raw = activePlayer.trackArtUrl || "";
        let currentTitle = activePlayer.trackTitle || "";

        // FIXED: Lock the artwork if the track hasn't changed to stop browser wipes
        if (currentTitle !== lastTrackTitle) {
            lastTrackTitle = currentTitle;
            if (raw !== "") {
                artFetchTimer.stop();
                currentArtUrl = formatArtUrl(raw);
            } else {
                artFetchTimer.restart(); // Wait for late metadata
            }
        } else if (currentArtUrl === "" && raw !== "") {
            // Accept late metadata if we don't have art yet
            artFetchTimer.stop();
            currentArtUrl = formatArtUrl(raw);
        }
    }

    function formatArtUrl(url) {
        if (!url || url === "") return "";
        if (url.startsWith("http://") || url.startsWith("https://") || url.startsWith("file://")) return url;
        if (url.startsWith("/")) return "file://" + encodeURI(url);
        return url;
    }

    // Hover Hysteresis & Expansion Logic
    readonly property bool isHovered: hoverArea.containsMouse || collapseTimer.running
    readonly property bool autoExpanded: autoShowTimer.running
    readonly property bool expanded: isHovered || autoExpanded

    Timer {
        id: collapseTimer
        interval: 400 
        repeat: false
    }

    Timer {
        id: autoShowTimer
        interval: 3500
        repeat: false
    }

    onCurrentTrackChanged: {
        if (isPlaying && currentTrack !== "") autoShowTimer.restart();
    }

    onIsPlayingChanged: {
        if (isPlaying) autoShowTimer.restart();
    }

    // Live Progress Position Updater (Required by MPRIS specifications)
    Timer {
        // Quickshell's Mpris length and position natively report in seconds
        interval: 1000
        running: root.isPlaying && root.expanded
        repeat: true
        onTriggered: {
            if (root.activePlayer) root.activePlayer.positionChanged();
        }
    }

    // Dynamic Island Geometry
    width: !isPlaying ? 0 : (expanded ? 380 : 210)
    height: !isPlaying ? 0 : (expanded ? 108 : 36)
    opacity: isPlaying ? 1.0 : 0.0

    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 0.5 } } 
    Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

    Rectangle {
        id: bg
        anchors.fill: parent
        color: Qt.alpha(root.colorBg, 0.95)
        radius: root.expanded ? 24 : height / 2
        border.color: root.isHovered ? root.colorPrimary : root.colorBorder
        border.width: 1
        clip: true

        Behavior on radius { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 180 } }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true

            onEntered: collapseTimer.stop()
            onExited: collapseTimer.start()
            
            // Clicking the collapsed pill toggles play/pause quickly
            onClicked: {
                if (!root.expanded && root.activePlayer && root.activePlayer.canTogglePlaying) {
                    root.activePlayer.togglePlaying();
                }
            }
        }

        // 1. COLLAPSED CONTENT (MINI PILL)
        Item {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 12
            opacity: root.expanded ? 0.0 : 1.0
            visible: opacity > 0.01

            Behavior on opacity { NumberAnimation { duration: 150 } }

            Rectangle {
                id: collapsedArtFrame
                width: 22
                height: 22
                radius: 11
                color: Qt.alpha(root.colorMuted, 0.2)
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                clip: true

                Text {
                    anchors.centerIn: parent
                    text: "󰎈"
                    font.family: root.fontIcon
                    font.pixelSize: 11
                    color: root.colorPrimary
                }

                Image {
                    anchors.fill: parent
                    source: root.currentArtUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    opacity: status === Image.Ready ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }
            }

            Text {
                anchors.left: collapsedArtFrame.right
                anchors.right: collapsedStatusIcon.left
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter

                text: root.currentTrack !== "" ? root.currentTrack : "Not Playing"
                font.family: root.fontText
                font.pixelSize: 13
                font.bold: true
                color: root.colorFg
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                id: collapsedStatusIcon
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                text: "󰎆"
                font.family: root.fontIcon
                font.pixelSize: 14
                color: root.colorPrimary
                opacity: root.isPlaying ? 1.0 : 0.4

                Behavior on opacity { NumberAnimation { duration: 250 } }
            }
        }

        // 2. EXPANDED CONTENT (FULL PLAYER)
        Item {
            anchors.fill: parent
            anchors.margins: 14
            opacity: root.expanded ? 1.0 : 0.0
            visible: opacity > 0.01
            enabled: root.expanded

            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }

            // Album Artwork (Left)
            Rectangle {
                id: expandedArtFrame
                width: 78
                height: 78
                radius: 12
                color: Qt.alpha(root.colorMuted, 0.2)
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                clip: true

                Text {
                    anchors.centerIn: parent
                    text: "󰎈"
                    font.family: root.fontIcon
                    font.pixelSize: 32
                    color: root.colorPrimary
                    opacity: 0.4
                }

                Image {
                    anchors.fill: parent
                    source: root.currentArtUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    opacity: status === Image.Ready ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }
            }

            // Track Info (Middle)
            Column {
                anchors.left: expandedArtFrame.right
                anchors.right: controlsRow.left
                anchors.leftMargin: 16
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Text {
                    width: parent.width
                    text: root.currentTrack !== "" ? root.currentTrack : "No Title"
                    font.family: root.fontText
                    font.pixelSize: 15
                    font.bold: true
                    color: root.colorFg
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.currentArtist !== "" ? root.currentArtist : "Unknown Artist"
                    font.family: root.fontText
                    font.pixelSize: 13
                    color: root.colorMuted
                    elide: Text.ElideRight
                }

                // Progress Bar
                Item {
                    width: parent.width
                    height: 16
                    anchors.topMargin: 4

                    Rectangle {
                        id: progressBg
                        width: parent.width
                        height: 4
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 2
                        color: Qt.alpha(root.colorMuted, 0.3)
                        clip: true

                        Rectangle {
                            id: progressFill
                            height: parent.height
                            color: root.colorPrimary
                            radius: 2
                            width: {
                                if (!root.activePlayer || !root.activePlayer.length || root.activePlayer.length <= 0) return 0;
                                return Math.min(parent.width, parent.width * (root.activePlayer.position / root.activePlayer.length));
                            }
                            Behavior on width { NumberAnimation { duration: 1000; easing.type: Easing.Linear } }
                        }
                    }

                    // Elapsed Time
                    Text {
                        anchors.left: parent.left
                        anchors.top: progressBg.bottom
                        anchors.topMargin: 4
                        text: root.formatTime(root.activePlayer ? root.activePlayer.position : 0)
                        font.family: root.fontIcon
                        font.pixelSize: 10
                        color: root.colorMuted
                    }

                    // FIXED: Remaining Time Countdown
                    Text {
                        anchors.right: parent.right
                        anchors.top: progressBg.bottom
                        anchors.topMargin: 4
                        text: {
                            if (!root.activePlayer || root.activePlayer.length <= 0) return "--:--";
                            let timeLeft = root.activePlayer.length - root.activePlayer.position;
                            return "-" + root.formatTime(Math.max(0, timeLeft));
                        }
                        font.family: root.fontIcon
                        font.pixelSize: 10
                        color: root.colorMuted
                    }
                }
            }

            // Controls (Right)
            Row {
                id: controlsRow
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                // Previous
                Text {
                    text: "󰒮"
                    font.family: root.fontIcon
                    font.pixelSize: 22
                    color: prevMouse.containsMouse ? root.colorPrimary : root.colorFg
                    Behavior on color { ColorAnimation { duration: 120 } }
                    opacity: root.activePlayer && root.activePlayer.canGoPrevious ? 1.0 : 0.4

                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.activePlayer && root.activePlayer.canGoPrevious
                        onClicked: if (root.activePlayer) root.activePlayer.previous()
                    }
                }

                // Play/Pause
                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: playMouse.containsMouse ? Qt.alpha(root.colorFg, 0.15) : Qt.alpha(root.colorMuted, 0.15)
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: root.isPlaying ? "󰏤" : "󰐊"
                        font.family: root.fontIcon
                        font.pixelSize: 20
                        color: root.colorFg
                        anchors.horizontalCenterOffset: root.isPlaying ? 0 : 2
                    }

                    MouseArea {
                        id: playMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.activePlayer && root.activePlayer.canTogglePlaying
                        onClicked: if (root.activePlayer) root.activePlayer.togglePlaying()
                    }
                }

                // Next
                Text {
                    text: "󰒭"
                    font.family: root.fontIcon
                    font.pixelSize: 22
                    color: nextMouse.containsMouse ? root.colorPrimary : root.colorFg
                    Behavior on color { ColorAnimation { duration: 120 } }
                    opacity: root.activePlayer && root.activePlayer.canGoNext ? 1.0 : 0.4

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.activePlayer && root.activePlayer.canGoNext
                        onClicked: if (root.activePlayer) root.activePlayer.next()
                    }
                }
            }
        }
    }

    function formatTime(seconds) {
        if (!seconds || seconds <= 0) return "0:00";
        const mins = Math.floor(seconds / 60);
        const secs = Math.floor(seconds % 60);
        return `${mins}:${secs < 10 ? "0" : ""}${secs}`;
    }
}

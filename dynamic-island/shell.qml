import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: window
                required property var modelData
                screen: modelData

                anchors {
                    top: true
                }

                WlrLayershell.layer: WlrLayer.Top
                exclusionMode: ExclusionMode.Ignore
                color: "transparent"
                width: 420
                height: 130

                mask: Region {
                    item: island
                }

                DynamicIsland {
                    id: island
                    anchors.top: parent.top
                    anchors.topMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}

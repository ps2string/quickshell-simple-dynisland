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

                // FIXED: Top layer avoids overlaying fullscreen applications.
                WlrLayershell.layer: WlrLayer.Top
                
                // FIXED: Prevents window from stealing desktop space from maximized apps.
                exclusionMode: ExclusionMode.Ignore

                color: "transparent"
                
                // FIXED: Explicit dimensions required by Wayland layer shell masking.
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

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

/**
 * @brief 链接（link）渲染组件
 *
 * 递归渲染子节点（text、strong、emphasis 等），并叠加鼠标交互区域，
 * 支持点击跳转与手型光标。
 */
Item {
    id: root

    required property var astNode
    required property var astStyle

    width: rowContent.width
    height: rowContent.height

    Row {
        id: rowContent
        spacing: 0

        MarkRowNodeComponent {
            astNode: root.astNode
            astStyle: root.astStyle
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: rowContent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        ToolTip {
            visible: mouseArea.containsMouse
            text: root.astNode.url
            delay: 500
            timeout: 5000
        }

        onClicked: {
            Qt.openUrlExternally(root.astNode.url)
        }
    }
}

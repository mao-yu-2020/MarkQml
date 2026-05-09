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

    property var astNode: null
    readonly property var astStyle: renderMark ? renderMark.style : null
    readonly property var cache: renderMark ? renderMark.compCache : null
    property var renderMark: null

    function init(node, rm) {
        astNode = node;
        renderMark = rm;
    }

    width: rowContent.width
    height: rowContent.height

    Row {
        id: rowContent
        spacing: 0

        MarkRowNodeComponent {
            astNode: root.astNode
            renderMark: root.renderMark
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: rowContent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        ToolTip {
            visible: mouseArea.containsMouse
            Binding on text {
                value: root.astNode ? root.astNode.url : ""
                when: root.astNode !== null
            }
            delay: 500
            timeout: 5000
        }

        onClicked: {
            if (root.astNode && root.astNode.url) {
                Qt.openUrlExternally(root.astNode.url);
            }
        }
    }
}

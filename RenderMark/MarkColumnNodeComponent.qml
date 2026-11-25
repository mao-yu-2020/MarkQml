pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 垂直容器，用于块级节点（document、list、item content 等）
 */
Column {
    id: root

    property var astNode: null
    readonly property var astStyle: renderMark ? renderMark.style : null
    readonly property var cache: renderMark ? renderMark.compCache : null
    property var renderMark: null

    function init(node, rm) {
        astNode = node;
        renderMark = rm;
    }

    width: parent ? parent.width : implicitWidth

    Repeater {
        model: root.astNode ? root.astNode.children : []

        MarkNodeComponent {
            required property var modelData
            width: root.width
            astNode: modelData
            renderMark: root.renderMark
        }
    }
}

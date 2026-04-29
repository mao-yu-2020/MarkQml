pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 垂直容器，用于块级节点（document、list、item content 等）
 */
Column {
    id: root

    property var astNode: null
    property var astStyle: null
    property var cache: null

    function init(node, style) {
        astNode = node;
        astStyle = style;
    }

    Repeater {
        model: root.astNode ? root.astNode.children : []

        MarkNodeComponent {
            required property var modelData
            astNode: modelData
            astStyle: root.astStyle
            cache: root.cache
        }
    }
}

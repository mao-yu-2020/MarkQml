pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 水平容器，用于行内节点（paragraph、heading 等）
 */
Row {
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

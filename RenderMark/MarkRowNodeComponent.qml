pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 水平容器，用于行内节点（paragraph、heading 等）
 */
Row {
    id: root

    property var astNode: null
    readonly property var astStyle: renderMark ? renderMark.style : null
    readonly property var cache: renderMark ? renderMark.compCache : null
    property var renderMark: null

    function init(node, rm) {
        astNode = node;
        renderMark = rm;
    }

    Repeater {
        model: root.astNode ? root.astNode.children : []

        MarkNodeComponent {
            required property var modelData
            astNode: modelData
            renderMark: root.renderMark
        }
    }
}

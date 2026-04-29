pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 斜体（emphasis）渲染组件
 *
 * 通过 MarkRowNodeComponent 递归渲染所有子节点，
 * 内部文本由 MarkNodeText.qml 检测祖先节点自动斜体。
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

    spacing: 0

    MarkRowNodeComponent {
        astNode: root.astNode
        astStyle: root.astStyle
        cache: root.cache
    }
}

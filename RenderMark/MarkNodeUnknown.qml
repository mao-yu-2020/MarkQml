pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 未知节点（unknown）渲染组件
 *
 * 直接显示原始文本内容。
 */
Text {
    id: root

    property var astNode: null
    property var renderMark: null
    readonly property var astStyle: renderMark ? renderMark.style : null

    function init(node, rm) {
        astNode = node;
        renderMark = rm;
    }

    Binding on text {
        value: root.astNode ? root.astNode.content : ""
        when: root.astNode !== null
    }

    Binding on color {
        value: root.astStyle.unknownStyle.color
        when: root.astStyle !== null
    }

    Binding on font.pixelSize {
        value: root.astStyle.unknownStyle.fontSize
        when: root.astStyle !== null
    }
}

pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 脚注引用（footnote_reference）渲染组件
 *
 * 以上标形式显示引用标记。
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
        value: root.astNode ? "[" + root.astNode.content + "]" : ""
        when: root.astNode !== null
    }

    Binding on color {
        value: root.astStyle.footnoteReferenceStyle.color
        when: root.astStyle !== null
    }

    Binding on font.pixelSize {
        value: root.astStyle.footnoteReferenceStyle.fontSize * 0.75
        when: root.astStyle !== null
    }
}

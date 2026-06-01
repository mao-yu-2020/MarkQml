pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 脚注定义（footnote_definition）渲染组件
 *
 * 带标签前缀的块级容器，内部垂直排列子节点。
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

    spacing: 4

    Text {
        Binding on text {
            value: root.astNode ? "[" + root.astNode.content + "]:" : ""
            when: root.astNode !== null
        }
        Binding on color {
            value: root.astStyle.footnoteDefinitionStyle.color
            when: root.astStyle !== null
        }
        Binding on font.pixelSize {
            value: root.astStyle.footnoteDefinitionStyle.fontSize * 0.85
            when: root.astStyle !== null
        }
        anchors.top: parent.top
    }

    MarkColumnNodeComponent {
        astNode: root.astNode
        renderMark: root.renderMark
    }
}

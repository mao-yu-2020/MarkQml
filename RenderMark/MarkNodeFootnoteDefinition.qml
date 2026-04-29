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
    property var astStyle: null
    property var cache: null

    function init(node, style) {
        astNode = node;
        astStyle = style;
    }

    spacing: 4

    Text {
        text: ""
        Binding on text {
            value: root.astNode ? "[" + root.astNode.content + "]:" : ""
            when: root.astNode !== null
        }
        color: "black"
        Binding on color {
            value: root.astStyle.linkColor
            when: root.astStyle !== null
        }
        font.pixelSize: 12
        Binding on font.pixelSize {
            value: root.astStyle.baseFontSize * 0.85
            when: root.astStyle !== null
        }
        anchors.top: parent.top
    }

    MarkColumnNodeComponent {
        astNode: root.astNode
        astStyle: root.astStyle
        cache: root.cache
    }
}

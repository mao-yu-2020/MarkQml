pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 脚注定义（footnote_definition）渲染组件
 *
 * 带标签前缀的块级容器，内部垂直排列子节点。
 */
Row {
    id: root

    required property var astNode
    required property var astStyle

    spacing: 4

    Text {
        text: "[" + root.astNode.content + "]:"
        color: root.astStyle.linkColor
        font.pixelSize: root.astStyle.baseFontSize * 0.85
        anchors.top: parent.top
    }

    MarkColumnNodeComponent {
        astNode: root.astNode
        astStyle: root.astStyle
    }
}

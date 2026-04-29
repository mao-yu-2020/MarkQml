pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 引用块（block_quote）渲染组件
 *
 * 左侧带竖线标识，背景使用 codeBackground，内部垂直排列子节点。
 */
Rectangle {
    id: root

    property var astNode: null
    property var astStyle: null
    property var cache: null

    function init(node, style) {
        astNode = node;
        astStyle = style;
    }

    color: "transparent"
    Binding on color {
        value: root.astStyle.codeBackground
        when: root.astStyle !== null
    }

    width: leftBar.width + contentColumn.implicitWidth + 12
    height: contentColumn.implicitHeight
    radius: 4

    // 左侧竖线
    Rectangle {
        id: leftBar
        width: 4
        height: root.height
        color: "#bdc3c7"
        Binding on color {
            value: root.astStyle.blockQuoteBorder
            when: root.astStyle !== null
        }
        radius: 2
    }

    // 内容区域
    MarkColumnNodeComponent {
        id: contentColumn
        anchors.left: leftBar.right
        anchors.top: parent.top
        anchors.leftMargin: 12
        astNode: root.astNode
        astStyle: root.astStyle
        cache: root.cache
    }
}

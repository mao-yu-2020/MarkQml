pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 引用块（block_quote）渲染组件
 *
 * 左侧带竖线标识，背景使用 blockQuoteStyle.background，内部垂直排列子节点。
 */
Rectangle {
    id: root

    property var astNode: null
    readonly property var astStyle: renderMark ? renderMark.style : null
    readonly property var cache: renderMark ? renderMark.compCache : null
    property var renderMark: null

    function init(node, rm) {
        astNode = node;
        renderMark = rm;
    }

    Binding on color {
        value: root.astStyle.blockQuoteStyle.background
        when: root.astStyle !== null
    }
    Binding on radius {
        value: root.astStyle ? root.astStyle.blockQuoteStyle.radius : 4
        when: root.astStyle !== null
    }

    width: leftBar.width + contentColumn.implicitWidth + root.astStyle.blockQuoteStyle.leftPadding
    height: contentColumn.implicitHeight

    // 左侧竖线
    Rectangle {
        id: leftBar
        width: root.astStyle.blockQuoteStyle.borderWidth
        height: root.height
        Binding on color {
            value: root.astStyle.blockQuoteStyle.borderColor
            when: root.astStyle !== null
        }
        radius: 2
    }

    // 内容区域
    MarkColumnNodeComponent {
        id: contentColumn
        anchors.left: leftBar.right
        anchors.top: parent.top
        anchors.leftMargin: root.astStyle.blockQuoteStyle.leftPadding
        astNode: root.astNode
        renderMark: root.renderMark
    }
}

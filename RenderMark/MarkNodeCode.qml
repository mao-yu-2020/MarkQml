pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 行内代码（code）渲染组件
 *
 * 等宽字体、带背景色圆角矩形，用于渲染 `inline code` 节点。
 */
Rectangle {
    id: root

    property var astNode: null
    property var renderMark: null
    readonly property var astStyle: renderMark ? renderMark.style : null

    function init(node, rm) {
        astNode = node;
        renderMark = rm;
    }

    Binding on color {
        value: root.astStyle.codeStyle.background
        when: root.astStyle !== null
    }
    Binding on radius {
        value: root.astStyle ? root.astStyle.codeStyle.radius : 3
        when: root.astStyle !== null
    }

    Binding on implicitWidth {
        value: textItem.implicitWidth + root.astStyle.codeStyle.hPadding * 2
        when: root.astStyle !== null
    }
    Binding on implicitHeight {
        value: textItem.implicitHeight + root.astStyle.codeStyle.vPadding * 2
        when: root.astStyle !== null
    }

    Text {
        id: textItem
        anchors.centerIn: parent
        Binding on text {
            value: root.astNode ? root.astNode.content : ""
            when: root.astNode !== null
        }
        Binding on color {
            value: root.astStyle.codeStyle.color
            when: root.astStyle !== null
        }
        Binding on font.pixelSize {
            value: root.astStyle.codeStyle.fontSize
            when: root.astStyle !== null
        }
        font.family: "Consolas, Courier New, monospace"
    }
}

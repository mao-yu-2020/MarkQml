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
    property var astStyle: null

    function init(node, style) {
        astNode = node;
        astStyle = style;
    }

    color: "#eaf2f8"
    Binding on color {
        value: root.astStyle.codeBackground
        when: root.astStyle !== null
    }
    radius: 3

    implicitWidth: textItem.implicitWidth + 12
    implicitHeight: textItem.implicitHeight + 6

    Text {
        id: textItem
        anchors.centerIn: parent
        text: ""
        Binding on text {
            value: root.astNode ? root.astNode.content : ""
            when: root.astNode !== null
        }
        color: "black"
        Binding on color {
            value: root.astStyle.textColor
            when: root.astStyle !== null
        }
        font.pixelSize: 14
        Binding on font.pixelSize {
            value: root.astStyle.baseFontSize
            when: root.astStyle !== null
        }
        font.family: "Consolas, Courier New, monospace"
    }
}

pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 行内代码（code）渲染组件
 *
 * 等宽字体、带背景色圆角矩形，用于渲染 `inline code` 节点。
 */
Rectangle {
    id: root

    required property var astNode
    required property var astStyle

    color: root.astStyle.codeBackground
    radius: 3

    implicitWidth: textItem.implicitWidth + 12
    implicitHeight: textItem.implicitHeight + 6

    Text {
        id: textItem
        anchors.centerIn: parent
        text: root.astNode.content
        color: root.astStyle.textColor
        font.pixelSize: root.astStyle.baseFontSize
        font.family: "Consolas, Courier New, monospace"
    }
}

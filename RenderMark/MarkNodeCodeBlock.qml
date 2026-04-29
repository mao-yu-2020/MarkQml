pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 代码块（code_block）渲染组件
 *
 * 带背景色的块级代码区域，支持显示语言标识。
 */
Rectangle {
    id: root

    required property var astNode
    required property var astStyle

    color: root.astStyle.codeBackground
    radius: 4

    width: childrenRect.width
    height: childrenRect.height


    // 垂直布局：语言标签 + 代码内容
    Column {
        id: contentColumn
        anchors.margins: 12
        spacing: 4

        Text {
            visible: root.astNode.language !== ""
            text: root.astNode.language
            color: root.astStyle.textColor
            font.pixelSize: root.astStyle.baseFontSize * 0.85
            opacity: 0.7
        }

        Text {
            text: root.astNode.content
            color: root.astStyle.textColor
            font.pixelSize: root.astStyle.baseFontSize
            font.family: "Consolas, Courier New, monospace"
            wrapMode: Text.Wrap
        }
    }
}

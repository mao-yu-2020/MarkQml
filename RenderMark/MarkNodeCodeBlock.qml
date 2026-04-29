pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 代码块（code_block）渲染组件
 *
 * 带背景色的块级代码区域，支持显示语言标识。
 */
Rectangle {
    id: root

    property var astNode: null
    property var astStyle: null

    function init(node, style) {
        astNode = node;
        astStyle = style;
    }

    Binding on color {
        value: root.astStyle.codeBackground
        when: root.astStyle !== null
    }
    radius: 4

    width: childrenRect.width
    height: childrenRect.height

    // 垂直布局：语言标签 + 代码内容
    Column {
        id: contentColumn
        anchors.margins: 12
        spacing: 4

        Text {
            visible: root.astNode ? root.astNode.language !== "" : false
            Binding on text {
                value: root.astNode ? root.astNode.language : ""
                when: root.astNode !== null
            }
            Binding on color {
                value: root.astStyle.textColor
                when: root.astStyle !== null
            }
            Binding on font.pixelSize {
                value: root.astStyle.baseFontSize * 0.85
                when: root.astStyle !== null
            }
            opacity: 0.7
        }

        Text {
            Binding on text {
                value: root.astNode ? root.astNode.content : ""
                when: root.astNode !== null
            }
            Binding on color {
                value: root.astStyle.textColor
                when: root.astStyle !== null
            }
            Binding on font.pixelSize {
                value: root.astStyle.baseFontSize
                when: root.astStyle !== null
            }
            font.family: "Consolas, Courier New, monospace"
            wrapMode: Text.Wrap
        }
    }
}

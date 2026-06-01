pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 代码块（code_block）渲染组件
 *
 * 带背景色的块级代码区域，支持显示语言标识。
 * 四周保留 padding 内边距，语言标签以 pill 样式呈现。
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
        value: root.astStyle.codeBlockStyle.background
        when: root.astStyle !== null
    }
    Binding on radius {
        value: root.astStyle ? root.astStyle.codeBlockStyle.radius : 4
        when: root.astStyle !== null
    }

    Binding on width {
        value: contentColumn.implicitWidth + root.astStyle.codeBlockStyle.padding * 2
        when: root.astStyle !== null
    }
    Binding on height {
        value: contentColumn.implicitHeight + root.astStyle.codeBlockStyle.padding * 2
        when: root.astStyle !== null
    }

    Column {
        id: contentColumn
        x: root.astStyle ? root.astStyle.codeBlockStyle.padding : 12
        y: root.astStyle ? root.astStyle.codeBlockStyle.padding : 12
        spacing: 8

        // 语言标签 pill
        Rectangle {
            visible: root.astNode ? root.astNode.language !== "" : false
            width: langLabel.implicitWidth + 16
            height: langLabel.implicitHeight + 8
            radius: 4

            Binding on color {
                value: root.astStyle.codeBlockStyle.langLabelBackground
                when: root.astStyle !== null
            }

            Text {
                id: langLabel
                anchors.centerIn: parent
                Binding on text {
                    value: root.astNode ? root.astNode.language : ""
                    when: root.astNode !== null
                }
                Binding on color {
                    value: root.astStyle.codeBlockStyle.langLabelColor
                    when: root.astStyle !== null
                }
                Binding on font.pixelSize {
                    value: root.astStyle.codeBlockStyle.fontSize * 0.8
                    when: root.astStyle !== null
                }
                font.family: "Consolas, Courier New, monospace"
            }
        }

        Text {
            Binding on text {
                value: root.astNode ? root.astNode.content : ""
                when: root.astNode !== null
            }
            Binding on color {
                value: root.astStyle.codeBlockStyle.color
                when: root.astStyle !== null
            }
            Binding on font.pixelSize {
                value: root.astStyle.codeBlockStyle.fontSize
                when: root.astStyle !== null
            }
            font.family: "Consolas, Courier New, monospace"
            wrapMode: Text.Wrap
        }
    }
}

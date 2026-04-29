pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 行内 HTML（html_inline）渲染组件
 *
 * 直接显示原始文本内容。
 */
Text {
    id: root

    property var astNode: null
    property var astStyle: null

    function init(node, style) {
        astNode = node;
        astStyle = style;
    }

    text: ""
    Binding on text {
        value: root.astNode ? root.astNode.content : ""
        when: root.astNode !== null
    }

    textFormat: Text.StyledText

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
}

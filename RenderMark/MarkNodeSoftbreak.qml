pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 软换行（softbreak）渲染组件
 *
 * 渲染为一个空格，保持行内文本连续性。
 */
Text {
    id: root

    property var astNode: null
    property var astStyle: null

    function init(node, style) {
        astNode = node;
        astStyle = style;
    }

    text: " "

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

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
    property var renderMark: null
    readonly property var astStyle: renderMark ? renderMark.style : null

    function init(node, rm) {
        astNode = node;
        renderMark = rm;
    }

    text: " "

    Binding on color {
        value: root.astStyle.textStyle.color
        when: root.astStyle !== null
    }

    Binding on font.pixelSize {
        value: root.astStyle.textStyle.fontSize
        when: root.astStyle !== null
    }
}

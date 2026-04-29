pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 软换行（softbreak）渲染组件
 *
 * 渲染为一个空格，保持行内文本连续性。
 */
Text {
    id: root

    required property var astNode
    required property var astStyle

    text: " "
    color: astStyle.textColor
    font.pixelSize: astStyle.baseFontSize
}

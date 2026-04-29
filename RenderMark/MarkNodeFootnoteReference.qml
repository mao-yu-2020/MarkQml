pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 脚注引用（footnote_reference）渲染组件
 *
 * 以上标形式显示引用标记。
 */
Text {
    id: root

    required property var astNode
    required property var astStyle

    text: "[" + astNode.content + "]"
    color: astStyle.linkColor
    font.pixelSize: astStyle.baseFontSize * 0.75
}

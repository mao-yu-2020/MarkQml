pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 未知节点（unknown）渲染组件
 *
 * 直接显示原始文本内容。
 */
Text {
    id: root

    required property var astNode
    required property var astStyle

    text: astNode.content
    color: astStyle.textColor
    font.pixelSize: astStyle.baseFontSize
}

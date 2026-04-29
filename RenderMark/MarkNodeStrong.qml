pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 粗体（strong）渲染组件
 *
 * 通过 MarkRowNodeComponent 递归渲染所有子节点，
 * 内部文本由 MarkNodeText.qml 检测祖先节点自动加粗。
 */
Row {
    id: root

    required property var astNode
    required property var astStyle

    spacing: 0

    MarkRowNodeComponent {
        astNode: root.astNode
        astStyle: root.astStyle
    }
}

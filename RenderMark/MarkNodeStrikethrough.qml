pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 删除线（strikethrough）渲染组件
 *
 * 通过 MarkRowNodeComponent 递归渲染所有子节点，
 * 内部文本由 MarkNodeText.qml 检测祖先节点自动添加删除线。
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

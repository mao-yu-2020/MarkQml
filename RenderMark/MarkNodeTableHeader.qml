pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 表头行（table_header）渲染组件
 *
 * 通过 Row 水平排列子单元格。
 */
Row {
    id: root

    required property var astNode
    required property var astStyle

    spacing: 0

    Repeater {
        model: root.astNode.children
        MarkNodeComponent {
            required property var modelData
            astNode: modelData
            astStyle: root.astStyle
        }
    }
}

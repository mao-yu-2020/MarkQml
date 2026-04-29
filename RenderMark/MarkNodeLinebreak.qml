pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 硬换行（linebreak）渲染组件
 *
 * 行内换行占位符，当前在 Row 布局中暂以零尺寸占位。
 */
Item {
    id: root

    required property var astNode
    required property var astStyle

    width: 0
    height: 0
}

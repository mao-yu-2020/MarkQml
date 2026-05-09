pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 硬换行（linebreak）渲染组件
 *
 * 行内换行占位符，当前在 Row 布局中暂以零尺寸占位。
 */
Item {
    id: root

    property var astNode: null
    property var renderMark: null
    readonly property var astStyle: renderMark ? renderMark.style : null

    function init(node, rm) {
        astNode = node;
        renderMark = rm;
    }

    width: 0
    height: 0
}

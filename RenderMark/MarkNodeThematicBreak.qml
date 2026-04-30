pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 主题分隔线（thematic_break）渲染组件
 *
 * 一条占满容器宽度的水平分割线。
 */
Rectangle {
    id: root

    property var astNode: null
    property var astStyle: null

    function init(node, style) {
        astNode = node;
        astStyle = style;
    }

    Binding on color {
        value: root.astStyle.blockQuoteBorder
        when: root.astStyle !== null
    }

    width: parent && parent.parent ? parent.parent.width : 0
    height: 2
}

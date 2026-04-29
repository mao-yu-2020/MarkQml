pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 主题分隔线（thematic_break）渲染组件
 *
 * 一条占满容器宽度的水平分割线。
 */
Rectangle {
    id: root

    required property var astNode
    required property var astStyle

    color: root.astStyle.blockQuoteBorder

    width: parent && parent.parent && parent.parent ? parent.parent.width : 0
    height: 2

    Component.onCompleted: {
        // console.log('object name: ', parent.parent.parent.objectName)
    }
}

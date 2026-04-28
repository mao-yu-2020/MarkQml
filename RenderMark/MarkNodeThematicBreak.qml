import QtQuick

/**
 * @brief Thematic Break 节点渲染组件
 *
 * 一条水平分隔线。
 */
Rectangle {
    id: control
    property var node: null
    property var style: null

    width: parent.width
    height: 1
    color: control.style ? control.style.tableBorder : "#cccccc"
}

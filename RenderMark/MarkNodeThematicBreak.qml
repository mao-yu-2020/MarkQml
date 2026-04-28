import QtQuick

/**
 * @brief Thematic Break 节点渲染组件
 *
 * 一条水平分隔线。
 */
Rectangle {
    property var node: null
    property var style: null

    width: parent.width
    height: 1
    color: style ? style.tableBorder : "#cccccc"
}

import QtQuick

/**
 * @brief Table Cell 节点渲染组件
 *
 * 带边框的矩形 + Flow 排列 inline 子节点。
 * 表头行单元格背景色不同。
 */
Rectangle {
    property var node: null
    property var style: null
    property Component inlineDelegate: null

    width: parent.width
    height: cellFlow.height + 8
    color: node && node.parentNode && node.parentNode.isHeader
           ? (style ? style.tableHeaderBg : "#f0f0f0")
           : "transparent"
    border.color: style ? style.tableBorder : "#cccccc"
    border.width: 1

    Flow {
        id: cellFlow
        anchors.fill: parent
        anchors.margins: 4
        spacing: 0

        Repeater {
            model: node ? node.children : []
            delegate: Loader {
                sourceComponent: inlineDelegate
                onLoaded: {
                    if (item) {
                        item.node = modelData
                        item.style = style
                    }
                }
            }
        }
    }
}

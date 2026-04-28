import QtQuick

/**
 * @brief Table Cell 节点渲染组件
 *
 * 带边框的矩形 + Flow 排列 inline 子节点。
 * 表头行单元格背景色不同。
 */
Rectangle {
    id: control
    property var node: null
    property var style: null
    property Component inlineDelegate: null

    width: parent.width
    height: cellFlow.height + 8
    color: control.node && control.node.parentNode && control.node.parentNode.isHeader
           ? (control.style ? control.style.tableHeaderBg : "#f0f0f0")
           : "transparent"
    border.color: control.style ? control.style.tableBorder : "#cccccc"
    border.width: 1

    Flow {
        id: cellFlow
        anchors.fill: parent
        anchors.margins: 4
        spacing: 0

        Repeater {
            model: control.node ? control.node.children : []
            delegate: Loader {
                sourceComponent: control.inlineDelegate
                onLoaded: {
                    if (item) {
                        item.astNode = modelData
                        item.style = control.style
                    }
                }
            }
        }
    }
}

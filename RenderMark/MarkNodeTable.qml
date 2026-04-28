import QtQuick

/**
 * @brief Table 节点渲染组件
 *
 * Column 排列 table_row / table_header 子节点。
 */
Column {
    id: control
    property var node: null
    property var style: null
    property Component tableRowDelegate: null

    width: parent.width
    spacing: 0

    Repeater {
        model: control.node ? control.node.children : []
        delegate: Loader {
            width: parent.width
            sourceComponent: control.tableRowDelegate
            onLoaded: {
                if (item) {
                    item.astNode = modelData
                    item.style = control.style
                }
            }
        }
    }
}

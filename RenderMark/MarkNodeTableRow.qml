import QtQuick

/**
 * @brief Table Row / Table Header 节点渲染组件
 *
 * Row 排列 table_cell 子节点，均分父组件宽度。
 */
Row {
    id: control
    property var node: null
    property var style: null
    property Component tableCellDelegate: null

    width: parent.width
    spacing: 0

    Repeater {
        model: control.node ? control.node.children : []
        delegate: Loader {
            width: {
                var cols = control.node && control.node.parentNode ? control.node.parentNode.columns : 1
                return cols > 0 ? parent.width / cols : parent.width
            }
            sourceComponent: control.tableCellDelegate
            onLoaded: {
                if (item) {
                    item.astNode = modelData
                    item.style = control.style
                }
            }
        }
    }
}

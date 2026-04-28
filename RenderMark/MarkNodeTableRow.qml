import QtQuick

/**
 * @brief Table Row / Table Header 节点渲染组件
 *
 * Row 排列 table_cell 子节点，均分父组件宽度。
 */
Row {
    property var node: null
    property var style: null
    property Component tableCellDelegate: null

    width: parent.width
    spacing: 0

    Repeater {
        model: node ? node.children : []
        delegate: Loader {
            width: {
                var cols = node && node.parentNode ? node.parentNode.columns : 1
                return cols > 0 ? parent.width / cols : parent.width
            }
            sourceComponent: tableCellDelegate
            onLoaded: {
                if (item) {
                    item.node = modelData
                    item.style = style
                }
            }
        }
    }
}

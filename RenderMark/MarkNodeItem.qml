import QtQuick

/**
 * @brief List Item 节点渲染组件
 *
 * Row 左侧显示 bullet/序号/复选框，右侧 Column 排列 block 子节点。
 */
Row {
    property var node: null
    property var style: null
    property Component blockDelegate: null

    width: parent.width
    spacing: 8

    // 列表标记（bullet、序号、任务列表勾选框）
    Text {
        text: {
            if (!node || !node.parentNode) return "•"
            if (node.parentNode.ordered)
                return (node.parentNode.start + node.parentNode.indexOf(node)) + "."
            if (node.tasklistChecked) return "☑"
            if (!node.tasklistChecked && node.parentNode.findFirst("item")
                && node.parentNode.findFirst("item").tasklistChecked)
                return "☐"
            return "•"
        }
        font.pixelSize: style ? style.baseFontSize : 14
        color: style ? style.textColor : "black"
    }

    // 列表项内容（paragraph 等 block 节点）
    Column {
        width: parent.width - 20
        spacing: 4

        Repeater {
            model: node ? node.children : []
            delegate: Loader {
                width: parent.width
                sourceComponent: blockDelegate
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

import QtQuick

/**
 * @brief List Item 节点渲染组件
 *
 * Row 左侧显示 bullet/序号/复选框，右侧 Column 排列 block 子节点。
 */
Row {
    id: control
    property var node: null
    property var style: null
    property Component blockDelegate: null

    width: parent.width
    spacing: 8

    // 列表标记（bullet、序号、任务列表勾选框）
    Text {
        text: {
            if (!control.node || !control.node.parentNode) return "•"
            if (control.node.parentNode.ordered)
                return (control.node.parentNode.start + control.node.parentNode.indexOf(control.node)) + "."
            if (control.node.tasklistChecked) return "☑"
            if (!control.node.tasklistChecked && control.node.parentNode.findFirst("item")
                && control.node.parentNode.findFirst("item").tasklistChecked)
                return "☐"
            return "•"
        }
        font.pixelSize: control.style ? control.style.baseFontSize : 14
        color: control.style ? control.style.textColor : "black"
    }

    // 列表项内容（paragraph 等 block 节点）
    Column {
        width: parent.width - 20
        spacing: 4

        Repeater {
            model: control.node ? control.node.children : []
            delegate: Loader {
                width: parent.width
                sourceComponent: control.blockDelegate
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

import QtQuick

/**
 * @brief Paragraph 节点渲染组件
 *
 * 使用 Flow 排列 inline 子节点，支持自动换行。
 */
Flow {
    property var node: null
    property var style: null
    property Component inlineDelegate: null

    width: parent.width
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

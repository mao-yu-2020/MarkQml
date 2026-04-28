import QtQuick

/**
 * @brief Heading 节点渲染组件
 *
 * 使用 Flow 排列 inline 子节点，并通过 headingLevel 传递给子 text 调整字体大小。
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
                    item.headingLevel = node.level
                }
            }
        }
    }
}

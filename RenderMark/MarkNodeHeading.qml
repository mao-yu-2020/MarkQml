import QtQuick

/**
 * @brief Heading 节点渲染组件
 *
 * 使用 Flow 排列 inline 子节点，并通过 headingLevel 传递给子 text 调整字体大小。
 */
Flow {
    id: control
    property var node: null
    property var style: null
    property Component inlineDelegate: null

    width: parent.width
    spacing: 0

    Repeater {
        model: control.node ? control.node.children : []
        delegate: Loader {
            sourceComponent: control.inlineDelegate
            onLoaded: {
                if (item) {
                    item.astNode = modelData
                    item.style = control.style
                    item.headingLevel = control.node.level
                }
            }
        }
    }
}

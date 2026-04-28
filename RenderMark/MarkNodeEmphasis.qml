import QtQuick

/**
 * @brief Emphasis（斜体）节点渲染组件
 *
 * Flow 包裹 inline 子节点，子 text 会通过祖先检测自动应用 italic。
 */
Flow {
    property var node: null
    property var style: null
    property Component inlineDelegate: null

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

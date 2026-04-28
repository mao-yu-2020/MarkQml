import QtQuick

/**
 * @brief Strikethrough（删除线）节点渲染组件
 *
 * Flow 包裹 inline 子节点。
 * 注：QML Text 原生不支持删除线，如需实现可在父级通过 Canvas 或自定义方式绘制横线。
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

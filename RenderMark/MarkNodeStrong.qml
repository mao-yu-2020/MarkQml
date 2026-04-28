import QtQuick

/**
 * @brief Strong（加粗）节点渲染组件
 *
 * Flow 包裹 inline 子节点，子 text 会通过祖先检测自动应用 bold。
 */
Flow {
    id: control
    property var node: null
    property var style: null
    property Component inlineDelegate: null

    spacing: 0

    Repeater {
        model: control.node ? control.node.children : []
        delegate: Loader {
            sourceComponent: control.inlineDelegate
            onLoaded: {
                if (item) {
                    item.astNode = modelData
                    item.style = control.style
                }
            }
        }
    }
}

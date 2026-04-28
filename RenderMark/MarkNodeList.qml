import QtQuick

/**
 * @brief List 节点渲染组件
 *
 * 用 Column 排列 item 子节点，整体左缩进。
 */
Column {
    id: control
    property var node: null
    property var style: null
    property Component itemDelegate: null

    width: parent.width
    spacing: 4
    leftPadding: 20

    Repeater {
        model: control.node ? control.node.children : []
        delegate: Loader {
            width: parent.width
            sourceComponent: control.itemDelegate
            onLoaded: {
                if (item) {
                    item.astNode = modelData
                    item.style = control.style
                }
            }
        }
    }
}

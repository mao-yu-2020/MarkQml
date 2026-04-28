import QtQuick

/**
 * @brief Block Quote 节点渲染组件
 *
 * 左侧竖线边框 + 缩进的 Column 排列 block 子节点。
 */
Item {
    id: control
    property var node: null
    property var style: null
    property Component blockDelegate: null

    width: parent.width
    height: quoteColumn.height + 16

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 4
        color: control.style ? control.style.blockQuoteBorder : "#cccccc"
    }

    Column {
        id: quoteColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16
        spacing: 8

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

import QtQuick

/**
 * @brief Block Quote 节点渲染组件
 *
 * 左侧竖线边框 + 缩进的 Column 排列 block 子节点。
 */
Item {
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
        color: style ? style.blockQuoteBorder : "#cccccc"
    }

    Column {
        id: quoteColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16
        spacing: 8

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

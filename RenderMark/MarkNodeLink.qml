import QtQuick

/**
 * @brief Link 节点渲染组件
 *
 * Flow 包裹 inline 子节点，整个区域可点击，点击后通过 Qt.openUrlExternally 打开链接。
 * 子 text 会通过祖先检测自动应用 linkColor 和下划线。
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

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (node && node.url) {
                Qt.openUrlExternally(node.url)
            }
        }
    }
}

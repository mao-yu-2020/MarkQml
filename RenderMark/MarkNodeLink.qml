import QtQuick

/**
 * @brief Link 节点渲染组件
 *
 * Flow 包裹 inline 子节点，整个区域可点击，点击后通过 Qt.openUrlExternally 打开链接。
 * 子 text 会通过祖先检测自动应用 linkColor 和下划线。
 */
Item {
    id: control
    property var node: null
    property var style: null
    property Component inlineDelegate: null

    width: parent.width
    height: flow.height

    Flow {
        id: flow
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
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (control.node && control.node.url) {
                Qt.openUrlExternally(control.node.url)
            }
        }
    }
}

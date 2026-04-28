import QtQuick

/**
 * @brief Code Block 节点渲染组件
 *
 * 带背景色的矩形框 + 等宽字体文本。
 */
Rectangle {
    id: control
    property var node: null
    property var style: null

    width: parent.width
    height: codeText.implicitHeight + 16
    color: control.style ? control.style.codeBackground : "#f5f5f5"
    radius: 4

    Text {
        id: codeText
        anchors.fill: parent
        anchors.margins: 8
        text: control.node ? control.node.content : ""
        font.family: "Consolas, monospace"
        font.pixelSize: control.style ? control.style.baseFontSize : 14
        color: control.style ? control.style.textColor : "black"
        wrapMode: Text.Wrap
    }
}

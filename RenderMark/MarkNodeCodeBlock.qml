import QtQuick

/**
 * @brief Code Block 节点渲染组件
 *
 * 带背景色的矩形框 + 等宽字体文本。
 */
Rectangle {
    property var node: null
    property var style: null

    width: parent.width
    height: codeText.implicitHeight + 16
    color: style ? style.codeBackground : "#f5f5f5"
    radius: 4

    Text {
        id: codeText
        anchors.fill: parent
        anchors.margins: 8
        text: node ? node.content : ""
        font.family: "Consolas, monospace"
        font.pixelSize: style ? style.baseFontSize : 14
        color: style ? style.textColor : "black"
        wrapMode: Text.Wrap
    }
}

import QtQuick

/**
 * @brief Inline Code 叶子节点渲染组件
 *
 * 等宽字体显示代码片段。
 */
Text {
    id: control
    property var node: null
    property var style: null

    text: control.node ? control.node.content : ""
    font.family: "Consolas, monospace"
    font.pixelSize: control.style ? control.style.baseFontSize : 14
    color: control.style ? control.style.textColor : "black"
}

import QtQuick

/**
 * @brief Inline Code 叶子节点渲染组件
 *
 * 等宽字体显示代码片段。
 */
Text {
    property var node: null
    property var style: null

    text: node ? node.content : ""
    font.family: "Consolas, monospace"
    font.pixelSize: style ? style.baseFontSize : 14
    color: style ? style.textColor : "black"
}

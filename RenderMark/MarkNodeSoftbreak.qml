import QtQuick

/**
 * @brief Softbreak 叶子节点渲染组件
 *
 * 渲染为一个空格。
 */
Text {
    property var style: null

    text: " "
    font.pixelSize: style ? style.baseFontSize : 14
}

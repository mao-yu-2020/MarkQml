import QtQuick

/**
 * @brief Softbreak 叶子节点渲染组件
 *
 * 渲染为一个空格。
 */
Text {
    id: control
    property var style: null

    text: " "
    font.pixelSize: control.style ? control.style.baseFontSize : 14
}

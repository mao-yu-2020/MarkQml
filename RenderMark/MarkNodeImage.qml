import QtQuick

/**
 * @brief Image 叶子节点渲染组件
 *
 * 按比例缩放显示图片。
 */
Image {
    property var node: null
    property var style: null

    source: node ? node.url : ""
    fillMode: Image.PreserveAspectFit
    width: Math.min(implicitWidth, parent ? parent.width : implicitWidth)
    height: width * (implicitHeight / Math.max(implicitWidth, 1))
}

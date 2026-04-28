import QtQuick

/**
 * @brief Linebreak 叶子节点渲染组件
 *
 * 渲染为一个换行占位。
 */
Item {
    property var style: null

    width: parent ? parent.width : 0
    height: style ? style.baseFontSize : 14
}

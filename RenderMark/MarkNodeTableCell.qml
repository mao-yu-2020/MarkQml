pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

/**
 * @brief 表格单元格（table_cell）渲染组件
 *
 * 带边框的矩形区域，内部通过 MarkRowNodeComponent 渲染行内内容。
 * 在 GridLayout 中使用，Layout.fillWidth 保证列宽对齐。
 */
Rectangle {
    id: root

    property var astNode: null
    property var astStyle: null
    property var cache: null
    property bool isHeaderRow: false

    function init(node, style) {
        astNode = node;
        astStyle = style;
    }

    Layout.fillWidth: true
    implicitWidth: cellContent.implicitWidth + 16
    implicitHeight: cellContent.implicitHeight + 16

    Binding on color {
        value: root.isHeaderRow ? root.astStyle.tableHeaderBg : "transparent"
        when: root.astStyle !== null
    }
    Binding on border.color {
        value: root.astStyle.tableBorder
        when: root.astStyle !== null
    }
    border.width: 1

    MarkRowNodeComponent {
        id: cellContent
        x: 8
        y: 8
        astNode: root.astNode
        astStyle: root.astStyle
        cache: root.cache
    }
}

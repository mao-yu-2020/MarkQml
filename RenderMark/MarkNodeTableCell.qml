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
    property var renderMark: null
    readonly property var astStyle: renderMark ? renderMark.style : null
    readonly property var cache: renderMark ? renderMark.compCache : null
    property bool isHeaderRow: false

    function init(node, rm) {
        astNode = node;
        renderMark = rm;
    }

    Layout.fillWidth: true
    Layout.fillHeight: true
    Binding on implicitWidth {
        value: cellContent.implicitWidth + root.astStyle.tableStyle.cellPadding * 2
        when: root.astStyle !== null
    }
    Binding on implicitHeight {
        value: cellContent.implicitHeight + root.astStyle.tableStyle.cellPadding * 2
        when: root.astStyle !== null
    }

    Binding on color {
        value: root.isHeaderRow ? root.astStyle.tableStyle.headerBg : root.astStyle.tableStyle.cellBg
        when: root.astStyle !== null
    }
    Binding on border.color {
        value: root.astStyle.tableStyle.borderColor
        when: root.astStyle !== null
    }
    Binding on border.width {
        value: root.astStyle ? root.astStyle.tableStyle.borderWidth : 1
        when: root.astStyle !== null
    }

    MarkRowNodeComponent {
        id: cellContent
        x: root.astStyle ? root.astStyle.tableStyle.cellPadding : 8
        y: root.astStyle ? root.astStyle.tableStyle.cellPadding : 8
        astNode: root.astNode
        renderMark: root.renderMark
    }
}

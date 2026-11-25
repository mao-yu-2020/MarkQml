pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

/**
 * @brief Table cell renderer.
 *
 * Cell text goes through the same inline rich-text flow as paragraphs so long
 * cells wrap and inline formatting works. Column alignment is supplied by
 * MarkNodeTable from the AST's GFM alignment data.
 */
Rectangle {
    id: root

    property var astNode: null
    property var renderMark: null
    property bool isHeaderRow: false
    property int alignment: 0

    readonly property var astStyle: renderMark ? renderMark.style : null

    function init(node, rm) {
        astNode = node
        renderMark = rm
    }

    Layout.fillWidth: true
    Layout.fillHeight: true

    implicitWidth: Math.max(0, cellText.implicitWidth)
        + (root.astStyle ? root.astStyle.tableStyle.cellPadding * 2 : 16)
    implicitHeight: cellText.height
        + (root.astStyle ? root.astStyle.tableStyle.cellPadding * 2 : 16)

    color: root.isHeaderRow
        ? (root.astStyle ? root.astStyle.tableStyle.headerBg : "transparent")
        : (root.astStyle ? root.astStyle.tableStyle.cellBg : "transparent")
    border.color: root.astStyle ? root.astStyle.tableStyle.borderColor : "#e2e8f0"
    border.width: root.astStyle ? root.astStyle.tableStyle.borderWidth : 1

    MarkInlineText {
        id: cellText
        x: root.astStyle ? root.astStyle.tableStyle.cellPadding : 8
        y: root.astStyle ? root.astStyle.tableStyle.cellPadding : 8
        width: Math.max(0, root.width - x * 2)
        astNode: root.astNode
        renderMark: root.renderMark
        isTableCell: true
        isHeaderCell: root.isHeaderRow
        horizontalAlignment: root.alignment === 1
            ? Text.AlignHCenter
            : (root.alignment === 2 ? Text.AlignRight : Text.AlignLeft)
    }
}

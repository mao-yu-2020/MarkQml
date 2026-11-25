pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

/**
 * @brief GFM table renderer.
 *
 * GridLayout keeps column widths aligned across rows. Each cell receives the
 * per-column alignment parsed by cmark-gfm so left/center/right markers behave
 * like the reference renderer.
 */
GridLayout {
    id: root

    property var astNode: null
    property var renderMark: null

    readonly property var astStyle: renderMark ? renderMark.style : null
    readonly property var alignments: root.astNode ? root.astNode.alignments : []
    readonly property var cellModel: {
        if (!root.astNode)
            return []
        var flat = []
        var rows = root.astNode.children
        for (var r = 0; r < rows.length; ++r) {
            var cells = rows[r].children
            for (var c = 0; c < cells.length; ++c) {
                flat.push({
                    cellNode: cells[c],
                    rowNode: rows[r],
                    colIndex: c
                })
            }
        }
        return flat
    }

    function init(node, rm) {
        astNode = node
        renderMark = rm
    }

    columns: root.astNode ? root.astNode.columns : 1
    rowSpacing: 0
    columnSpacing: 0
    width: parent ? parent.width : implicitWidth

    Repeater {
        model: root.cellModel

        MarkNodeTableCell {
            required property var modelData

            astNode: modelData.cellNode
            renderMark: root.renderMark
            isHeaderRow: modelData.rowNode.isHeader
            alignment: root.alignments.length > modelData.colIndex
                ? root.alignments[modelData.colIndex] : 0
        }
    }
}

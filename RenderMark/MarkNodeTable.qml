pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

/**
 * @brief 表格（table）渲染组件
 *
 * 使用 GridLayout 扁平化渲染所有单元格，确保同一列的宽度自动对齐。
 */
GridLayout {
    id: root

    required property var astNode
    required property var astStyle

    columns: root.astNode.columns
    rowSpacing: 0
    columnSpacing: 0

    Repeater {
        model: {
            let flat = [];
            const rows = root.astNode.children;
            for (let r = 0; r < rows.length; ++r) {
                const cells = rows[r].children;
                for (let c = 0; c < cells.length; ++c) {
                    flat.push({
                        cellNode: cells[c],
                        rowNode: rows[r],
                        colIndex: c
                    });
                }
            }
            return flat;
        }

        MarkNodeTableCell {
            required property var modelData
            astNode: modelData.cellNode
            astStyle: root.astStyle
            isHeaderRow: modelData.rowNode.isHeader
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 水平容器，用于行内节点（paragraph、heading 等）
 */
Row {
    id: root

    property var astNode: null
    property var astStyle: null
    property var cache: null
    property var renderMark: null

    /**
     * @brief 是否为节点的外层主组件
     *
     * 仅 _compCache 中作为 paragraph/tableHeader/tableRow 主路径的实例会置 true，
     * 内部嵌套使用（如 Strong/Emphasis/Heading 等内部 row）保持默认 false，
     * 以避免重复触发 callback / 把错误的内部 item 传给用户。
     */
    property bool _isOuterContainer: false

    function init(node, style) {
        astNode = node;
        astStyle = style;
    }

    Repeater {
        model: root.astNode ? root.astNode.children : []

        MarkNodeComponent {
            required property var modelData
            astNode: modelData
            astStyle: root.astStyle
            cache: root.cache
            renderMark: root.renderMark
        }
    }

    Component.onCompleted: {
        if (!root._isOuterContainer) return;
        Qt.callLater(function () {
            if (!root.renderMark || !root.astNode) return;
            var cb = null;
            switch (root.astNode.type) {
            case "paragraph":    cb = root.renderMark.paragraphNodeCallback;   break;
            case "table_header": cb = root.renderMark.tableHeaderNodeCallback; break;
            case "table_row":    cb = root.renderMark.tableRowNodeCallback;    break;
            }
            if (typeof cb === "function") cb(root);
        });
    }
}

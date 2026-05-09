pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 垂直容器，用于块级节点（document、list、item content 等）
 */
Column {
    id: root

    property var astNode: null
    property var astStyle: null
    property var cache: null
    property var renderMark: null

    /**
     * @brief 是否为节点的外层主组件
     *
     * 仅 _compCache 中作为 list 主路径的实例、以及 MarkNodeDocument 会置 true，
     * 内部嵌套使用（如 BlockQuote/Item/FootnoteDefinition 内部 column）保持默认 false，
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
            case "list":     cb = root.renderMark.listNodeCallback;     break;
            case "document": cb = root.renderMark.documentNodeCallback; break;
            }
            if (typeof cb === "function") cb(root);
        });
    }
}

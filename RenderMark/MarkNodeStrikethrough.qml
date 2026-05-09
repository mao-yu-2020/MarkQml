pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 删除线（strikethrough）渲染组件
 *
 * 通过 MarkRowNodeComponent 递归渲染所有子节点，
 * 内部文本由 MarkNodeText.qml 检测祖先节点自动添加删除线。
 */
Row {
    id: root

    property var astNode: null
    property var astStyle: null
    property var cache: null
    property var renderMark: null

    function init(node, style) {
        astNode = node;
        astStyle = style;
    }

    Component.onCompleted: {
        Qt.callLater(function () {
            if (root.renderMark && root.astNode
                && typeof root.renderMark.strikethroughNodeCallback === "function") {
                root.renderMark.strikethroughNodeCallback(root);
            }
        });
    }

    spacing: 0

    MarkRowNodeComponent {
        astNode: root.astNode
        astStyle: root.astStyle
        cache: root.cache
        renderMark: root.renderMark
    }
}

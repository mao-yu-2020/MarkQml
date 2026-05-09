pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 未知节点（unknown）渲染组件
 *
 * 直接显示原始文本内容。
 */
Text {
    id: root

    property var astNode: null
    property var astStyle: null
    property var renderMark: null

    function init(node, style) {
        astNode = node;
        astStyle = style;
    }

    Component.onCompleted: {
        Qt.callLater(function () {
            if (root.renderMark && root.astNode
                && typeof root.renderMark.unknownNodeCallback === "function") {
                root.renderMark.unknownNodeCallback(root);
            }
        });
    }

    Binding on text {
        value: root.astNode ? root.astNode.content : ""
        when: root.astNode !== null
    }

    Binding on color {
        value: root.astStyle.textColor
        when: root.astStyle !== null
    }

    Binding on font.pixelSize {
        value: root.astStyle.baseFontSize
        when: root.astStyle !== null
    }
}

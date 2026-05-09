pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 脚注引用（footnote_reference）渲染组件
 *
 * 以上标形式显示引用标记。
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
                && typeof root.renderMark.footnoteReferenceNodeCallback === "function") {
                root.renderMark.footnoteReferenceNodeCallback(root);
            }
        });
    }

    Binding on text {
        value: root.astNode ? "[" + root.astNode.content + "]" : ""
        when: root.astNode !== null
    }

    Binding on color {
        value: root.astStyle.linkColor
        when: root.astStyle !== null
    }

    Binding on font.pixelSize {
        value: root.astStyle.baseFontSize * 0.75
        when: root.astStyle !== null
    }
}

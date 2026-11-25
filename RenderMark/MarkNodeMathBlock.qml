pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief Display-math block rendered by MathTextItem.
 *
 * Block math is detected by MarkNodeParagraph from a paragraph whose textual
 * content is enclosed in $$...$$. The preview is centered and
 * scaled down only when it would exceed the available column width.
 */
Item {
    id: root

    property var astNode: null
    property var renderMark: null
    property string formula: ""

    readonly property var astStyle: renderMark ? renderMark.style : null

    function init(node, rm) {
        astNode = node
        renderMark = rm
    }

    width: parent ? parent.width : implicitWidth
    implicitHeight: mathItem.height
    height: implicitHeight

    MathTextItem {
        id: mathItem
        anchors.horizontalCenter: parent.horizontalCenter
        latex: root.formula
        fontSize: root.astStyle ? Math.round(root.astStyle.baseFontSize * 1.25) : 20
        color: root.astStyle ? root.astStyle.textColor : "#1a1a2e"
        padding: 4
        width: Math.min(implicitWidth, parent.width)
        height: implicitWidth > 0 ? width * implicitHeight / implicitWidth : implicitHeight
    }
}

pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief List item renderer (normal bullet/number and GFM task items).
 *
 * cmark-gfm exposes task items as a "tasklist" node with a checked flag.
 * Earlier builds only handled "item", so task items fell through to the
 * unknown-node renderer. Render both node types here and show a native
 * checkbox for task items.
 */
Row {
    id: root

    property var astNode: null
    readonly property var astStyle: renderMark ? renderMark.style : null
    readonly property var cache: renderMark ? renderMark.compCache : null
    property var renderMark: null

    readonly property bool isTasklist: astNode ? astNode.isTasklist : false
    readonly property bool isChecked: astNode ? astNode.tasklistChecked : false

    function init(node, rm) {
        astNode = node
        renderMark = rm
    }

    spacing: root.astStyle ? root.astStyle.itemStyle.bulletRightMargin : 8
    width: parent ? parent.width : implicitWidth

    // Compute the item index within the parent list for ordered markers.
    property int _itemIndex: {
        if (!root.astNode)
            return 0
        let listNode = root.astNode.parentNode
        if (!listNode || !listNode.isList())
            return 0
        for (let i = 0; i < listNode.children.length; ++i) {
            if (listNode.children[i] === root.astNode)
                return i
        }
        return 0
    }

    // Marker: checkbox for task items, bullet/number otherwise.
    Item {
        id: marker
        width: root.isTasklist
            ? 16
            : markerText.implicitWidth
        height: Math.max(root.isTasklist ? 16 : markerText.implicitHeight,
                         contentColumn.height)

        Text {
            id: markerText
            visible: !root.isTasklist
            text: {
                if (!root.astNode)
                    return "•"
                let listNode = root.astNode.parentNode
                if (!listNode || !listNode.isList())
                    return "•"
                if (listNode.ordered)
                    return (root._itemIndex + listNode.start) + "."
                return "•"
            }
            color: root.astStyle ? root.astStyle.itemStyle.color : "#1a1a2e"
            font.pixelSize: root.astStyle ? root.astStyle.itemStyle.fontSize : 14
            y: root.isTasklist ? 0 : 0
        }

        Rectangle {
            id: checkbox
            visible: root.isTasklist
            width: 16
            height: 16
            radius: 3
            color: root.isChecked
                ? (root.astStyle ? root.astStyle.linkStyle.color : "#2563eb")
                : "transparent"
            border.width: 1
            border.color: root.astStyle ? root.astStyle.itemStyle.color : "#1a1a2e"

            Text {
                anchors.centerIn: parent
                text: "✓"
                visible: root.isChecked
                color: "white"
                font.pixelSize: 12
                font.bold: true
            }
        }
    }

    // Right-hand content: paragraphs, nested lists, etc.
    MarkColumnNodeComponent {
        id: contentColumn
        width: Math.max(0, root.width - marker.width - root.spacing)
        astNode: root.astNode
        renderMark: root.renderMark
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

/**
 * @brief Fenced code block renderer.
 *
 * The block is width-constrained so it cannot push the chat column sideways.
 * Code wraps by default; callers can set wrapCode to false to get a horizontal
 * scroller. The copy action selects the whole code body before copying, so it
 * does not depend on a previous manual selection.
 */
Rectangle {
    id: root

    property var astNode: null
    property var renderMark: null
    property bool wrapCode: renderMark ? renderMark.codeWrap : true

    readonly property var astStyle: renderMark ? renderMark.style : null
    readonly property string code: root.astNode ? root.astNode.content : ""
    readonly property string language: root.astNode ? root.astNode.language : ""

    function init(node, rm) {
        astNode = node
        renderMark = rm
    }

    function copyAll() {
        codeEdit.selectAll()
        codeEdit.copy()
        codeEdit.deselect()
    }

    width: parent ? parent.width : implicitWidth
    implicitHeight: contentColumn.implicitHeight + (root.astStyle ? root.astStyle.codeBlockStyle.padding * 2 : 24)
    height: implicitHeight
    color: root.astStyle ? root.astStyle.codeBlockStyle.background : "#f8fafc"
    radius: root.astStyle ? root.astStyle.codeBlockStyle.radius : 4

    Column {
        id: contentColumn
        x: root.astStyle ? root.astStyle.codeBlockStyle.padding : 12
        y: root.astStyle ? root.astStyle.codeBlockStyle.padding : 12
        width: Math.max(0, root.width - x * 2)
        spacing: 6

        RowLayout {
            width: parent.width
            spacing: 8

            Rectangle {
                visible: root.language !== ""
                implicitWidth: langLabel.implicitWidth + 16
                implicitHeight: langLabel.implicitHeight + 8
                radius: 4
                color: root.astStyle ? root.astStyle.codeBlockStyle.langLabelBackground : Qt.rgba(0, 0, 0, 0.05)

                Text {
                    id: langLabel
                    anchors.centerIn: parent
                    text: root.language
                    color: root.astStyle ? root.astStyle.codeBlockStyle.langLabelColor : "#1a1a2e"
                    font.pixelSize: root.astStyle ? root.astStyle.codeBlockStyle.fontSize * 0.8 : 11
                    font.family: "monospace"
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                id: copyButton
                implicitWidth: copyLabel.implicitWidth + 16
                implicitHeight: copyLabel.implicitHeight + 8
                radius: 4
                color: copyMouse.containsMouse
                    ? Qt.rgba(0.5, 0.5, 0.5, 0.18)
                    : Qt.rgba(0.5, 0.5, 0.5, 0.08)

                Text {
                    id: copyLabel
                    anchors.centerIn: parent
                    text: "复制"
                    color: root.astStyle ? root.astStyle.codeBlockStyle.langLabelColor : "#1a1a2e"
                    font.pixelSize: root.astStyle ? root.astStyle.codeBlockStyle.fontSize * 0.8 : 11
                }

                MouseArea {
                    id: copyMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.copyAll()
                }
            }
        }

        TextMetrics {
            id: codeMetrics
            font: codeEdit.font
            text: root.wrapCode ? "" : root.code
        }

        Flickable {
            id: codeFlick
            width: parent.width
            height: codeEdit.contentHeight
            contentWidth: root.wrapCode ? width : Math.max(width, codeMetrics.advanceWidth + 2)
            contentHeight: height
            clip: true
            flickableDirection: Flickable.HorizontalFlick

            TextEdit {
                id: codeEdit
                width: root.wrapCode ? codeFlick.width : Math.max(codeFlick.width, codeMetrics.advanceWidth + 2)
                text: root.code
                height: contentHeight
                readOnly: true
                selectByMouse: true
                persistentSelection: true
                textFormat: TextEdit.PlainText
                wrapMode: root.wrapCode ? TextEdit.WrapAnywhere : TextEdit.NoWrap
                textMargin: 0
                padding: 0
                leftPadding: 0
                rightPadding: 0
                topPadding: 0
                bottomPadding: 0
                color: root.astStyle ? root.astStyle.codeBlockStyle.color : "#1a1a2e"
                font.pixelSize: root.astStyle ? root.astStyle.codeBlockStyle.fontSize : 14
                font.family: "monospace"
            }
        }
    }
}

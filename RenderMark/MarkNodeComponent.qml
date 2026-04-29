import QtQuick

Loader {
    id: root

    required property var astNode
    required property var astStyle

    Component.onCompleted: {
        if (astNode.isDocument()) {
            setSource('MarkNodeDocument.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }
        if (astNode.isBlockQuote()) {
            setSource('MarkNodeBlockQuote.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }
        if (astNode.isList()) {
            setSource('MarkColumnNodeComponent.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }
        if (astNode.isItem()) {
            setSource('MarkNodeItem.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }
        if (astNode.isCodeBlock()) {
            setSource('MarkNodeCodeBlock.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }
        if (astNode.isHtmlBlock()) {
            setSource('MarkNodeHtmlBlock.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }

        if (astNode.isParagraph()) {
            setSource('MarkRowNodeComponent.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }

        if (astNode.isHeading()) {
            setSource('MarkRowNodeComponent.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }

        if (astNode.isText()) {
            setSource('MarkNodeText.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }

        if (astNode.isStrong()) {
            setSource('MarkNodeStrong.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }

        if (astNode.isEmphasis()) {
            setSource('MarkNodeEmphasis.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }

        if (astNode.isThematicBreak()) {
            setSource('MarkNodeThematicBreak.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }
        if (astNode.isFootnoteDefinition()) {
            setSource('MarkNodeFootnoteDefinition.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }
        if (astNode.isSoftbreak()) {
            setSource('MarkNodeSoftbreak.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }
        if (astNode.isLinebreak()) {
            setSource('MarkNodeLinebreak.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }
        if (astNode.isCode()) {
            setSource('MarkNodeCode.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }
        if (astNode.isHtmlInline()) {
            setSource('MarkNodeHtmlInline.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }
        if (astNode.isLink()) {
            setSource('MarkNodeLink.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }
        if (astNode.isImage()) {
            setSource('MarkNodeImage.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }
        if (astNode.isFootnoteReference()) {
            setSource('MarkNodeFootnoteReference.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }
        if (astNode.isTable()) {
            setSource('MarkNodeTable.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }
        if (astNode.isTableHeader()) {
            setSource('MarkNodeTableHeader.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }
        if (astNode.isTableRow()) {
            setSource('MarkNodeTableRow.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }
        if (astNode.isTableCell()) {
            setSource('MarkNodeTableCell.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }
        if (astNode.isStrikethrough()) {
            setSource('MarkNodeStrikethrough.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }
        if (astNode.isUnknown()) {
            setSource('MarkNodeUnknown.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }
    }
}

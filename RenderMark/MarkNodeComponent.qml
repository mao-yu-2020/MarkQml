import QtQuick

Loader {
    id: root

    required property var astNode
    required property var astStyle

    Component.onCompleted: {
        // if (astNode.isDocument())           return null;
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
        // if (astNode.isHtmlBlock())          return null;

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
            setSource('MarkNodeText.qml', {astNode: astNode.children[0], astStyle: astStyle})
            return;
        }

        if (astNode.isEmphasis()) {
            setSource('MarkNodeText.qml', {astNode: astNode.children[0], astStyle: astStyle})
            return;
        }

        // if (astNode.isThematicBreak())      return null;
        // if (astNode.isFootnoteDefinition()) return null;
        // if (astNode.isSoftbreak())          return null;
        // if (astNode.isLinebreak())          return null;
        // if (astNode.isCode())               return null;
        // if (astNode.isHtmlInline())         return null;
        if (astNode.isLink()) {
            setSource('MarkNodeLink.qml', {astNode: astNode, astStyle: astStyle})
            return;
        }
        // if (astNode.isImage())              return null;
        // if (astNode.isFootnoteReference())  return null;
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
        // if (astNode.isStrikethrough())      return null;
        // if (astNode.isUnknown())            return null;
    }
}

import QtQuick

Loader {
    id: root

    required property var astNode
    required property var astStyle

    Component.onCompleted: {
        // if (astNode.isDocument())           return null;
        // if (astNode.isBlockQuote())         return null;
        // if (astNode.isList())               return null;
        // if (astNode.isItem())               return null;
        // if (astNode.isCodeBlock())          return null;
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
        // if (astNode.isLink())               return null;
        // if (astNode.isImage())              return null;
        // if (astNode.isFootnoteReference())  return null;
        // if (astNode.isTable())              return null;
        // if (astNode.isTableHeader())        return null;
        // if (astNode.isTableRow())           return null;
        // if (astNode.isTableCell())          return null;
        // if (astNode.isStrikethrough())      return null;
        // if (astNode.isUnknown())            return null;
    }
}

import QtQuick

/**
 * @brief AST 节点分发器
 *
 * 根据 astNode 的类型，从组件缓存中选择对应的 Component，
 * 通过 sourceComponent 动态加载，避免重复解析 QML 文件。
 */
Loader {
    id: root

    property var astNode: null
    property var astStyle: null
    property var cache: null

    sourceComponent: {
        var node = astNode;
        var c = cache;
        if (!c || !node) return null;

        if (node.isDocument()) return c.document;
        if (node.isBlockQuote()) return c.blockQuote;
        if (node.isList()) return c.list;
        if (node.isItem()) return c.item;
        if (node.isCodeBlock()) return c.codeBlock;
        if (node.isParagraph()) return c.paragraph;
        if (node.isHeading()) return c.heading;
        if (node.isText()) return c.text;
        if (node.isStrong()) return c.strong;
        if (node.isEmphasis()) return c.emphasis;
        if (node.isThematicBreak()) return c.thematicBreak;
        if (node.isFootnoteDefinition()) return c.footnoteDefinition;
        if (node.isSoftbreak()) return c.softbreak;
        if (node.isLinebreak()) return c.linebreak;
        if (node.isCode()) return c.code;
        if (node.isHtmlInline()) return c.htmlInline;
        if (node.isLink()) return c.link;
        if (node.isImage()) return c.image;
        if (node.isFootnoteReference()) return c.footnoteReference;
        if (node.isTable()) return c.table;
        if (node.isTableHeader()) return c.tableHeader;
        if (node.isTableRow()) return c.tableRow;
        if (node.isTableCell()) return c.tableCell;
        if (node.isStrikethrough()) return c.strikethrough;
        if (node.isUnknown()) return c.unknown;

        return null;
    }

    onLoaded: {
        if (item && item.init) {
            item.init(root.astNode, root.astStyle);
        }
        if (item && item.cache !== undefined) {
            item.cache = root.cache;
        }
    }

    onAstNodeChanged: {
        if (item && item.init && root.astNode !== null) {
            item.init(root.astNode, root.astStyle);
        }
    }

    onAstStyleChanged: {
        if (item && item.init && root.astNode !== null) {
            item.init(root.astNode, root.astStyle);
        }
    }
}

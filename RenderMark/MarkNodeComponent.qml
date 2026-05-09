import QtQuick

/**
 * @brief AST 节点分发器
 *
 * 根据 astNode 的类型，从 renderMark.compCache 选择对应的 Component，
 * 通过 sourceComponent 动态加载，避免重复解析 QML 文件。
 *
 * 加载完成后会统一派发节点级回调 `<type>NodeCallback`，叶子组件无需自行处理。
 */
Loader {
    id: root

    property var astNode: null
    property var renderMark: null

    /** AST type 字符串 → RenderMark 上回调属性名的映射（缺省走 unknownNodeCallback） */
    readonly property var _typeToCallback: ({
        "document":            "documentNodeCallback",
        "paragraph":           "paragraphNodeCallback",
        "heading":             "headingNodeCallback",
        "text":                "textNodeCallback",
        "link":                "linkNodeCallback",
        "image":               "imageNodeCallback",
        "list":                "listNodeCallback",
        "item":                "itemNodeCallback",
        "code_block":          "codeBlockNodeCallback",
        "code":                "codeNodeCallback",
        "block_quote":         "blockQuoteNodeCallback",
        "thematic_break":      "thematicBreakNodeCallback",
        "table":               "tableNodeCallback",
        "table_header":        "tableHeaderNodeCallback",
        "table_row":           "tableRowNodeCallback",
        "table_cell":          "tableCellNodeCallback",
        "strong":              "strongNodeCallback",
        "emphasis":            "emphasisNodeCallback",
        "strikethrough":       "strikethroughNodeCallback",
        "html_block":          "htmlBlockNodeCallback",
        "html_inline":         "htmlInlineNodeCallback",
        "footnote_definition": "footnoteDefinitionNodeCallback",
        "footnote_reference":  "footnoteReferenceNodeCallback",
        "softbreak":           "softbreakNodeCallback",
        "linebreak":           "linebreakNodeCallback"
    })

    /**
     * 统一派发节点渲染完成回调。
     * 由 onLoaded 通过 Qt.callLater 调度，保证 item / astNode / renderMark 已就绪。
     */
    function _dispatchCallback() {
        if (!root.renderMark || !root.astNode || !item) return;
        var key = root._typeToCallback[root.astNode.type] || "unknownNodeCallback";
        var cb = root.renderMark[key];
        if (typeof cb === "function") cb(item);
    }

    sourceComponent: {
        if (!astNode || !renderMark) return null;
        var c = renderMark.compCache;
        if (!c) return null;

        var node = astNode;
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
            item.init(root.astNode, root.renderMark);
        }
        Qt.callLater(_dispatchCallback);
    }

    onAstNodeChanged: {
        if (item && item.init && root.astNode !== null) {
            item.init(root.astNode, root.renderMark);
        }
    }
}

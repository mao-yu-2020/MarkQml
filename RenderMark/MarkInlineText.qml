pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief Rich-text renderer for one Markdown inline container.
 *
 * Markdown inline nodes (text, strong, emphasis, links, code, ...) must be
 * laid out as one text flow, otherwise long paragraphs cannot wrap and inline
 * formatting is broken across separate QML Labels. This component converts the
 * AST subtree into a small Qt rich-text document and renders it with a
 * read-only TextEdit so selection/copy and link activation keep working.
 *
 * HTML is deliberately escaped; raw Markdown HTML is never executed. Link
 * schemes are delegated to RenderMark.isSafeUrl().
 */
TextEdit {
    id: root

    property var astNode: null
    property var renderMark: null

    /** 0 = paragraph/table cell; 1..6 = heading level. */
    property int headingLevel: 0

    /** Table cells use the paragraph style and may be bold in the header. */
    property bool isTableCell: false
    property bool isHeaderCell: false

    readonly property var astStyle: renderMark ? renderMark.style : null

    function init(node, rm) {
        astNode = node
        renderMark = rm
    }

    function escapeHtml(value) {
        var text = value === undefined || value === null ? "" : String(value)
        return text
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#39;")
    }

    function escapeAttr(value) {
        return escapeHtml(value).replace(/\n/g, "&#10;")
    }

    function isSafeImageSource(url) {
        if (!url)
            return false
        var value = String(url).trim()
        if (!value)
            return false
        return /^(file:|qrc:|data:image\/|https?:\/\/|\/|\.{1,2}\/)/i.test(value)
            || value.indexOf("://") === -1
    }

    function resolveImageSource(url) {
        if (!url)
            return ""
        var value = String(url).trim()
        if (/^(file:|qrc:|data:image\/|https?:\/\/)/i.test(value))
            return value
        if (renderMark && renderMark.baseUrl) {
            var base = renderMark.baseUrl.toString()
            if (base.length && base.charAt(base.length - 1) !== "/")
                base += "/"
            return base + value.replace(/\\/g, "/")
        }
        return value
    }

    function renderChildren(node) {
        if (!node || !node.children)
            return ""
        var out = ""
        for (var i = 0; i < node.children.length; ++i)
            out += renderNode(node.children[i])
        return out
    }

    function renderNode(node) {
        if (!node)
            return ""

        if (node.isText && node.isText())
            return escapeHtml(node.content)
        if (node.isSoftbreak && node.isSoftbreak())
            return " "
        if (node.isLinebreak && node.isLinebreak())
            return "<br/>"
        if (node.isStrong && node.isStrong())
            return "<b>" + renderChildren(node) + "</b>"
        if (node.isEmphasis && node.isEmphasis())
            return "<i>" + renderChildren(node) + "</i>"
        if (node.isStrikethrough && node.isStrikethrough())
            return "<s>" + renderChildren(node) + "</s>"

        if (node.isCode && node.isCode()) {
            var codeColor = astStyle ? astStyle.codeStyle.color : "#1a1a2e"
            var codeBg = astStyle ? astStyle.codeStyle.background : "#f1f5f9"
            return "<span style=\"font-family:monospace; color:" + codeColor
                + "; background-color:" + codeBg + ";\">"
                + escapeHtml(node.content) + "</span>"
        }

        if (node.isLink && node.isLink()) {
            var label = renderChildren(node)
            var href = node.url || ""
            if (!renderMark || !renderMark.isSafeUrl(href))
                return label
            var linkColor = astStyle ? astStyle.linkStyle.color : "#2563eb"
            return "<a href=\"" + escapeAttr(href) + "\" style=\"color:" + linkColor
                + "; text-decoration:underline;\">" + label + "</a>"
        }

        if (node.isImage && node.isImage()) {
            // QML rich text can only resolve resource-style image URLs; file
            // and network sources would become broken images. A paragraph
            // containing just an image is handled by MarkNodeParagraph and
            // MarkNodeImage instead. For a mixed text/image paragraph keep a
            // discoverable link placeholder.
            var src = node.url || ""
            var alt = node.plainText ? node.plainText() : ""
            if (!isSafeImageSource(src))
                return escapeHtml(alt || src)
            var resolved = resolveImageSource(src)
            if (!renderMark || !renderMark.isSafeUrl(resolved))
                return escapeHtml(alt || resolved)
            return "<a href=\"" + escapeAttr(resolved) + "\">[图片: "
                + escapeHtml(alt || resolved) + "]</a>"
        }

        if (node.isHtmlInline && node.isHtmlInline())
            return escapeHtml(node.content)
        if (node.isHtmlBlock && node.isHtmlBlock())
            return escapeHtml(node.content)
        if (node.isFootnoteReference && node.isFootnoteReference())
            return "[" + escapeHtml(node.content) + "]"
        if (node.isUnknown && node.isUnknown())
            return escapeHtml(node.content || (node.plainText ? node.plainText() : ""))

        if (node.children && node.children.length > 0)
            return renderChildren(node)
        return escapeHtml(node.content)
    }

    readonly property int effectiveFontSize: {
        if (!astStyle)
            return 14
        if (headingLevel >= 1 && headingLevel <= 6) {
            switch (headingLevel) {
            case 1: return astStyle.headingStyle.h1Size
            case 2: return astStyle.headingStyle.h2Size
            case 3: return astStyle.headingStyle.h3Size
            case 4: return astStyle.headingStyle.h4Size
            case 5: return astStyle.headingStyle.h5Size
            case 6: return astStyle.headingStyle.h6Size
            }
        }
        return astStyle.paragraphStyle.fontSize
    }

    readOnly: true
    selectByMouse: true
    persistentSelection: true
    cursorVisible: false
    activeFocusOnPress: false
    textFormat: TextEdit.RichText
    wrapMode: TextEdit.Wrap
    textMargin: 0
    padding: 0
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    width: parent ? parent.width : implicitWidth
    height: contentHeight

    color: astStyle
        ? (headingLevel > 0 ? astStyle.headingStyle.color : astStyle.paragraphStyle.color)
        : "#1a1a2e"
    font.pixelSize: effectiveFontSize
    font.bold: headingLevel > 0 || isHeaderCell

    text: root.astNode ? root.renderChildren(root.astNode) : ""

    onLinkActivated: function(link) {
        if (root.renderMark)
            root.renderMark.openLink(link)
    }
}

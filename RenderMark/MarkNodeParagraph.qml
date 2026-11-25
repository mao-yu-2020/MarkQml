pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief Paragraph renderer.
 *
 * A paragraph is normally one inline text flow. When the paragraph contains
 * only an image (the common Markdown image-block form), use the native Image
 * component instead; QML rich text cannot load arbitrary file:// images. Mixed
 * text/image paragraphs keep the inline form and show the image as a link
 * placeholder.
 */
Item {
    id: root

    property var astNode: null
    property var renderMark: null

    readonly property var astStyle: renderMark ? renderMark.style : null
    readonly property string soleMathFormula: findSoleMath(root.astNode)
    readonly property var soleImageNode: root.soleMathFormula === ""
        ? findSoleImage(root.astNode) : null

    function init(node, rm) {
        astNode = node
        renderMark = rm
    }

    function nodeText(node) {
        if (!node)
            return ""
        if (node.isText && node.isText())
            return node.content
        if (node.isCode && node.isCode())
            return "\u0000"
        if (node.isSoftbreak && node.isSoftbreak())
            return "\n"
        if (node.isLinebreak && node.isLinebreak())
            return "\n"
        var out = ""
        if (node.children) {
            for (var i = 0; i < node.children.length; ++i)
                out += nodeText(node.children[i])
        }
        return out
    }

    function blockQuoteDepth(node) {
        var depth = 0
        var parent = node ? node.parentNode : null
        while (parent) {
            if (parent.isBlockQuote && parent.isBlockQuote())
                ++depth
            parent = parent.parentNode
        }
        return depth
    }

    function stripBlockQuoteMarkers(text, depth) {
        if (depth <= 0)
            return text
        var lines = text.split("\n")
        for (var i = 0; i < lines.length; ++i) {
            for (var level = 0; level < depth; ++level) {
                var match = lines[i].match(/^\s*> ?/)
                if (!match)
                    break
                lines[i] = lines[i].substring(match[0].length)
            }
        }
        return lines.join("\n").trim()
    }

    function findSoleMath(node) {
        if (!node)
            return ""
        var text = nodeText(node).trim()
        if (text.indexOf("\u0000") >= 0)
            return ""
        if (text.length >= 4 && text.indexOf("$$") === 0
                && text.lastIndexOf("$$") === text.length - 2)
            return stripBlockQuoteMarkers(text.substring(2, text.length - 2).trim(),
                                         blockQuoteDepth(node))
        return ""
    }

    function findSoleImage(node) {
        if (!node || !node.children)
            return null
        var image = null
        for (var i = 0; i < node.children.length; ++i) {
            var child = node.children[i]
            if (!child)
                continue
            if (child.isImage && child.isImage()) {
                if (image)
                    return null
                image = child
            } else if (child.isText && child.isText()
                       && String(child.content).trim() === "") {
                continue
            } else if (child.isSoftbreak && child.isSoftbreak()) {
                continue
            } else {
                return null
            }
        }
        return image
    }

    width: parent ? parent.width : implicitWidth
    implicitHeight: root.soleMathFormula !== ""
        ? mathLoader.height
        : (root.soleImageNode ? imageLoader.height : inlineItem.height)
    height: implicitHeight

    MarkInlineText {
        id: inlineItem
        visible: root.soleMathFormula === "" && !root.soleImageNode
        width: root.width
        astNode: root.astNode
        renderMark: root.renderMark
    }

    Loader {
        id: mathLoader
        active: root.soleMathFormula !== ""
        width: root.width
        sourceComponent: Component {
            MarkNodeMathBlock {}
        }
        onLoaded: {
            item.astNode = Qt.binding(function() { return root.astNode })
            item.renderMark = Qt.binding(function() { return root.renderMark })
            item.formula = Qt.binding(function() { return root.soleMathFormula })
        }
    }

    Loader {
        id: imageLoader
        active: !!root.soleImageNode
        width: root.width
        sourceComponent: Component {
            MarkNodeImage {}
        }
        onLoaded: {
            item.astNode = Qt.binding(function() { return root.soleImageNode })
            item.renderMark = Qt.binding(function() { return root.renderMark })
        }
    }
}

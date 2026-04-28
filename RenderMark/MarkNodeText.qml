import QtQuick

/**
 * @brief Text 叶子节点渲染组件
 *
 * 纯文本显示，根据祖先节点（strong/emphasis/link）自动应用样式。
 * 若位于 heading 内，根据 headingLevel 调整字体大小。
 */
Text {
    property var node: null
    property var style: null
    property int headingLevel: 0

    text: node ? node.content : ""
    color: hasLinkAncestor() ? (style ? style.linkColor : "#0066cc") : (style ? style.textColor : "black")
    font.bold: hasStrongAncestor()
    font.italic: hasEmphasisAncestor()
    font.underline: hasLinkAncestor()
    font.pixelSize: headingLevel > 0 ? headingPixelSize(headingLevel) : (style ? style.baseFontSize : 14)
    wrapMode: Text.Wrap

    function hasStrongAncestor() {
        var n = node
        while (n) {
            if (n.isStrong()) return true
            n = n.parentNode
        }
        return false
    }

    function hasEmphasisAncestor() {
        var n = node
        while (n) {
            if (n.isEmphasis()) return true
            n = n.parentNode
        }
        return false
    }

    function hasLinkAncestor() {
        var n = node
        while (n) {
            if (n.isLink()) return true
            n = n.parentNode
        }
        return false
    }

    function headingPixelSize(level) {
        var sizes = [0, 32, 28, 24, 20, 18, 16]
        return sizes[level] || (style ? style.baseFontSize : 14)
    }
}

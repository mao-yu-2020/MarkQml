import QtQuick
import RenderMark

/**
 * @brief Markdown AST 递归渲染组件（根容器）
 *
 * 接收 MarkTree（或 Markdown 文本），通过 Loader + source 分发到各个 MarkNodexxx.qml 子组件。
 */
Flickable {
    id: root

    // -----------------------------------------------------------------------
    // 公共属性
    // -----------------------------------------------------------------------

    /** @brief MarkTree 实例，由 Mark.parse() 或 Mark.end() 生成 */
    property var tree: null

    /** @brief 直接传入 Markdown 文本（内部自动解析为 tree） */
    property string markdown: ""

    // 样式配置
    property color textColor: "black"
    property color linkColor: "#0066cc"
    property color codeBackground: "#f5f5f5"
    property color blockQuoteBorder: "#cccccc"
    property color tableBorder: "#cccccc"
    property color tableHeaderBg: "#f0f0f0"
    property int baseFontSize: 14

    // 内部 Mark 解析器
    Mark {
        id: _mark
    }

    // 当 markdown 文本变化时自动解析
    onMarkdownChanged: {
        if (markdown !== "") {
            tree = _mark.parse(markdown)
        }
    }

    // Flickable 内容区域
    contentWidth: contentColumn.width
    contentHeight: contentColumn.height
    clip: true

    // 根布局：用 Column 排列顶层 Block 节点
    Column {
        id: contentColumn
        width: root.width
        spacing: 8

        Repeater {
            model: tree && tree.root ? tree.root.children : []
            delegate: Loader {
                width: parent.width
                sourceComponent: blockDelegate
                onLoaded: item.node = modelData
            }
        }
    }

    // 样式对象，统一传递给所有子组件
    property var markStyle: ({
        textColor: textColor,
        linkColor: linkColor,
        codeBackground: codeBackground,
        blockQuoteBorder: blockQuoteBorder,
        tableBorder: tableBorder,
        tableHeaderBg: tableHeaderBg,
        baseFontSize: baseFontSize
    })

    // -----------------------------------------------------------------------
    // Block 级分发器
    // -----------------------------------------------------------------------
    Component {
        id: blockDelegate

        Loader {
            property var node: null

            source: {
                if (!node) return ""
                if (node.isHeading()) return "MarkNodeHeading.qml"
                if (node.isParagraph()) return "MarkNodeParagraph.qml"
                if (node.isCodeBlock()) return "MarkNodeCodeBlock.qml"
                if (node.isList()) return "MarkNodeList.qml"
                if (node.isBlockQuote()) return "MarkNodeBlockQuote.qml"
                if (node.isThematicBreak()) return "MarkNodeThematicBreak.qml"
                if (node.isTable()) return "MarkNodeTable.qml"
                return ""
            }

            onLoaded: {
                if (!item) return
                item.node = node
                item.style = root.markStyle
                if (node.isHeading() || node.isParagraph())
                    item.inlineDelegate = inlineDelegate
                if (node.isList())
                    item.itemDelegate = itemDelegate
                if (node.isBlockQuote())
                    item.blockDelegate = blockDelegate
                if (node.isTable())
                    item.tableRowDelegate = tableRowDelegate
            }
        }
    }

    // -----------------------------------------------------------------------
    // Inline 级分发器
    // -----------------------------------------------------------------------
    Component {
        id: inlineDelegate

        Loader {
            property var node: null
            property int headingLevel: 0

            source: {
                if (!node) return ""
                if (node.isText()) return "MarkNodeText.qml"
                if (node.isCode()) return "MarkNodeInlineCode.qml"
                if (node.isStrong()) return "MarkNodeStrong.qml"
                if (node.isEmphasis()) return "MarkNodeEmphasis.qml"
                if (node.isLink()) return "MarkNodeLink.qml"
                if (node.isImage()) return "MarkNodeImage.qml"
                if (node.isStrikethrough()) return "MarkNodeStrikethrough.qml"
                if (node.isSoftbreak()) return "MarkNodeSoftbreak.qml"
                if (node.isLinebreak()) return "MarkNodeLinebreak.qml"
                return ""
            }

            onLoaded: {
                if (!item) return
                item.node = node
                item.style = root.markStyle
                if (node.isText())
                    item.headingLevel = headingLevel
                if (node.isStrong() || node.isEmphasis() || node.isLink() || node.isStrikethrough())
                    item.inlineDelegate = inlineDelegate
            }
        }
    }

    // -----------------------------------------------------------------------
    // 列表项、表格行/单元格专用分发器
    // -----------------------------------------------------------------------
    Component {
        id: itemDelegate

        Loader {
            property var node: null
            source: "MarkNodeItem.qml"
            onLoaded: {
                if (item) {
                    item.node = node
                    item.style = root.markStyle
                    item.blockDelegate = blockDelegate
                }
            }
        }
    }

    Component {
        id: tableRowDelegate

        Loader {
            property var node: null
            source: "MarkNodeTableRow.qml"
            onLoaded: {
                if (item) {
                    item.node = node
                    item.style = root.markStyle
                    item.tableCellDelegate = tableCellDelegate
                }
            }
        }
    }

    Component {
        id: tableCellDelegate

        Loader {
            property var node: null
            source: "MarkNodeTableCell.qml"
            onLoaded: {
                if (item) {
                    item.node = node
                    item.style = root.markStyle
                    item.inlineDelegate = inlineDelegate
                }
            }
        }
    }
}

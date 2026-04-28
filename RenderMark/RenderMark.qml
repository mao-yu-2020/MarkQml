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
                onLoaded: {
                    item.astNode = modelData
                    item.style = root.markStyle
                }
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
            // 使用 astNode 而非 node，避免与子组件的 node 属性名冲突导致 Unqualified access 警告
            property var astNode: null
            property var style: null

            source: {
                if (!astNode) return ""
                if (astNode.isHeading()) return "MarkNodeHeading.qml"
                if (astNode.isParagraph()) return "MarkNodeParagraph.qml"
                if (astNode.isCodeBlock()) return "MarkNodeCodeBlock.qml"
                if (astNode.isList()) return "MarkNodeList.qml"
                if (astNode.isBlockQuote()) return "MarkNodeBlockQuote.qml"
                if (astNode.isThematicBreak()) return "MarkNodeThematicBreak.qml"
                if (astNode.isTable()) return "MarkNodeTable.qml"
                return ""
            }

            onLoaded: {
                if (!item) return
                item.node = astNode
                item.style = style
                if (astNode.isHeading() || astNode.isParagraph())
                    item.inlineDelegate = inlineDelegate
                if (astNode.isList())
                    item.itemDelegate = itemDelegate
                if (astNode.isBlockQuote())
                    item.blockDelegate = blockDelegate
                if (astNode.isTable())
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
            property var astNode: null
            property int headingLevel: 0
            property var style: null

            source: {
                if (!astNode) return ""
                if (astNode.isText()) return "MarkNodeText.qml"
                if (astNode.isCode()) return "MarkNodeInlineCode.qml"
                if (astNode.isStrong()) return "MarkNodeStrong.qml"
                if (astNode.isEmphasis()) return "MarkNodeEmphasis.qml"
                if (astNode.isLink()) return "MarkNodeLink.qml"
                if (astNode.isImage()) return "MarkNodeImage.qml"
                if (astNode.isStrikethrough()) return "MarkNodeStrikethrough.qml"
                if (astNode.isSoftbreak()) return "MarkNodeSoftbreak.qml"
                if (astNode.isLinebreak()) return "MarkNodeLinebreak.qml"
                return ""
            }

            onLoaded: {
                if (!item) return
                item.node = astNode
                item.style = style
                if (astNode.isText())
                    item.headingLevel = headingLevel
                if (astNode.isStrong() || astNode.isEmphasis() || astNode.isLink() || astNode.isStrikethrough())
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
            property var astNode: null
            property var style: null
            source: "MarkNodeItem.qml"
            onLoaded: {
                if (item) {
                    item.node = astNode
                    item.style = style
                    item.blockDelegate = blockDelegate
                }
            }
        }
    }

    Component {
        id: tableRowDelegate

        Loader {
            property var astNode: null
            property var style: null
            source: "MarkNodeTableRow.qml"
            onLoaded: {
                if (item) {
                    item.node = astNode
                    item.style = style
                    item.tableCellDelegate = tableCellDelegate
                }
            }
        }
    }

    Component {
        id: tableCellDelegate

        Loader {
            property var astNode: null
            property var style: null
            source: "MarkNodeTableCell.qml"
            onLoaded: {
                if (item) {
                    item.node = astNode
                    item.style = style
                    item.inlineDelegate = inlineDelegate
                }
            }
        }
    }
}

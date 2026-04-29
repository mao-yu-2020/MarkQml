pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
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

    /** @brief MarkTree 实例，通常由内部自动设置 */
    property var tree: null

    /** @brief 直接传入 Markdown 文本，设置后自动解析并渲染 */
    property string markdown: ""

    /** @brief 本地文件路径或 file:/// URL，设置后自动加载并渲染 */
    property string source: ""

    /** @brief 渲染区域背景色 */
    property color bgColor: "#f4f9ff"

    /** @brief 基础字体大小 */
    property int baseFontSize: 14

    /** @brief 内置 Markdown 解析器，可直接调用 parse / parseFile / toHtml */
    property alias parser: _mark

    /** @brief 暴露样式对象 */
    property alias style: markStyle

    /** @brief 样式对象，统一传递给所有子组件（QtObject 支持属性变更通知） */
    QtObject {
        id: markStyle
        property color textColor: "#2c3e50"
        property color linkColor: "#3498db"
        property color codeBackground: "#eaf2f8"
        property color blockQuoteBorder: "#bdc3c7"
        property color tableBorder: "#bdc3c7"
        property color tableHeaderBg: "#d6eaf8"
        property int baseFontSize: root.baseFontSize
    }

    /** @brief 组件缓存，避免重复解析 QML 文件 */
    Item {
        id: _compCache
        visible: false
        width: 0
        height: 0

        Component { id: _cText;         MarkNodeText {} }
        Component { id: _cLink;         MarkNodeLink {} }
        Component { id: _cParagraph;    MarkRowNodeComponent {} }
        Component { id: _cHeading;      MarkRowNodeComponent {} }
        Component { id: _cList;         MarkColumnNodeComponent {} }
        Component { id: _cItem;         MarkNodeItem {} }
        Component { id: _cCodeBlock;    MarkNodeCodeBlock {} }
        Component { id: _cCode;         MarkNodeCode {} }
        Component { id: _cBlockQuote;   MarkNodeBlockQuote {} }
        Component { id: _cThematicBreak; MarkNodeThematicBreak {} }
        Component { id: _cTable;        MarkNodeTable {} }
        Component { id: _cTableCell;    MarkNodeTableCell {} }
        Component { id: _cImage;        MarkNodeImage {} }
        Component { id: _cDocument;     MarkNodeDocument {} }
        Component { id: _cStrong;       MarkNodeStrong {} }
        Component { id: _cEmphasis;     MarkNodeEmphasis {} }
        Component { id: _cStrikethrough; MarkNodeStrikethrough {} }
        Component { id: _cHtmlBlock;    MarkNodeHtmlBlock {} }
        Component { id: _cHtmlInline;   MarkNodeHtmlInline {} }
        Component { id: _cFootnoteDefinition; MarkNodeFootnoteDefinition {} }
        Component { id: _cFootnoteReference; MarkNodeFootnoteReference {} }
        Component { id: _cSoftbreak;    MarkNodeSoftbreak {} }
        Component { id: _cLinebreak;    MarkNodeLinebreak {} }
        Component { id: _cUnknown;      MarkNodeUnknown {} }
        Component { id: _cTableHeader;  MarkRowNodeComponent {} }
        Component { id: _cTableRow;     MarkRowNodeComponent {} }

        property alias text: _cText
        property alias link: _cLink
        property alias paragraph: _cParagraph
        property alias heading: _cHeading
        property alias list: _cList
        property alias item: _cItem
        property alias codeBlock: _cCodeBlock
        property alias code: _cCode
        property alias blockQuote: _cBlockQuote
        property alias thematicBreak: _cThematicBreak
        property alias table: _cTable
        property alias tableCell: _cTableCell
        property alias image: _cImage
        property alias document: _cDocument
        property alias strong: _cStrong
        property alias emphasis: _cEmphasis
        property alias strikethrough: _cStrikethrough
        property alias htmlBlock: _cHtmlBlock
        property alias htmlInline: _cHtmlInline
        property alias footnoteDefinition: _cFootnoteDefinition
        property alias footnoteReference: _cFootnoteReference
        property alias softbreak: _cSoftbreak
        property alias linebreak: _cLinebreak
        property alias unknown: _cUnknown
        property alias tableHeader: _cTableHeader
        property alias tableRow: _cTableRow
    }

    // -----------------------------------------------------------------------
    // 主题切换函数
    // -----------------------------------------------------------------------

    function setLightTheme() {
        markStyle.textColor = "#1a1a2e"
        markStyle.linkColor = "#2563eb"
        markStyle.codeBackground = "#f1f5f9"
        markStyle.blockQuoteBorder = "#3b82f6"
        markStyle.tableBorder = "#cbd5e1"
        markStyle.tableHeaderBg = "#e2e8f0"
        bgColor = "#ffffff"
    }

    function setDarkTheme() {
        markStyle.textColor = "#f1f5f9"
        markStyle.linkColor = "#60a5fa"
        markStyle.codeBackground = "#27272a"
        markStyle.blockQuoteBorder = "#a78bfa"
        markStyle.tableBorder = "#52525b"
        markStyle.tableHeaderBg = "#18181b"
        bgColor = "#0a0a0f"
    }

    function setColdTheme() {
        markStyle.textColor = "#0c4a6e"
        markStyle.linkColor = "#0891b2"
        markStyle.codeBackground = "#ecfeff"
        markStyle.blockQuoteBorder = "#22d3ee"
        markStyle.tableBorder = "#7dd3fc"
        markStyle.tableHeaderBg = "#bae6fd"
        bgColor = "#f0f9ff"
    }

    function setWarmTheme() {
        markStyle.textColor = "#431407"
        markStyle.linkColor = "#ea580c"
        markStyle.codeBackground = "#ffedd5"
        markStyle.blockQuoteBorder = "#f97316"
        markStyle.tableBorder = "#fdba74"
        markStyle.tableHeaderBg = "#fed7aa"
        bgColor = "#fff7ed"
    }

    // 内置 Mark 解析器
    Mark {
        id: _mark
    }

    // 当 markdown 文本变化时自动解析
    onMarkdownChanged: {
        if (markdown !== "") {
            source = ""
            tree = null
            tree = _mark.parse(markdown)
        }
    }

    // 当 source 路径变化时自动加载
    onSourceChanged: {
        if (source !== "") {
            markdown = ""
            var path = source
            if (path.indexOf("file:///") === 0) {
                path = decodeURIComponent(path.substring(8))
            }
            tree = _mark.parseFile(path)
        }
    }

    // Flickable 内容区域
    contentWidth: contentRectangle.width
    contentHeight: contentRectangle.height
    clip: true

    Rectangle {
        id: contentRectangle

        color: root.bgColor
        width: contentColumn.width
        height: contentColumn.height

        Column {
            id: contentColumn
            width: childrenRect.width
            height: childrenRect.height
            spacing: 8

            Repeater {
                model: root.tree && root.tree.root ? tree.root.children : []

                delegate: MarkNodeComponent {
                    required property var modelData

                    astNode: modelData
                    astStyle: markStyle
                    cache: _compCache
                }
            }
        }
    }

    ScrollBar.vertical: ScrollBar {}
    ScrollBar.horizontal: ScrollBar {}
}

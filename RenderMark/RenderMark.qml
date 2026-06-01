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

    /** @brief 源文件所在目录的 URL，用于解析图片等相对路径 */
    property url baseUrl: ""

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

        // -------------------------------------------------------------------
        // 全局回退
        // -------------------------------------------------------------------
        property color textColor: "#2c3e50"
        property int   baseFontSize: root.baseFontSize

        // -------------------------------------------------------------------
        // 行内节点样式
        // -------------------------------------------------------------------
        property QtObject textStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
        }

        property QtObject linkStyle: QtObject {
            property color color: "#3498db"
            property int   fontSize: markStyle.baseFontSize
            property bool  underline: true
        }

        property QtObject codeStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
            property color background: "#eaf2f8"
            property real  radius: 3
            property int   hPadding: 4
            property int   vPadding: 1
        }

        property QtObject strongStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
            property bool  bold: true
        }

        property QtObject emphasisStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
            property bool  italic: true
        }

        property QtObject strikethroughStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
            property bool  strikeout: true
        }

        property QtObject imageStyle: QtObject {
            property real  maxWidth: -1
            property real  maxHeight: -1
            property real  radius: 0
            property color placeholderBg: markStyle.codeStyle.background
            property color placeholderBorderColor: markStyle.tableStyle.borderColor
            property color placeholderTextColor: markStyle.textColor
            property int   placeholderFontSize: markStyle.baseFontSize
        }

        property QtObject footnoteReferenceStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
        }

        // -------------------------------------------------------------------
        // 块级节点样式
        // -------------------------------------------------------------------
        property QtObject paragraphStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
            property color background: "transparent"
            property int   topMargin: 0
            property int   bottomMargin: 8
        }

        property QtObject headingStyle: QtObject {
            property color color: markStyle.textColor
            property color background: "transparent"
            property int   h1Size: markStyle.baseFontSize * 2.0
            property int   h2Size: markStyle.baseFontSize * 1.75
            property int   h3Size: markStyle.baseFontSize * 1.5
            property int   h4Size: markStyle.baseFontSize * 1.25
            property int   h5Size: markStyle.baseFontSize * 1.125
            property int   h6Size: markStyle.baseFontSize * 1.0
            property int   topMargin: 16
            property int   bottomMargin: 8
        }

        property QtObject codeBlockStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
            property color background: "#eaf2f8"
            property color langLabelColor: markStyle.textColor
            property color langLabelBackground: Qt.rgba(0, 0, 0, 0.05)
            property real  radius: 4
            property int   padding: 12
            property int   topMargin: 8
            property int   bottomMargin: 8
        }

        property QtObject blockQuoteStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
            property color background: "#eaf2f8"
            property color borderColor: "#bdc3c7"
            property int   borderWidth: 4
            property real  radius: 4
            property int   leftPadding: 12
            property int   topMargin: 8
            property int   bottomMargin: 8
        }

        property QtObject listStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
            property color background: "transparent"
            property int   topMargin: 8
            property int   bottomMargin: 8
            property int   spacing: 4
        }

        property QtObject itemStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
            property color background: "transparent"
            property int   spacing: 2
            property int   bulletRightMargin: 8
        }

        property QtObject tableStyle: QtObject {
            property color borderColor: "#bdc3c7"
            property int   borderWidth: 1
            property color headerBg: "#d6eaf8"
            property color cellBg: "transparent"
            property int   cellPadding: 8
            property int   topMargin: 8
            property int   bottomMargin: 8
        }

        property QtObject thematicBreakStyle: QtObject {
            property color color: "#bdc3c7"
            property int   height: 2
            property int   topMargin: 16
            property int   bottomMargin: 16
        }

        // -------------------------------------------------------------------
        // 其他节点样式
        // -------------------------------------------------------------------
        property QtObject documentStyle: QtObject {
            property color background: "transparent"
            property int   padding: 0
        }

        property QtObject htmlBlockStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
        }

        property QtObject htmlInlineStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
        }

        property QtObject footnoteDefinitionStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
        }

        property QtObject softbreakStyle: QtObject { }
        property QtObject linebreakStyle: QtObject { }
        property QtObject unknownStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
        }
    }

    /**
     * @brief 树重新渲染完成信号
     * @param tree 当前渲染的 MarkTree 实例（可能为 null）
     *
     * 当 tree 被赋值并开始重新渲染后发出，
     * 外部使用者可连接此信号来清空大纲、清除外部缓存等。
     */
    signal treeReady(var tree)

    // -----------------------------------------------------------------------
    // 节点渲染完成回调（按节点类型暴露，外部赋值后由对应组件在渲染完成时调用）
    //
    // 约定：每个回调签名为 (item) => void，item 为该节点在 QML 中的渲染实例。
    // 默认 null，未赋值则跳过。回调时机统一为 Component.onCompleted 后的下一帧
    // （Qt.callLater），保证 astNode/astStyle/renderMark 都已就绪。
    // -----------------------------------------------------------------------

    property var documentNodeCallback: null
    property var paragraphNodeCallback: null
    property var headingNodeCallback: null
    property var textNodeCallback: null
    property var linkNodeCallback: null
    property var imageNodeCallback: null
    property var listNodeCallback: null
    property var itemNodeCallback: null
    property var codeBlockNodeCallback: null
    property var codeNodeCallback: null
    property var blockQuoteNodeCallback: null
    property var thematicBreakNodeCallback: null
    property var tableNodeCallback: null
    property var tableHeaderNodeCallback: null
    property var tableRowNodeCallback: null
    property var tableCellNodeCallback: null
    property var strongNodeCallback: null
    property var emphasisNodeCallback: null
    property var strikethroughNodeCallback: null
    property var htmlBlockNodeCallback: null
    property var htmlInlineNodeCallback: null
    property var footnoteDefinitionNodeCallback: null
    property var footnoteReferenceNodeCallback: null
    property var softbreakNodeCallback: null
    property var linebreakNodeCallback: null
    property var unknownNodeCallback: null

    /**
     * @brief 组件缓存对外别名
     *
     * 外部可通过 `renderMark.compCache.xxx = customComponent` 替换任意节点的渲染组件。
     * 例如：renderMark.compCache.codeBlock = myCustomCodeBlockComponent
     */
    property alias compCache: _compCache

    /**
     * @brief 组件缓存，避免重复解析 QML 文件
     *
     * 每个节点类型对应一个可写的 `property Component`，默认指向内置 _defaultXxx 实现，
     * 外部赋值后 MarkNodeComponent.sourceComponent 会自动选用新组件。
     */
    Item {
        id: _compCache
        visible: false
        width: 0
        height: 0

        // 各类节点对应的渲染 Component，外部可重新赋值以替换默认实现
        property Component text:               _defaultText
        property Component link:               _defaultLink
        property Component paragraph:          _defaultParagraph
        property Component heading:            _defaultHeading
        property Component list:               _defaultList
        property Component item:               _defaultItem
        property Component codeBlock:          _defaultCodeBlock
        property Component code:               _defaultCode
        property Component blockQuote:         _defaultBlockQuote
        property Component thematicBreak:      _defaultThematicBreak
        property Component table:              _defaultTable
        property Component tableCell:          _defaultTableCell
        property Component image:              _defaultImage
        property Component document:           _defaultDocument
        property Component strong:             _defaultStrong
        property Component emphasis:           _defaultEmphasis
        property Component strikethrough:      _defaultStrikethrough
        property Component htmlBlock:          _defaultHtmlBlock
        property Component htmlInline:         _defaultHtmlInline
        property Component footnoteDefinition: _defaultFootnoteDefinition
        property Component footnoteReference:  _defaultFootnoteReference
        property Component softbreak:          _defaultSoftbreak
        property Component linebreak:          _defaultLinebreak
        property Component unknown:            _defaultUnknown
        property Component tableHeader:        _defaultTableHeader
        property Component tableRow:           _defaultTableRow

        // 内置默认组件实现
        Component { id: _defaultText;               MarkNodeText {} }
        Component { id: _defaultLink;               MarkNodeLink {} }
        Component { id: _defaultParagraph;          MarkRowNodeComponent {} }
        Component { id: _defaultHeading;            MarkNodeHeading {} }
        Component { id: _defaultList;               MarkColumnNodeComponent {} }
        Component { id: _defaultItem;               MarkNodeItem {} }
        Component { id: _defaultCodeBlock;          MarkNodeCodeBlock {} }
        Component { id: _defaultCode;               MarkNodeCode {} }
        Component { id: _defaultBlockQuote;         MarkNodeBlockQuote {} }
        Component { id: _defaultThematicBreak;      MarkNodeThematicBreak {} }
        Component { id: _defaultTable;              MarkNodeTable {} }
        Component { id: _defaultTableCell;          MarkNodeTableCell {} }
        Component { id: _defaultImage;              MarkNodeImage {} }
        Component { id: _defaultDocument;           MarkNodeDocument {} }
        Component { id: _defaultStrong;             MarkNodeStrong {} }
        Component { id: _defaultEmphasis;           MarkNodeEmphasis {} }
        Component { id: _defaultStrikethrough;      MarkNodeStrikethrough {} }
        Component { id: _defaultHtmlBlock;          MarkNodeHtmlBlock {} }
        Component { id: _defaultHtmlInline;         MarkNodeHtmlInline {} }
        Component { id: _defaultFootnoteDefinition; MarkNodeFootnoteDefinition {} }
        Component { id: _defaultFootnoteReference;  MarkNodeFootnoteReference {} }
        Component { id: _defaultSoftbreak;          MarkNodeSoftbreak {} }
        Component { id: _defaultLinebreak;          MarkNodeLinebreak {} }
        Component { id: _defaultUnknown;            MarkNodeUnknown {} }
        Component { id: _defaultTableHeader;        MarkRowNodeComponent {} }
        Component { id: _defaultTableRow;           MarkRowNodeComponent {} }
    }

    // -----------------------------------------------------------------------
    // 主题切换函数
    // -----------------------------------------------------------------------

    function setLightTheme() {
        markStyle.textColor = "#1a1a2e"
        markStyle.baseFontSize = 14

        markStyle.textStyle.color = "#1a1a2e"
        markStyle.linkStyle.color = "#2563eb"
        markStyle.codeStyle.background = "#f1f5f9"
        markStyle.strongStyle.color = "#1a1a2e"
        markStyle.emphasisStyle.color = "#1a1a2e"
        markStyle.strikethroughStyle.color = "#1a1a2e"
        markStyle.imageStyle.placeholderBg = "#f1f5f9"
        markStyle.imageStyle.placeholderBorderColor = "#cbd5e1"
        markStyle.imageStyle.placeholderTextColor = "#1a1a2e"

        markStyle.paragraphStyle.color = "#1a1a2e"
        markStyle.headingStyle.color = "#1a1a2e"
        markStyle.codeBlockStyle.background = "#f1f5f9"
        markStyle.codeBlockStyle.color = "#1a1a2e"
        markStyle.blockQuoteStyle.background = "#f1f5f9"
        markStyle.blockQuoteStyle.borderColor = "#3b82f6"
        markStyle.tableStyle.borderColor = "#cbd5e1"
        markStyle.tableStyle.headerBg = "#e2e8f0"
        markStyle.thematicBreakStyle.color = "#cbd5e1"

        bgColor = "#ffffff"
    }

    function setDarkTheme() {
        markStyle.textColor = "#f1f5f9"
        markStyle.baseFontSize = 14

        markStyle.textStyle.color = "#f1f5f9"
        markStyle.linkStyle.color = "#60a5fa"
        markStyle.codeStyle.background = "#27272a"
        markStyle.strongStyle.color = "#f1f5f9"
        markStyle.emphasisStyle.color = "#f1f5f9"
        markStyle.strikethroughStyle.color = "#f1f5f9"
        markStyle.imageStyle.placeholderBg = "#27272a"
        markStyle.imageStyle.placeholderBorderColor = "#52525b"
        markStyle.imageStyle.placeholderTextColor = "#f1f5f9"

        markStyle.paragraphStyle.color = "#f1f5f9"
        markStyle.headingStyle.color = "#f1f5f9"
        markStyle.codeBlockStyle.background = "#27272a"
        markStyle.codeBlockStyle.color = "#f1f5f9"
        markStyle.blockQuoteStyle.background = "#18181b"
        markStyle.blockQuoteStyle.borderColor = "#a78bfa"
        markStyle.tableStyle.borderColor = "#52525b"
        markStyle.tableStyle.headerBg = "#18181b"
        markStyle.thematicBreakStyle.color = "#52525b"

        bgColor = "#0a0a0f"
    }

    function setColdTheme() {
        markStyle.textColor = "#0c4a6e"
        markStyle.baseFontSize = 14

        markStyle.textStyle.color = "#0c4a6e"
        markStyle.linkStyle.color = "#0891b2"
        markStyle.codeStyle.background = "#ecfeff"
        markStyle.strongStyle.color = "#0c4a6e"
        markStyle.emphasisStyle.color = "#0c4a6e"
        markStyle.strikethroughStyle.color = "#0c4a6e"
        markStyle.imageStyle.placeholderBg = "#ecfeff"
        markStyle.imageStyle.placeholderBorderColor = "#7dd3fc"
        markStyle.imageStyle.placeholderTextColor = "#0c4a6e"

        markStyle.paragraphStyle.color = "#0c4a6e"
        markStyle.headingStyle.color = "#0c4a6e"
        markStyle.codeBlockStyle.background = "#ecfeff"
        markStyle.codeBlockStyle.color = "#0c4a6e"
        markStyle.blockQuoteStyle.background = "#ecfeff"
        markStyle.blockQuoteStyle.borderColor = "#22d3ee"
        markStyle.tableStyle.borderColor = "#7dd3fc"
        markStyle.tableStyle.headerBg = "#bae6fd"
        markStyle.thematicBreakStyle.color = "#7dd3fc"

        bgColor = "#f0f9ff"
    }

    function setWarmTheme() {
        markStyle.textColor = "#431407"
        markStyle.baseFontSize = 14

        markStyle.textStyle.color = "#431407"
        markStyle.linkStyle.color = "#ea580c"
        markStyle.codeStyle.background = "#ffedd5"
        markStyle.strongStyle.color = "#431407"
        markStyle.emphasisStyle.color = "#431407"
        markStyle.strikethroughStyle.color = "#431407"
        markStyle.imageStyle.placeholderBg = "#ffedd5"
        markStyle.imageStyle.placeholderBorderColor = "#fdba74"
        markStyle.imageStyle.placeholderTextColor = "#431407"

        markStyle.paragraphStyle.color = "#431407"
        markStyle.headingStyle.color = "#431407"
        markStyle.codeBlockStyle.background = "#ffedd5"
        markStyle.codeBlockStyle.color = "#431407"
        markStyle.blockQuoteStyle.background = "#ffedd5"
        markStyle.blockQuoteStyle.borderColor = "#f97316"
        markStyle.tableStyle.borderColor = "#fdba74"
        markStyle.tableStyle.headerBg = "#fed7aa"
        markStyle.thematicBreakStyle.color = "#fdba74"

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

    // tree 变化时发出 treeReady 信号，通知外部重新渲染已开始
    onTreeChanged: {
        root.treeReady(root.tree)
    }

    // -----------------------------------------------------------------------
    // 公共方法
    // -----------------------------------------------------------------------

    /**
     * @brief 滚动到指定 heading Item 所在位置
     * @param item heading 渲染后的 QML Item
     *
     * 外部使用者负责维护 node→item 的映射，调用时直接传入 item。
     */
    function scrollToHeading(item) {
        if (!item)
            return;
        var pos = item.mapToItem(contentItem, 0, 0);
        contentY = Math.max(0, pos.y - 20);
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
                    required property int index

                    astNode: modelData
                    renderMark: root

                    opacity: 0

                    Component.onCompleted: opacity = 1

                    Behavior on opacity {
                        SequentialAnimation {
                            PauseAnimation { duration: Math.min(index * 40, 600) }
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                }
            }
        }
    }

    ScrollBar.vertical: ScrollBar {}
    ScrollBar.horizontal: ScrollBar {}
}

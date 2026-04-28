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
        width: childrenRect.width
        height: childrenRect.height
        spacing: 8



        Repeater {
            model: root.tree && root.tree.root ? tree.root.children : []

            delegate:  Loader {
                id: loader
                required property var modelData
                property var nodeStyle: root.markStyle

                Component {
                    id: _headingComponent

                    MarkNodeHeading {
                        node: loader.modelData
                        style: loader.nodeStyle
                    }
                }

                sourceComponent: {
                    if (modelData.isDocument())           return null;
                    if (modelData.isBlockQuote())         return null;
                    if (modelData.isList())               return null;
                    if (modelData.isItem())               return null;
                    if (modelData.isCodeBlock())          return null;
                    if (modelData.isHtmlBlock())          return null;
                    if (modelData.isParagraph())          return null;
                    if (modelData.isHeading())
                        return _headingComponent;
                    if (modelData.isThematicBreak())      return null;
                    if (modelData.isFootnoteDefinition()) return null;
                    if (modelData.isText())               return null;
                    if (modelData.isSoftbreak())          return null;
                    if (modelData.isLinebreak())          return null;
                    if (modelData.isCode())               return null;
                    if (modelData.isHtmlInline())         return null;
                    if (modelData.isEmphasis())           return null;
                    if (modelData.isStrong())             return null;
                    if (modelData.isLink())               return null;
                    if (modelData.isImage())              return null;
                    if (modelData.isFootnoteReference())  return null;
                    if (modelData.isTable())              return null;
                    if (modelData.isTableHeader())        return null;
                    if (modelData.isTableRow())           return null;
                    if (modelData.isTableCell())          return null;
                    if (modelData.isStrikethrough())      return null;
                    if (modelData.isUnknown())            return null;
                    return null;
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


}

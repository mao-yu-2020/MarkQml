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

    /** @brief 渲染区域背景色 */
    property color bgColor: "#f4f9ff"

    /** @brief 基础字体大小 */
    property int baseFontSize: 14

    /** 暴露样式属性 */
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

    // -----------------------------------------------------------------------
    // 主题切换函数
    // -----------------------------------------------------------------------

    function setLightTheme() {
        markStyle.textColor = "black"
        markStyle.linkColor = "#0066cc"
        markStyle.codeBackground = "#f5f5f5"
        markStyle.blockQuoteBorder = "#cccccc"
        markStyle.tableBorder = "#cccccc"
        markStyle.tableHeaderBg = "#f0f0f0"
        bgColor = "#ffffff"
    }

    function setDarkTheme() {
        markStyle.textColor = "#e0e0e0"
        markStyle.linkColor = "#4dabf7"
        markStyle.codeBackground = "#2d2d2d"
        markStyle.blockQuoteBorder = "#444444"
        markStyle.tableBorder = "#444444"
        markStyle.tableHeaderBg = "#2d2d2d"
        bgColor = "#1e1e1e"
    }

    function setColdTheme() {
        markStyle.textColor = "#2c3e50"
        markStyle.linkColor = "#3498db"
        markStyle.codeBackground = "#eaf2f8"
        markStyle.blockQuoteBorder = "#bdc3c7"
        markStyle.tableBorder = "#bdc3c7"
        markStyle.tableHeaderBg = "#d6eaf8"
        bgColor = "#f4f9ff"
    }

    function setWarmTheme() {
        markStyle.textColor = "#4a3728"
        markStyle.linkColor = "#e67e22"
        markStyle.codeBackground = "#fdf2e9"
        markStyle.blockQuoteBorder = "#d5c4a1"
        markStyle.tableBorder = "#d5c4a1"
        markStyle.tableHeaderBg = "#fdebd0"
        bgColor = "#fffaf5"
    }

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
                }
            }
        }
    }

    ScrollBar.vertical: ScrollBar {}
    ScrollBar.horizontal: ScrollBar {}
}

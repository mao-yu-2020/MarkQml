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

    // 样式配置（默认冷色调）
    property color textColor: "#2c3e50"
    property color linkColor: "#3498db"
    property color codeBackground: "#eaf2f8"
    property color blockQuoteBorder: "#bdc3c7"
    property color tableBorder: "#bdc3c7"
    property color tableHeaderBg: "#d6eaf8"
    property color bgColor: "#f4f9ff"
    property int baseFontSize: 14

    // -----------------------------------------------------------------------
    // 主题切换函数
    // -----------------------------------------------------------------------

    function _refresh() {
        if (tree) {
            var t = tree
            tree = null
            Qt.callLater(function() { tree = t })
        } else if (markdown !== "") {
            var m = markdown
            markdown = ""
            Qt.callLater(function() { markdown = m })
        }
    }

    function setLightTheme() {
        textColor = "black"
        linkColor = "#0066cc"
        codeBackground = "#f5f5f5"
        blockQuoteBorder = "#cccccc"
        tableBorder = "#cccccc"
        tableHeaderBg = "#f0f0f0"
        bgColor = "#ffffff"
        _refresh()
    }

    function setDarkTheme() {
        textColor = "#e0e0e0"
        linkColor = "#4dabf7"
        codeBackground = "#2d2d2d"
        blockQuoteBorder = "#444444"
        tableBorder = "#444444"
        tableHeaderBg = "#2d2d2d"
        bgColor = "#1e1e1e"
        _refresh()
    }

    function setColdTheme() {
        textColor = "#2c3e50"
        linkColor = "#3498db"
        codeBackground = "#eaf2f8"
        blockQuoteBorder = "#bdc3c7"
        tableBorder = "#bdc3c7"
        tableHeaderBg = "#d6eaf8"
        bgColor = "#f4f9ff"
        _refresh()
    }

    function setWarmTheme() {
        textColor = "#4a3728"
        linkColor = "#e67e22"
        codeBackground = "#fdf2e9"
        blockQuoteBorder = "#d5c4a1"
        tableBorder = "#d5c4a1"
        tableHeaderBg = "#fdebd0"
        bgColor = "#fffaf5"
        _refresh()
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
                    astStyle: root.markStyle
                }
            }
        }


    }

    // 根布局：用 Column 排列顶层 Block 节点
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

    ScrollBar.vertical: ScrollBar {}
    ScrollBar.horizontal: ScrollBar {}
}

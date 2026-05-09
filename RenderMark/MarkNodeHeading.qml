import QtQuick

/**
 * @brief Heading 专用渲染组件
 *
 * 内部复用 MarkRowNodeComponent 渲染行内内容。
 * 注册与定位逻辑由上层 MarkNodeComponent + RenderMark 统一管理，
 * 本组件保持纯渲染，不感知大纲预览存在。
 */
Item {
    id: root

    property var astNode: null
    property var astStyle: null
    property var cache: null
    property var renderMark: null

    function init(n, s) {
        astNode = n;
        astStyle = s;
    }

    width: row.width
    height: row.height

    MarkRowNodeComponent {
        id: row
        astNode: root.astNode
        astStyle: root.astStyle
        cache: root.cache
        renderMark: root.renderMark
    }
}

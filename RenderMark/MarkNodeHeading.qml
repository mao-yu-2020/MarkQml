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
    property var renderMark: null
    readonly property var astStyle: renderMark ? renderMark.style : null
    readonly property var cache: renderMark ? renderMark.compCache : null

    function init(n, rm) {
        astNode = n;
        renderMark = rm;
    }

    width: row.width
    height: row.height

    MarkRowNodeComponent {
        id: row
        astNode: root.astNode
        renderMark: root.renderMark
    }
}

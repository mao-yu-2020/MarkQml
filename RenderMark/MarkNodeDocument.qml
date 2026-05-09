pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 文档根节点（document）渲染组件
 *
 * 直接复用 MarkColumnNodeComponent 垂直排列子节点，
 * 标记为外层主组件以触发 documentNodeCallback。
 */
MarkColumnNodeComponent {
    _isOuterContainer: true
}

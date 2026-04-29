pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 列表项（item）渲染组件
 *
 * 左侧显示无序列表的 bullet（•）或有序列表的序号（1. 2. ...），
 * 右侧通过 MarkColumnNodeComponent 递归渲染子节点（paragraph、嵌套 list 等）。
 */
Row {
    id: root

    required property var astNode
    required property var astStyle

    spacing: 8

    // 计算当前 item 在父 list 中的索引，用于有序列表序号
    property int _itemIndex: {
        let listNode = root.astNode.parentNode;
        if (!listNode || !listNode.isList())
            return 0;
        for (let i = 0; i < listNode.children.length; ++i) {
            if (listNode.children[i] === root.astNode)
                return i;
        }
        return 0;
    }

    // 左侧标记（bullet 或 number）
    Text {
        id: marker
        color: root.astStyle.textColor
        font.pixelSize: root.astStyle.baseFontSize
        text: {
            let listNode = root.astNode.parentNode;
            if (!listNode || !listNode.isList())
                return "•";

            if (listNode.ordered) {
                let num = root._itemIndex + listNode.start;
                return num + ".";
            }

            return "•";
        }
    }

    // 右侧内容
    MarkColumnNodeComponent {
        astNode: root.astNode
        astStyle: root.astStyle
    }
}

pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief Heading 节点渲染组件
 *
 * 根据节点 level 设置不同字体大小，并拼接子节点文本内容显示。
 * 后续内联组件完善后，可替换为 Row + Repeater 递归渲染子节点。
 */
Text {
    required property var node
    required property var style

    // 临时策略：拼接所有子节点的 content 作为纯文本显示
    text: {
        let result = "";
        const children = node.children;
        for (let i = 0; i < children.length; ++i) {

            const child = children[i];
            // console.log('i = ', i, ' ctx: ', child.content, ' type: ', child.type)

            if (child && child.content !== undefined) {
                result += child.content;
            }
        }
        return result;
    }

    color: style.textColor
    font.pixelSize: {
        switch (node.level) {
        case 1: return style.baseFontSize * 2.0;
        case 2: return style.baseFontSize * 1.75;
        case 3: return style.baseFontSize * 1.5;
        case 4: return style.baseFontSize * 1.25;
        case 5: return style.baseFontSize * 1.125;
        case 6: return style.baseFontSize * 1.0;
        default: return style.baseFontSize;
        }
    }
    font.bold: true
    wrapMode: Text.Wrap
}

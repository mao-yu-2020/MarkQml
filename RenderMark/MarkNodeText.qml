pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

/**
 * @brief 文本节点（text）渲染组件
 *
 * 核心文本标签，通过遍历父节点链判断 heading 级别、粗体、斜体、
 * 下划线（链接）、删除线等样式。
 */
Label {
    id: root

    property var astNode: null
    property var astStyle: null

    function init(node, style) {
        astNode = node;
        astStyle = style;
    }

    Binding on text {
        value: root.astNode ? root.astNode.content : ""
        when: root.astNode !== null
    }

    Binding on color {
        value: {
            if (!root.astNode || !root.astStyle) return "black";
            var p = root.astNode.parentNode;
            while (p) {
                if (p.isLink && p.isLink()) return root.astStyle.linkColor;
                p = p.parentNode;
            }
            return root.astStyle.textColor;
        }
        when: root.astNode !== null && root.astStyle !== null
    }

    Binding on font.pixelSize {
        value: {
            if (!root.astNode || !root.astStyle) return 14;
            let parentNode = root.astNode.parentNode;
            if (parentNode && parentNode.isHeading && parentNode.isHeading()) {
                switch (parentNode.level) {
                case 1: return root.astStyle.baseFontSize * 2.0;
                case 2: return root.astStyle.baseFontSize * 1.75;
                case 3: return root.astStyle.baseFontSize * 1.5;
                case 4: return root.astStyle.baseFontSize * 1.25;
                case 5: return root.astStyle.baseFontSize * 1.125;
                case 6: return root.astStyle.baseFontSize * 1.0;
                }
            }
            return root.astStyle.baseFontSize;
        }
        when: root.astNode !== null && root.astStyle !== null
    }

    Binding on font.bold {
        value: {
            if (!root.astNode) return false;
            var p = root.astNode.parentNode;
            while (p) {
                if (p.isStrong && p.isStrong()) return true;
                p = p.parentNode;
            }
            return false;
        }
        when: root.astNode !== null
    }

    Binding on font.italic {
        value: {
            if (!root.astNode) return false;
            var p = root.astNode.parentNode;
            while (p) {
                if (p.isEmphasis && p.isEmphasis()) return true;
                p = p.parentNode;
            }
            return false;
        }
        when: root.astNode !== null
    }

    Binding on font.underline {
        value: {
            if (!root.astNode) return false;
            var p = root.astNode.parentNode;
            while (p) {
                if (p.isLink && p.isLink()) return true;
                p = p.parentNode;
            }
            return false;
        }
        when: root.astNode !== null
    }

    Binding on font.strikeout {
        value: {
            if (!root.astNode) return false;
            var p = root.astNode.parentNode;
            while (p) {
                if (p.isStrikethrough && p.isStrikethrough()) return true;
                p = p.parentNode;
            }
            return false;
        }
        when: root.astNode !== null
    }
}

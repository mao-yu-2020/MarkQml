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
    property var renderMark: null
    readonly property var astStyle: renderMark ? renderMark.style : null

    function init(node, rm) {
        astNode = node;
        renderMark = rm;
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
                if (p.isLink && p.isLink())             return root.astStyle.linkStyle.color;
                if (p.isStrong && p.isStrong())         return root.astStyle.strongStyle.color;
                if (p.isEmphasis && p.isEmphasis())     return root.astStyle.emphasisStyle.color;
                if (p.isCode && p.isCode())             return root.astStyle.codeStyle.color;
                if (p.isStrikethrough && p.isStrikethrough()) return root.astStyle.strikethroughStyle.color;
                p = p.parentNode;
            }
            return root.astStyle.textStyle.color;
        }
        when: root.astNode !== null && root.astStyle !== null
    }

    Binding on font.pixelSize {
        value: {
            if (!root.astNode || !root.astStyle) return 14;
            let parentNode = root.astNode.parentNode;
            if (parentNode && parentNode.isHeading && parentNode.isHeading()) {
                switch (parentNode.level) {
                    case 1: return root.astStyle.headingStyle.h1Size;
                    case 2: return root.astStyle.headingStyle.h2Size;
                    case 3: return root.astStyle.headingStyle.h3Size;
                    case 4: return root.astStyle.headingStyle.h4Size;
                    case 5: return root.astStyle.headingStyle.h5Size;
                    case 6: return root.astStyle.headingStyle.h6Size;
                }
            }
            return root.astStyle.textStyle.fontSize;
        }
        when: root.astNode !== null && root.astStyle !== null
    }

    Binding on font.bold {
        value: {
            if (!root.astNode || !root.astStyle) return false;
            var p = root.astNode.parentNode;
            while (p) {
                if (p.isStrong && p.isStrong()) return root.astStyle.strongStyle.bold;
                p = p.parentNode;
            }
            return false;
        }
        when: root.astNode !== null && root.astStyle !== null
    }

    Binding on font.italic {
        value: {
            if (!root.astNode || !root.astStyle) return false;
            var p = root.astNode.parentNode;
            while (p) {
                if (p.isEmphasis && p.isEmphasis()) return root.astStyle.emphasisStyle.italic;
                p = p.parentNode;
            }
            return false;
        }
        when: root.astNode !== null && root.astStyle !== null
    }

    Binding on font.underline {
        value: {
            if (!root.astNode || !root.astStyle) return false;
            var p = root.astNode.parentNode;
            while (p) {
                if (p.isLink && p.isLink()) return root.astStyle.linkStyle.underline;
                p = p.parentNode;
            }
            return false;
        }
        when: root.astNode !== null && root.astStyle !== null
    }

    Binding on font.strikeout {
        value: {
            if (!root.astNode || !root.astStyle) return false;
            var p = root.astNode.parentNode;
            while (p) {
                if (p.isStrikethrough && p.isStrikethrough()) return root.astStyle.strikethroughStyle.strikeout;
                p = p.parentNode;
            }
            return false;
        }
        when: root.astNode !== null && root.astStyle !== null
    }
}

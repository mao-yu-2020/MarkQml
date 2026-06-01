# RenderMark 细粒度样式重构 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 RenderMark.qml 的扁平 markStyle 重构为按节点类型划分的嵌套样式对象，并更新所有子组件以读取对应的新样式路径。

**Architecture:** 每个节点类型在 markStyle 下拥有独立的 QtObject 子对象（xxxStyle），子属性默认绑定到全局回退值（textColor / baseFontSize）。主题切换函数显式设置各子对象属性以打破绑定、实现完整配色。所有 MarkNode*.qml 中将旧样式引用迁移到新的 xxxStyle.xxx 路径。

**Tech Stack:** Qt 6 QML, CMake, MSVC 2022

---

## File Structure

| 文件 | 职责 |
|---|---|
| `RenderMark/RenderMark.qml` | markStyle 定义 + 主题切换函数 |
| `RenderMark/MarkNodeText.qml` | 文本节点颜色/字号/字重逻辑（最复杂） |
| `RenderMark/MarkNodeCode.qml` | 行内代码样式 |
| `RenderMark/MarkNodeCodeBlock.qml` | 代码块样式 |
| `RenderMark/MarkNodeBlockQuote.qml` | 引用块样式 |
| `RenderMark/MarkNodeTableCell.qml` | 表格单元格样式 |
| `RenderMark/MarkNodeThematicBreak.qml` | 分隔线样式 |
| `RenderMark/MarkNodeImage.qml` | 图片及占位符样式 |
| `RenderMark/MarkNodeItem.qml` | 列表项标记样式 |
| `RenderMark/MarkNodeHtmlBlock.qml` | HTML 块文本样式 |
| `RenderMark/MarkNodeHtmlInline.qml` | 行内 HTML 文本样式 |
| `RenderMark/MarkNodeFootnoteDefinition.qml` | 脚注定义标签样式 |
| `RenderMark/MarkNodeFootnoteReference.qml` | 脚注引用文本样式 |
| `RenderMark/MarkNodeUnknown.qml` | 未知节点文本样式 |
| `RenderMark/MarkNodeSoftbreak.qml` | 软换行文本样式 |

---

## Task 1: 重构 RenderMark.qml 的 markStyle 定义

**Files:**
- Modify: `RenderMark/RenderMark.qml:44-53`

- [ ] **Step 1: 替换 markStyle 定义**

将原有的扁平 markStyle：

```qml
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
```

替换为嵌套样式对象：

```qml
    QtObject {
        id: markStyle

        // -------------------------------------------------------------------
        // 全局回退
        // -------------------------------------------------------------------
        property color textColor: "#2c3e50"
        property int   baseFontSize: root.baseFontSize

        // -------------------------------------------------------------------
        // 行内节点样式
        // -------------------------------------------------------------------
        property QtObject textStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
        }

        property QtObject linkStyle: QtObject {
            property color color: "#3498db"
            property int   fontSize: markStyle.baseFontSize
            property bool  underline: true
        }

        property QtObject codeStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
            property color background: "#eaf2f8"
            property real  radius: 3
            property int   hPadding: 4
            property int   vPadding: 1
        }

        property QtObject strongStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
            property bool  bold: true
        }

        property QtObject emphasisStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
            property bool  italic: true
        }

        property QtObject strikethroughStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
            property bool  strikeout: true
        }

        property QtObject imageStyle: QtObject {
            property real  maxWidth: -1
            property real  maxHeight: -1
            property real  radius: 0
            property color placeholderBg: markStyle.codeStyle.background
            property color placeholderBorderColor: markStyle.tableStyle.borderColor
            property color placeholderTextColor: markStyle.textColor
            property int   placeholderFontSize: markStyle.baseFontSize
        }

        property QtObject footnoteReferenceStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
        }

        // -------------------------------------------------------------------
        // 块级节点样式
        // -------------------------------------------------------------------
        property QtObject paragraphStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
            property color background: "transparent"
            property int   topMargin: 0
            property int   bottomMargin: 8
        }

        property QtObject headingStyle: QtObject {
            property color color: markStyle.textColor
            property color background: "transparent"
            property int   h1Size: markStyle.baseFontSize * 2.0
            property int   h2Size: markStyle.baseFontSize * 1.75
            property int   h3Size: markStyle.baseFontSize * 1.5
            property int   h4Size: markStyle.baseFontSize * 1.25
            property int   h5Size: markStyle.baseFontSize * 1.125
            property int   h6Size: markStyle.baseFontSize * 1.0
            property int   topMargin: 16
            property int   bottomMargin: 8
        }

        property QtObject codeBlockStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
            property color background: "#eaf2f8"
            property color langLabelColor: markStyle.textColor
            property color langLabelBackground: Qt.rgba(0, 0, 0, 0.05)
            property real  radius: 4
            property int   padding: 12
            property int   topMargin: 8
            property int   bottomMargin: 8
        }

        property QtObject blockQuoteStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
            property color background: "#eaf2f8"
            property color borderColor: "#bdc3c7"
            property int   borderWidth: 4
            property real  radius: 4
            property int   leftPadding: 12
            property int   topMargin: 8
            property int   bottomMargin: 8
        }

        property QtObject listStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
            property color background: "transparent"
            property int   topMargin: 8
            property int   bottomMargin: 8
            property int   spacing: 4
        }

        property QtObject itemStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
            property color background: "transparent"
            property int   spacing: 2
            property int   bulletRightMargin: 8
        }

        property QtObject tableStyle: QtObject {
            property color borderColor: "#bdc3c7"
            property int   borderWidth: 1
            property color headerBg: "#d6eaf8"
            property color cellBg: "transparent"
            property int   cellPadding: 8
            property int   topMargin: 8
            property int   bottomMargin: 8
        }

        property QtObject thematicBreakStyle: QtObject {
            property color color: "#bdc3c7"
            property int   height: 2
            property int   topMargin: 16
            property int   bottomMargin: 16
        }

        // -------------------------------------------------------------------
        // 其他节点样式
        // -------------------------------------------------------------------
        property QtObject documentStyle: QtObject {
            property color background: "transparent"
            property int   padding: 0
        }

        property QtObject htmlBlockStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
        }

        property QtObject htmlInlineStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
        }

        property QtObject footnoteDefinitionStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
        }

        property QtObject softbreakStyle: QtObject { }
        property QtObject linebreakStyle: QtObject { }
        property QtObject unknownStyle: QtObject {
            property color color: markStyle.textColor
            property int   fontSize: markStyle.baseFontSize
        }
    }
```

- [ ] **Step 2: Commit**

```bash
git add RenderMark/RenderMark.qml
git commit -m "refactor: restructure markStyle into per-node QtObject styles"
```

---

## Task 2: 更新主题切换函数

**Files:**
- Modify: `RenderMark/RenderMark.qml:180-218`

- [ ] **Step 1: 重写 setLightTheme**

将 `setLightTheme()` 替换为：

```qml
    function setLightTheme() {
        markStyle.textColor = "#1a1a2e"
        markStyle.baseFontSize = 14

        markStyle.textStyle.color = "#1a1a2e"
        markStyle.linkStyle.color = "#2563eb"
        markStyle.codeStyle.background = "#f1f5f9"
        markStyle.strongStyle.color = "#1a1a2e"
        markStyle.emphasisStyle.color = "#1a1a2e"
        markStyle.strikethroughStyle.color = "#1a1a2e"
        markStyle.imageStyle.placeholderBg = "#f1f5f9"
        markStyle.imageStyle.placeholderBorderColor = "#cbd5e1"
        markStyle.imageStyle.placeholderTextColor = "#1a1a2e"

        markStyle.paragraphStyle.color = "#1a1a2e"
        markStyle.headingStyle.color = "#1a1a2e"
        markStyle.codeBlockStyle.background = "#f1f5f9"
        markStyle.codeBlockStyle.color = "#1a1a2e"
        markStyle.blockQuoteStyle.background = "#f1f5f9"
        markStyle.blockQuoteStyle.borderColor = "#3b82f6"
        markStyle.tableStyle.borderColor = "#cbd5e1"
        markStyle.tableStyle.headerBg = "#e2e8f0"
        markStyle.thematicBreakStyle.color = "#cbd5e1"

        bgColor = "#ffffff"
    }
```

- [ ] **Step 2: 重写 setDarkTheme**

将 `setDarkTheme()` 替换为：

```qml
    function setDarkTheme() {
        markStyle.textColor = "#f1f5f9"
        markStyle.baseFontSize = 14

        markStyle.textStyle.color = "#f1f5f9"
        markStyle.linkStyle.color = "#60a5fa"
        markStyle.codeStyle.background = "#27272a"
        markStyle.strongStyle.color = "#f1f5f9"
        markStyle.emphasisStyle.color = "#f1f5f9"
        markStyle.strikethroughStyle.color = "#f1f5f9"
        markStyle.imageStyle.placeholderBg = "#27272a"
        markStyle.imageStyle.placeholderBorderColor = "#52525b"
        markStyle.imageStyle.placeholderTextColor = "#f1f5f9"

        markStyle.paragraphStyle.color = "#f1f5f9"
        markStyle.headingStyle.color = "#f1f5f9"
        markStyle.codeBlockStyle.background = "#27272a"
        markStyle.codeBlockStyle.color = "#f1f5f9"
        markStyle.blockQuoteStyle.background = "#18181b"
        markStyle.blockQuoteStyle.borderColor = "#a78bfa"
        markStyle.tableStyle.borderColor = "#52525b"
        markStyle.tableStyle.headerBg = "#18181b"
        markStyle.thematicBreakStyle.color = "#52525b"

        bgColor = "#0a0a0f"
    }
```

- [ ] **Step 3: 重写 setColdTheme**

将 `setColdTheme()` 替换为：

```qml
    function setColdTheme() {
        markStyle.textColor = "#0c4a6e"
        markStyle.baseFontSize = 14

        markStyle.textStyle.color = "#0c4a6e"
        markStyle.linkStyle.color = "#0891b2"
        markStyle.codeStyle.background = "#ecfeff"
        markStyle.strongStyle.color = "#0c4a6e"
        markStyle.emphasisStyle.color = "#0c4a6e"
        markStyle.strikethroughStyle.color = "#0c4a6e"
        markStyle.imageStyle.placeholderBg = "#ecfeff"
        markStyle.imageStyle.placeholderBorderColor = "#7dd3fc"
        markStyle.imageStyle.placeholderTextColor = "#0c4a6e"

        markStyle.paragraphStyle.color = "#0c4a6e"
        markStyle.headingStyle.color = "#0c4a6e"
        markStyle.codeBlockStyle.background = "#ecfeff"
        markStyle.codeBlockStyle.color = "#0c4a6e"
        markStyle.blockQuoteStyle.background = "#ecfeff"
        markStyle.blockQuoteStyle.borderColor = "#22d3ee"
        markStyle.tableStyle.borderColor = "#7dd3fc"
        markStyle.tableStyle.headerBg = "#bae6fd"
        markStyle.thematicBreakStyle.color = "#7dd3fc"

        bgColor = "#f0f9ff"
    }
```

- [ ] **Step 4: 重写 setWarmTheme**

将 `setWarmTheme()` 替换为：

```qml
    function setWarmTheme() {
        markStyle.textColor = "#431407"
        markStyle.baseFontSize = 14

        markStyle.textStyle.color = "#431407"
        markStyle.linkStyle.color = "#ea580c"
        markStyle.codeStyle.background = "#ffedd5"
        markStyle.strongStyle.color = "#431407"
        markStyle.emphasisStyle.color = "#431407"
        markStyle.strikethroughStyle.color = "#431407"
        markStyle.imageStyle.placeholderBg = "#ffedd5"
        markStyle.imageStyle.placeholderBorderColor = "#fdba74"
        markStyle.imageStyle.placeholderTextColor = "#431407"

        markStyle.paragraphStyle.color = "#431407"
        markStyle.headingStyle.color = "#431407"
        markStyle.codeBlockStyle.background = "#ffedd5"
        markStyle.codeBlockStyle.color = "#431407"
        markStyle.blockQuoteStyle.background = "#ffedd5"
        markStyle.blockQuoteStyle.borderColor = "#f97316"
        markStyle.tableStyle.borderColor = "#fdba74"
        markStyle.tableStyle.headerBg = "#fed7aa"
        markStyle.thematicBreakStyle.color = "#fdba74"

        bgColor = "#fff7ed"
    }
```

- [ ] **Step 5: Commit**

```bash
git add RenderMark/RenderMark.qml
git commit -m "refactor: update theme functions to set per-node styles"
```

---

## Task 3: 重构 MarkNodeText.qml

**Files:**
- Modify: `RenderMark/MarkNodeText.qml`

- [ ] **Step 1: 更新颜色绑定**

将 `Binding on color`（约第 29-40 行）替换为：

```qml
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
```

- [ ] **Step 2: 更新字号绑定**

将 `Binding on font.pixelSize`（约第 42-59 行）替换为：

```qml
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
```

- [ ] **Step 3: 更新字重绑定**

将 `Binding on font.bold`（约第 61-72 行）替换为：

```qml
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
```

- [ ] **Step 4: 更新斜体绑定**

将 `Binding on font.italic`（约第 74-85 行）替换为：

```qml
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
```

- [ ] **Step 5: 更新下划线绑定**

将 `Binding on font.underline`（约第 87-98 行）替换为：

```qml
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
```

- [ ] **Step 6: 更新删除线绑定**

将 `Binding on font.strikeout`（约第 100-111 行）替换为：

```qml
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
```

- [ ] **Step 7: Commit**

```bash
git add RenderMark/MarkNodeText.qml
git commit -m "refactor: MarkNodeText reads per-node styles from xxxStyle objects"
```

---

## Task 4: 重构 MarkNodeCode.qml

**Files:**
- Modify: `RenderMark/MarkNodeCode.qml`

- [ ] **Step 1: 替换样式引用**

将文件内容替换为：

```qml
pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 行内代码（code）渲染组件
 *
 * 等宽字体、带背景色圆角矩形，用于渲染 `inline code` 节点。
 */
Rectangle {
    id: root

    property var astNode: null
    property var renderMark: null
    readonly property var astStyle: renderMark ? renderMark.style : null

    function init(node, rm) {
        astNode = node;
        renderMark = rm;
    }

    Binding on color {
        value: root.astStyle.codeStyle.background
        when: root.astStyle !== null
    }
    Binding on radius {
        value: root.astStyle ? root.astStyle.codeStyle.radius : 3
        when: root.astStyle !== null
    }

    implicitWidth: textItem.implicitWidth + root.astStyle.codeStyle.hPadding * 2
    implicitHeight: textItem.implicitHeight + root.astStyle.codeStyle.vPadding * 2

    Text {
        id: textItem
        anchors.centerIn: parent
        Binding on text {
            value: root.astNode ? root.astNode.content : ""
            when: root.astNode !== null
        }
        Binding on color {
            value: root.astStyle.codeStyle.color
            when: root.astStyle !== null
        }
        Binding on font.pixelSize {
            value: root.astStyle.codeStyle.fontSize
            when: root.astStyle !== null
        }
        font.family: "Consolas, Courier New, monospace"
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add RenderMark/MarkNodeCode.qml
git commit -m "refactor: MarkNodeCode reads from codeStyle"
```

---

## Task 5: 重构 MarkNodeCodeBlock.qml

**Files:**
- Modify: `RenderMark/MarkNodeCodeBlock.qml`

- [ ] **Step 1: 替换样式引用**

将文件内容替换为：

```qml
pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 代码块（code_block）渲染组件
 *
 * 带背景色的块级代码区域，支持显示语言标识。
 * 四周保留 padding 内边距，语言标签以 pill 样式呈现。
 */
Rectangle {
    id: root

    property var astNode: null
    property var renderMark: null
    readonly property var astStyle: renderMark ? renderMark.style : null

    function init(node, rm) {
        astNode = node;
        renderMark = rm;
    }

    Binding on color {
        value: root.astStyle.codeBlockStyle.background
        when: root.astStyle !== null
    }
    Binding on radius {
        value: root.astStyle ? root.astStyle.codeBlockStyle.radius : 4
        when: root.astStyle !== null
    }

    width: contentColumn.implicitWidth + root.astStyle.codeBlockStyle.padding * 2
    height: contentColumn.implicitHeight + root.astStyle.codeBlockStyle.padding * 2

    Column {
        id: contentColumn
        x: root.astStyle ? root.astStyle.codeBlockStyle.padding : 12
        y: root.astStyle ? root.astStyle.codeBlockStyle.padding : 12
        spacing: 8

        // 语言标签 pill
        Rectangle {
            visible: root.astNode ? root.astNode.language !== "" : false
            width: langLabel.implicitWidth + 16
            height: langLabel.implicitHeight + 8
            radius: 4

            Binding on color {
                value: root.astStyle.codeBlockStyle.langLabelBackground
                when: root.astStyle !== null
            }

            Text {
                id: langLabel
                anchors.centerIn: parent
                Binding on text {
                    value: root.astNode ? root.astNode.language : ""
                    when: root.astNode !== null
                }
                Binding on color {
                    value: root.astStyle.codeBlockStyle.langLabelColor
                    when: root.astStyle !== null
                }
                Binding on font.pixelSize {
                    value: root.astStyle.codeBlockStyle.fontSize * 0.8
                    when: root.astStyle !== null
                }
                font.family: "Consolas, Courier New, monospace"
            }
        }

        Text {
            Binding on text {
                value: root.astNode ? root.astNode.content : ""
                when: root.astNode !== null
            }
            Binding on color {
                value: root.astStyle.codeBlockStyle.color
                when: root.astStyle !== null
            }
            Binding on font.pixelSize {
                value: root.astStyle.codeBlockStyle.fontSize
                when: root.astStyle !== null
            }
            font.family: "Consolas, Courier New, monospace"
            wrapMode: Text.Wrap
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add RenderMark/MarkNodeCodeBlock.qml
git commit -m "refactor: MarkNodeCodeBlock reads from codeBlockStyle"
```

---

## Task 6: 重构 MarkNodeBlockQuote.qml

**Files:**
- Modify: `RenderMark/MarkNodeBlockQuote.qml`

- [ ] **Step 1: 替换样式引用**

将文件内容替换为：

```qml
pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 引用块（block_quote）渲染组件
 *
 * 左侧带竖线标识，背景使用 blockQuoteStyle.background，内部垂直排列子节点。
 */
Rectangle {
    id: root

    property var astNode: null
    readonly property var astStyle: renderMark ? renderMark.style : null
    readonly property var cache: renderMark ? renderMark.compCache : null
    property var renderMark: null

    function init(node, rm) {
        astNode = node;
        renderMark = rm;
    }

    Binding on color {
        value: root.astStyle.blockQuoteStyle.background
        when: root.astStyle !== null
    }
    Binding on radius {
        value: root.astStyle ? root.astStyle.blockQuoteStyle.radius : 4
        when: root.astStyle !== null
    }

    width: leftBar.width + contentColumn.implicitWidth + root.astStyle.blockQuoteStyle.leftPadding
    height: contentColumn.implicitHeight

    // 左侧竖线
    Rectangle {
        id: leftBar
        width: root.astStyle.blockQuoteStyle.borderWidth
        height: root.height
        Binding on color {
            value: root.astStyle.blockQuoteStyle.borderColor
            when: root.astStyle !== null
        }
        radius: 2
    }

    // 内容区域
    MarkColumnNodeComponent {
        id: contentColumn
        anchors.left: leftBar.right
        anchors.top: parent.top
        anchors.leftMargin: root.astStyle.blockQuoteStyle.leftPadding
        astNode: root.astNode
        renderMark: root.renderMark
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add RenderMark/MarkNodeBlockQuote.qml
git commit -m "refactor: MarkNodeBlockQuote reads from blockQuoteStyle"
```

---

## Task 7: 重构 MarkNodeTableCell.qml

**Files:**
- Modify: `RenderMark/MarkNodeTableCell.qml`

- [ ] **Step 1: 替换样式引用**

将文件内容替换为：

```qml
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

/**
 * @brief 表格单元格（table_cell）渲染组件
 *
 * 带边框的矩形区域，内部通过 MarkRowNodeComponent 渲染行内内容。
 * 在 GridLayout 中使用，Layout.fillWidth 保证列宽对齐。
 */
Rectangle {
    id: root

    property var astNode: null
    property var renderMark: null
    readonly property var astStyle: renderMark ? renderMark.style : null
    readonly property var cache: renderMark ? renderMark.compCache : null
    property bool isHeaderRow: false

    function init(node, rm) {
        astNode = node;
        renderMark = rm;
    }

    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitWidth: cellContent.implicitWidth + root.astStyle.tableStyle.cellPadding * 2
    implicitHeight: cellContent.implicitHeight + root.astStyle.tableStyle.cellPadding * 2

    Binding on color {
        value: root.isHeaderRow ? root.astStyle.tableStyle.headerBg : root.astStyle.tableStyle.cellBg
        when: root.astStyle !== null
    }
    Binding on border.color {
        value: root.astStyle.tableStyle.borderColor
        when: root.astStyle !== null
    }
    Binding on border.width {
        value: root.astStyle ? root.astStyle.tableStyle.borderWidth : 1
        when: root.astStyle !== null
    }

    MarkRowNodeComponent {
        id: cellContent
        x: root.astStyle.tableStyle.cellPadding
        y: root.astStyle.tableStyle.cellPadding
        astNode: root.astNode
        renderMark: root.renderMark
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add RenderMark/MarkNodeTableCell.qml
git commit -m "refactor: MarkNodeTableCell reads from tableStyle"
```

---

## Task 8: 重构 MarkNodeThematicBreak.qml

**Files:**
- Modify: `RenderMark/MarkNodeThematicBreak.qml`

- [ ] **Step 1: 替换样式引用**

将文件内容替换为：

```qml
pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 主题分隔线（thematic_break）渲染组件
 *
 * 一条占满容器宽度的水平分割线。
 */
Rectangle {
    id: root

    property var astNode: null
    property var renderMark: null
    readonly property var astStyle: renderMark ? renderMark.style : null

    function init(node, rm) {
        astNode = node;
        renderMark = rm;
    }

    Binding on color {
        value: root.astStyle.thematicBreakStyle.color
        when: root.astStyle !== null
    }
    Binding on height {
        value: root.astStyle ? root.astStyle.thematicBreakStyle.height : 2
        when: root.astStyle !== null
    }

    width: parent && parent.parent ? parent.parent.width : 0
}
```

- [ ] **Step 2: Commit**

```bash
git add RenderMark/MarkNodeThematicBreak.qml
git commit -m "refactor: MarkNodeThematicBreak reads from thematicBreakStyle"
```

---

## Task 9: 重构 MarkNodeImage.qml

**Files:**
- Modify: `RenderMark/MarkNodeImage.qml`

- [ ] **Step 1: 替换样式引用**

将文件内容替换为：

```qml
pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief 图片（image）渲染组件
 *
 * 加载并显示图片，限制最大宽度为 600px（可通过 imageStyle.maxWidth 覆盖）。
 * 本地路径自动补全 file:/// 前缀。
 * 加载失败时显示占位提示。
 */
Item {
    id: root

    property var astNode: null
    property var renderMark: null
    readonly property var astStyle: renderMark ? renderMark.style : null

    function init(node, rm) {
        astNode = node;
        renderMark = rm;
    }

    Binding on width {
        value: {
            if (!root.astNode) return 0;
            return image.status === Image.Ready ? image.implicitWidth : 400;
        }
        when: root.astNode !== null
    }

    Binding on height {
        value: {
            if (!root.astNode) return 0;
            return image.status === Image.Ready ? image.implicitHeight : 200;
        }
        when: root.astNode !== null
    }

    Image {
        id: image
        x: 0
        y: 0
        fillMode: Image.PreserveAspectFit
        sourceSize.width: {
            var mw = root.astStyle ? root.astStyle.imageStyle.maxWidth : -1;
            return mw > 0 ? mw : 600;
        }

        Binding on source {
            value: {
                if (!root.astNode) return "";
                var url = root.astNode.url;

                if (url.indexOf("://") === -1) {

                    if (root.renderMark && root.renderMark.baseUrl) {
                        var base = root.renderMark.baseUrl.toString();
                        if (base.charAt(base.length - 1) !== "/") base += "/";
                        url = base + url.replace(/\\/g, "/");
                    } else {
                        url = "file:///" + url.replace(/\\/g, "/");
                    }
                }
                return url;
            }
            when: root.astNode !== null
        }

        onStatusChanged: {
            if (status === Image.Error && root.astNode) {
                console.log("Failed to load image:", root.astNode.url);
            }
        }
    }

    Rectangle {
        id: placeholderRect
        visible: image.status !== Image.Ready
        anchors.fill: parent
        Binding on color {
            value: root.astStyle.imageStyle.placeholderBg
            when: root.astStyle !== null
        }
        Binding on border.color {
            value: root.astStyle.imageStyle.placeholderBorderColor
            when: root.astStyle !== null
        }
        border.width: 1
        radius: root.astStyle ? root.astStyle.imageStyle.radius : 0

        Column {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: image.status === Image.Loading ? "加载中..." : "图片加载失败"
                Binding on color {
                    value: root.astStyle.imageStyle.placeholderTextColor
                    when: root.astStyle !== null
                }
                Binding on font.pixelSize {
                    value: root.astStyle.imageStyle.placeholderFontSize
                    when: root.astStyle !== null
                }
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: root.astNode ? root.astNode.url : ""
                Binding on color {
                    value: root.astStyle.imageStyle.placeholderTextColor
                    when: root.astStyle !== null
                }
                Binding on font.pixelSize {
                    value: root.astStyle.imageStyle.placeholderFontSize * 0.75
                    when: root.astStyle !== null
                }
                opacity: 0.6
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.parent.width - 32
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add RenderMark/MarkNodeImage.qml
git commit -m "refactor: MarkNodeImage reads from imageStyle"
```

---

## Task 10: 重构 MarkNodeItem.qml

**Files:**
- Modify: `RenderMark/MarkNodeItem.qml`

- [ ] **Step 1: 替换样式引用**

将文件内容替换为：

```qml
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

    property var astNode: null
    readonly property var astStyle: renderMark ? renderMark.style : null
    readonly property var cache: renderMark ? renderMark.compCache : null
    property var renderMark: null

    function init(node, rm) {
        astNode = node;
        renderMark = rm;
    }

    spacing: root.astStyle ? root.astStyle.itemStyle.bulletRightMargin : 8

    // 计算当前 item 在父 list 中的索引，用于有序列表序号
    property int _itemIndex: {
        if (!root.astNode) return 0;
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
        Binding on text {
            value: {
                if (!root.astNode) return "•";
                let listNode = root.astNode.parentNode;
                if (!listNode || !listNode.isList())
                    return "•";
                if (listNode.ordered) {
                    let num = root._itemIndex + listNode.start;
                    return num + ".";
                }
                return "•";
            }
            when: root.astNode !== null
        }
        Binding on color {
            value: root.astStyle.itemStyle.color
            when: root.astStyle !== null
        }
        Binding on font.pixelSize {
            value: root.astStyle.itemStyle.fontSize
            when: root.astStyle !== null
        }
    }

    // 右侧内容
    MarkColumnNodeComponent {
        astNode: root.astNode
        renderMark: root.renderMark
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add RenderMark/MarkNodeItem.qml
git commit -m "refactor: MarkNodeItem reads from itemStyle"
```

---

## Task 11: 重构简单文本节点

**Files:**
- Modify: `RenderMark/MarkNodeHtmlBlock.qml`
- Modify: `RenderMark/MarkNodeHtmlInline.qml`
- Modify: `RenderMark/MarkNodeFootnoteDefinition.qml`
- Modify: `RenderMark/MarkNodeFootnoteReference.qml`
- Modify: `RenderMark/MarkNodeUnknown.qml`
- Modify: `RenderMark/MarkNodeSoftbreak.qml`

- [ ] **Step 1: 更新 MarkNodeHtmlBlock.qml**

将第 29-37 行的样式绑定替换为：

```qml
    Binding on color {
        value: root.astStyle.htmlBlockStyle.color
        when: root.astStyle !== null
    }

    Binding on font.pixelSize {
        value: root.astStyle.htmlBlockStyle.fontSize
        when: root.astStyle !== null
    }
```

- [ ] **Step 2: 更新 MarkNodeHtmlInline.qml**

将第 29-37 行的样式绑定替换为：

```qml
    Binding on color {
        value: root.astStyle.htmlInlineStyle.color
        when: root.astStyle !== null
    }

    Binding on font.pixelSize {
        value: root.astStyle.htmlInlineStyle.fontSize
        when: root.astStyle !== null
    }
```

- [ ] **Step 3: 更新 MarkNodeFootnoteDefinition.qml**

将第 30-37 行的样式绑定替换为：

```qml
        Binding on color {
            value: root.astStyle.footnoteDefinitionStyle.color
            when: root.astStyle !== null
        }
        Binding on font.pixelSize {
            value: root.astStyle.footnoteDefinitionStyle.fontSize * 0.85
            when: root.astStyle !== null
        }
```

- [ ] **Step 4: 更新 MarkNodeFootnoteReference.qml**

将第 27-35 行的样式绑定替换为：

```qml
    Binding on color {
        value: root.astStyle.footnoteReferenceStyle.color
        when: root.astStyle !== null
    }

    Binding on font.pixelSize {
        value: root.astStyle.footnoteReferenceStyle.fontSize * 0.75
        when: root.astStyle !== null
    }
```

- [ ] **Step 5: 更新 MarkNodeUnknown.qml**

将第 27-35 行的样式绑定替换为：

```qml
    Binding on color {
        value: root.astStyle.unknownStyle.color
        when: root.astStyle !== null
    }

    Binding on font.pixelSize {
        value: root.astStyle.unknownStyle.fontSize
        when: root.astStyle !== null
    }
```

- [ ] **Step 6: 更新 MarkNodeSoftbreak.qml**

将第 24-32 行的样式绑定替换为：

```qml
    Binding on color {
        value: root.astStyle.textStyle.color
        when: root.astStyle !== null
    }

    Binding on font.pixelSize {
        value: root.astStyle.textStyle.fontSize
        when: root.astStyle !== null
    }
```

- [ ] **Step 7: Commit**

```bash
git add RenderMark/MarkNodeHtmlBlock.qml RenderMark/MarkNodeHtmlInline.qml RenderMark/MarkNodeFootnoteDefinition.qml RenderMark/MarkNodeFootnoteReference.qml RenderMark/MarkNodeUnknown.qml RenderMark/MarkNodeSoftbreak.qml
git commit -m "refactor: simple text nodes read from corresponding xxxStyle objects"
```

---

## Task 12: 编译验证与主题切换测试

**Files:**
- Test: 运行程序验证所有节点渲染正常

- [ ] **Step 1: 编译项目**

运行：
```bash
cd D:\jie_code\MarkQml\build
# 如果有 CMake 缓存，直接构建
cmake --build . --config Debug
```

Expected: 编译成功，无 QML 属性未找到的错误。

- [ ] **Step 2: 运行程序并验证默认主题**

运行生成的可执行文件（如 `Debug\appMarkQml.exe`），检查：
- 文本、粗体、斜体、链接、行内代码颜色正常
- 代码块背景色和语言标签正常
- 引用块左侧竖线和背景正常
- 表格边框和表头背景正常
- 分隔线颜色正常
- 图片占位符背景/边框/文字正常
- 列表 bullet/序号颜色和间距正常

- [ ] **Step 3: 验证主题切换**

依次点击界面上的 **亮色 / 暗色 / 冷色 / 暖色** 按钮，检查：
- 所有节点颜色随主题正确变化
- 无节点保持旧颜色（说明旧属性引用已清除干净）
- 无 QML Binding 警告输出到控制台

- [ ] **Step 4: Commit 最终确认**

```bash
git commit --allow-empty -m "chore: verify fine-grained styles compile and theme switching works"
```

---

## Self-Review Checklist

**1. Spec coverage:**
- [x] markStyle 重构为嵌套 QtObject — Task 1
- [x] 主题切换函数更新 — Task 2
- [x] MarkNodeText 颜色/字号/字重绑定 — Task 3
- [x] MarkNodeCode/CodeBlock 样式 — Task 4, 5
- [x] MarkNodeBlockQuote 样式 — Task 6
- [x] MarkNodeTableCell 样式 — Task 7
- [x] MarkNodeThematicBreak 样式 — Task 8
- [x] MarkNodeImage 样式 — Task 9
- [x] MarkNodeItem 样式 — Task 10
- [x] 简单文本节点样式 — Task 11
- [x] 编译与主题切换验证 — Task 12

**2. Placeholder scan:**
- [x] 无 "TBD", "TODO", "implement later"
- [x] 每个代码块包含完整可替换内容
- [x] 无 "Similar to Task N"

**3. Type consistency:**
- [x] 所有 `xxxStyle` 命名与 spec 一致
- [x] 属性访问路径统一为 `astStyle.xxxStyle.xxx`
- [x] 主题函数中设置的属性名与 markStyle 定义一致

# RenderMark 细粒度节点样式设计

## 1. 背景与目标

目前 `RenderMark.qml` 中的 `markStyle` 是一个扁平的 `QtObject`，仅提供 7 个通用样式属性（`textColor`、`linkColor`、`codeBackground` 等）。所有节点组件（`MarkNodeText`、`MarkNodeCodeBlock`、`MarkNodeHeading` 等）共用这些属性，导致：

- 无法为不同节点类型单独设置颜色、字号、背景色、边距等。
- 主题切换时只能全局调整，不能针对特定节点做差异化配色。

**目标**：将 `markStyle` 重构为按节点类型划分的嵌套样式对象，实现每个 Markdown 节点拥有独立的样式命名空间。

---

## 2. 架构设计

### 2.1 核心思路

- `markStyle` 下每个节点类型对应一个 `QtObject` 子对象，命名规范为 `<nodeType>Style`（如 `textStyle`、`headingStyle`、`codeBlockStyle`）。
- 子对象的属性默认**绑定**到全局回退值（`textColor`、`baseFontSize`）。日常改主题时，大部分节点会自动跟随全局值变化。
- 任何节点都可以被**单独覆盖**。一旦对某个子对象的属性显式赋值，该属性将脱离绑定，不再受全局值影响。

### 2.2 访问路径示例

```qml
// 读取 heading 的 H1 字号
renderMark.style.headingStyle.h1Size

// 单独覆盖代码块背景（不影响其他节点）
renderMark.style.codeBlockStyle.background = "#1e1e1e"

// 修改全局文本颜色，所有未覆盖的 text 节点自动跟随
renderMark.style.textColor = "#f1f5f9"
```

---

## 3. markStyle 完整定义

### 3.1 全局回退属性

保留两个顶层属性作为总开关，其余旧属性（`linkColor`、`codeBackground` 等）全部移除：

| 属性 | 类型 | 默认值 | 说明 |
|---|---|---|---|
| `textColor` | `color` | `"#2c3e50"` | 全局默认文本颜色 |
| `baseFontSize` | `int` | `14` | 全局默认字号 |

### 3.2 行内节点样式

| 子对象名 | 属性 | 类型 | 默认值 | 说明 |
|---|---|---|---|---|
| `textStyle` | `color` | `color` | `markStyle.textColor` | 普通文本颜色 |
| | `fontSize` | `int` | `markStyle.baseFontSize` | 普通文本字号 |
| `linkStyle` | `color` | `color` | `"#3498db"` | 链接文本颜色 |
| | `fontSize` | `int` | `markStyle.baseFontSize` | 链接字号 |
| | `underline` | `bool` | `true` | 是否带下划线 |
| `codeStyle` | `color` | `color` | `markStyle.textColor` | 行内代码颜色 |
| | `fontSize` | `int` | `markStyle.baseFontSize` | 行内代码字号 |
| | `background` | `color` | `"#eaf2f8"` | 行内代码背景 |
| | `radius` | `real` | `3` | 背景圆角 |
| | `hPadding` | `int` | `4` | 水平内边距 |
| | `vPadding` | `int` | `1` | 垂直内边距 |
| `strongStyle` | `color` | `color` | `markStyle.textColor` | 粗体颜色 |
| | `fontSize` | `int` | `markStyle.baseFontSize` | 粗体字号 |
| | `bold` | `bool` | `true` | 是否粗体 |
| `emphasisStyle` | `color` | `color` | `markStyle.textColor` | 斜体颜色 |
| | `fontSize` | `int` | `markStyle.baseFontSize` | 斜体字号 |
| | `italic` | `bool` | `true` | 是否斜体 |
| `strikethroughStyle` | `color` | `color` | `markStyle.textColor` | 删除线颜色 |
| | `fontSize` | `int` | `markStyle.baseFontSize` | 删除线字号 |
| | `strikeout` | `bool` | `true` | 是否删除线 |
| `imageStyle` | `maxWidth` | `real` | `-1` | 最大宽度（-1 不限） |
| | `maxHeight` | `real` | `-1` | 最大高度 |
| | `radius` | `real` | `0` | 图片圆角 |
| `footnoteReferenceStyle` | `color` | `color` | `markStyle.textColor` | 脚注引用颜色 |
| | `fontSize` | `int` | `markStyle.baseFontSize` | 脚注引用字号 |

### 3.3 块级节点样式

| 子对象名 | 属性 | 类型 | 默认值 | 说明 |
|---|---|---|---|---|
| `paragraphStyle` | `color` | `color` | `markStyle.textColor` | 段落文本颜色 |
| | `fontSize` | `int` | `markStyle.baseFontSize` | 段落字号 |
| | `background` | `color` | `"transparent"` | 段落背景 |
| | `topMargin` | `int` | `0` | 上边距 |
| | `bottomMargin` | `int` | `8` | 下边距 |
| `headingStyle` | `color` | `color` | `markStyle.textColor` | 标题文本颜色 |
| | `background` | `color` | `"transparent"` | 标题背景 |
| | `h1Size` | `int` | `baseFontSize * 2.0` | H1 字号 |
| | `h2Size` | `int` | `baseFontSize * 1.75` | H2 字号 |
| | `h3Size` | `int` | `baseFontSize * 1.5` | H3 字号 |
| | `h4Size` | `int` | `baseFontSize * 1.25` | H4 字号 |
| | `h5Size` | `int` | `baseFontSize * 1.125` | H5 字号 |
| | `h6Size` | `int` | `baseFontSize * 1.0` | H6 字号 |
| | `topMargin` | `int` | `16` | 上边距 |
| | `bottomMargin` | `int` | `8` | 下边距 |
| `codeBlockStyle` | `color` | `color` | `markStyle.textColor` | 代码块文本颜色 |
| | `fontSize` | `int` | `markStyle.baseFontSize` | 代码块字号 |
| | `background` | `color` | `"#eaf2f8"` | 代码块背景 |
| | `langLabelColor` | `color` | `markStyle.textColor` | 语言标签颜色 |
| | `langLabelBackground` | `color` | `Qt.rgba(0,0,0,0.05)` | 语言标签背景 |
| | `radius` | `real` | `4` | 代码块圆角 |
| | `padding` | `int` | `12` | 内边距 |
| | `topMargin` | `int` | `8` | 上边距 |
| | `bottomMargin` | `int` | `8` | 下边距 |
| `blockQuoteStyle` | `color` | `color` | `markStyle.textColor` | 引用块文本颜色 |
| | `fontSize` | `int` | `markStyle.baseFontSize` | 引用块字号 |
| | `background` | `color` | `"#eaf2f8"` | 引用块背景 |
| | `borderColor` | `color` | `"#bdc3c7"` | 左边框颜色 |
| | `borderWidth` | `int` | `4` | 左边框宽度 |
| | `radius` | `real` | `4` | 圆角 |
| | `leftPadding` | `int` | `12` | 内容左偏移 |
| | `topMargin` | `int` | `8` | 上边距 |
| | `bottomMargin` | `int` | `8` | 下边距 |
| `listStyle` | `color` | `color` | `markStyle.textColor` | 列表文本颜色 |
| | `fontSize` | `int` | `markStyle.baseFontSize` | 列表字号 |
| | `background` | `color` | `"transparent"` | 列表背景 |
| | `topMargin` | `int` | `8` | 上边距 |
| | `bottomMargin` | `int` | `8` | 下边距 |
| | `spacing` | `int` | `4` | 列表项之间间距 |
| `itemStyle` | `color` | `color` | `markStyle.textColor` | 列表项文本颜色 |
| | `fontSize` | `int` | `markStyle.baseFontSize` | 列表项字号 |
| | `background` | `color` | `"transparent"` | 列表项背景 |
| | `spacing` | `int` | `2` | 列表项内部行间距 |
| | `bulletRightMargin` | `int` | `8` | 列表符号与内容间距 |
| `tableStyle` | `borderColor` | `color` | `"#bdc3c7"` | 边框颜色 |
| | `borderWidth` | `int` | `1` | 边框宽度 |
| | `headerBg` | `color` | `"#d6eaf8"` | 表头背景 |
| | `cellBg` | `color` | `"transparent"` | 普通单元格背景 |
| | `cellPadding` | `int` | `8` | 单元格内边距 |
| | `topMargin` | `int` | `8` | 上边距 |
| | `bottomMargin` | `int` | `8` | 下边距 |
| `thematicBreakStyle` | `color` | `color` | `"#bdc3c7"` | 分隔线颜色 |
| | `height` | `int` | `2` | 分隔线高度 |
| | `topMargin` | `int` | `16` | 上边距 |
| | `bottomMargin` | `int` | `16` | 下边距 |

### 3.4 其他节点样式

以下节点当前渲染逻辑较简单，为其预留统一的样式对象，方便后续扩展：

```qml
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
```

---

## 4. 节点组件修改点

所有 `MarkNode*.qml` 文件中通过 `astStyle.xxx` 访问旧样式的地方，都需要改为读取对应的 `astStyle.xxxStyle.xxx`。

### 4.1 MarkNodeText（重点修改）

`MarkNodeText` 是目前样式逻辑最复杂的组件，需要更新以下绑定：

**颜色绑定**：遍历父节点链，按父节点类型匹配对应的 `xxxStyle.color`：

```qml
Binding on color {
    value: {
        if (!root.astNode || !root.astStyle) return "black";
        var p = root.astNode.parentNode;
        while (p) {
            if (p.isLink && p.isLink())         return root.astStyle.linkStyle.color;
            if (p.isStrong && p.isStrong())     return root.astStyle.strongStyle.color;
            if (p.isEmphasis && p.isEmphasis()) return root.astStyle.emphasisStyle.color;
            if (p.isCode && p.isCode())         return root.astStyle.codeStyle.color;
            if (p.isStrikethrough && p.isStrikethrough()) return root.astStyle.strikethroughStyle.color;
            p = p.parentNode;
        }
        return root.astStyle.textStyle.color;
    }
    when: root.astNode !== null && root.astStyle !== null
}
```

**字号绑定**：检测到父节点为 `heading` 时，改读 `headingStyle.hXSize`：

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

### 4.2 其他子组件修改清单

| 文件 | 修改内容 |
|---|---|
| `MarkNodeCodeBlock.qml` | `astStyle.codeBackground` → `astStyle.codeBlockStyle.background`；`astStyle.textColor` → `astStyle.codeBlockStyle.color`；`astStyle.baseFontSize` → `astStyle.codeBlockStyle.fontSize`；语言标签样式改读 `codeBlockStyle.langLabelColor` / `langLabelBackground` |
| `MarkNodeBlockQuote.qml` | `astStyle.codeBackground` → `astStyle.blockQuoteStyle.background`；`astStyle.blockQuoteBorder` → `astStyle.blockQuoteStyle.borderColor` |
| `MarkNodeTableCell.qml` | `astStyle.tableHeaderBg` → `astStyle.tableStyle.headerBg`；`astStyle.tableBorder` → `astStyle.tableStyle.borderColor` |
| `MarkNodeThematicBreak.qml` | 改为读取 `astStyle.thematicBreakStyle.color` / `height` |
| `MarkNodeImage.qml` | 改为读取 `astStyle.imageStyle.maxWidth` / `maxHeight` / `radius` |
| `MarkNodeLink.qml` | 无需直接读取颜色（由子 Text 节点处理），但后续可扩展 hover 颜色 |
| `MarkNodeHeading.qml` | 内部行内容通过 `MarkRowNodeComponent` 渲染，最终样式由 `MarkNodeText` 的 heading 逻辑处理，本文件本身不直接读取样式属性 |
| `MarkNodeItem.qml` | 检查是否有直接访问旧样式的地方，改为对应 `xxxStyle` |
| `MarkNodeComponent.qml` | 检查是否有直接访问旧样式的地方，改为对应 `xxxStyle` |
| `MarkRowNodeComponent.qml` / `MarkColumnNodeComponent.qml` | 检查并更新段落/列表等通用容器的边距逻辑 |
| 其余简单节点 | 统一检查是否有直接访问 `astStyle.textColor` / `astStyle.baseFontSize` 的地方，改为对应 `xxxStyle` |

---

## 5. 主题切换适配

现有 `setLightTheme()` / `setDarkTheme()` / `setColdTheme()` / `setWarmTheme()` 需要更新为直接操作新的 `xxxStyle` 属性。

以 `setDarkTheme()` 为例：

```qml
function setDarkTheme() {
    // 全局回退
    markStyle.textColor = "#f1f5f9"
    markStyle.baseFontSize = 14

    // 行内节点
    markStyle.textStyle.color = "#f1f5f9"
    markStyle.linkStyle.color = "#60a5fa"
    markStyle.codeStyle.background = "#27272a"
    markStyle.strongStyle.color = "#f1f5f9"
    markStyle.emphasisStyle.color = "#f1f5f9"
    markStyle.strikethroughStyle.color = "#f1f5f9"

    // 块级节点
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

> **注意**：由于子对象属性默认绑定到全局值，上述显式赋值会**打破绑定**。这意味着调用 `setDarkTheme()` 后，即使后续修改 `markStyle.textColor`，已显式赋值的节点颜色不会再自动跟随。这是预期行为，因为主题函数的职责就是一次性设定完整配色。

---

## 6. 实施范围

### 6.1 需要修改的文件

- `RenderMark/RenderMark.qml` —— `markStyle` 定义 + 主题切换函数
- `RenderMark/MarkNodeText.qml` —— 颜色/字号/字重绑定逻辑
- `RenderMark/MarkNodeCodeBlock.qml` —— 代码块样式读取
- `RenderMark/MarkNodeBlockQuote.qml` —— 引用块样式读取
- `RenderMark/MarkNodeTableCell.qml` —— 表格单元格样式读取
- `RenderMark/MarkNodeThematicBreak.qml` —— 分隔线样式读取
- `RenderMark/MarkNodeImage.qml` —— 图片样式读取
- `RenderMark/MarkNodeLink.qml` —— 如有 hover 样式则扩展
- `RenderMark/MarkNodeItem.qml` —— 列表项样式读取
- `RenderMark/MarkNodeComponent.qml` —— 通用节点组件样式读取
- `RenderMark/MarkRowNodeComponent.qml` / `MarkColumnNodeComponent.qml` —— 检查并更新段落/列表等通用容器的边距逻辑
- `RenderMark/MarkNodeHtmlBlock.qml`、`MarkNodeHtmlInline.qml`、`MarkNodeFootnoteDefinition.qml`、`MarkNodeFootnoteReference.qml`、`MarkNodeUnknown.qml` —— 统一替换旧样式引用

### 6.2 向后兼容性

- **破坏性变更**：移除旧的扁平属性（`linkColor`、`codeBackground`、`blockQuoteBorder`、`tableBorder`、`tableHeaderBg`）。外部代码若直接访问这些属性将无法工作。
- **保留属性**：`textColor` 和 `baseFontSize` 作为全局回退继续保留在顶层。
- **迁移建议**：外部使用者应迁移到 `renderMark.style.xxxStyle.xxx` 形式。

---

## 7. 风险与注意事项

1. **QML 绑定破坏**：子对象属性一旦被显式赋值，将永久失去与全局回退值的绑定。主题切换函数必须完整设置所有需要变更的属性。
2. **节点 parent 链遍历性能**：`MarkNodeText` 通过遍历 `parentNode` 链来确定颜色来源。目前链深通常不超过 5 层，性能影响可忽略。
3. **默认值一致性**：新增子对象时，其默认值应优先绑定到全局回退属性，避免硬编码颜色分散在多处。

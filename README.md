# MarkQml

基于 **Qt 6 + QML** 的原生 Markdown 渲染器，使用 `cmark-gfm` 作为底层解析引擎，将 Markdown 文本解析为 AST（抽象语法树）后，通过 QML 组件递归渲染，不依赖 WebEngine。

---

## 特性

- 🚀 **纯 QML 渲染** — 无需内嵌浏览器，性能更高、内存占用更低
- 🎨 **四种内置主题** — 亮色 / 暗色 / 冷色 / 暖色，一键切换
- 📐 **AST 驱动组件化架构** — 每个 Markdown 节点对应独立 QML 组件，易于扩展
- 🔗 **GFM 扩展支持** — 表格、删除线、任务列表、自动链接等

---

## 项目结构

```
MarkQml/
├── CMakeLists.txt          # 根 CMake 配置
├── main.cpp                # 程序入口
├── Main.qml                # 主窗口（工具栏 + 渲染区）
├── test.md                 # 综合测试文档
├── README.md               # 本文件
│
└── RenderMark/             # 渲染库（QML 模块）
    ├── CMakeLists.txt
    ├── Mark.h / Mark.cpp              # cmark-gfm 封装，提供 parse / parseFile
    ├── MarkNode.h / MarkNode.cpp      # AST 节点（QML 可访问）
    ├── MarkTree.h / MarkTree.cpp      # AST 树容器
    │
    ├── RenderMark.qml                 # 根容器（Flickable + Column）
    │
    ├── MarkNodeComponent.qml          # 【核心分发器】根据节点类型路由
    ├── MarkColumnNodeComponent.qml    # 块级垂直布局（Column）
    ├── MarkRowNodeComponent.qml       # 行内水平布局（Row）
    │
    └── MarkNode*.qml                  # 各类节点渲染组件
```

---

## 渲染架构设计

### 1. 整体数据流

```
Markdown 文本
    │
    ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────────────────────┐
│  Mark.parse │ ──► │  MarkTree   │ ──► │  RenderMark (tree.root.children)│
│  (cmark-gfm)│     │  (AST 树)   │     │  根容器遍历顶层 Block 节点      │
└─────────────┘     └─────────────┘     └─────────────────────────────┘
                                                │
                                                ▼
                                        MarkNodeComponent
                                          (类型分发)
                                                │
                    ┌─────────────┬─────────────┼─────────────┬─────────────┐
                    ▼             ▼             ▼             ▼             ▼
              MarkNodeText  MarkNodeLink  MarkNodeItem  MarkNodeTable  ...
```

### 2. AST 与 QML 的桥梁 —— MarkNode

`MarkNode` 继承自 `QObject` 并注册为 `QML_ELEMENT`，每个 AST 节点在 QML 中表现为一个带有以下信息的 JavaScript 对象：

| 属性 | 说明 | 适用节点 |
|------|------|----------|
| `type` | 节点类型字符串 | 全部 |
| `content` | 纯文本内容 | text / code / html 等 |
| `children` | 子节点列表 (`QVariantList`) | 全部 |
| `level` | 标题级别 h1~h6 | heading |
| `url` / `title` | 链接地址与标题 | link / image |
| `ordered` / `start` | 有序列表标志与起始序号 | list |
| `columns` / `alignments` | 列数与对齐方式 | table |
| `language` | 代码语言标识 | code_block |
| `parentNode` | 逻辑父节点 | 全部 |

此外，`MarkNode` 提供了一系列 `isXxx()` 便捷判断方法（如 `isHeading()`、`isLink()`），方便 QML 端快速分发。

### 3. 组件分发机制 —— MarkNodeComponent

`RenderMark.qml` 通过 `Repeater` 遍历 `tree.root.children`，每个子节点由一个 `MarkNodeComponent`（本质是一个 `Loader`）接管。

`MarkNodeComponent.onCompleted` 中根据节点类型选择对应组件：

```qml
if (astNode.isHeading()) {
    setSource('MarkRowNodeComponent.qml', {astNode: astNode, astStyle: astStyle})
    return;
}
if (astNode.isLink()) {
    setSource('MarkNodeLink.qml', {astNode: astNode, astStyle: astStyle})
    return;
}
// ... 其他分支
```

**关键点**：
- **块级节点**（paragraph、heading、list、block_quote 等）通常先进入 `MarkColumnNodeComponent.qml` 或 `MarkRowNodeComponent.qml`，再由内部的嵌套 `MarkNodeComponent` 继续分发子节点，形成递归。
- **行内节点**（text、link、code、strong 等）直接在 `Row` 内完成渲染。
- **特殊节点**（table）采用**扁平化渲染**：`MarkNodeTable.qml` 使用 `GridLayout` 将所有 `table_cell` 统一排列，确保列宽自动对齐，而不是让 `table_header` / `table_row` 各自独立渲染。

### 4. 布局原则 —— 自下而上推导大小

本项目的 QML 组件遵循**自下而上（bottom-up）**的大小推导原则：

- 父容器的大小由子内容决定（`childrenRect.width/height`、`implicitWidth/implicitHeight`）
- 避免 `width: parent.width` 或 `anchors.fill: parent` 导致的循环依赖
- 典型示例：`MarkNodeCodeBlock.qml` 的 `Rectangle` 宽高直接绑定到内部 `Column` 的 `childrenRect`

```qml
Rectangle {
    width: childrenRect.width
    height: childrenRect.height
    // 内部 Column 自然推导尺寸，Rectangle 跟随内容
}
```

### 5. 样式传递

`RenderMark.qml` 维护一组颜色/字体属性，并打包为 `markStyle` 对象：

```qml
property var markStyle: ({
    textColor: textColor,
    linkColor: linkColor,
    codeBackground: codeBackground,
    // ...
})
```

所有子组件通过 `astStyle` 属性接收该对象，确保配色全局一致。切换主题时只需修改 `RenderMark` 的根属性，随后调用 `_refresh()` 清空并恢复 `tree`/`markdown`，强制重新创建全部子组件以应用新样式。

### 6. 行内样式嵌套

对于 `**[粗体链接](url)**` 这类嵌套结构，AST 表现为 `strong → link → text`。处理方式是：

1. `strong` 不再假设子节点一定是 `text`，而是创建 `MarkNodeStrong.qml`，内部用 `MarkRowNodeComponent` 递归渲染所有子节点。
2. `MarkNodeText.qml` 通过**遍历祖先节点**而非仅检查父节点，来判断是否需要应用 `bold`、`italic`、`underline`、`strikeout`。

```qml
font.bold: {
    var p = astNode.parentNode;
    while (p) {
        if (p.isStrong && p.isStrong()) return true;
        p = p.parentNode;
    }
    return false;
}
```

这样任意深度的嵌套（如 `strong → emphasis → link → text`）都能正确传递样式。

---

## 构建

依赖：
- Qt 6.8+
- cmark-gfm (通过 vcpkg 安装)
- CMake 3.16+

```bash
# 使用 vcpkg 安装依赖
vcpkg install cmark-gfm cmark-gfm-extensions

# 构建
mkdir build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=[vcpkg 路径]/scripts/buildsystems/vcpkg.cmake
cmake --build .
```

---

## 使用

### 基本用法

```qml
import RenderMark

RenderMark {
    anchors.fill: parent
    markdown: "# Hello\n\nThis is **bold** and *italic*."
}
```

### 切换主题

```qml
renderMark.setDarkTheme()   // 暗色
renderMark.setLightTheme()  // 亮色
renderMark.setColdTheme()   // 冷色（默认）
renderMark.setWarmTheme()   // 暖色
```

### 加载本地文件

```qml
renderMark.tree = _mark.parseFile("/path/to/file.md")
```

---

## 许可证

MIT

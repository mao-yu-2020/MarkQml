# MarkQml

[English](./README_EN.md)

基于 **Qt 6 + QML** 的原生 Markdown 渲染器，使用 `cmark-gfm` 作为底层解析引擎，将 Markdown 文本解析为 AST（抽象语法树）后，通过 QML 组件递归渲染，不依赖 WebEngine。

---

## 特性

- 🚀 **纯 QML 渲染** — 无需内嵌浏览器，性能更高、内存占用更低
- 🎨 **四种内置主题** — 亮色 / 暗色 / 冷色 / 暖色，一键切换，绑定驱动实时生效
- 📐 **AST 驱动组件化架构** — 每个 Markdown 节点对应独立 QML 组件，易于扩展
- 🔗 **GFM 扩展支持** — 表格、删除线、任务列表、自动链接等
- ⚡ **组件缓存优化** — 预缓存 QML `Component` 对象，避免每次重复解析 QML 文件
- 🛡️ **无初始化冲突** — 取消 `required property`，通过 `init()` + `Binding` 条件绑定安全传递 AST 节点

---

## 项目结构

```
MarkQml/
├── CMakeLists.txt          # 根 CMake 配置
├── vcpkg.json              # vcpkg 依赖清单
├── main.cpp                # 程序入口
├── Main.qml                # 主窗口（工具栏 + 文件对话框 + 渲染区）
├── test.md                 # 综合测试文档（覆盖全部节点类型）
├── README.md               # 本文件
│
└── RenderMark/             # 渲染库（QML 模块）
    ├── CMakeLists.txt
    ├── Mark.h / Mark.cpp              # cmark-gfm 封装，提供 parse / parseFile / toHtml
    ├── MarkNode.h / MarkNode.cpp      # AST 节点（QML 可访问）
    ├── MarkTree.h / MarkTree.cpp      # AST 树容器
    │
    ├── RenderMark.qml                 # 根容器（Flickable + Repeater）
    │   └── _compCache (Item)          # 组件缓存，预加载全部 Component
    │
    ├── MarkNodeComponent.qml          # 【核心分发器】Loader + sourceComponent + 组件缓存
    ├── MarkColumnNodeComponent.qml    # 块级垂直布局（Column）
    ├── MarkRowNodeComponent.qml       # 行内水平布局（Row）
    │
    └── MarkNode*.qml                  # 各类节点渲染组件（共 20+ 个）
```

---

## 渲染架构设计

### 1. 整体数据流

```
Markdown 文本 / 文件
    │
    ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────────────────────┐
│  Mark.parse │ ──► │  MarkTree   │ ──► │  RenderMark (tree.root.children)│
│  (cmark-gfm)│     │  (AST 树)   │     │  根容器遍历顶层 Block 节点      │
└─────────────┘     └─────────────┘     └─────────────────────────────┘
                                                │
                                                ▼
                                        MarkNodeComponent
                                          (Loader 分发)
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

`MarkNodeComponent` 采用**组件缓存**策略：

1. `RenderMark` 内部维护 `_compCache`（`Item` 容器），预加载全部 26 种 `Component` 对象；
2. `MarkNodeComponent` 通过 `sourceComponent` 绑定，根据 `astNode` 类型从缓存中选取对应 `Component`；
3. `Loader.onLoaded` 中调用 `item.init(astNode, astStyle)` 完成初始化，同时传递 `cache`；
4. 若 `Repeater` 重用了 delegate 但 `Loader` 的 `item` 意外为 `null`，通过 `Qt.callLater` 强制重置 `sourceComponent` 触发重新加载。

```qml
Loader {
    id: root
    property var astNode: null
    property var astStyle: null
    property var cache: null

    sourceComponent: {
        var node = astNode;
        var c = cache;
        if (!c || !node) return null;
        if (node.isDocument()) return c.document;
        if (node.isParagraph()) return c.paragraph;
        // ... 其他分支
        return null;
    }

    onLoaded: {
        if (item && item.cache !== undefined) item.cache = root.cache;
        if (item && item.init) item.init(root.astNode, root.astStyle);
    }
}
```

**关键点**：
- **块级节点**（paragraph、heading、list、block_quote 等）通常先进入 `MarkColumnNodeComponent.qml` 或 `MarkRowNodeComponent.qml`，再由内部的嵌套 `MarkNodeComponent` 继续分发子节点，形成递归。
- **行内节点**（text、link、code、strong 等）直接在 `Row` 内完成渲染。
- **特殊节点**（table）采用**扁平化渲染**：`MarkNodeTable.qml` 使用 `GridLayout` 将所有 `table_cell` 统一排列，确保列宽自动对齐。

### 4. 安全初始化 —— init() + Binding

为避免 `required property` 与 `Loader` 之间的初始化时序冲突，所有渲染组件统一采用以下模式：

```qml
Rectangle {
    id: root
    property var astNode: null
    property var astStyle: null

    function init(node, style) {
        astNode = node;
        astStyle = style;
    }

    // 所有依赖 astNode / astStyle 的属性均使用 Binding + when 条件
    Binding on color {
        value: root.astStyle.codeBackground
        when: root.astStyle !== null
    }
}
```

- `init()` 在 `Loader.onLoaded` 中被调用，确保 `astNode` / `astStyle` 就绪后才赋值；
- `Binding` 的 `when` 条件保证在 `null` 状态下不会触发属性访问，彻底规避 `TypeError: Cannot read property 'xxx' of undefined`。

### 5. 布局原则 —— 自下而上推导大小

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

### 6. 样式传递与主题切换

`RenderMark.qml` 维护一个 `QtObject` 样式的 `markStyle` 对象（不再是普通 JS 对象）：

```qml
QtObject {
    id: markStyle
    property color textColor: "#2c3e50"
    property color linkColor: "#3498db"
    property color codeBackground: "#eaf2f8"
    // ...
}
```

所有子组件通过 `astStyle` 属性接收该对象。由于 `QtObject` 支持属性变更通知，切换主题时所有 `Binding` 会自动重新求值，**无需销毁重建组件**。

```qml
renderMark.setDarkTheme()   // 暗色
renderMark.setLightTheme()  // 亮色
renderMark.setColdTheme()   // 冷色（默认）
renderMark.setWarmTheme()   // 暖色
```

### 7. 行内样式嵌套

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

### 依赖

- Qt 6.8+
- CMake 3.16+
- cmark-gfm（含 extensions）— **通过 vcpkg 管理**

### vcpkg 包管理

本项目使用 [vcpkg](https://github.com/microsoft/vcpkg) 作为 C++ 依赖包管理器。项目根目录下的 `vcpkg.json` 是**清单文件（manifest）**，定义了项目所需的依赖：

```json
{
  "name": "markqml",
  "version": "0.1.0",
  "dependencies": [
    "cmark-gfm"
  ]
}
```

`cmark-gfm` 的 vcpkg port 会自动拉取核心库以及所有扩展（table、strikethrough、autolinks、tagfilter、tasklist），无需在 `vcpkg.json` 中单独声明 extensions。

#### Qt Creator vcpkg 插件（默认方式）

本项目默认假设你在 **Qt Creator** 中已安装并配置了 [vcpkg 插件](https://doc.qt.io/qtcreator/creator-vcpkg.html)。插件会自动识别项目根目录的 `vcpkg.json`，并在后台完成依赖的下载与集成，无需在 CMake 命令行中手动指定 `CMAKE_TOOLCHAIN_FILE`。

#### 方式一：使用 vcpkg 清单模式（命令行 / 无插件时）

如果你没有使用 Qt Creator 的 vcpkg 插件，也不想每次都在命令行中传入 `-DCMAKE_TOOLCHAIN_FILE`，可以直接在 `CMakeLists.txt` 顶部加入：

```cmake
include(${CMAKE_CURRENT_SOURCE_DIR}/vcpkg/scripts/buildsystems/vcpkg.cmake)
```

> 请将路径替换为你本地 vcpkg 仓库的实际位置。

或者，在构建时显式指定 toolchain：

```bash
# 1. 克隆 vcpkg（如尚未克隆）
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
.\bootstrap-vcpkg.bat    # Windows
# ./bootstrap-vcpkg.sh   # Linux / macOS

# 2. 在项目根目录构建（CMake 会自动读取 vcpkg.json 并安装依赖）
cd /path/to/MarkQml
mkdir build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=C:/path/to/vcpkg/scripts/buildsystems/vcpkg.cmake
cmake --build . --config Release
```

在 Qt Creator 中，可在 **Projects → Build → CMake → Initial CMake parameters** 中添加：

```
-DCMAKE_TOOLCHAIN_FILE:STRING=C:/path/to/vcpkg/scripts/buildsystems/vcpkg.cmake
```

#### 方式二：手动通过 vcpkg 安装

```bash
vcpkg install cmark-gfm
```

安装完成后，同样需要在 CMake 配置中指定 `CMAKE_TOOLCHAIN_FILE`。

### 构建命令示例

```bash
# Windows (Visual Studio 2022)
mkdir build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake -G "Visual Studio 17 2022"
cmake --build . --config Release

# Linux / macOS
mkdir build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=~/vcpkg/scripts/buildsystems/vcpkg.cmake
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
renderMark.source = "file:///C:/path/to/file.md"
// 或
renderMark.tree = renderMark.parser.parseFile("/path/to/file.md")
```

### 读取内置解析器

```qml
// 获取 HTML 字符串
var html = renderMark.parser.toHtml("# Markdown")

// 获取 AST 树（MarkTree）
var tree = renderMark.parser.parse("# Markdown")
console.log(tree.printTree())   // 打印树形结构
```

---

## 许可证

MIT

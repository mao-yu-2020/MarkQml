# MarkQml

[简体中文](./README.md)

A native **Qt 6 + QML** Markdown renderer powered by `cmark-gfm`. It parses Markdown text into an AST (Abstract Syntax Tree) and recursively renders it through QML components — no WebEngine required.

---

## Features

- 🚀 **Pure QML Rendering** — No embedded browser, higher performance and lower memory footprint
- 📑 **Outline Preview** — Automatically extracts Markdown heading hierarchy into a clickable table of contents; click to scroll to the corresponding heading
- 🖼️ **Image Click-to-Zoom** — Clicking an image in the document emits `clickedImage(url)`; the consumer implements the full-screen zoom preview
- 🎨 **Four Built-in Themes** — Light / Dark / Cold / Warm, one-click switching with binding-driven live updates
- 📐 **AST-Driven Componentized Architecture** — Each Markdown node maps to an independent QML component, easy to extend
- 🔗 **GFM Extension Support** — Tables, strikethrough, task lists, autolinks, and more
- ⚡ **Component Cache Optimization** — Pre-caches QML `Component` objects to avoid repeated QML file parsing
- 🛡️ **No Initialization Conflicts** — Eliminates `required property` issues; safely passes AST nodes via `init()` + conditional `Binding`

---

## Screenshot

![Screenshot](./readme_res/run.png)

---

## Project Structure

```
MarkQml/
├── CMakeLists.txt          # Root CMake configuration
├── vcpkg.json              # vcpkg dependency manifest
├── main.cpp                # Application entry point
├── Main.qml                # Main window (toolbar + file dialog + render area)
├── test.md                 # Comprehensive test document (covers all node types)
├── README.md               # This file
│
└── RenderMark/             # Rendering library (QML module)
    ├── CMakeLists.txt
    ├── Mark.h / Mark.cpp              # cmark-gfm wrapper; provides parse / parseFile / toHtml
    ├── MarkNode.h / MarkNode.cpp      # AST node (accessible from QML)
    ├── MarkTree.h / MarkTree.cpp      # AST tree container
    │
    ├── RenderMark.qml                 # Root container (Flickable + Repeater)
    │   └── _compCache (Item)          # Component cache; preloads all Components
    │
    ├── MarkNodeComponent.qml          # [Core dispatcher] Loader + sourceComponent + cache
    ├── MarkColumnNodeComponent.qml    # Block-level vertical layout (Column)
    ├── MarkRowNodeComponent.qml       # Inline horizontal layout (Row)
    ├── MarkOutline.qml                # Outline preview component (auto-extracts heading hierarchy)
    │
    └── MarkNode*.qml                  # Various node rendering components (20+ files)
```

---

## Rendering Architecture

### 1. Overall Data Flow

```
Markdown text / file
    │
    ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────────────────────┐
│  Mark.parse │ ──► │  MarkTree   │ ──► │  RenderMark (tree.root.children)│
│  (cmark-gfm)│     │  (AST tree) │     │  Root container iterates top-level Block nodes│
└─────────────┘     └─────────────┘     └─────────────────────────────┘
                                                │
                                                ▼
                                        MarkNodeComponent
                                          (Loader dispatch)
                                                │
                    ┌─────────────┬─────────────┼─────────────┬─────────────┐
                    ▼             ▼             ▼             ▼             ▼
              MarkNodeText  MarkNodeLink  MarkNodeItem  MarkNodeTable  ...
```

### 2. Bridge Between AST and QML — MarkNode

`MarkNode` inherits from `QObject` and is registered as `QML_ELEMENT`. Each AST node appears in QML as a JavaScript object with the following information:

| Property | Description | Applicable Nodes |
|----------|-------------|------------------|
| `type` | Node type string | All |
| `content` | Plain text content | text / code / html etc. |
| `children` | Child node list (`QVariantList`) | All |
| `level` | Heading level h1~h6 | heading |
| `url` / `title` | Link address and title | link / image |
| `ordered` / `start` | Ordered list flag and starting number | list |
| `columns` / `alignments` | Column count and alignment | table |
| `language` | Code language identifier | code_block |
| `parentNode` | Logical parent node | All |

In addition, `MarkNode` provides a set of convenient `isXxx()` methods (e.g. `isHeading()`, `isLink()`) for quick dispatch on the QML side.

### 3. Component Dispatch Mechanism — MarkNodeComponent

`RenderMark.qml` traverses `tree.root.children` via `Repeater`; each child node is handled by a `MarkNodeComponent` (essentially a `Loader`).

`MarkNodeComponent` adopts a **component caching** strategy:

1. `RenderMark` maintains `_compCache` (an `Item` container) which preloads all 26 `Component` objects;
2. `MarkNodeComponent` selects the corresponding `Component` from the cache via a `sourceComponent` binding based on `astNode` type;
3. In `Loader.onLoaded`, it calls `item.init(astNode, astStyle)` to initialize, and also passes `cache`;
4. If `Repeater` reuses a delegate but the `Loader`'s `item` is unexpectedly `null`, it forces a reload by resetting `sourceComponent` through `Qt.callLater`.

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
        // ... other branches
        return null;
    }

    onLoaded: {
        if (item && item.cache !== undefined) item.cache = root.cache;
        if (item && item.init) item.init(root.astNode, root.astStyle);
    }
}
```

**Key points**:
- **Block-level nodes** (paragraph, heading, list, block_quote, etc.) usually enter `MarkColumnNodeComponent.qml` or `MarkRowNodeComponent.qml` first, then continue dispatching child nodes through nested `MarkNodeComponent`s recursively.
- **Inline nodes** (text, link, code, strong, etc.) render directly inside a `Row`.
- **Special nodes** (table) use **flattened rendering**: `MarkNodeTable.qml` arranges all `table_cell`s in a single `GridLayout` to ensure column widths align automatically, rather than rendering `table_header` / `table_row` independently.

### 4. Safe Initialization — init() + Binding

To avoid initialization timing conflicts between `required property` and `Loader`, all rendering components uniformly adopt the following pattern:

```qml
Rectangle {
    id: root
    property var astNode: null
    property var astStyle: null

    function init(node, style) {
        astNode = node;
        astStyle = style;
    }

    // All properties depending on astNode / astStyle use Binding + when condition
    Binding on color {
        value: root.astStyle.codeBackground
        when: root.astStyle !== null
    }
}
```

- `init()` is called inside `Loader.onLoaded`, ensuring `astNode` / `astStyle` are ready before assignment;
- The `when` condition of `Binding` guarantees no property access is triggered in the `null` state, completely avoiding `TypeError: Cannot read property 'xxx' of undefined`.

### 5. Layout Principle — Bottom-Up Size Derivation

The QML components in this project follow a **bottom-up** size derivation principle:

- Parent container size is determined by child content (`childrenRect.width/height`, `implicitWidth/implicitHeight`)
- Avoids circular dependencies caused by `width: parent.width` or `anchors.fill: parent`
- Typical example: `MarkNodeCodeBlock.qml`'s `Rectangle` width and height are bound directly to its inner `Column`'s `childrenRect`

```qml
Rectangle {
    width: childrenRect.width
    height: childrenRect.height
    // Inner Column naturally derives its size; Rectangle follows content
}
```

### 6. Style Passing and Theme Switching

`RenderMark.qml` maintains a `QtObject`-based `markStyle` object (no longer a plain JS object):

```qml
QtObject {
    id: markStyle
    property color textColor: "#2c3e50"
    property color linkColor: "#3498db"
    property color codeBackground: "#eaf2f8"
    // ...
}
```

All child components receive this object through the `astStyle` property. Because `QtObject` supports property change notifications, all `Binding`s automatically re-evaluate when switching themes — **no need to destroy and recreate components**.

```qml
renderMark.setDarkTheme()   // Dark
renderMark.setLightTheme()  // Light
renderMark.setColdTheme()   // Cold (default)
renderMark.setWarmTheme()   // Warm
```

### 7. Inline Style Nesting

For nested structures like `**[bold link](url)**`, the AST is represented as `strong → link → text`. The handling approach is:

1. `strong` no longer assumes its child must be `text`; instead it creates `MarkNodeStrong.qml`, which uses `MarkRowNodeComponent` to recursively render all child nodes.
2. `MarkNodeText.qml` determines whether to apply `bold`, `italic`, `underline`, or `strikeout` by **traversing ancestor nodes** rather than only checking the parent node.

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

This correctly propagates styles through arbitrary nesting depths (e.g. `strong → emphasis → link → text`).

---

## Build

### Dependencies

- Qt 6.8+
- CMake 3.16+
- cmark-gfm (with extensions) — **managed via vcpkg**

### vcpkg Package Management

This project uses [vcpkg](https://github.com/microsoft/vcpkg) as the C++ dependency package manager. The `vcpkg.json` in the project root is a **manifest** that defines the required dependencies:

```json
{
  "name": "markqml",
  "version": "0.1.0",
  "dependencies": [
    "cmark-gfm"
  ]
}
```

The vcpkg port for `cmark-gfm` automatically pulls the core library and all extensions (table, strikethrough, autolinks, tagfilter, tasklist); there is no need to declare extensions separately in `vcpkg.json`.

#### Qt Creator vcpkg Plugin (Default)

This project assumes by default that you have installed and configured the [vcpkg plugin](https://doc.qt.io/qtcreator/creator-vcpkg.html) in **Qt Creator**. The plugin automatically recognizes the `vcpkg.json` in the project root and downloads and integrates dependencies in the background, without requiring you to manually specify `CMAKE_TOOLCHAIN_FILE` on the CMake command line.

#### Option 1: vcpkg Manifest Mode (Command Line / No Plugin)

If you are not using the Qt Creator vcpkg plugin and don't want to pass `-DCMAKE_TOOLCHAIN_FILE` every time on the command line, you can add the following directly at the top of `CMakeLists.txt`:

```cmake
include(${CMAKE_CURRENT_SOURCE_DIR}/vcpkg/scripts/buildsystems/vcpkg.cmake)
```

> Replace the path with the actual location of your local vcpkg repository.

Or, specify the toolchain explicitly at build time:

```bash
# 1. Clone vcpkg (if not already cloned)
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
.\bootstrap-vcpkg.bat    # Windows
# ./bootstrap-vcpkg.sh   # Linux / macOS

# 2. Build from project root (CMake will automatically read vcpkg.json and install dependencies)
cd /path/to/MarkQml
mkdir build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=C:/path/to/vcpkg/scripts/buildsystems/vcpkg.cmake
cmake --build . --config Release
```

In Qt Creator, you can add the following under **Projects → Build → CMake → Initial CMake parameters**:

```
-DCMAKE_TOOLCHAIN_FILE:STRING=C:/path/to/vcpkg/scripts/buildsystems/vcpkg.cmake
```

#### Option 2: Manual vcpkg Installation

```bash
vcpkg install cmark-gfm
```

After installation, you still need to specify `CMAKE_TOOLCHAIN_FILE` in the CMake configuration.

### Build Command Examples

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

## Usage

### Basic Usage

```qml
import RenderMark

RenderMark {
    anchors.fill: parent
    markdown: "# Hello\n\nThis is **bold** and *italic*."
}
```

### Switching Themes

```qml
renderMark.setDarkTheme()   // Dark
renderMark.setLightTheme()  // Light
renderMark.setColdTheme()   // Cold (default)
renderMark.setWarmTheme()   // Warm
```

### Loading Local Files

When loading via `source`, set `baseUrl` together so that relative image paths in the document can be resolved correctly:

```qml
renderMark.source = "file:///C:/path/to/file.md"
renderMark.baseUrl = "file:///C:/path/to/"

// Or pass the AST directly
renderMark.tree = renderMark.parser.parseFile("/path/to/file.md")
```

### Outline Preview

Bind `MarkOutline` to the `outline` property of `RenderMark` to automatically extract and render the document outline:

```qml
import RenderMark

RenderMark {
    id: renderMark
    anchors.fill: parent
    markdown: "# Heading 1\n\n## Heading 2\n\nBody text"
    outline: outlineView   // Bind outline component; headings are registered automatically
}

MarkOutline {
    id: outlineView
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    width: parent.width / 4
    onHeadingClicked: (node, item) => {
        if (item) renderMark.scrollToHeading(item);
    }
}
```

**Notes**:
- `MarkOutline` collects heading nodes incrementally via `registerHeading`; no need to pass the AST manually.
- Clicking an outline item emits `headingClicked(node, item)`, where `item` is the corresponding QML element and can be used directly for scroll positioning.
- `RenderMark.scrollToHeading(item)` scrolls the view to the heading (with a 20px top margin).

### Image Click-to-Zoom

`RenderMark` emits `clickedImage(url)` when an internal image is clicked; the argument is the resolved full image URL. The consumer can implement a zoom preview based on this signal:

```qml
RenderMark {
    anchors.fill: parent
    markdown: "![Example](./image.png)"

    onClickedImage: (url) => {
        imageOverlay.source = url;
        imageOverlay.visible = true;
    }
}

// Zoom overlay (fills parent, click to close)
Rectangle {
    id: imageOverlay
    property alias source: previewImage.source
    anchors.fill: parent
    visible: false
    color: "#cc000000"
    z: 100

    Image {
        id: previewImage
        anchors.fill: parent
        anchors.margins: 32
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            imageOverlay.visible = false;
            previewImage.source = "";
        }
    }
}
```

**Notes**:
- Only successfully loaded images respond to clicks (a placeholder is shown on load failure and is not clickable).
- The cursor changes to a pointing hand when hovering over a clickable image.

### Accessing the Built-in Parser

```qml
// Get HTML string
var html = renderMark.parser.toHtml("# Markdown")

// Get AST tree (MarkTree)
var tree = renderMark.parser.parse("# Markdown")
console.log(tree.printTree())   // Print tree structure
```

---

## License

MIT

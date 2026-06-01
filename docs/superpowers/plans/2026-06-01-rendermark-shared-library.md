# RenderMark Shared Library Conversion — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert `RenderMark` from a static library to a shared (dynamic) library with proper cross-platform export/import macros and updated CMake package config for external QML consumers.

**Architecture:** Use `qt_add_library(RenderMark SHARED)` so Qt 6 auto-generates a dynamic QML plugin. Use CMake `generate_export_header()` for cross-platform export macros. Update `RenderMarkConfig.cmake.in` to import shared targets and remove static-plugin `Q_IMPORT_PLUGIN` mechanics.

**Tech Stack:** Qt 6.8, CMake 3.16+, MSVC 2022 / GCC / Clang, vcpkg (cmark-gfm)

---

## File Map

| File | Responsibility | Action |
|------|---------------|--------|
| `RenderMark/CMakeLists.txt` | Core build config: library type, export header, include dirs, install rules | Modify |
| `RenderMark/Mark.h` | Public C++ class `Mark` — add export macro | Modify |
| `RenderMark/MarkNode.h` | Public C++ class `MarkNode` — add export macro | Modify |
| `RenderMark/MarkTree.h` | Public C++ class `MarkTree` — add export macro | Modify |
| `RenderMark/cmake/RenderMarkConfig.cmake.in` | CMake package config for `find_package(RenderMark)` consumers | Modify |
| `CMakeLists.txt` (root) | App executable config | Verify no changes needed |

---

## Task 1: Update RenderMark/CMakeLists.txt — Core Build Configuration

**Files:**
- Modify: `RenderMark/CMakeLists.txt`

### Step 1: Change library type from STATIC to SHARED

Change line 11:

```cmake
qt_add_library(RenderMark STATIC)
```

To:

```cmake
qt_add_library(RenderMark SHARED)
```

### Step 2: Add export header generation

After the `qt_add_library(RenderMark SHARED)` line, add:

```cmake
include(GenerateExportHeader)
generate_export_header(RenderMark
    BASE_NAME RENDERMARK
    EXPORT_FILE_NAME "${CMAKE_CURRENT_BINARY_DIR}/rendermark_export.h"
)
```

### Step 3: Add public include directories

After the `target_link_libraries` block (around line 78), add:

```cmake
target_include_directories(RenderMark
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
        $<INSTALL_INTERFACE:include/RenderMark>
)
```

This ensures the generated `rendermark_export.h` (in the build tree) is found during compilation, and external consumers find installed headers under `include/RenderMark/`.

### Step 4: Set hidden visibility for non-Windows platforms

After `target_include_directories`, add:

```cmake
if(NOT WIN32)
    target_compile_options(RenderMark PRIVATE -fvisibility=hidden)
endif()
```

### Step 5: Remove static plugin import file generation

Delete the entire block (lines 153-160):

```cmake
# 生成静态插件导入文件，供外部项目自动编译以确保 QML 类型被注册
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/rendermark_plugin_import.cpp"
    "#include <QtPlugin>\n"
    "Q_IMPORT_PLUGIN(RenderMarkPlugin)\n"
)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/rendermark_plugin_import.cpp"
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/RenderMark
)
```

### Step 6: Split install targets (main lib vs QML plugin)

Replace the current combined install block (lines 87-92):

```cmake
install(TARGETS RenderMark RenderMarkplugin
    EXPORT RenderMarkTargets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
```

With:

```cmake
# Install main shared library
install(TARGETS RenderMark
    EXPORT RenderMarkTargets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# Install QML plugin into QML import path (needed for runtime QML engine loading)
install(TARGETS RenderMarkplugin
    ARCHIVE DESTINATION ${CMAKE_INSTALL_QMLDIR}/RenderMark
    LIBRARY DESTINATION ${CMAKE_INSTALL_QMLDIR}/RenderMark
    RUNTIME DESTINATION ${CMAKE_INSTALL_QMLDIR}/RenderMark
)
```

### Step 7: Install generated export header

After the existing header install block (line 95-97), add:

```cmake
# Install generated export header
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/rendermark_export.h"
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/RenderMark
)
```

### Step 8: Commit

```bash
git add RenderMark/CMakeLists.txt
git commit -m "build: convert RenderMark to shared library with export header"
```

---

## Task 2: Add Export Macros to Public C++ Headers

**Files:**
- Modify: `RenderMark/Mark.h`
- Modify: `RenderMark/MarkNode.h`
- Modify: `RenderMark/MarkTree.h`

### Step 1: Update Mark.h

After `#pragma once`, add:

```cpp
#include "rendermark_export.h"
```

Change the class declaration:

```cpp
class Mark : public QObject
```

To:

```cpp
class RENDERMARK_EXPORT Mark : public QObject
```

### Step 2: Update MarkNode.h

After `#pragma once`, add:

```cpp
#include "rendermark_export.h"
```

Change:

```cpp
class MarkNode : public QObject
```

To:

```cpp
class RENDERMARK_EXPORT MarkNode : public QObject
```

### Step 3: Update MarkTree.h

After `#pragma once`, add:

```cpp
#include "rendermark_export.h"
```

Change:

```cpp
class MarkTree : public QObject
```

To:

```cpp
class RENDERMARK_EXPORT MarkTree : public QObject
```

### Step 4: Commit

```bash
git add RenderMark/Mark.h RenderMark/MarkNode.h RenderMark/MarkTree.h
git commit -m "feat: add RENDERMARK_EXPORT to public C++ classes"
```

---

## Task 3: Update RenderMarkConfig.cmake.in for Shared Library Import

**Files:**
- Modify: `RenderMark/cmake/RenderMarkConfig.cmake.in`

### Step 1: Update RenderMarkplugin target to SHARED IMPORTED

Replace:

```cmake
# 创建 RenderMarkplugin IMPORTED 目标（QML 静态插件）
if(NOT TARGET RenderMarkplugin)
    add_library(RenderMarkplugin STATIC IMPORTED)
    set_target_properties(RenderMarkplugin PROPERTIES
        IMPORTED_LOCATION "${PACKAGE_PREFIX_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}RenderMarkplugin${CMAKE_STATIC_LIBRARY_SUFFIX}"
    )
endif()
```

With:

```cmake
# 创建 RenderMarkplugin IMPORTED 目标（QML 动态插件）
if(NOT TARGET RenderMarkplugin)
    add_library(RenderMarkplugin SHARED IMPORTED)
    if(WIN32)
        set_target_properties(RenderMarkplugin PROPERTIES
            IMPORTED_IMPLIB "${PACKAGE_PREFIX_DIR}/lib/${CMAKE_IMPORT_LIBRARY_PREFIX}RenderMarkplugin${CMAKE_IMPORT_LIBRARY_SUFFIX}"
            IMPORTED_LOCATION "${PACKAGE_PREFIX_DIR}/lib/qml/RenderMark/${CMAKE_SHARED_LIBRARY_PREFIX}RenderMarkplugin${CMAKE_SHARED_LIBRARY_SUFFIX}"
        )
    else()
        set_target_properties(RenderMarkplugin PROPERTIES
            IMPORTED_LOCATION "${PACKAGE_PREFIX_DIR}/lib/qml/RenderMark/${CMAKE_SHARED_LIBRARY_PREFIX}RenderMarkplugin${CMAKE_SHARED_LIBRARY_SUFFIX}"
        )
    endif()
endif()
```

### Step 2: Update RenderMark::RenderMark target to SHARED IMPORTED

Replace:

```cmake
# 创建 RenderMark::RenderMark IMPORTED 目标（手动定义，避免导出 QML 内部资源目标）
if(NOT TARGET RenderMark::RenderMark)
    add_library(RenderMark::RenderMark STATIC IMPORTED)
    set_target_properties(RenderMark::RenderMark PROPERTIES
        IMPORTED_LOCATION "${PACKAGE_PREFIX_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}RenderMark${CMAKE_STATIC_LIBRARY_SUFFIX}"
        INTERFACE_INCLUDE_DIRECTORIES "${PACKAGE_PREFIX_DIR}/include/RenderMark"
        INTERFACE_LINK_LIBRARIES "Qt6::Quick;cmark-gfm;cmark-gfm-extensions;RenderMarkplugin"
    )
endif()
```

With:

```cmake
# 创建 RenderMark::RenderMark IMPORTED 目标（手动定义，避免导出 QML 内部资源目标）
if(NOT TARGET RenderMark::RenderMark)
    add_library(RenderMark::RenderMark SHARED IMPORTED)
    if(WIN32)
        set_target_properties(RenderMark::RenderMark PROPERTIES
            IMPORTED_IMPLIB "${PACKAGE_PREFIX_DIR}/lib/${CMAKE_IMPORT_LIBRARY_PREFIX}RenderMark${CMAKE_IMPORT_LIBRARY_SUFFIX}"
            IMPORTED_LOCATION "${PACKAGE_PREFIX_DIR}/bin/${CMAKE_SHARED_LIBRARY_PREFIX}RenderMark${CMAKE_SHARED_LIBRARY_SUFFIX}"
        )
    else()
        set_target_properties(RenderMark::RenderMark PROPERTIES
            IMPORTED_LOCATION "${PACKAGE_PREFIX_DIR}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}RenderMark${CMAKE_SHARED_LIBRARY_SUFFIX}"
        )
    endif()
    set_target_properties(RenderMark::RenderMark PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${PACKAGE_PREFIX_DIR}/include/RenderMark"
        INTERFACE_LINK_LIBRARIES "Qt6::Quick;cmark-gfm;cmark-gfm-extensions"
    )
endif()
```

**Note:** `RenderMarkplugin` is removed from `INTERFACE_LINK_LIBRARIES` because external consumers do not link the QML plugin — the QML engine loads it dynamically at runtime from the QML import path.

### Step 3: Remove static plugin import file logic

Delete the entire block:

```cmake
# 自动编译静态插件导入文件，确保外部项目链接时 QML 类型被正确注册
set_property(TARGET RenderMark::RenderMark APPEND PROPERTY
    INTERFACE_SOURCES "${PACKAGE_PREFIX_DIR}/include/RenderMark/rendermark_plugin_import.cpp"
)
```

### Step 4: Commit

```bash
git add RenderMark/cmake/RenderMarkConfig.cmake.in
git commit -m "build: update CMake package config for shared library import"
```

---

## Task 4: Build Verification

**Files:**
- Verify: `RenderMark/CMakeLists.txt`, `RenderMark/Mark.h`, `RenderMark/MarkNode.h`, `RenderMark/MarkTree.h`, `RenderMark/cmake/RenderMarkConfig.cmake.in`

### Step 1: Reconfigure and build

Run from the build directory:

```bash
cd D:\jie_code\MarkQml\build\Desktop_Qt_6_8_3_MSVC2022_64bit-Debug
cmake ..
ninja
```

**Expected result:** All 7 targets build successfully with no errors or warnings.

### Step 2: Verify shared library artifacts exist

On Windows:

```bash
dir RenderMark\RenderMark.dll
dir RenderMark\RenderMarkplugin.dll
```

**Expected:** Both `RenderMark.dll` and `RenderMarkplugin.dll` exist in `RenderMark/` subdirectory of the build tree.

### Step 3: Verify export symbols (Windows)

```bash
dumpbin /exports RenderMark\RenderMark.dll | findstr Mark
```

**Expected output contains:** `Mark`, `MarkNode`, `MarkTree` class symbols (mangled C++ names).

### Step 4: Commit (if all passes)

No new file changes — build artifacts are in `.gitignore`.

---

## Task 5: Install Layout Verification

**Files:**
- Verify: Install tree structure

### Step 1: Install to a temporary prefix

```bash
cd D:\jie_code\MarkQml\build\Desktop_Qt_6_8_3_MSVC2022_64bit-Debug
cmake --install . --prefix D:\temp\rendermark-install
```

### Step 2: Verify directory layout

```bash
tree /F D:\temp\rendermark-install
```

**Expected structure (Windows):**

```
D:\temp\rendermark-install
├── bin
│   ├── RenderMark.dll
│   ├── cmark-gfm.dll
│   └── cmark-gfm-extensions.dll
├── include\RenderMark
│   ├── Mark.h
│   ├── MarkNode.h
│   ├── MarkTree.h
│   └── rendermark_export.h
├── lib
│   ├── RenderMark.lib
│   ├── cmark-gfm.lib
│   ├── cmark-gfm-extensions.lib
│   └── qml\RenderMark
│       ├── qmldir
│       ├── RenderMark.qmltypes
│       └── RenderMarkplugin.dll
└── lib\cmake\RenderMark
    ├── RenderMarkConfig.cmake
    └── RenderMarkConfigVersion.cmake
```

**Critical checks:**
- `RenderMark.dll` is in `bin/`
- `RenderMarkplugin.dll` is in `lib/qml/RenderMark/` (NOT `bin/`)
- `rendermark_export.h` is in `include/RenderMark/`
- No `rendermark_plugin_import.cpp` anywhere

### Step 3: Clean up temp install

```bash
rmdir /S /Q D:\temp\rendermark-install
```

---

## Self-Review Checklist

| Spec Requirement | Implementing Task |
|-----------------|-------------------|
| `qt_add_library(RenderMark SHARED)` | Task 1, Step 1 |
| Cross-platform export/import macro | Task 1, Steps 2-4 + Task 2 |
| `generate_export_header()` usage | Task 1, Step 2 |
| Public include dirs for build + install | Task 1, Step 3 |
| Hidden visibility on Linux/macOS | Task 1, Step 4 |
| Remove static plugin import file | Task 1, Step 5 |
| Split install: main lib vs QML plugin | Task 1, Step 6 |
| Install `rendermark_export.h` | Task 1, Step 7 |
| Add `RENDERMARK_EXPORT` to `Mark` | Task 2, Step 1 |
| Add `RENDERMARK_EXPORT` to `MarkNode` | Task 2, Step 2 |
| Add `RENDERMARK_EXPORT` to `MarkTree` | Task 2, Step 3 |
| `RenderMarkConfig.cmake.in`: SHARED IMPORTED | Task 3, Steps 1-2 |
| Remove `rendermark_plugin_import.cpp` from config | Task 3, Step 3 |
| `RenderMarkplugin` removed from `INTERFACE_LINK_LIBRARIES` | Task 3, Step 2 |
| Build verification | Task 4 |
| Install layout verification | Task 5 |

**Placeholder scan:** No TBD, TODO, or vague steps. All code blocks contain exact file paths and content. All commands have expected output.

**Type consistency:** `RENDERMARK_EXPORT` is generated by `generate_export_header(RenderMark BASE_NAME RENDERMARK)` and used in all three headers. `SHARED IMPORTED` is used consistently for both `RenderMark::RenderMark` and `RenderMarkplugin`.

# RenderMark 安装配置详解

本文档逐行解释 `RenderMark/CMakeLists.txt` 中的**安装与导出**逻辑，帮助你理解 CMake 是如何把编译好的库打包、安装，并让外部项目通过 `find_package` 使用的。

---

## 一、整体目标

Build（编译）阶段完成后，我们得到一堆文件：
- `RenderMark.dll` / `libRenderMark.so` —— 编译好的 C++ 动态库
- `RenderMarkplugin.dll` / `libRenderMarkplugin.so` —— QML 动态插件
- 一堆 `.obj`、`.qmlc` 等中间文件

Install（安装）阶段要做的是：**把外部项目真正需要的东西，复制到一个干净的目录里**。外部项目只需要：
1. 运行动态库文件（`.dll` / `.so` / `.dylib`）
2. 包含头文件（`.h`）
3. 识别 QML 模块（`qmldir` + `.qml` + `.qmltypes`）
4. 找到 CMake 配置（`RenderMarkConfig.cmake`）

---

## 二、第一部分：库是怎么定义出来的（构建阶段）

```cmake
qt_add_library(RenderMark SHARED)                          # 创建一个叫 RenderMark 的动态库
generate_export_header(RenderMark                           # 自动生成跨平台导出/导入宏头文件
    BASE_NAME RENDERMARK
    EXPORT_FILE_NAME "${CMAKE_CURRENT_BINARY_DIR}/rendermark_export.h"
)

target_include_directories(RenderMark
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
        $<INSTALL_INTERFACE:include/RenderMark>
)

if(NOT WIN32)
    target_compile_options(RenderMark PRIVATE -fvisibility=hidden)
endif()

qt_add_qml_module(RenderMark                               # 给它附加一个 QML 模块
    URI RenderMark                                         # QML 中 import 时用的名字
    VERSION 1.0
    QML_FILES ${RENDERMARK_QML_FILES}                      # 25 个 .qml 文件列表
    SOURCES ${RENDERMARK_HEADERS} ${RENDERMARK_SOURCES}     # 3 个头文件 + 3 个 cpp 文件
)
```

`qt_add_qml_module` 是一个 Qt6 的 CMake 宏，它会做很多事情：
- 把 25 个 `.qml` 文件编译进 Qt 资源系统（QRC）
- 自动生成 `qmldir` 文件（描述模块版本、插件类名、类型信息等）
- 自动生成 `RenderMark.qmltypes`（QML 类型描述，供 IDE 识别）
- 自动生成插件类 `RenderMarkPlugin` 和 `plugin_init` 代码
- 创建内部辅助目标：`RenderMarkplugin`、`RenderMarkplugin_init`、`RenderMark_resources_1` 等

当 `RenderMark` 是 **SHARED**（动态库）时，`qt_add_qml_module` 会自动生成**动态 QML 插件**（`RenderMarkplugin.dll`），而非静态插件。这意味着 QML 引擎在运行时会自动加载插件，外部项目不需要 `Q_IMPORT_PLUGIN`。

```cmake
target_link_libraries(RenderMark
    PUBLIC
        Qt6::Quick                 # 链接 Qt Quick（公开依赖，外部项目也需要）
        ${CMARK_LIBS}              # 链接 cmark-gfm（Windows 下是动态库）
)
```

这里 `PUBLIC` 表示：**外部项目链接 RenderMark 时，会自动同时链接 Qt6::Quick 和 cmark-gfm**。

---

## 三、第二部分：安装规则详解

### 3.1 引入标准安装目录变量

```cmake
include(GNUInstallDirs)
```

这行引入 CMake 标准变量，比如：
- `${CMAKE_INSTALL_LIBDIR}` → `lib`（库文件目录）
- `${CMAKE_INSTALL_BINDIR}` → `bin`（可执行文件/动态库目录）
- `${CMAKE_INSTALL_INCLUDEDIR}` → `include`（头文件目录）

如果你指定 `--prefix D:/temp/RenderMark`，那么：
- `lib` 对应 `D:/temp/RenderMark/lib`
- `bin` 对应 `D:/temp/RenderMark/bin`
- `include` 对应 `D:/temp/RenderMark/include`

### 3.2 安装动态库（主库与 QML 插件分开）

```cmake
# 安装主共享库
install(TARGETS RenderMark
    EXPORT RenderMarkTargets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}    # .lib（Windows import lib）放这里
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}    # .so / .dylib 文件放这里
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}    # .dll 文件放这里
)

# 安装 QML 插件到 QML 导入路径（QML 引擎运行时加载需要）
install(TARGETS RenderMarkplugin
    ARCHIVE DESTINATION ${CMAKE_INSTALL_QMLDIR}/RenderMark
    LIBRARY DESTINATION ${CMAKE_INSTALL_QMLDIR}/RenderMark
    RUNTIME DESTINATION ${CMAKE_INSTALL_QMLDIR}/RenderMark
)
```

**作用**：
- 主库 `RenderMark.dll`（Windows）或 `libRenderMark.so`（Linux）安装到 `bin/` 或 `lib/`
- QML 插件 `RenderMarkplugin.dll` 安装到 `lib/qml/RenderMark/`，这样 QML 引擎在 `import RenderMark` 时能自动找到并加载它

三个 `DESTINATION` 的区别：
- `ARCHIVE` —— 导入库（Windows `.lib`）
- `LIBRARY` —— 共享库本体（Linux `.so`，macOS `.dylib`）
- `RUNTIME` —— 运行时动态库（Windows `.dll`，可执行文件 `.exe`）

### 3.3 安装头文件

```cmake
install(FILES ${RENDERMARK_HEADERS}
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/RenderMark
)

# 安装自动生成的导出宏头文件
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/rendermark_export.h"
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/RenderMark
)
```

**作用**：把 `Mark.h`、`MarkNode.h`、`MarkTree.h` 以及自动生成的 `rendermark_export.h` 复制到 `include/RenderMark/` 下。

外部项目写 `#include <Mark.h>` 时，CMake 会通过 `INTERFACE_INCLUDE_DIRECTORIES` 告诉编译器去 `include/RenderMark/` 里找。

### 3.4 安装 cmark-gfm 依赖库（核心：打包第三方库）

```cmake
set(CMARK_VCPKG_DIR "${_VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}")
```

vcpkg 在构建时会设置这两个变量：
- `_VCPKG_INSTALLED_DIR` → vcpkg 安装根目录（如 `D:/.../vcpkg_installed`）
- `VCPKG_TARGET_TRIPLET` → 目标平台（如 `x64-windows`）

合起来就是 cmark-gfm 实际安装的位置。

```cmake
if(NOT EXISTS "${CMARK_VCPKG_DIR}")
    get_target_property(CMARK_GFM_IMPLIB libcmark-gfm IMPORTED_IMPLIB_RELEASE)
    get_filename_component(CMARK_VCPKG_DIR "${CMARK_GFM_IMPLIB}" DIRECTORY)
    get_filename_component(CMARK_VCPKG_DIR "${CMARK_VCPKG_DIR}" DIRECTORY)
endif()
```

**回退逻辑**：如果上面那个路径不存在（比如某些构建环境没设置 vcpkg 变量），就通过 CMake 目标属性反推：
- `IMPORTED_IMPLIB_RELEASE` → cmark-gfm 的导入库 `.lib` 文件路径
- `get_filename_component(... DIRECTORY)` 两次 → 从 `lib/cmark-gfm.lib` 回退到安装根目录

```cmake
if(ANDROID)
    get_target_property(CMARK_GFM_LIB libcmark-gfm_static IMPORTED_LOCATION)
    get_target_property(CMARK_GFM_EXT_LIB libcmark-gfm-extensions_static IMPORTED_LOCATION)
    install(FILES ${CMARK_GFM_LIB} ${CMARK_GFM_EXT_LIB}
        DESTINATION ${CMAKE_INSTALL_LIBDIR}
    )
elseif(EXISTS "${CMARK_VCPKG_DIR}")
    install(FILES
        "${CMARK_VCPKG_DIR}/lib/cmark-gfm.lib"
        "${CMARK_VCPKG_DIR}/lib/cmark-gfm-extensions.lib"
        DESTINATION ${CMAKE_INSTALL_LIBDIR}
    )
    install(FILES
        "${CMARK_VCPKG_DIR}/bin/cmark-gfm.dll"
        "${CMARK_VCPKG_DIR}/bin/cmark-gfm-extensions.dll"
        DESTINATION ${CMAKE_INSTALL_BINDIR}
    )
endif()
```

**作用**：把 cmark-gfm 的库文件也一起打包安装。

平台差异：
- **Android**：cmark-gfm 是静态库（`.a`），文件名叫 `libcmark-gfm_static.a`，通过 `IMPORTED_LOCATION` 获取路径后直接安装到 `lib/`。
- **Windows（vcpkg）**：cmark-gfm 是动态库，分成两部分安装：
  - `.lib`（导入库，链接时用）→ 安装到 `lib/`
  - `.dll`（运行时库，执行时用）→ 安装到 `bin/`

**为什么要打包 cmark-gfm？** 因为 RenderMark 是动态库，它在运行时需要加载 cmark-gfm。把 cmark-gfm 和 RenderMark 打包在一起，外部项目运行时不需要单独安装 cmark-gfm。

### 3.5 安装 QML 模块文件

```cmake
set(CMAKE_INSTALL_QMLDIR "${CMAKE_INSTALL_LIBDIR}/qml" CACHE PATH "QML import path")

install(FILES ${RENDERMARK_QML_FILES}
    DESTINATION ${CMAKE_INSTALL_QMLDIR}/RenderMark
)

install(FILES "${CMAKE_CURRENT_BINARY_DIR}/qmldir"
    DESTINATION ${CMAKE_INSTALL_QMLDIR}/RenderMark
)

install(FILES "${CMAKE_CURRENT_BINARY_DIR}/RenderMark.qmltypes"
    DESTINATION ${CMAKE_INSTALL_QMLDIR}/RenderMark
)
```

这三行分别安装：
1. **25 个 `.qml` 文件** —— 组件源码（虽然运行时优先用资源里的，但文件系统副本供 qmlls 扫描）
2. **`qmldir`** —— QML 模块的"身份证"，记录了模块名、版本、插件类名、类型信息等
3. **`RenderMark.qmltypes`** —— QML 类型数据库，qmlls 靠它知道 `RenderMark` 有哪些属性、方法、信号

安装后的路径：`lib/qml/RenderMark/`（包含 `qmldir` + `.qmltypes` + 所有 `.qml` + `RenderMarkplugin.dll`）。

### 3.6 生成 CMake 包配置文件（核心：让 find_package 能工作）

```cmake
include(CMakePackageConfigHelpers)

configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/RenderMarkConfig.cmake.in"   # 输入模板
    "${CMAKE_CURRENT_BINARY_DIR}/RenderMarkConfig.cmake"             # 输出文件
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/RenderMark    # 安装位置
)

write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/RenderMarkConfigVersion.cmake"
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/RenderMarkConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/RenderMarkConfigVersion.cmake"
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/RenderMark
)
```

**作用**：生成两个文件并安装到 `lib/cmake/RenderMark/`：
1. **`RenderMarkConfig.cmake`** —— 外部项目 `find_package(RenderMark)` 时执行的脚本
2. **`RenderMarkConfigVersion.cmake`** —— 版本兼容性检查（SameMajorVersion 表示主版本号相同即可兼容）

`configure_package_config_file` 会读取模板文件 `RenderMarkConfig.cmake.in`，把里面的 `@PACKAGE_INIT@` 等占位符替换为实际路径，生成最终的配置文件。

---

## 四、RenderMarkConfig.cmake.in 模板详解

这个文件是 `configure_package_config_file` 的输入模板，安装时会被处理成 `RenderMarkConfig.cmake`。

```cmake
@PACKAGE_INIT@
```

这是占位符，会被替换为一系列标准宏定义（如 `set_and_check`、`check_required_components`）和 `PACKAGE_PREFIX_DIR` 变量（指向安装根目录）。

```cmake
find_dependency(Qt6 COMPONENTS Quick)
```

外部项目使用 `find_package(RenderMark)` 时，自动确保 Qt6::Quick 也已被找到。

```cmake
if(NOT TARGET cmark-gfm)
    add_library(cmark-gfm STATIC IMPORTED)
    set_target_properties(cmark-gfm PROPERTIES
        IMPORTED_LOCATION "${PACKAGE_PREFIX_DIR}/lib/cmark-gfm.lib"
    )
endif()
```

**手动创建 IMPORTED 目标**。因为 cmark-gfm 的 `.lib` 文件被一起打包安装了，但外部项目没有它的 CMake 配置文件，所以我们直接在 RenderMark 的配置文件里"告诉"CMake：
- 有一个叫 `cmark-gfm` 的库
- 它的文件在 `${PACKAGE_PREFIX_DIR}/lib/cmark-gfm.lib`

同理创建 `cmark-gfm-extensions`。

```cmake
if(NOT TARGET RenderMarkplugin)
    add_library(RenderMarkplugin SHARED IMPORTED)
    if(WIN32)
        set_target_properties(RenderMarkplugin PROPERTIES
            IMPORTED_IMPLIB "${PACKAGE_PREFIX_DIR}/lib/RenderMarkplugin.lib"
            IMPORTED_LOCATION "${PACKAGE_PREFIX_DIR}/lib/qml/RenderMark/RenderMarkplugin.dll"
        )
    else()
        set_target_properties(RenderMarkplugin PROPERTIES
            IMPORTED_LOCATION "${PACKAGE_PREFIX_DIR}/lib/qml/RenderMark/libRenderMarkplugin.so"
        )
    endif()
endif()
```

创建 `RenderMarkplugin` IMPORTED 目标。这是 QML 动态插件，外部项目**不需要链接它**——QML 引擎会在运行时自动从 `lib/qml/RenderMark/` 加载。但定义成 IMPORTED 目标有助于 CMake 追踪依赖完整性。

```cmake
if(NOT TARGET RenderMark::RenderMark)
    add_library(RenderMark::RenderMark SHARED IMPORTED)
    if(WIN32)
        set_target_properties(RenderMark::RenderMark PROPERTIES
            IMPORTED_IMPLIB "${PACKAGE_PREFIX_DIR}/lib/RenderMark.lib"
            IMPORTED_LOCATION "${PACKAGE_PREFIX_DIR}/bin/RenderMark.dll"
        )
    else()
        set_target_properties(RenderMark::RenderMark PROPERTIES
            IMPORTED_LOCATION "${PACKAGE_PREFIX_DIR}/lib/libRenderMark.so"
        )
    endif()
    set_target_properties(RenderMark::RenderMark PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${PACKAGE_PREFIX_DIR}/include/RenderMark"
        INTERFACE_LINK_LIBRARIES "Qt6::Quick;cmark-gfm;cmark-gfm-extensions"
    )
endif()
```

这是核心：**创建 `RenderMark::RenderMark` IMPORTED 目标**，包含三个关键属性：
- `IMPORTED_LOCATION` / `IMPORTED_IMPLIB` —— 库文件在哪里（Windows 需要分开指定 `.lib` 和 `.dll`）
- `INTERFACE_INCLUDE_DIRECTORIES` —— 头文件在哪里（外部项目 `#include <Mark.h>` 时自动添加 `-I`）
- `INTERFACE_LINK_LIBRARIES` —— 链接 RenderMark 时，自动链接 Qt6::Quick + cmark-gfm + cmark-gfm-extensions

**注意**：`RenderMarkplugin` **不在** `INTERFACE_LINK_LIBRARIES` 中，因为外部项目不需要链接动态 QML 插件——它在运行时被 QML 引擎自动加载。

```cmake
set(RenderMark_QML_IMPORT_PATH "${PACKAGE_PREFIX_DIR}/lib/qml")
```

提供一个变量，外部项目可以设置 `QML_IMPORT_PATH` 让 QML 引擎找到 QML 模块。

---

## 五、完整流程图

```
构建阶段 (Build)                              安装阶段 (Install)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

qt_add_library(RenderMark SHARED)              install(TARGETS RenderMark)
generate_export_header(RenderMark)               ↓ 复制到 <prefix>/lib/ 或 <prefix>/bin/
  ↓ 生成 RenderMark.dll / .so / .dylib
  ↓ 生成 rendermark_export.h

target_include_directories(...)                install(TARGETS RenderMarkplugin)
  ↓ 添加 include 路径                            ↓ 复制到 <prefix>/lib/qml/RenderMark/

qt_add_qml_module(RenderMark ...)                
  ↓ 生成 qmldir, RenderMark.qmltypes            install(FILES *.h + rendermark_export.h)
  ↓ 生成 RenderMarkplugin.dll / .so              ↓ 复制到 <prefix>/include/RenderMark/
  ↓ 生成 plugin_init 代码
                                                install(FILES cmark-gfm.lib / .dll)
链接 cmark-gfm (vcpkg)                           ↓ 复制到 <prefix>/lib/ 和 <prefix>/bin/
  ↓ 使用 vcpkg 安装的库
                                                install(FILES *.qml, qmldir, *.qmltypes)
                                                ↓ 复制到 <prefix>/lib/qml/RenderMark/

configure_package_config_file()                 install(FILES RenderMarkConfig.cmake)
  ↓ 读取 .in 模板，替换路径                       ↓ 复制到 <prefix>/lib/cmake/RenderMark/
  ↓ 生成 RenderMarkConfig.cmake
```

---

## 六、安装后的目录结构

执行 `cmake --install <build-dir> --prefix D:/temp/RenderMark` 后：

```
D:/temp/RenderMark/
├── bin/
│   ├── appMarkQml.exe               # 主程序（可选，根项目安装的）
│   ├── RenderMark.dll               # RenderMark 主动态库（Windows）
│   ├── cmark-gfm.dll                # cmark-gfm 运行时（Windows）
│   └── cmark-gfm-extensions.dll     # cmark-gfm 扩展运行时（Windows）
├── include/RenderMark/
│   ├── Mark.h                        # C++ 头文件
│   ├── MarkNode.h
│   ├── MarkTree.h
│   └── rendermark_export.h           # 自动生成的导出/导入宏头文件
├── lib/
│   ├── RenderMark.lib                # Windows import library（链接时用）
│   ├── cmark-gfm.lib                 # cmark-gfm 导入库（已打包）
│   ├── cmark-gfm-extensions.lib      # cmark-gfm 扩展导入库（已打包）
│   ├── cmake/RenderMark/
│   │   ├── RenderMarkConfig.cmake    # CMake 包配置（find_package 用）
│   │   └── RenderMarkConfigVersion.cmake
│   └── qml/RenderMark/               # QML 模块
│       ├── qmldir                    # 模块描述
│       ├── RenderMark.qmltypes       # 类型信息（qmlls 用）
│       ├── RenderMarkplugin.dll      # QML 动态插件（运行时加载）
│       └── ... (25 个 .qml 文件)
```

**与静态库版本的关键区别**：
- `RenderMark.dll` 在 `bin/`（Windows）或 `lib/`（Linux/macOS），而不是 `RenderMark.lib` 静态库
- `RenderMarkplugin.dll` 在 `lib/qml/RenderMark/`（动态插件），而不是 `RenderMarkplugin.lib` 静态库
- **没有** `rendermark_plugin_import.cpp` —— 动态插件由 QML 引擎自动加载，不需要手动 `Q_IMPORT_PLUGIN`

---

## 七、外部项目怎么使用

### 7.1 CMake 配置

```cmake
# 1. 告诉 CMake 去哪里找 RenderMark
list(APPEND CMAKE_PREFIX_PATH "D:/temp/RenderMark")

# 2. 查找包
find_package(Qt6 REQUIRED COMPONENTS Quick)
find_package(RenderMark CONFIG REQUIRED)

# 3. 为 Qt Creator 的 QML Language Server 提供导入路径
set(QML_IMPORT_PATH "${RenderMark_QML_IMPORT_PATH}" CACHE STRING "")

# 4. 链接
qt_add_executable(MyApp main.cpp)
qt_add_qml_module(MyApp URI MyApp QML_FILES Main.qml)
target_link_libraries(MyApp PRIVATE Qt6::Quick RenderMark::RenderMark)
```

外部项目只需要链接 `RenderMark::RenderMark`，以下内容全部自动完成：
- 链接 `RenderMark.lib`（Windows import library）
- 链接 `cmark-gfm.lib` + `cmark-gfm-extensions.lib`
- 添加 `include/RenderMark` 到头文件搜索路径

### 7.2 C++ 代码中设置 QML 导入路径

```cpp
#include <QGuiApplication>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    // 让 QML 引擎能找到 RenderMark 模块
    engine.addImportPath("D:/temp/RenderMark/lib/qml");

    engine.load(QUrl(QStringLiteral("qrc:/Main.qml")));
    return app.exec();
}
```

**注意**：动态 QML 插件需要在运行时由 QML 引擎加载，所以必须调用 `engine.addImportPath()` 指向 `lib/qml/` 目录。QML 引擎会自动在 `lib/qml/RenderMark/` 下找到 `qmldir` 和 `RenderMarkplugin.dll` 并加载。

### 7.3 QML 中使用

```qml
import QtQuick
import RenderMark  // 动态插件自动加载，无需 Q_IMPORT_PLUGIN

Window {
    width: 800; height: 600; visible: true

    Mark {
        id: parser
    }

    Component.onCompleted: {
        let tree = parser.parse("# Hello\n\nThis is **bold**.")
        console.log(tree.root.plainText())
    }
}
```

### 7.4 运行时部署注意事项

由于 RenderMark 是动态库，外部项目发布时需要确保以下 DLL 在可执行文件同一目录或系统 PATH 中：

**Windows：**
- `RenderMark.dll`
- `cmark-gfm.dll`
- `cmark-gfm-extensions.dll`

**Linux：**
- `libRenderMark.so`
- `libcmark-gfm.so`
- `libcmark-gfm-extensions.so`

同时确保 QML 导入路径目录（`lib/qml/RenderMark/`）存在且包含 `qmldir` 和 `RenderMarkplugin.dll`。

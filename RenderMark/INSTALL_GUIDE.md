# RenderMark 安装配置详解

本文档逐行解释 `RenderMark/CMakeLists.txt` 中的**安装与导出**逻辑，帮助你理解 CMake 是如何把编译好的库打包、安装，并让外部项目通过 `find_package` 使用的。

---

## 一、整体目标

Build（编译）阶段完成后，我们得到一堆文件：
- `RenderMark.lib` —— 编译好的 C++ 静态库
- `RenderMarkplugin.lib` —— QML 插件静态库
- 一堆 `.obj`、`.qmlc` 等中间文件

Install（安装）阶段要做的是：**把外部项目真正需要的东西，复制到一个干净的目录里**。外部项目只需要：
1. 链接库文件（`.lib` / `.a`）
2. 包含头文件（`.h`）
3. 识别 QML 模块（`qmldir` + `.qml` + `.qmltypes`）
4. 找到 CMake 配置（`RenderMarkConfig.cmake`）

---

## 二、第一部分：库是怎么定义出来的（构建阶段）

```cmake
qt_add_library(RenderMark STATIC)                          # 创建一个叫 RenderMark 的静态库
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

```cmake
target_link_libraries(RenderMark
    PUBLIC
        Qt6::Quick                 # 链接 Qt Quick（公开依赖，外部项目也需要）
        ${CMARK_LIBS}              # 链接 cmark-gfm（Windows 下是动态库）
)
```

这里 `PUBLIC` 表示：**外部项目链接 RenderMark 时，会自动同时链接 Qt6::Quick 和 cmark-gfm**。

---

## 三、第二部分：安装规则详解（第 80~181 行）

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

### 3.2 安装静态库

```cmake
install(TARGETS RenderMark RenderMarkplugin
    EXPORT RenderMarkTargets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}    # .lib / .a 文件放这里
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}    # .so / .dylib 文件放这里
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}    # .dll / .exe 文件放这里
)
```

**作用**：把构建出来的 `RenderMark.lib` 和 `RenderMarkplugin.lib` 复制到安装目录的 `lib/` 下。

`EXPORT RenderMarkTargets` 是给 CMake 内部用的标记，表示"这俩目标属于 RenderMarkTargets 导出组"（虽然后面我们没有用 `install(EXPORT)` 来生成导出文件，而是用手动方式替代）。

三个 `DESTINATION` 的区别：
- `ARCHIVE` —— 静态库（Windows `.lib`，Linux `.a`）
- `LIBRARY` —— 共享库（Linux `.so`，macOS `.dylib`）
- `RUNTIME` —— 运行时（Windows `.dll`，可执行文件 `.exe`）

### 3.3 安装头文件

```cmake
install(FILES ${RENDERMARK_HEADERS}
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/RenderMark
)
```

**作用**：把 `Mark.h`、`MarkNode.h`、`MarkTree.h` 复制到 `include/RenderMark/` 下。

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

**为什么要打包 cmark-gfm？** 因为 RenderMark 是静态库，它把 cmark-gfm 的符号链接到了自己的 `.obj` 中。外部项目链接 RenderMark 时，编译器会看到这些符号，需要在链接阶段找到 cmark-gfm 的定义，所以外部项目也需要 cmark-gfm 的 `.lib` 文件。

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

安装后的路径：`lib/qml/RenderMark/`（包含 `qmldir` + `.qmltypes` + 所有 `.qml`）。

### 3.6 生成并安装静态插件导入文件

```cmake
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/rendermark_plugin_import.cpp"
    "#include <QtPlugin>\n"
    "Q_IMPORT_PLUGIN(RenderMarkPlugin)\n"
)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/rendermark_plugin_import.cpp"
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/RenderMark
)
```

**问题背景**：RenderMark 是静态库，它的 QML 插件也是静态的。Qt 的静态插件不会自动加载，需要 `Q_IMPORT_PLUGIN` 宏来注册。

**解决方式**：我们生成一个只有两行的 `.cpp` 文件，里面写了 `Q_IMPORT_PLUGIN(RenderMarkPlugin)`。然后通过 `RenderMarkConfig.cmake` 的 `INTERFACE_SOURCES` 属性，让外部项目自动编译这个文件。这样外部项目不需要手动写 `Q_IMPORT_PLUGIN`。

### 3.7 生成 CMake 包配置文件（核心：让 find_package 能工作）

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
- 有一个叫 `cmark-gfm` 的静态库
- 它的文件在 `${PACKAGE_PREFIX_DIR}/lib/cmark-gfm.lib`

同理创建 `cmark-gfm-extensions` 和 `RenderMarkplugin`。

```cmake
if(NOT TARGET RenderMark::RenderMark)
    add_library(RenderMark::RenderMark STATIC IMPORTED)
    set_target_properties(RenderMark::RenderMark PROPERTIES
        IMPORTED_LOCATION "${PACKAGE_PREFIX_DIR}/lib/RenderMark.lib"
        INTERFACE_INCLUDE_DIRECTORIES "${PACKAGE_PREFIX_DIR}/include/RenderMark"
        INTERFACE_LINK_LIBRARIES "Qt6::Quick;cmark-gfm;cmark-gfm-extensions;RenderMarkplugin"
    )
endif()
```

这是核心：**创建 `RenderMark::RenderMark` IMPORTED 目标**，包含三个关键属性：
- `IMPORTED_LOCATION` —— 库文件在哪里
- `INTERFACE_INCLUDE_DIRECTORIES` —— 头文件在哪里（外部项目 `#include <Mark.h>` 时自动添加 `-I`）
- `INTERFACE_LINK_LIBRARIES` —— 链接 RenderMark 时，自动链接 Qt6::Quick + cmark-gfm + cmark-gfm-extensions + RenderMarkplugin

```cmake
set_property(TARGET RenderMark::RenderMark APPEND PROPERTY
    INTERFACE_SOURCES "${PACKAGE_PREFIX_DIR}/include/RenderMark/rendermark_plugin_import.cpp"
)
```

**自动编译插件导入文件**。外部项目链接 `RenderMark::RenderMark` 时，CMake 会自动把 `rendermark_plugin_import.cpp` 加入编译列表，不需要用户手动处理 `Q_IMPORT_PLUGIN`。

```cmake
set(RenderMark_QML_IMPORT_PATH "${PACKAGE_PREFIX_DIR}/lib/qml")
```

提供一个变量，外部项目可以设置 `QML_IMPORT_PATH` 让 qmlls 找到 QML 模块。

---

## 五、完整流程图

```
构建阶段 (Build)                              安装阶段 (Install)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

qt_add_library(RenderMark STATIC)              install(TARGETS RenderMark RenderMarkplugin)
  ↓ 生成 RenderMark.lib                          ↓ 复制到 <prefix>/lib/
qt_add_qml_module(RenderMark ...)                
  ↓ 生成 qmldir, RenderMark.qmltypes            install(FILES *.h)
  ↓ 生成 RenderMarkplugin.lib                    ↓ 复制到 <prefix>/include/RenderMark/
  ↓ 生成 plugin_init 代码
                                                install(FILES cmark-gfm.lib / .dll)
链接 cmark-gfm (vcpkg)                           ↓ 复制到 <prefix>/lib/ 和 <prefix>/bin/
  ↓ 使用 vcpkg 安装的库
                                                install(FILES *.qml, qmldir, *.qmltypes)
                                                ↓ 复制到 <prefix>/lib/qml/RenderMark/
                                                install(FILES rendermark_plugin_import.cpp)
configure_package_config_file()                  ↓ 复制到 <prefix>/include/RenderMark/
  ↓ 读取 .in 模板，替换路径
  ↓ 生成 RenderMarkConfig.cmake
                                                install(FILES RenderMarkConfig.cmake)
                                                ↓ 复制到 <prefix>/lib/cmake/RenderMark/
```

---

## 六、安装后的目录结构

执行 `cmake --install <build-dir> --prefix D:/temp/RenderMark` 后：

```
D:/temp/RenderMark/
├── bin/
│   ├── appMarkQml.exe               # 主程序（可选，根项目安装的）
│   ├── cmark-gfm.dll                # cmark-gfm 运行时（Windows）
│   └── cmark-gfm-extensions.dll     # cmark-gfm 扩展运行时（Windows）
├── include/RenderMark/
│   ├── Mark.h                        # C++ 头文件
│   ├── MarkNode.h
│   ├── MarkTree.h
│   └── rendermark_plugin_import.cpp  # 静态插件自动注册文件
├── lib/
│   ├── RenderMark.lib                # 主静态库
│   ├── RenderMarkplugin.lib          # QML 插件静态库
│   ├── cmark-gfm.lib                 # cmark-gfm 导入库（已打包）
│   ├── cmark-gfm-extensions.lib      # cmark-gfm 扩展导入库（已打包）
│   └── cmake/RenderMark/
│       ├── RenderMarkConfig.cmake    # CMake 包配置（find_package 用）
│       └── RenderMarkConfigVersion.cmake
│   └── qml/RenderMark/               # QML 模块
│       ├── qmldir                    # 模块描述
│       ├── RenderMark.qmltypes       # 类型信息（qmlls 用）
│       └── ... (25 个 .qml 文件)
```

---

## 七、外部项目怎么使用

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
- 链接 `RenderMark.lib` + `RenderMarkplugin.lib`
- 链接 `cmark-gfm.lib` + `cmark-gfm-extensions.lib`
- 添加 `include/RenderMark` 到头文件搜索路径
- 自动编译 `rendermark_plugin_import.cpp`（注册 QML 静态插件）

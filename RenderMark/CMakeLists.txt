cmake_minimum_required(VERSION 3.16)

project(RenderMark LANGUAGES CXX VERSION 1.0.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_add_library(RenderMark SHARED)

include(GenerateExportHeader)
generate_export_header(RenderMark
    BASE_NAME RENDERMARK
    EXPORT_FILE_NAME "${CMAKE_CURRENT_BINARY_DIR}/rendermark_export.h"
)

set(RENDERMARK_QML_FILES
    RenderMark.qml
    MarkRowNodeComponent.qml
    MarkColumnNodeComponent.qml
    MarkNodeComponent.qml
    MarkNodeHeading.qml
    MarkOutline.qml
    MarkNodeText.qml
    MarkNodeItem.qml
    MarkNodeCode.qml
    MarkNodeCodeBlock.qml
    MarkNodeLink.qml
    MarkNodeImage.qml
    MarkNodeStrong.qml
    MarkNodeEmphasis.qml
    MarkNodeStrikethrough.qml
    MarkNodeTable.qml
    MarkNodeTableCell.qml
    MarkNodeBlockQuote.qml
    MarkNodeThematicBreak.qml
    MarkNodeDocument.qml
    MarkNodeHtmlBlock.qml
    MarkNodeFootnoteDefinition.qml
    MarkNodeSoftbreak.qml
    MarkNodeLinebreak.qml
    MarkNodeHtmlInline.qml
    MarkNodeFootnoteReference.qml
    MarkNodeUnknown.qml
)

set(RENDERMARK_HEADERS
    Mark.h
    MarkNode.h
    MarkTree.h
)

set(RENDERMARK_SOURCES
    Mark.cpp
    MarkNode.cpp
    MarkTree.cpp
)

qt_add_qml_module(RenderMark
    URI RenderMark
    VERSION 1.0
    QML_FILES ${RENDERMARK_QML_FILES}
    SOURCES ${RENDERMARK_HEADERS} ${RENDERMARK_SOURCES}
)

if(ANDROID)
    set(CMARK_LIBS
        libcmark-gfm_static
        libcmark-gfm-extensions_static
    )
else()
    set(CMARK_LIBS
        libcmark-gfm
        libcmark-gfm-extensions
    )
endif()

target_link_libraries(RenderMark
    PUBLIC
        Qt6::Quick
        ${CMARK_LIBS}
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

# -----------------------------------------------------------------------
# 安装与导出（使外部项目可通过 find_package(RenderMark) 使用）
# -----------------------------------------------------------------------

include(GNUInstallDirs)

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

# 安装头文件
install(FILES ${RENDERMARK_HEADERS}
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/RenderMark
)

# Install generated export header
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/rendermark_export.h"
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/RenderMark
)

# 安装 cmark-gfm 依赖库（一起打包，使用者无需自行安装）
# vcpkg 默认安装动态库：lib/ 下是 implib，bin/ 下是 DLL
set(CMARK_VCPKG_DIR "${_VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}")
if(NOT EXISTS "${CMARK_VCPKG_DIR}")
    # 回退：尝试从目标属性推导
    get_target_property(CMARK_GFM_IMPLIB libcmark-gfm IMPORTED_IMPLIB_RELEASE)
    get_target_property(CMARK_GFM_DLL libcmark-gfm IMPORTED_LOCATION_RELEASE)
    get_filename_component(CMARK_VCPKG_DIR "${CMARK_GFM_IMPLIB}" DIRECTORY)
    get_filename_component(CMARK_VCPKG_DIR "${CMARK_VCPKG_DIR}" DIRECTORY)
endif()

if(ANDROID)
    # Android 平台：cmark-gfm 是静态库（.a），通过目标属性获取实际路径
    get_target_property(CMARK_GFM_LIB libcmark-gfm_static IMPORTED_LOCATION)
    get_target_property(CMARK_GFM_EXT_LIB libcmark-gfm-extensions_static IMPORTED_LOCATION)
    if(CMARK_GFM_LIB AND CMARK_GFM_EXT_LIB)
        install(FILES ${CMARK_GFM_LIB} ${CMARK_GFM_EXT_LIB}
            DESTINATION ${CMAKE_INSTALL_LIBDIR}
        )
    endif()
elseif(EXISTS "${CMARK_VCPKG_DIR}")
    # Windows 平台：vcpkg 默认安装动态库，lib/ 下是 implib，bin/ 下是 DLL
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
# 注：cmark-gfm 头文件不安装，因为 RenderMark 的公开头文件未暴露其 API

set(CMARK_GFM_BUNDLED TRUE)

# 安装 QML 原始文件（便于外部开发时引用或调试）
set(CMAKE_INSTALL_QMLDIR "${CMAKE_INSTALL_LIBDIR}/qml" CACHE PATH "QML import path")
install(FILES ${RENDERMARK_QML_FILES}
    DESTINATION ${CMAKE_INSTALL_QMLDIR}/RenderMark
)

# 安装 qmldir 文件（QML 引擎识别模块所需）
# qt_add_qml_module 会在构建目录生成 qmldir，位置为 ${CMAKE_CURRENT_BINARY_DIR}/qmldir
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/qmldir"
    DESTINATION ${CMAKE_INSTALL_QMLDIR}/RenderMark
)

# 安装 .qmltypes 文件（QML Language Server 识别类型所需）
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/RenderMark.qmltypes"
    DESTINATION ${CMAKE_INSTALL_QMLDIR}/RenderMark
)

# 生成 CMake 包配置文件（手动定义 IMPORTED 目标，避免导出 QML 内部资源目标）
include(CMakePackageConfigHelpers)

configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/RenderMarkConfig.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/RenderMarkConfig.cmake"
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/RenderMark
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


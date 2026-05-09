cmake_minimum_required(VERSION 3.16)

project(RenderMark LANGUAGES CXX VERSION 1.0.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_add_library(RenderMark STATIC)

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

# -----------------------------------------------------------------------
# 安装与导出（使外部项目可通过 find_package(RenderMark) 使用）
# -----------------------------------------------------------------------

include(GNUInstallDirs)

# 安装静态库
install(TARGETS RenderMark
    EXPORT RenderMarkTargets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# 安装头文件
install(FILES ${RENDERMARK_HEADERS}
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/RenderMark
)

# 安装 QML 原始文件（便于外部开发时引用或调试）
set(CMAKE_INSTALL_QMLDIR "${CMAKE_INSTALL_LIBDIR}/qml" CACHE PATH "QML import path")
install(FILES ${RENDERMARK_QML_FILES}
    DESTINATION ${CMAKE_INSTALL_QMLDIR}/RenderMark
)

# 生成 CMake 包配置文件（手动定义 IMPORTED 目标，避免导出 QML 内部资源目标）
include(CMakePackageConfigHelpers)

# 把当前平台使用的 cmark 目标名传给配置模板
set(CMARK_GFM_TARGET "libcmark-gfm")
set(CMARK_GFM_EXTENSIONS_TARGET "libcmark-gfm-extensions")
if(ANDROID)
    set(CMARK_GFM_TARGET "libcmark-gfm_static")
    set(CMARK_GFM_EXTENSIONS_TARGET "libcmark-gfm-extensions_static")
endif()

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

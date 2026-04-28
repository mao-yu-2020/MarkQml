cmake_minimum_required(VERSION 3.16)

project(RenderMark LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)

find_package(cmark-gfm CONFIG REQUIRED)
find_package(cmark-gfm-extensions CONFIG REQUIRED)

qt_add_library(RenderMark STATIC)

qt_add_qml_module(RenderMark
    URI RenderMark
    VERSION 1.0
    QML_FILES
        RenderMark.qml
        MarkNodeHeading.qml
        MarkNodeParagraph.qml
        MarkNodeCodeBlock.qml
        MarkNodeList.qml
        MarkNodeItem.qml
        MarkNodeBlockQuote.qml
        MarkNodeThematicBreak.qml
        MarkNodeTable.qml
        MarkNodeTableRow.qml
        MarkNodeTableCell.qml
        MarkNodeText.qml
        MarkNodeInlineCode.qml
        MarkNodeStrong.qml
        MarkNodeEmphasis.qml
        MarkNodeLink.qml
        MarkNodeImage.qml
        MarkNodeStrikethrough.qml
        MarkNodeSoftbreak.qml
        MarkNodeLinebreak.qml
    SOURCES
        Mark.h
        Mark.cpp
        MarkNode.h
        MarkNode.cpp
        MarkTree.h
        MarkTree.cpp
)

target_link_libraries(RenderMark
    PUBLIC
        Qt6::Quick
        libcmark-gfm
        libcmark-gfm-extensions
)

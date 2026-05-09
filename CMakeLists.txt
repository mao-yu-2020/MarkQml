cmake_minimum_required(VERSION 3.16)

project(MarkQml VERSION 1.1.0 LANGUAGES CXX)

find_package(Qt6 REQUIRED COMPONENTS Quick)
find_package(cmark-gfm CONFIG REQUIRED)
find_package(cmark-gfm-extensions CONFIG REQUIRED)

qt_standard_project_setup(REQUIRES 6.8)

add_subdirectory(RenderMark)

qt_add_executable(appMarkQml main.cpp)

qt_add_qml_module(appMarkQml
    URI MarkQml
    QML_FILES Main.qml
)

set_target_properties(appMarkQml PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appMarkQml PRIVATE Qt6::Quick RenderMark)

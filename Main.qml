import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import RenderMark

Window {
    id: mainWindow
    width: 1024
    height: 768
    visible: true
    title: qsTr("MarkQml - Markdown 渲染器")

    // 默认展示一段测试 Markdown，方便初次打开即可看到效果
    property string markdownText:
"# MarkQml 测试文档\n\n" +
"这是一个 **粗体** 和 *斜体* 的测试。\n\n" +
"## 代码块\n\n" +
"```cpp\n" +
"#include <iostream>\n\n" +
"int main() {\n" +
"    std::cout << \"Hello MarkQml!\" << std::endl;\n" +
"    return 0;\n" +
"}\n" +
"```\n\n" +
"## 列表演示\n\n" +
"- 无序列表项 A\n" +
"- 无序列表项 B\n" +
"- 无序列表项 C\n\n" +
"1. 有序列表项 1\n" +
"2. 有序列表项 2\n" +
"3. 有序列表项 3\n\n" +
"## 链接与图片\n\n" +
"[Qt 官方网站](https://www.qt.io)\n\n" +
"## 表格\n\n" +
"| 名称 | 类型 | 说明 |\n" +
"|------|------|------|\n" +
"| Mark | class | Markdown 解析器 |\n" +
"| MarkNode | class | AST 节点 |\n" +
"| MarkTree | class | AST 树容器 |\n\n" +
"> 这是一段引用块的内容。\n\n" +
"---\n\n" +
"**请使用上方按钮打开本地的 .md 文件进行测试。**"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // 顶部工具栏
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Button {
                text: "📂 打开 Markdown 文件"
                onClicked: fileDialog.open()
            }

            Button {
                text: "🌲 打印节点树"
                onClicked: {
                    if (renderMark.tree) {
                        console.log(renderMark.tree.printTree())
                    } else {
                        console.log("节点树为空")
                    }
                }
            }

            ComboBox {
                id: themeSelector
                Layout.preferredWidth: 160
                model: [
                    { name: "☀️ Daylight", theme: "daylight", preview: "#ffffff" },
                    { name: "🌙 Midnight", theme: "midnight", preview: "#0d1117" },
                    { name: "❄️ Glacier",  theme: "glacier",  preview: "#f0f9ff" },
                    { name: "🔥 Caramel",  theme: "caramel",  preview: "#fff7ed" },
                    { name: "🌲 Forest",   theme: "forest",   preview: "#f0fdf4" },
                    { name: "💜 Neon",     theme: "neon",     preview: "#1a0b2e" }
                ]
                textRole: "name"
                valueRole: "theme"
                currentIndex: 0

                delegate: ItemDelegate {
                    width: themeSelector.width
                    height: 32
                    contentItem: Row {
                        spacing: 8
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle {
                            width: 12
                            height: 12
                            radius: 6
                            color: modelData.preview
                            border.color: "#cccccc"
                            border.width: 1
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: modelData.name
                            color: parent.parent.palette.text
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    highlighted: themeSelector.highlightedIndex === index
                }

                displayText: currentIndex >= 0 && currentIndex < model.length
                    ? model[currentIndex].name
                    : ""

                onActivated: {
                    switch (model[index].theme) {
                        case "daylight": renderMark.setDaylightTheme(); break;
                        case "midnight": renderMark.setMidnightTheme(); break;
                        case "glacier":  renderMark.setGlacierTheme();  break;
                        case "caramel":  renderMark.setCaramelTheme();  break;
                        case "forest":   renderMark.setForestTheme();   break;
                        case "neon":     renderMark.setNeonTheme();     break;
                    }
                }
            }

            Label {
                text: "MarkQml 渲染测试"
                font.pixelSize: 18
                font.bold: true
            }

            Item {
                Layout.fillWidth: true
            }

            Label {
                text: "当前：" + (fileDialog.currentFile.toString().length > 0
                    ? decodeURIComponent(fileDialog.currentFile.toString().replace("file:///", ""))
                    : "默认测试文档")
                font.pixelSize: 12
                color: "#666666"
            }
        }

        // 渲染区域
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            color: renderMark.bgColor

            RenderMark {
                id: renderMark
                anchors.fill: parent
                anchors.margins: 16
                markdown: mainWindow.markdownText

                // tree 重新渲染时清空大纲
                onTreeReady: outlineView.rebuild()

                // heading 渲染完成时手动注册到大纲组件
                headingNodeCallback: (item) => {
                    outlineView.registerHeading(item.astNode, item)
                }
            }

            // 右侧悬浮大纲预览（50% 透明度，用于测试效果）
            MarkOutline {
                id: outlineView
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 16
                width: parent.width / 3
                opacity: 0.5
                onHeadingClicked: (node, item) => {
                    if (item) renderMark.scrollToHeading(item);
                }
            }
        }
    }

    Component.onCompleted: {
        renderMark.setDaylightTheme()
    }

    // 文件对话框
    FileDialog {
        id: fileDialog
        title: "选择一个 Markdown 文件"
        nameFilters: ["Markdown files (*.md)", "All files (*)"]

        onAccepted: {
            var fileUrl = fileDialog.currentFile.toString()
            var lastSlash = fileUrl.lastIndexOf("/")
            if (lastSlash >= 0) {
                renderMark.baseUrl = fileUrl.substring(0, lastSlash + 1)
            }

            renderMark.source = fileUrl
        }
    }
}

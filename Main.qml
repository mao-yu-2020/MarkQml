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
            color: "#fafafa"
            border.color: "#dddddd"
            border.width: 1
            radius: 4

            RenderMark {
                id: renderMark
                anchors.fill: parent
                anchors.margins: 16
                markdown: mainWindow.markdownText
            }
        }
    }

    Mark {
        id: _mark
    }

    // 文件对话框
    FileDialog {
        id: fileDialog
        title: "选择一个 Markdown 文件"
        nameFilters: ["Markdown files (*.md)", "All files (*)"]

        onAccepted: {
            var localPath = decodeURIComponent(fileDialog.currentFile.toString().replace("file:///", ""))
            renderMark.markdown = ""
            renderMark.tree = _mark.parseFile(localPath)
        }
    }
}

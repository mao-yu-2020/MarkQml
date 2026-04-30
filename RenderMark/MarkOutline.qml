import QtQuick
import QtQuick.Controls

/**
 * @brief Markdown 大纲预览组件
 *
 * 独立组件，接收纯 JS 对象数组（每项含 text/level/node）并展示为层级列表。
 * 与 Markdown AST / MarkNode 完全解耦，仅依赖外部注入的数据。
 * 点击某一项时发出 headingClicked(node) 信号，由外部决定如何滚动定位。
 */
ListView {
    id: root

    // -----------------------------------------------------------------------
    // 公共属性
    // -----------------------------------------------------------------------

    /** @brief 大纲数据，每项为 { text: string, level: int, node: var } */
    property var modelData: []

    /** @brief 当前高亮的 heading 节点 */
    property var currentHeading: null

    /** @brief 文本颜色 */
    property color textColor: "#2c3e50"

    /** @brief 高亮背景色 */
    property color highlightColor: "#e0f2fe"

    /** @brief 高亮文本颜色 */
    property color highlightTextColor: "#0284c7"

    /** @brief 基础字体大小 */
    property int baseFontSize: 14

    /** @brief 每级缩进像素 */
    property int indentSize: 16

    /** @brief 项高度 */
    property int itemHeight: 32

    // -----------------------------------------------------------------------
    // 信号
    // -----------------------------------------------------------------------

    /** @brief 用户点击某一大纲项 */
    signal headingClicked(var headingNode)

    // -----------------------------------------------------------------------
    // 模型
    // -----------------------------------------------------------------------

    model: root.modelData

    // -----------------------------------------------------------------------
    // Delegate
    // -----------------------------------------------------------------------

    delegate: Rectangle {
        required property var modelData

        width: ListView.view.width
        height: root.itemHeight
        color: root.currentHeading === modelData.node ? root.highlightColor : "transparent"

        Label {
            anchors.verticalCenter: parent.verticalCenter
            x: (modelData.level - 1) * root.indentSize + 8
            text: modelData.text || ""
            color: root.currentHeading === modelData.node ? root.highlightTextColor : root.textColor
            font.pointSize: root.baseFontSize - (modelData.level > 2 ? 1 : 0)
            font.bold: modelData.level <= 2
            elide: Text.ElideRight
            width: parent.width - x - 8
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.currentHeading = modelData.node;
                root.headingClicked(modelData.node);
            }
        }
    }
}

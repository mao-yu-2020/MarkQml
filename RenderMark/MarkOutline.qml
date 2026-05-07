pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

/**
 * @brief Markdown 大纲预览组件
 *
 * 自包含组件，内部维护 heading 映射表与大纲数据。
 * 可与 RenderMark 的 outline 属性绑定，自动接收 heading 注册与树重建事件。
 * 点击某一项时发出 headingClicked(node, item) 信号，由外部决定如何滚动定位。
 */
ListView {
    id: root

    // -----------------------------------------------------------------------
    // 内部状态
    // -----------------------------------------------------------------------

    /** @brief 大纲数据，每项为 { text: string, level: int, node: var, item: var } */
    property var outlineData: []

    /** @brief 当前高亮的 heading 节点 */
    property var currentHeading: null

    // -----------------------------------------------------------------------
    // 外观属性
    // -----------------------------------------------------------------------

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
    signal headingClicked(var headingNode, var headingItem)

    // -----------------------------------------------------------------------
    // 公共方法
    // -----------------------------------------------------------------------

    /**
     * @brief 注册 heading 节点与其对应的 QML Item，并追加到大纲数据
     * @param node heading 对应的 MarkNode 指针
     * @param item heading 渲染后的 QML Item
     */
    function registerHeading(node, item) {
        if (node && item) {
            outlineData.push({
                node: node,
                item: item,
                level: node.level,
                text: node.plainText ? node.plainText() : ""
            });
            outlineData = outlineData;
        }
    }

    /**
     * @brief 重建大纲数据并清空旧数据
     */
    function rebuild() {
        outlineData = [];
    }

    // -----------------------------------------------------------------------
    // 模型
    // -----------------------------------------------------------------------

    model: root.outlineData

    // -----------------------------------------------------------------------
    // Delegate
    // -----------------------------------------------------------------------

    delegate: Rectangle {
        id: item
        required property var modelData

        width: ListView.view.width
        height: root.itemHeight
        color: root.currentHeading === modelData.node ? root.highlightColor : "transparent"

        Label {
            anchors.verticalCenter: parent.verticalCenter
            x: (item.modelData.level - 1) * root.indentSize + 8
            text: item.modelData.text || ""
            color: root.currentHeading === item.modelData.node ? root.highlightTextColor : root.textColor
            font.pointSize: root.baseFontSize - (item.modelData.level > 2 ? 1 : 0)
            font.bold: item.modelData.level <= 2
            elide: Text.ElideRight
            width: parent.width - x - 8
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.currentHeading = item.modelData.node;
                root.headingClicked(modelData.node, modelData.item);
            }
        }
    }
}

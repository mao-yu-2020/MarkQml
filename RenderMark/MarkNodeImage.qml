pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

/**
 * @brief 图片（image）渲染组件
 *
 * 加载并显示图片，限制最大宽度为 600px，支持悬浮提示标题。
 * 本地路径会自动补全 file:/// 前缀。
 */
Image {
    id: root

    required property var astNode
    required property var astStyle

    source: {
        var url = astNode.url;
        if (url.indexOf("://") === -1) {
            url = "file:///" + url.replace(/\\/g, "/");
        }
        return url;
    }

    fillMode: Image.PreserveAspectFit
    sourceSize.width: 600

    onStatusChanged: {
        if (status === Image.Error) {
            console.log("Failed to load image:", astNode.url);
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        ToolTip {
            visible: parent.containsMouse
            text: root.astNode.title || root.astNode.url
            delay: 500
        }
    }
}

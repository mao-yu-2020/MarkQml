pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

/**
 * @brief 图片（image）渲染组件
 *
 * 加载并显示图片，限制最大宽度为 600px。
 * 本地路径自动补全 file:/// 前缀。
 * 加载失败时显示占位提示。
 */
Item {
    id: root

    required property var astNode
    required property var astStyle

    width: image.status === Image.Ready ? image.implicitWidth : 400
    height: image.status === Image.Ready ? image.implicitHeight : 200

    Image {
        id: image
        x: 0
        y: 0
        fillMode: Image.PreserveAspectFit
        sourceSize.width: 600

        source: {
            var url = astNode.url;
            if (url.indexOf("://") === -1) {
                url = "file:///" + url.replace(/\\/g, "/");
            }
            return url;
        }

        onStatusChanged: {
            if (status === Image.Error) {
                console.log("Failed to load image:", astNode.url);
            }
        }
    }

    Rectangle {
        visible: image.status !== Image.Ready
        anchors.fill: parent
        color: root.astStyle.codeBackground
        border.color: root.astStyle.tableBorder
        border.width: 1
        radius: 4

        Column {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: image.status === Image.Loading ? "加载中..." : "图片加载失败"
                color: root.astStyle.textColor
                font.pixelSize: root.astStyle.baseFontSize
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: root.astNode.url
                color: root.astStyle.textColor
                font.pixelSize: root.astStyle.baseFontSize * 0.75
                opacity: 0.6
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.parent.width - 32
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}

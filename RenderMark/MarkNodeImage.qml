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

    property var astNode: null
    property var astStyle: null

    function init(node, style) {
        astNode = node;
        astStyle = style;
    }

    Binding on width {
        value: {
            if (!root.astNode) return 0;
            return image.status === Image.Ready ? image.implicitWidth : 400;
        }
        when: root.astNode !== null
    }

    Binding on height {
        value: {
            if (!root.astNode) return 0;
            return image.status === Image.Ready ? image.implicitHeight : 200;
        }
        when: root.astNode !== null
    }

    Image {
        id: image
        x: 0
        y: 0
        fillMode: Image.PreserveAspectFit
        sourceSize.width: 600

        Binding on source {
            value: {
                if (!root.astNode) return "";
                var url = root.astNode.url;
                if (url.indexOf("://") === -1) {
                    url = "file:///" + url.replace(/\\/g, "/");
                }
                return url;
            }
            when: root.astNode !== null
        }

        onStatusChanged: {
            if (status === Image.Error && root.astNode) {
                console.log("Failed to load image:", root.astNode.url);
            }
        }
    }

    Rectangle {
        id: placeholderRect
        visible: image.status !== Image.Ready
        anchors.fill: parent
        Binding on color {
            value: root.astStyle.codeBackground
            when: root.astStyle !== null
        }
        Binding on border.color {
            value: root.astStyle.tableBorder
            when: root.astStyle !== null
        }
        border.width: 1
        radius: 4

        Column {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: image.status === Image.Loading ? "加载中..." : "图片加载失败"
                Binding on color {
                    value: root.astStyle.textColor
                    when: root.astStyle !== null
                }
                Binding on font.pixelSize {
                    value: root.astStyle.baseFontSize
                    when: root.astStyle !== null
                }
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: root.astNode ? root.astNode.url : ""
                Binding on color {
                    value: root.astStyle.textColor
                    when: root.astStyle !== null
                }
                Binding on font.pixelSize {
                    value: root.astStyle.baseFontSize * 0.75
                    when: root.astStyle !== null
                }
                opacity: 0.6
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.parent.width - 32
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}

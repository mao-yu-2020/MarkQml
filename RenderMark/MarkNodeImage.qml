pragma ComponentBehavior: Bound

import QtQuick

/**
 * @brief Image renderer.
 *
 * Markdown images are inline by nature, but a standalone image block still
 * needs a hard width bound. Keep the image inside the available column and
 * preserve its aspect ratio; remote images are loaded asynchronously and never
 * force the document wider than the chat surface.
 */
Item {
    id: root

    property var astNode: null
    property var renderMark: null

    readonly property var astStyle: renderMark ? renderMark.style : null

    readonly property real maxImageWidth: {
        if (!root.astStyle)
            return 600
        var configured = root.astStyle.imageStyle.maxWidth
        if (configured > 0)
            return configured
        if (root.parent && root.parent.width > 0)
            return root.parent.width
        return 600
    }

    readonly property real maxImageHeight: {
        if (!root.astStyle)
            return -1
        return root.astStyle.imageStyle.maxHeight
    }

    readonly property real pictureWidth: {
        if (image.status === Image.Ready && image.implicitWidth > 0)
            return Math.min(image.implicitWidth, maxImageWidth)
        return Math.min(400, maxImageWidth)
    }

    readonly property real pictureHeight: {
        if (image.status === Image.Ready && image.implicitWidth > 0) {
            var height = pictureWidth * image.implicitHeight / image.implicitWidth
            if (maxImageHeight > 0)
                height = Math.min(height, maxImageHeight)
            return height
        }
        return Math.min(200, maxImageHeight > 0 ? maxImageHeight : 200)
    }

    function init(node, rm) {
        astNode = node
        renderMark = rm
    }

    width: pictureWidth
    height: pictureHeight

    Image {
        id: image
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        cache: true
        sourceSize.width: root.maxImageWidth > 0 ? root.maxImageWidth : 600

        Binding on source {
            value: {
                if (!root.astNode)
                    return ""
                var url = root.astNode.url
                if (!url)
                    return ""
                if (root.renderMark && !root.renderMark.isSafeImageUrl(url))
                    return ""
                if (url.indexOf("://") === -1) {
                    if (root.renderMark && root.renderMark.baseUrl) {
                        var base = root.renderMark.baseUrl.toString()
                        if (base.charAt(base.length - 1) !== "/")
                            base += "/"
                        url = base + url.replace(/\\/g, "/")
                    } else {
                        url = "file:///" + url.replace(/\\/g, "/")
                    }
                }
                return url
            }
            when: root.astNode !== null
        }

        onStatusChanged: {
            if (status === Image.Error && root.astNode)
                console.log("Failed to load image:", root.astNode.url)
        }
    }

    Rectangle {
        id: placeholderRect
        visible: image.status !== Image.Ready
        anchors.fill: parent
        color: root.astStyle ? root.astStyle.imageStyle.placeholderBg : "#f1f5f9"
        border.color: root.astStyle ? root.astStyle.imageStyle.placeholderBorderColor : "#e2e8f0"
        border.width: 1
        radius: root.astStyle ? root.astStyle.imageStyle.radius : 0

        Column {
            anchors.centerIn: parent
            spacing: 8
            width: Math.max(0, parent.width - 32)

            Text {
                text: image.status === Image.Loading ? "加载中..." : "图片加载失败"
                color: root.astStyle ? root.astStyle.imageStyle.placeholderTextColor : "#1a1a2e"
                font.pixelSize: root.astStyle ? root.astStyle.imageStyle.placeholderFontSize : 14
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: root.astNode ? root.astNode.url : ""
                color: root.astStyle ? root.astStyle.imageStyle.placeholderTextColor : "#1a1a2e"
                font.pixelSize: root.astStyle ? root.astStyle.imageStyle.placeholderFontSize * 0.75 : 10
                opacity: 0.6
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}

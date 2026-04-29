import QtQuick
import QtQuick.Controls


Label {
    id: root

    required property var astNode
    required property var astStyle

    text: astNode.content

    color: {
        var p = astNode.parentNode;
        while (p) {
            if (p.isLink && p.isLink()) return astStyle.linkColor;
            p = p.parentNode;
        }
        return astStyle.textColor;
    }

    font.pixelSize: {
        let parentNode = astNode.parentNode;
        if (parentNode && parentNode.isHeading && parentNode.isHeading()) {
            switch (parentNode.level) {
            case 1: return astStyle.baseFontSize * 2.0;
            case 2: return astStyle.baseFontSize * 1.75;
            case 3: return astStyle.baseFontSize * 1.5;
            case 4: return astStyle.baseFontSize * 1.25;
            case 5: return astStyle.baseFontSize * 1.125;
            case 6: return astStyle.baseFontSize * 1.0;
            }
        }
        return astStyle.baseFontSize;
    }

    font.bold: {
        var p = astNode.parentNode;
        while (p) {
            if (p.isStrong && p.isStrong()) return true;
            p = p.parentNode;
        }
        return false;
    }

    font.italic: {
        var p = astNode.parentNode;
        while (p) {
            if (p.isEmphasis && p.isEmphasis()) return true;
            p = p.parentNode;
        }
        return false;
    }

    font.underline: {
        var p = astNode.parentNode;
        while (p) {
            if (p.isLink && p.isLink()) return true;
            p = p.parentNode;
        }
        return false;
    }

    font.strikeout: {
        var p = astNode.parentNode;
        while (p) {
            if (p.isStrikethrough && p.isStrikethrough()) return true;
            p = p.parentNode;
        }
        return false;
    }

    Component.onCompleted: {
        console.log("content: ", astNode.content)
    }

}

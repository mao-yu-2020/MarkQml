import QtQuick
import QtQuick.Controls


Label {
    id: root

    required property var astNode
    required property var astStyle

    text: astNode.content
    color: astNode.parentNode && astNode.parentNode.isLink() ? astStyle.linkColor : astStyle.textColor

    font.pixelSize: {
        let parentNode = astNode.parentNode;
        if (parentNode && parentNode.isHeading()) {
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

    font.bold:      astNode.parentNode && astNode.parentNode.isStrong()
    font.italic:    astNode.parentNode && astNode.parentNode.isEmphasis()
    font.underline: astNode.parentNode && astNode.parentNode.isLink()
}

pragma ComponentBehavior: Bound

import QtQuick

Column {
    id: root

    required property var astNode
    required property var astStyle

    Repeater {

        model: root.astNode.children

        MarkNodeComponent {

            required property var modelData

            astNode: modelData
            astStyle: root.astStyle


        }

    }
}

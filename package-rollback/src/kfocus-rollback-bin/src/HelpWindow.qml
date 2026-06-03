import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as Controls
import org.kde.kirigami 2.20 as Kirigami

Kirigami.ApplicationWindow {
    id: root
    property string helpText  : ''
    property string helpTitle : ''

    title: helpTitle

    width         : Kirigami.Units.gridUnit * 30
    height        : Kirigami.Units.gridUnit * 22
    minimumWidth  : Kirigami.Units.gridUnit * 30
    minimumHeight : Kirigami.Units.gridUnit * 22

    pageStack.initialPage : Kirigami.Page {
        title : helpTitle

        RowLayout {
            anchors.fill : parent
            Kirigami.Icon {
                Layout.alignment       : Qt.AlignTop
                Layout.preferredHeight : Kirigami.Units.gridUnit * 3
                Layout.preferredWidth  : Kirigami.Units.gridUnit * 3
                Layout.rightMargin     : Kirigami.Units.gridUnit * 0.25
                source                 : 'dialog-information'
            }
            Controls.Label {
                text             : helpText
                wrapMode         : Text.WordWrap
                Layout.fillWidth : true
                Layout.alignment : Qt.AlignTop
            }
        }
    }
}

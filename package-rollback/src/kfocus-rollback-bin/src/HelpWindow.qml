import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
    id: root
    property string helpText  : ''
    property string helpTitle : ''

    title: helpTitle

    width         : Kirigami.Units.gridUnit * 35
    height        : Kirigami.Units.gridUnit * 27
    minimumWidth  : Kirigami.Units.gridUnit * 35
    minimumHeight : Kirigami.Units.gridUnit * 27

    pageStack.initialPage : Kirigami.Page {
        title : helpTitle

        RowLayout {
            anchors.fill : parent
            Kirigami.Icon {
                Layout.alignment       : Qt.AlignTop
                Layout.preferredHeight : Kirigami.Units.gridUnit * 3
                Layout.preferredWidth  : Kirigami.Units.gridUnit * 3
                Layout.rightMargin     : Kirigami.Units.gridUnit * 0.5
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

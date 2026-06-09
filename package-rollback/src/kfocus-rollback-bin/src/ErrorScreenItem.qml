import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

ColumnLayout {
    property string infoText : ''
    property bool isCritical : false

    signal okClicked();

    anchors {
        right        : parent.right
        top          : parent.top
        bottom       : parent.bottom
        rightMargin  : Kirigami.Units.gridUnit * 1
        topMargin    : Kirigami.Units.gridUnit * 4.28
        bottomMargin : Kirigami.Units.gridUnit * 1
    }
    width : parent.width
      - snapshotListView.width
      - (Kirigami.Units.gridUnit * 3)

    RowLayout {
        Kirigami.Icon {
            Layout.alignment       : Qt.AlignTop
            Layout.preferredHeight : Kirigami.Units.gridUnit * 3
            Layout.preferredWidth  : Kirigami.Units.gridUnit * 3
            Layout.rightMargin     : Kirigami.Units.gridUnit * 0.5
            source                 : isCritical
              ? 'dialog-error'
              : 'dialog-warning'
        }
        Controls.Label {
            text             : infoText
            wrapMode         : Text.WordWrap
            Layout.fillWidth : true
            Layout.alignment : Qt.AlignTop
        }
    }

    Item {
        Layout.fillHeight : true
    }

    Controls.Button {
        text                  : 'OK'
        Layout.preferredWidth : Kirigami.Units.gridUnit * 8.4
        Layout.alignment      : Qt.AlignRight
        onClicked             : {
            okClicked();
        }

        HoverHandler {
            cursorShape : Qt.PointingHandCursor
        }
    }
}

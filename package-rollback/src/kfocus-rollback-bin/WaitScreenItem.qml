import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as Controls
import org.kde.kirigami 2.20 as Kirigami

ColumnLayout {
    property string headerText  : ''
    property string description : ''

    anchors {
        right        : parent.right
        top          : parent.top
        bottom       : parent.bottom
        rightMargin  : Kirigami.Units.gridUnit * 0.75
        topMargin    : Kirigami.Units.gridUnit * 3.5
        bottomMargin : Kirigami.Units.gridUnit * 0.775
    }
    width : parent.width
      - snapshotListView.width
      - (Kirigami.Units.gridUnit * 2.40)

    Controls.BusyIndicator {
        Layout.alignment       : Qt.AlignHCenter
        Layout.preferredHeight : Kirigami.Units.gridUnit * 6
        Layout.preferredWidth  : Kirigami.Units.gridUnit * 6
        Layout.topMargin       : Kirigami.Units.gridUnit * 1
        Layout.bottomMargin    : Kirigami.Units.gridUnit * 1
        running                : true
    }

    Kirigami.Heading {
        Layout.alignment    : Qt.AlignHCenter | Qt.AlignTop
        Layout.bottomMargin : Kirigami.Units.gridUnit * 0.5
        text                : headerText
        level               : 1
    }

    Controls.Label {
        Layout.fillWidth : true
        text             : description
        wrapMode         : Text.WordWrap
    }

    Item {
        Layout.fillHeight : true
    }
}

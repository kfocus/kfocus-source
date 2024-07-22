import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as Controls
import org.kde.kirigami 2.20 as Kirigami

ColumnLayout {
    property string infoText: ''

    signal okAction()
    signal cancelled()
    signal linkActivated(string link)

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

    Controls.Label {
        text             : infoText
        wrapMode         : Text.WordWrap
        onLinkActivated  : parent.linkActivated(link)
        Layout.fillWidth : true
        Layout.alignment : Qt.AlignTop
    }

    Item {
        Layout.fillHeight : true
    }
}

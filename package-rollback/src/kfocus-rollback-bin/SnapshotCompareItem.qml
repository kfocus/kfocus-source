import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as Controls
import org.kde.kirigami 2.20 as Kirigami

ColumnLayout {
    property var snapshotList : ListModel {}
    property int compareIndex : compareSelectBox.currentIndex

    signal compareClicked()
    signal cancelled()

    anchors {
        right        : parent.right
        top          : parent.top
        bottom       : parent.bottom
        rightMargin  : Kirigami.Units.gridUnit * 0.75
        topMargin    : Kirigami.Units.gridUnit * 3.5
        bottomMargin : Kirigami.Units.gridUnit * 0.75
    }
    width : parent.width
      - snapshotListView.width
      - (Kirigami.Units.gridUnit * 2.25)

    Controls.Label {
        text                : 'Please select the snapshot to compare to:'
        Layout.bottomMargin : Kirigami.Units.gridUnit * 0.25
    }

    Controls.ComboBox {
        id               : compareSelectBox
        Layout.fillWidth : true
        textRole         : "date"
        valueRole        : "name"
        displayText      : currentText + ' - ' + currentValue
        model            : snapshotList
        delegate         : Kirigami.BasicListItem {
            label    : date
            subtitle : name
            icon     : reason === 'System Schedule'
              ? 'clock'
              : reason === 'Before Package Change'
                ? 'system-upgrade'
                : reason === 'Pre-Rollback'
                  ? 'edit-undo'
                  : reason === 'current'
                    ? 'drive-harddisk-root'
                    : 'user'
            trailing : Kirigami.Icon {
                source: pinned ? 'pin' : ''
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
        }

        Component.onCompleted : {
            resetSelector();
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }
    }

    Item {
        Layout.fillHeight : true
    }

    Controls.Button {
        id                    : compareButton
        Layout.alignment      : Qt.AlignRight
        Layout.preferredWidth : Kirigami.Units.gridUnit * 7
        Layout.bottomMargin   : Kirigami.Units.gridUnit * 0.5
        text                  : 'Compare'
        icon.name             : 'document-duplicate'
        onClicked             : compareClicked()

        HoverHandler {
            cursorShape : Qt.PointingHandCursor
        }
    }

    Controls.Button {
        id                    : cancelButton
        Layout.alignment      : Qt.AlignRight
        Layout.preferredWidth : Kirigami.Units.gridUnit * 7
        text                  : 'Cancel'
        icon.name             : 'cancel'
        onClicked             : cancelled()

        HoverHandler {
            cursorShape : Qt.PointingHandCursor
        }
    }

    function resetSelector() {
        compareSelectBox.currentIndex = 0;
    }
}

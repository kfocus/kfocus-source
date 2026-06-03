import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.kirigami.delegates as KirigamiDelegates

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
        delegate         : Controls.ItemDelegate {
            width: ListView.view.width
            contentItem: RowLayout {
                KirigamiDelegates.IconTitleSubtitle {
                    Layout.fillWidth: true
                    title: date
                    subtitle: name
                    icon.name: reason === 'System Schedule'
                      ? 'clock'
                      : reason === 'Before Package Change'
                        ? 'system-upgrade'
                        : reason === 'Pre-Rollback'
                          ? 'edit-undo'
                          : reason === 'current'
                            ? 'drive-harddisk-root'
                            : 'user'
                }
                Kirigami.Icon {
                    source: pinned ? 'lock' : ''
                }
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
        Layout.bottomMargin : Kirigami.Units.gridUnit * 0.25
    }
    Controls.Label {
        text             : ''
          + '<p><b><font color="#f7941d">IMPORTANT: A comparison can '
          + 'take many minutes to complete.</font></b> You might want '
          + 'to do something else when it is running.</p>'
        wrapMode         : Text.WordWrap
        Layout.fillWidth : true
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
        icon.name             : 'dialog-cancel'
        onClicked             : cancelled()

        HoverHandler {
            cursorShape : Qt.PointingHandCursor
        }
    }

    function resetSelector() {
        compareSelectBox.currentIndex = 0;
    }
}

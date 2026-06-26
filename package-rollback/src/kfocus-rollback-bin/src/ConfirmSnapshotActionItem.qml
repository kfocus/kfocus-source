import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

ColumnLayout {
    property string startInfoText   : ''
    property string endInfoText     : ''
    property string date            : ''
    property string name            : ''
    property string reason          : ''
    property string acceptText      : ''
    property string acceptIcon      : ''
    property bool   actionsEnabled  : true
    property bool   isOkDestructive : false
    property string okColor         : isOkDestructive
      ? Kirigami.Theme.negativeTextColor
      : Kirigami.Theme.textColor

    signal okAction()
    signal cancelled()

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

    Controls.Label {
        text             : startInfoText
        wrapMode         : Text.WordWrap
        Layout.fillWidth : true
    }

    RowLayout {
        Layout.fillWidth: true
        Kirigami.Icon {
            Layout.alignment   : Qt.AlignVCenter
            Layout.rightMargin : Kirigami.Units.gridUnit * 0.5
            source             : reason === 'System Schedule'
              ? 'clock'
              : reason === 'Before Package Change'
                ? 'system-upgrade'
                : reason === 'Pre-Rollback'
                  ? 'edit-undo'
                  : 'user'
        }
        ColumnLayout {
            Kirigami.Heading {
                text  : date
                level : 2
            }
            Controls.Label {
                text  : '<i>' + name + '</i>'
                color : Kirigami.Theme.disabledTextColor
            }
        }
    }

    Controls.Label {
        text             : endInfoText
        wrapMode         : Text.WordWrap
        Layout.fillWidth : true
    }

    Item {
        Layout.fillHeight : true
    }

    Controls.Button {
        Kirigami.Theme.textColor : okColor
        text                  : acceptText
        icon.name             : acceptIcon
        Layout.preferredWidth : Kirigami.Units.gridUnit * 8.4
        Layout.bottomMargin   : Kirigami.Units.gridUnit * 0.5
        Layout.alignment      : Qt.AlignRight
        enabled               : actionsEnabled
        onClicked             : {
            actionsEnabled = false;
            okAction();
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }
    }

    Controls.Button {
        text                  : 'Cancel'
        icon.name             : 'dialog-cancel'
        Layout.preferredWidth : Kirigami.Units.gridUnit * 8.4
        Layout.alignment      : Qt.AlignRight
        enabled               : actionsEnabled
        onClicked             : {
            cancelled();
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }
    }
}

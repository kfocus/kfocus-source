import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as Controls
import org.kde.kirigami 2.20 as Kirigami

ColumnLayout {
    property string startInfoText  : ''
    property string endInfoText    : ''
    property string date           : ''
    property string name           : ''
    property string reason         : ''
    property string acceptText     : ''
    property string acceptIcon     : ''
    property bool   actionsEnabled : true
    property bool   isDestructive  : false

    signal okAction()
    signal cancelled()

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
        text             : startInfoText
        wrapMode         : Text.WordWrap
        Layout.fillWidth : true
    }

    RowLayout {
        Layout.fillWidth: true
        Kirigami.Icon {
            Layout.alignment   : Qt.AlignVCenter
            Layout.rightMargin : Kirigami.Units.gridUnit * 0.25
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
        palette.buttonText: isDestructive
          ? Kirigami.Theme.negativeTextColor
          : Kirigami.Theme.textColor
        text                  : acceptText
        icon.name             : acceptIcon
        Layout.preferredWidth : Kirigami.Units.gridUnit * 7
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
        Layout.preferredWidth : Kirigami.Units.gridUnit * 7
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

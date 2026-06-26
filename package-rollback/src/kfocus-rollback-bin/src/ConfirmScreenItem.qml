import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

ColumnLayout {
    property string infoText         : ''
    property string acceptText       : ''
    property string acceptIcon       : ''
    property string accept2Text      : ''
    property string accept2Icon      : ''
    property bool   actionsEnabled   : true
    property bool   isOkDestructive  : false
    property bool   isOk2Destructive : false
    property bool   ok2Visible       : false
    property string okColor          : isOkDestructive
      ? Kirigami.Theme.negativeTextColor
      : Kirigami.Theme.textColor
    property string ok2Color         : isOk2Destructive
      ? Kirigami.Theme.negativeTextColor
      : Kirigami.Theme.textColor

    signal okAction()
    signal ok2Action()
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
        text             : infoText
        wrapMode         : Text.WordWrap
        Layout.fillWidth : true
        Layout.alignment : Qt.AlignTop
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
        Kirigami.Theme.textColor : ok2Color
        text                  : accept2Text
        icon.name             : accept2Icon
        Layout.preferredWidth : Kirigami.Units.gridUnit * 8.4
        Layout.bottomMargin   : Kirigami.Units.gridUnit * 0.5
        Layout.alignment      : Qt.AlignRight
        enabled               : actionsEnabled
        visible               : ok2Visible

        onClicked             : {
            actionsEnabled = false;
            ok2Action();
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

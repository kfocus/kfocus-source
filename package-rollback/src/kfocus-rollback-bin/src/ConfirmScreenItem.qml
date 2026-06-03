import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as Controls
import org.kde.kirigami 2.20 as Kirigami

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

    signal okAction()
    signal ok2Action()
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
        text             : infoText
        wrapMode         : Text.WordWrap
        Layout.fillWidth : true
        Layout.alignment : Qt.AlignTop
    }

    Item {
        Layout.fillHeight : true
    }

    Controls.Button {
        palette.buttonText: isOkDestructive
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
        palette.buttonText: isOk2Destructive
          ? Kirigami.Theme.negativeTextColor
          : Kirigami.Theme.textColor
        text                  : accept2Text
        icon.name             : accept2Icon
        Layout.preferredWidth : Kirigami.Units.gridUnit * 7
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

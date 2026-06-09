import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

ColumnLayout {
    property string startInfoText : ''
    property string endInfoText   : ''
    property string date          : ''
    property string name          : ''
    property string reason        : ''
    property bool   isCritical    : false

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
        ColumnLayout {
            Controls.Label {
                text             : startInfoText
                wrapMode         : Text.WordWrap
                Layout.fillWidth : true
                onLinkActivated  : Qt.openUrlExternally(link)
            }

            RowLayout {
                Layout.fillWidth : true
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
                onLinkActivated  : Qt.openUrlExternally(link)
            }
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

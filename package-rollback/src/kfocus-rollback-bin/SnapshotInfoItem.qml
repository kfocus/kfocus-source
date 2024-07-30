import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as Controls
import org.kde.kirigami 2.20 as Kirigami

RowLayout {
    // Public
    property string date        : ''
    property string reason      : ''
    property string name        : ''
    property string description : ''
    property bool pinned        : false
    property bool editing       : false
    property bool saving        : false

    // Private
    property bool oldPinned     : pinned
    property var  focusedBox    : undefined

    signal saved()
    signal cancelled()
    signal deleteClicked()
    signal restoreClicked()
    signal compareClicked()

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

    ColumnLayout {
        Layout.fillHeight: true

        RowLayout {
            Layout.fillWidth    : true
            Layout.bottomMargin : Kirigami.Units.gridUnit * 0.3

            Kirigami.Icon {
                source : reason === 'System Schedule'
                  ? 'clock'
                  : reason === 'Before Package Change'
                  ? 'system-upgrade'
                  : reason === 'Pre-Rollback'
                  ? 'edit-undo-symbolic'
                  : 'user'
            }

            Kirigami.Heading {
                id               : snapshotTitle
                Layout.alignment : Qt.AlignVCenter

                text             : date
                level            : 2
            }

            Item {
                Layout.fillWidth : true
            }

            Controls.Label {
                Layout.alignment : Qt.AlignVCenter

                text             : {
                    switch ( reason ) {
                    case 'System Schedule':
                        return '<i>(Created by <b>System Schedule</b>)</i>';
                    case 'Before Package Change':
                        return '<i>(Created before <b>Package Change</b>)</i>';
                    case 'Pre-Rollback':
                        return '<i>(Created before '
                          + '<b>Snapshot Rollback</b>)</i>';
                    default:
                        let input_str = reason;
                        let out_list  = input_str.match( /^[^(]+\(([^)]+)\)/ )
                          || [];
                        let user_str = out_list[1] || 'user';
                        return '<i>(Created by <b>' + user_str + '</b>)</i>';
                    }
                }
            }
        }

        Controls.TextField {
            id                  : nameField
            Layout.alignment    : Qt.AlignTop
            Layout.fillWidth    : true
            Layout.bottomMargin : Kirigami.Units.gridUnit * 0.55

            text                : name
            font.family         : 'courier'
            readOnly            : !editing
            color               : editing ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
            placeholderText     : reason

            onActiveFocusChanged: {
                if (activeFocus) {
                    focusedBox = this;
                }
            }
            background          : Rectangle {
                id: nameFieldBackground
                color: editing
                  ? Kirigami.Theme.backgroundColor
                  : Kirigami.Theme.alternateBackgroundColor
                border.color: {
                    if (editing) {
                        if (focusedBox === nameField) {
                            return Kirigami.Theme.highlightColor
                        }
                    }
                    return Kirigami.Theme.activeBackgroundColor
                }
                border.width: 1
                radius: Kirigami.Units.gridUnit * 0.125
            }
        }

        Controls.TextArea {
            id                  : descField
            Layout.alignment    : Qt.AlignTop
            Layout.fillWidth    : true
            Layout.fillHeight   : true
            Layout.bottomMargin : Kirigami.Units.gridUnit * 0.5

            placeholderText     : '<p><i>Press the "Edit" button to:</i></p>'
              + '<br>'
              + '<p><i>* Rename the Snapshot</i><br>'
              + '<i>* Change this description</i><br>'
              + '<i>* Pin the Snapshot</i></p>'
            text                : description
            font.family         : 'courier'
            wrapMode            : Text.WordWrap
            readOnly            : !editing
            color               : editing
              ? Kirigami.Theme.textColor
              : Kirigami.Theme.disabledTextColor

            activeFocusOnPress  : true
            activeFocusOnTab    : true
            onActiveFocusChanged: {
                if (activeFocus) {
                    focusedBox = this;
                }
            }

            background          : Rectangle {
                id           : descFieldBackground
                color        : editing
                  ? Kirigami.Theme.backgroundColor
                  : Kirigami.Theme.alternateBackgroundColor
                border.color : {
                    if (editing) {
                        if (focusedBox === descField) {
                            return Kirigami.Theme.highlightColor
                        }
                    }
                    return Kirigami.Theme.activeBackgroundColor
                }

                border.width : 1
                radius       : Kirigami.Units.gridUnit * 0.125
            }
        }

        RowLayout {
            Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
            Kirigami.Heading {
                text  : 'Pin This Snapshot'
                level : 2
            }

            Controls.Switch {
                Layout.leftMargin: Kirigami.Units.gridUnit * 0.5
                id        : pinSwitch
                checked   : pinned
                onClicked : {
                    if ( !editing ) {
                        editButton.clicked();
                    }
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
            }

            Kirigami.Icon {
                source: 'pin'
                visible: pinSwitch.checked
            }
        }
    }

    ColumnLayout {
        Layout.leftMargin : Kirigami.Units.gridUnit * 0.45

        Controls.Button {
            id                    : deleteButton
            Layout.alignment      : Qt.AlignTop
            Layout.preferredWidth : Kirigami.Units.gridUnit * 7
            Layout.bottomMargin   : Kirigami.Units.gridUnit * 0.5
            text                  : 'Delete'
            icon.name             : 'delete'
            onClicked             : deleteClicked()

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
        }

        Controls.Button {
            id                    : restoreButton
            Layout.alignment      : Qt.AlignTop
            Layout.preferredWidth : Kirigami.Units.gridUnit * 7
            Layout.bottomMargin   : Kirigami.Units.gridUnit * 0.5
            text                  : 'Restore'
            icon.name             : 'edit-undo-symbolic'
            onClicked             : restoreClicked()

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
        }

        Controls.Button {
            id                    : compareButton
            Layout.alignment      : Qt.AlignTop
            Layout.preferredWidth : Kirigami.Units.gridUnit * 7
            text                  : 'Compare With'
            icon.name             : 'document-duplicate'
            onClicked             : compareClicked()

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
        }

        Item {
            Layout.fillHeight : true
        }

        Controls.Button {
            id                    : editButton
            Layout.alignment      : Qt.AlignBottom
            Layout.preferredWidth : Kirigami.Units.gridUnit * 7
            text                  : 'Edit'
            icon.name             : 'document-edit'
            visible               : !editing
            onClicked             : {
                nameField.text = name;
                descField.text = description;
                editing        = true;
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
        }

        Controls.Button {
            id                    : saveButton
            Layout.alignment      : Qt.AlignBottom
            Layout.preferredWidth : Kirigami.Units.gridUnit * 7
            Layout.bottomMargin   : Kirigami.Units.gridUnit * 0.5
            text                  : 'Save'
            icon.name             : 'document-save'
            visible               : editing
            enabled               : !saving
            onClicked             : {
                saving = true;
                if ( nameField.text === '' ) {
                    name = reason;
                } else {
                    name = nameField.text;
                }
                description       = descField.text;
                pinned            = pinSwitch.checked;
                nameField.text    = Qt.binding(function() { return name; });
                descField.text    = Qt.binding(function() {
                    return description;
                });
                pinSwitch.checked = Qt.binding(function() { return pinned; });
                saved();
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
        }

        Controls.Button {
            id                    : cancelButton
            Layout.alignment      : Qt.AlignBottom
            Layout.preferredWidth : Kirigami.Units.gridUnit * 7
            text                  : 'Cancel'
            icon.name             : 'dialog-cancel'
            visible               : editing
            enabled               : !saving
            onClicked             : {
                editing           = false;
                nameField.text    = Qt.binding(function() { return name; });
                descField.text    = Qt.binding(function() {
                    return description;
                });
                pinSwitch.checked = Qt.binding(function() { return pinned; });
                cancelled();
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
        }
    }
}

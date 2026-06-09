import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

RowLayout {
    // Public
    property string date        : ''
    property string dayofweek   : ''
    property string mainSize    : ''
    property string bootSize    : ''
    property string reason      : ''
    property string name        : ''
    property string description : ''
    property bool pinned        : false
    property bool editing       : false
    property bool saving        : false
    property bool diskLow       : false

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
        rightMargin  : Kirigami.Units.gridUnit * 1
        topMargin    : Kirigami.Units.gridUnit * 4.55
        bottomMargin : Kirigami.Units.gridUnit * 1
    }
    width : parent.width
      - snapshotListView.width
      - (Kirigami.Units.gridUnit * 3)

    ColumnLayout {
        Layout.fillHeight : true

        RowLayout {
            Layout.fillWidth    : true
            Layout.topMargin    : Kirigami.Units.gridUnit * -0.25
            Layout.bottomMargin : Kirigami.Units.gridUnit * 0.45

            Kirigami.Icon {
                Layout.alignment : Qt.AlignVCenter
                source           : reason === 'System Schedule'
                  ? 'clock'
                  : reason === 'Before Package Change'
                    ? 'system-upgrade'
                    : reason === 'Pre-Rollback'
                      ? 'edit-undo-symbolic'
                      : 'user'
            }

            ColumnLayout {
                Kirigami.Heading {
                    id               : snapshotTitle
                    Layout.alignment : Qt.AlignVCenter

                    text             : date
                    level            : 2
                }
                Controls.Label {
                    Layout.alignment : Qt.AlignVCenter

                    font.pixelSize   : 12
                    text             : {
                        switch ( reason ) {
                        case 'System Schedule':
                        case 'Before Package Change':
                        case 'Pre-Rollback':
                        case 'Unknown (no reason found)':
                            return reason;
                        default:
                            let input_str = reason;
                            let out_list  = input_str.match( /^[^(]+\(([^)]+)\)/ )
                              || [];
                            let user_str  = out_list[1] || 'user';
                            return '<i>User Snapshot (' + user_str + ')</i>';
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth : true
            }

            ColumnLayout {
                Kirigami.Heading {
                    Layout.alignment : Qt.AlignVCenter | Qt.AlignRight
                    text             : mainSize !== '' && bootSize != ''
                      ? mainSize + ' [' + bootSize + ']'
                      : ''
                    level            : 2
                }

                Controls.Label {
                    Layout.alignment : Qt.AlignVCenter | Qt.AlignRight
                    font.pixelSize   : 12
                    text             : dayofweek
                }
            }
        }

        Controls.TextField {
            id                   : nameField
            Layout.alignment     : Qt.AlignTop
            Layout.fillWidth     : true
            Layout.bottomMargin  : Kirigami.Units.gridUnit * 0.72

            text                 : name
            font.family          : 'courier'
            maximumLength        : 40
            readOnly             : !editing
            color                : editing
              ? Kirigami.Theme.textColor
              : Kirigami.Theme.disabledTextColor
            placeholderText      : reason

            onActiveFocusChanged : {
                if (activeFocus) {
                    focusedBox = this;
                }
            }
            background           : Rectangle {
                id           : nameFieldBackground
                color        : editing
                  ? Kirigami.Theme.backgroundColor
                  : Kirigami.Theme.alternateBackgroundColor
                radius       : Kirigami.Units.gridUnit * 0.25
                border.width : 1
                border.color : {
                    if (editing) {
                        if (focusedBox === nameField) {
                            return Kirigami.Theme.highlightColor
                        }
                    }
                    return Kirigami.Theme.activeBackgroundColor
                }
            }
        }

        Controls.ScrollView {
            Layout.alignment  : Qt.AlignTop
            Layout.fillWidth  : true
            Layout.fillHeight : true

            Controls.TextArea {
                id                   : descField
                placeholderText      : ''
                  + '<p><i>Press the "Edit" button to:</i></p><br>'
                  + '<p><i>* Change the name.</i><br></p>'
                  + '<p><i>* Add a description here<br>'
                  + ' &nbsp; (up to 1024 characters).</i><br></p>'
                  + '<p><i>* Protect the snapshot.</i></p>'
                  ;
                text                 : description
                font.family          : 'courier'
                // Text.Wrap tries to wrap on word boundaries.
                // Unlike Text.WordWrap, it will break words if needed.
                wrapMode             : Text.Wrap
                readOnly             : !editing
                color                : editing
                  ? Kirigami.Theme.textColor
                  : Kirigami.Theme.disabledTextColor

                activeFocusOnPress   : true
                activeFocusOnTab     : true
                onActiveFocusChanged : {
                    if (activeFocus) {
                        focusedBox = this;
                    }
                }
                background           : Rectangle {
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
                    radius       : Kirigami.Units.gridUnit * 0.25
                }
            }
        }
    }

    ColumnLayout {
        Layout.leftMargin : Kirigami.Units.gridUnit * 0.67

        Rectangle {
            Layout.alignment       : Qt.AlignTop
            Layout.preferredWidth  : Kirigami.Units.gridUnit * 8.4
            Layout.bottomMargin    : Kirigami.Units.gridUnit * 0.5
            Layout.preferredHeight : restoreButton.implicitHeight
            color                  :
              Kirigami.Theme.activeBackgroundColor

            Controls.Button {
                id           : restoreButton
                anchors.fill : parent
                text         : 'Restore'
                icon.name    : 'edit-undo-symbolic'
                onClicked    : restoreClicked()
                enabled      : !editing && !diskLow

                HoverHandler {
                    cursorShape : Qt.PointingHandCursor
                }
            }

            Rectangle {
                width   : restoreButton.width
                height  : restoreButton.height
                visible : diskLow
                opacity : 0

                HoverHandler {
                    id : restoreDisableHover
                }

                Controls.ToolTip {
                    visible :
                      restoreDisableHover.hovered
                    text    :
                      'Disk space low, cannot restore snapshot'
                }
            }
        }

        Controls.Button {
            id                    : compareButton
            Layout.alignment      : Qt.AlignTop
            Layout.preferredWidth : Kirigami.Units.gridUnit * 8.4
            Layout.bottomMargin   : Kirigami.Units.gridUnit * 0.5
            text                  : 'Compare'
            icon.name             : 'document-duplicate'
            onClicked             : compareClicked()
            enabled               : !editing

            HoverHandler {
                cursorShape : Qt.PointingHandCursor
            }
        }

        Rectangle {
            Layout.alignment       : Qt.AlignTop
            Layout.preferredWidth  : Kirigami.Units.gridUnit * 8.4
            Layout.bottomMargin    : Kirigami.Units.gridUnit * 0.5
            Layout.preferredHeight : deleteButton.implicitHeight
            color                  :
              Kirigami.Theme.activeBackgroundColor

            Controls.Button {
                id           : deleteButton
                anchors.fill : parent
                text         : 'Delete'
                icon.name    : 'edit-delete-remove'
                onClicked    : deleteClicked()
                enabled      : !editing && !pinned

                HoverHandler {
                    cursorShape : Qt.PointingHandCursor
                }
            }

            Rectangle {
                width   : deleteButton.width
                height  : deleteButton.height
                visible : pinned
                opacity : 0

                HoverHandler {
                    id : deleteDisableHover
                }

                Controls.ToolTip {
                    visible :
                      deleteDisableHover.hovered
                    text    :
                      'Cannot delete protected snapshot'
                }
            }
        }

        RowLayout {
            Layout.preferredHeight : Kirigami.Units.gridUnit * 1.5
            Kirigami.Heading {
                text  : 'Protect'
                level : 2
            }

            Controls.Switch {
                Layout.leftMargin      : Kirigami.Units.gridUnit * 0.5
                id                     : pinSwitch
                checked                : pinned

                // This doesn't make the switch taller, it makes Qt allocate
                // it (and the containing layout) more vertical space so that
                // toggling on the lock icon doesn't result in widget shifting
                Layout.preferredHeight : Kirigami.Units.gridUnit * 2

                onClicked         : {
                    if ( !editing ) {
                        editButton.clicked();
                    }
                }

                HoverHandler {
                    cursorShape : Qt.PointingHandCursor
                }
            }

            Kirigami.Icon {
                source  : 'lock'
                visible : pinSwitch.checked
            }
        }

        Item {
            Layout.fillHeight : true
        }

        Controls.Button {
            id                    : editButton
            Layout.alignment      : Qt.AlignBottom
            Layout.preferredWidth : Kirigami.Units.gridUnit * 8.4
            text                  : 'Edit'
            icon.name             : 'document-edit'
            visible               : !editing
            onClicked             : {
                nameField.text = name;
                descField.text = description;
                editing        = true;
            }

            HoverHandler {
                cursorShape : Qt.PointingHandCursor
            }
        }

        Controls.Button {
            id                    : saveButton
            Layout.alignment      : Qt.AlignBottom
            Layout.preferredWidth : Kirigami.Units.gridUnit * 8.4
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
                // Limit to a max of 1024 characters
                description       = descField.text.substr(0,1024);
                pinned            = pinSwitch.checked;
                nameField.text    = Qt.binding(function() { return name; });
                descField.text    = Qt.binding(function() {
                    return description;
                });
                pinSwitch.checked = Qt.binding(function() { return pinned; });
                saved();
            }

            HoverHandler {
                cursorShape : Qt.PointingHandCursor
            }
        }

        Controls.Button {
            id                    : cancelButton
            Layout.alignment      : Qt.AlignBottom
            Layout.preferredWidth : Kirigami.Units.gridUnit * 8.4
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
                cursorShape : Qt.PointingHandCursor
            }
        }
    }
}

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as Controls
import org.kde.kirigami 2.20 as Kirigami
import shellengine 1.1
import backendengine 1.0

Kirigami.ApplicationWindow {
    id: root
    title: 'Kubuntu Focus System Rollback'

    // Connects the QML and C++ components of kfocus-rollback-bin.
    BackendEngine {
        id                 : backend
        onSystemDataLoaded : {
            populateSnapshotModelFn();
            derivateSnapshotModelFn();
            fillPartitionHealthTableFn();

            createSnapshotView.actionsEnabled = true;
            optimizeDiskView.actionsEnabled   = true;
            deleteSnapshotView.actionsEnabled = true;

            if ( !firstInitDone ) {
                switchViewFn( snapshotView, snapshotView );
                if (backend.mainSpaceLow) {
                    lowDiskOverlay.visible = true;
                } else if (backend.isPostRestore) {
                    postRestoreOverlay.visible = true;
                }

                pageStack.pop();
                pageStack.push( mainPage );
                firstInitDone = true;
            } else {
                switchViewFn( sysRefreshSourceView, sysRefreshTargetView );
            }

            backend.inhibitClose = false;
        }
    }

    // == BEGIN Models ================================================
    // Set Global Properties
    property bool   firstInitDone            : false
    property var    sysRefreshSourceView
    property var    sysRefreshTargetView
    property int    disabledSnapshotBarIndex : 0
    property bool   uiLocked                 : false
    property string compareSourceIdStr       : ''
    property string compareTargetIdStr       : ''
    property string compareResultStr         : ''
    property string rollbackStr              : backend.pkexecExe
      + ' '
      + backend.rollbackBackendExe
      + ' '

    // Set Constant Names
    property string automaticSnapshotsLabel     : 'Automatic Snapshots'
    property string calculateSnapshotSizesLabel : 'Show Snapshot Sizes'
    property string compareSnapshotLabel        : 'Compare Snapshots'
    property string createSnapshotErrorLabel    : 'Snapshot Creation Failed'
    property string createSnapshotLabel         : 'Create New Snapshot'
    property string deleteSnapshotDeniedLabel   : 'Cannot Delete Pinned Snapshot'
    property string deleteSnapshotErrorLabel    : 'Snapshot Deletion Failed'
    property string deleteSnapshotLabel         : 'Delete Snapshot'
    property string optimizeDiskLabel           : 'Clean Up Disk'
    property string restoreSnapshotErrorLabel   : 'Snapshot Restore Failed'
    property string restoreSnapshotLabel        : 'Restore Snapshot'

    // Purpose: Contains list of snapshots and snapshot info
    ListModel {
        id: snapshotModel
    }

    // Purpose: Only used for snapshot comparison, contains list of snapshots
    // and snapshot info plus "current system" entry
    ListModel {
        id: derivSnapshotModel
    }

    // == . END Models ================================================

    // == BEGIN Views =================================================
    // Define window size
    width         : Kirigami.Units.gridUnit * 45
    height        : Kirigami.Units.gridUnit * 30
    minimumWidth  : Kirigami.Units.gridUnit * 45
    minimumHeight : Kirigami.Units.gridUnit * 30

    // BEGIN Define sidebar views
    Component {
        id: enabledSnapshotBarDelegate

        Kirigami.BasicListItem {
            font.family : "courier"
            label       : date + '     ' + size
            subtitle    : name
            icon        : getIconForReasonFn( reason )
            trailing    : Kirigami.Icon {
                source  : pinned ? 'pin' : ''
            }
        }
    }

    Component {
        id: disabledSnapshotBarDelegate

        Kirigami.BasicListItem {
            font.family : "courier"
            label       : date + '     ' + size
            subtitle    : name
            icon        : getIconForReasonFn( reason )
            trailing    : Kirigami.Icon {
                source  : pinned ? 'pin' : ''
            }
            fadeContent : true
            onClicked   : {
                snapshotBar.currentIndex = disabledSnapshotBarIndex;
            }
        }
    }
    // . END Define sidebar views

    // BEGIN Define popup windows
    Component {
        id: globalHelpWindowComponent
        HelpWindow {
            helpText: `<p>These are actions that do not pertain to a specific
              snapshot.</p>

              <p><b><font color="#f7941d">`
              + automaticSnapshotsLabel
              + `:</b></font> When enabled, take snapshots without
              intervention before apt software changes; or at least once a
              week.</p>

              <p><b><font color="#f7941d">` + calculateSnapshotSizesLabel
              + `:</b></font>
              Calculate and display the estimated space used by each
              snapshot. Deleting a snapshot will free the amount of space
              shown.</p>

              <p><b><font color="#f7941d">` + createSnapshotLabel
              + `:</b></font> Immediately create a snapshot of the
              current system state. This includes the /boot and root
              filesystems. This snapshot can be restored later as needed.</p>

              <p><b><font color="#f7941d">` + optimizeDiskLabel
              + `:</font></b> Delete all snapshots, defragment files as
              needed, recover unreachable space, and consolidate data on the
              boot disk. Use this to maximize available free space and improve
              performance.</p>
              `
            helpTitle: 'Global Actions Help'
        }
    }

    Component {
        id: partitionHealthHelpWindowComponent
        HelpWindow {
            helpText: `<p>This table shows disk usage for the system
              partitions that this tool may affect.</p>

              <p><font color="#f7941d"><b>Mount:</b></font>
              The filesystem's mount point. System Rollback keeps snapshots
              for both the root (<code>/</code>) and boot (<code>/boot</code>)
              filesystems correlated so there are no data inconsistencies.</p>

              <p><font color="#f7941d"><b>Status:</b></font> Disk space
              status. "<font color="#27ae60"><code>Good</code></font>" means
              that disk space is sufficient.
              "<font color="#da4453"><code>ALERT</code></font>" means that
              disk space is low. Delete files or snapshots to free up disk
              space.</p>

              <p><font color="#f7941d"><b>Size GiB:</b></font>
              Filesystem size, in gigabytes.</p>

              <p><font color="#f7941d"><b>Remain GiB:</b></font>
              Remaining free space on the filesystem.</p>

              <p><font color="#f7941d"><b>Unalloc %:</b></font>
              Percentage of unallocated space left on the filesystem.
              Unallocated space should exceed 15% at all times.</p>`
            helpTitle: 'Partition Health Help'
        }
    }

    Component {
        id: snapshotsHelpWindowComponent
        HelpWindow {
            helpText: `<p>These are snapshot-specific view and edit
              controls.</p>

              <p><b><font color="#f7941d">Delete</font></b> -
              Remove the selected snapshot from the disk permanently.</p>

              <p><b><font color="#f7941d">Restore</font></b> - Roll back
              the system to the selected snapshot. The system will reboot
              automatically during the restore process.</p>

              <p><b><font color="#f7941d">Compare With</font></b> -
              Shows the difference between any two snapshots, or between a
              snapshot and the current system state.</p>

              <p><b><font color="#f7941d">Edit</font></b> - Change
              the name, description, or pinning of the selected
              snapshot.</p>

              <p><b><font color="#f7941d">Pin This Snapshot</font></b> -
              Pin or unpin the selected snapshot. Pinned snapshots will not be
              deleted until unpinned.</p>`
            helpTitle: 'Snapshots Help'
        }
    }

    Component {
        id: snapshotCompareWindowComponent

        SnapshotCompareWindow {
            id               : snapshotCompareWindow
            sourceSnapshotId : compareSourceIdStr
            targetSnapshotId : compareTargetIdStr
            compareText      : compareResultStr
        }
    }
    // . END Define popup windows

    pageStack.initialPage: waitPage

    Kirigami.Page {
        id : waitPage

        Controls.BusyIndicator {
            id     : waitPageSpinner

            anchors {
                horizontalCenter : parent.horizontalCenter
                verticalCenter   : parent.verticalCenter
            }

            width  : Kirigami.Units.gridUnit * 6
            height : Kirigami.Units.gridUnit * 6
        }

        Item {
            anchors {
                top              : waitPageSpinner.bottom
                bottom           : parent.bottom
                horizontalCenter : parent.horizontalCenter
            }

            Controls.Label {
                id                : waitPageWarningLabel
                anchors {
                    verticalCenter   : parent.verticalCenter
                    horizontalCenter : parent.horizontalCenter
                }

                visible           : false
                width             : Kirigami.Units.gridUnit * 14
                verticalAlignment : Qt.AlignVCenter
                wrapMode          : Text.WordWrap

                background: Rectangle {
                    anchors {
                        verticalCenter   : parent.verticalCenter
                        horizontalCenter : parent.horizontalCenter
                    }

                    width        : parent.width + Kirigami.Units.gridUnit * 1.5
                    height       : parent.height + Kirigami.Units.gridUnit * 1
                    color        : Kirigami.Theme.neutralBackgroundColor
                    border.width : 2
                    border.color : Kirigami.Theme.neutralTextColor
                    radius       : Kirigami.Units.gridUnit * 0.5
                }
            }
        }

        Timer {
            interval    : 5000
            running     : true
            repeat      : false
            onTriggered : {
                if (backend.isBackgroundRollbackRunning()) {
                    waitPageWarningLabel.text
                      = 'Waiting for background processes to complete. '
                      + 'Please wait, this may take five minutes or more...';
                } else {
                    waitPageWarningLabel.text
                      = 'Loading snapshot data is taking longer than '
                      + 'expected. You may need to reboot your system.';
                }
                waitPageWarningLabel.visible = true;
            }
        }
    }

    Kirigami.Page {
        id      : mainPage
        title   : 'Kubuntu Focus System Rollback'
        visible : false

        ColumnLayout {
            anchors.fill: parent

            RowLayout {
                Layout.fillWidth     : true
                Layout.maximumHeight : Kirigami.Units.gridUnit * 7

                ColumnLayout {
                    Layout.alignment    : Qt.AlignTop
                    Layout.bottomMargin : Kirigami.Units.gridUnit * 0.75

                    RowLayout {
                        Layout.bottomMargin: Kirigami.Units.gridUnit * 0.5

                        Controls.Button {
                            Layout.preferredWidth  : Kirigami.Units.gridUnit
                              * 1.3
                            Layout.preferredHeight : Kirigami.Units.gridUnit
                              * 1.3
                            Layout.leftMargin      : Kirigami.Units.gridUnit
                              * 0.2
                            icon.name              : 'help-contextual'
                            icon.width             : Kirigami.Units.gridUnit
                            icon.height            : Kirigami.Units.gridUnit
                            enabled                : !uiLocked
                            onClicked              : {
                                showWindowFn( globalHelpWindowComponent )
                            }

                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                        Kirigami.Heading {
                            text             : 'Global Actions'
                            color            : uiLocked
                              ? Kirigami.Theme.disabledTextColor
                              : Kirigami.Theme.textColor
                            Layout.alignment : Qt.AlignTop
                            level            : 1
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                    GridLayout {
                        columns             : 2
                        Layout.maximumWidth : mainPage.width / 2
                        Layout.alignment    : Qt.AlignBottom

                        RowLayout {
                            Layout.preferredWidth  : (mainPage.width / 4)
                              - Kirigami.Units.gridUnit * 0.35
                            Layout.bottomMargin    :
                              Kirigami.Units.gridUnit * 0.45
                            Controls.Label {
                                text               : automaticSnapshotsLabel
                                color              : uiLocked
                                  ? Kirigami.Theme.disabledTextColor
                                  : Kirigami.Theme.textColor
                                Layout.alignment   : Qt.AlignRight
                                Layout.rightMargin : Kirigami.Units.gridUnit
                                  * 0.125
                            }
                            Controls.Switch {
                                id                : automaticSnapshotsSwitch
                                Layout.alignment  : Qt.AlignRight
                                Layout.leftMargin : Kirigami.Units.gridUnit
                                  * 0.125
                                checked           :
                                  backend.automaticSnapshotsEnabled
                                enabled           : !uiLocked
                                onClicked         : switchAutomaticSnapshotsFn();

                                HoverHandler {
                                    cursorShape: Qt.PointingHandCursor
                                }
                            }
                        }
                        Controls.Button {
                            Layout.bottomMargin   :
                              Kirigami.Units.gridUnit * 0.45
                            text                  : calculateSnapshotSizesLabel
                            icon.name             : 'disk-quota'
                            Layout.preferredWidth : (mainPage.width / 4)
                              - Kirigami.Units.gridUnit * 0.35
                            Layout.alignment      : Qt.AlignRight
                            enabled               : !uiLocked

                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }

                            onClicked             : calculateSnapshotSizesFn();
                        }

                        Controls.Button {
                            text                  : createSnapshotLabel
                            icon.name             : 'document-new'
                            Layout.preferredWidth : (mainPage.width / 4)
                              - Kirigami.Units.gridUnit * 0.36
                            Layout.alignment      : Qt.AlignLeft
                            enabled               : !uiLocked
                            onClicked             : {
                                switchViewFn(
                                  snapshotView, createSnapshotView
                                )
                            }

                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                        Controls.Button {
                            text                  : optimizeDiskLabel
                            icon.name             : 'clean-up-destructive'
                            Layout.preferredWidth : (mainPage.width / 4)
                              - Kirigami.Units.gridUnit * 0.36
                            Layout.alignment      : Qt.AlignRight
                            enabled               : !uiLocked;
                            onClicked             : {
                                switchViewFn( snapshotView, optimizeDiskView )
                            }

                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }
                }

                Item {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 0.30
                }

                Rectangle {
                    Layout.preferredWidth  : 1
                    Layout.preferredHeight : Kirigami.Units.gridUnit * 6.25
                    Layout.alignment       : Qt.AlignTop
                    color                  : Kirigami.Theme.disabledTextColor
                }

                Item {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 0.30
                }

                ColumnLayout {
                    Layout.alignment    : Qt.AlignTop
                    Layout.bottomMargin : Kirigami.Units.gridUnit * 0.75

                    RowLayout {
                        Layout.bottomMargin : Kirigami.Units.gridUnit * 0.5
                        Layout.alignment    : Qt.AlignTop

                        Controls.Button {
                            Layout.preferredWidth  : Kirigami.Units.gridUnit
                              * 1.3
                            Layout.preferredHeight : Kirigami.Units.gridUnit
                              * 1.3
                            Layout.leftMargin      : Kirigami.Units.gridUnit
                              * 0.2
                            icon.name              : "help-contextual"
                            icon.width             : Kirigami.Units.gridUnit
                            icon.height            : Kirigami.Units.gridUnit
                            enabled                : !uiLocked
                            onClicked              : {
                                showWindowFn(
                                  partitionHealthHelpWindowComponent
                                )
                            }

                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                        Kirigami.Heading {
                            text  : 'Partition Health'
                            color : uiLocked
                              ? Kirigami.Theme.disabledTextColor
                              : Kirigami.Theme.textColor
                            level : 1
                        }
                    }

                    GridLayout {
                        columns             : 5
                        Layout.maximumWidth : mainPage.width / 2
                        Layout.alignment    : Qt.AlignTop
                        Layout.topMargin    : Kirigami.Units.gridUnit * 0.7

                        Controls.Label {
                            text  : 'Mount'
                            color : uiLocked
                              ? Kirigami.Theme.disabledTextColor
                              : Kirigami.Theme.textColor
                        }
                        Controls.Label {
                            text  : 'Status'
                            color : uiLocked
                              ? Kirigami.Theme.disabledTextColor
                              : Kirigami.Theme.textColor
                        }
                        Controls.Label {
                            text             : 'Size GiB'
                            Layout.alignment : Qt.AlignRight
                            color            : uiLocked
                              ? Kirigami.Theme.disabledTextColor
                              : Kirigami.Theme.textColor
                        }
                        Controls.Label {
                            text             : 'Remain GiB'
                            Layout.alignment : Qt.AlignRight
                            color            : uiLocked
                              ? Kirigami.Theme.disabledTextColor
                              : Kirigami.Theme.textColor
                        }
                        Controls.Label {
                            text             : 'Unalloc %'
                            Layout.alignment : Qt.AlignRight
                            color            : uiLocked
                              ? Kirigami.Theme.disabledTextColor
                              : Kirigami.Theme.textColor
                        }

                        // -----

                        Controls.Label {
                            text        : '/'
                            font.family : 'courier'
                            color       : uiLocked
                              ? Kirigami.Theme.disabledTextColor
                              : Kirigami.Theme.textColor
                        }
                        Controls.Label {
                            id          : mainPartStatusStr
                            text        : ''
                            font.family : 'courier'
                            color : uiLocked
                              ? Kirigami.Theme.disabledTextColor
                              : text === 'Good'
                                ? Kirigami.Theme.positiveTextColor
                                : Kirigami.Theme.negativeTextColor
                        }
                        Controls.Label {
                            id               : mainPartSizeStr
                            text             : ''
                            font.family      : 'courier'
                            Layout.alignment : Qt.AlignRight
                            color            : uiLocked
                              ? Kirigami.Theme.disabledTextColor
                              : Kirigami.Theme.textColor
                        }
                        Controls.Label {
                            id               : mainPartRemainStr
                            text             : ''
                            font.family      : 'courier'
                            Layout.alignment : Qt.AlignRight
                            color            : uiLocked
                              ? Kirigami.Theme.disabledTextColor
                              : Kirigami.Theme.textColor
                        }
                        Controls.Label {
                            id               : mainPartUnallocStr
                            text             : ''
                            font.family      : 'courier'
                            Layout.alignment : Qt.AlignRight
                            color            : uiLocked
                              ? Kirigami.Theme.disabledTextColor
                              : Kirigami.Theme.textColor
                        }

                        // -----

                        Controls.Label {
                            text        : '/boot'
                            font.family : 'courier'
                            color       : uiLocked
                              ? Kirigami.Theme.disabledTextColor
                              : Kirigami.Theme.textColor
                        }
                        Controls.Label {
                            id          : bootPartStatusStr
                            text        : ''
                            font.family : 'courier'
                            color       : uiLocked
                              ? Kirigami.Theme.disabledTextColor
                              : text === 'Good'
                                ? Kirigami.Theme.positiveTextColor
                                : Kirigami.Theme.negativeTextColor
                        }
                        Controls.Label {
                            id               : bootPartSizeStr
                            text             : ''
                            font.family      : 'courier'
                            Layout.alignment : Qt.AlignRight
                            color: uiLocked
                              ? Kirigami.Theme.disabledTextColor
                              : Kirigami.Theme.textColor
                        }
                        Controls.Label {
                            id               : bootPartRemainStr
                            text             : ''
                            font.family      : 'courier'
                            Layout.alignment : Qt.AlignRight
                            color            : uiLocked
                              ? Kirigami.Theme.disabledTextColor
                              : Kirigami.Theme.textColor
                        }
                        Controls.Label {
                            id               : bootPartUnallocStr
                            text             : ''
                            font.family      : 'courier'
                            Layout.alignment : Qt.AlignRight
                            color            : uiLocked
                              ? Kirigami.Theme.disabledTextColor
                              : Kirigami.Theme.textColor
                        }
                    }
                }
            }

            Rectangle {
                id                : mainAreaBorder
                Layout.fillWidth  : true
                Layout.fillHeight : true
                color             : {
                    if ( Kirigami.Theme.textColor.hsvValue > 0.5 ) {
                        return Kirigami.Theme.alternateBackgroundColor;
                    } else {
                        return Kirigami.Theme.activeBackgroundColor;
                    }
                }

                Controls.Button {
                    id        : mainAreaHelpButton

                    anchors {
                        verticalCenter : mainAreaLabel.verticalCenter
                        right          : mainAreaLabel.left
                        rightMargin    : Kirigami.Units.gridUnit * 0.25
                    }

                    width       : Kirigami.Units.gridUnit * 1.3
                    height      : Kirigami.Units.gridUnit * 1.3
                    icon.name   : "help-contextual"
                    icon.width  : Kirigami.Units.gridUnit
                    icon.height : Kirigami.Units.gridUnit
                    onClicked   : showWindowFn( snapshotsHelpWindowComponent )

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                Kirigami.Heading {
                    id    : mainAreaLabel
                    anchors {
                        top              : parent.top
                        horizontalCenter : parent.horizontalCenter
                        topMargin        : Kirigami.Units.gridUnit  * 0.75
                        leftMargin       : Kirigami.Units.gridUnit * 0.25
                    }
                    level : 1
                }

                Controls.ScrollView {
                    id         : snapshotListView

                    anchors {
                        left         : parent.left
                        top          : parent.top
                        bottom       : parent.bottom
                        leftMargin   : Kirigami.Units.gridUnit * 0.80
                        topMargin    : Kirigami.Units.gridUnit * 2.75
                        bottomMargin : Kirigami.Units.gridUnit * 0.80
                    }
                    width      : Kirigami.Units.gridUnit * 15
                    background : Rectangle {
                        color        : Kirigami.Theme.backgroundColor
                    }

                    ListView {
                        id           : snapshotBar
                        anchors.fill : parent
                        visible      : true
                        model        : snapshotModel
                        delegate     : !uiLocked
                          ? enabledSnapshotBarDelegate
                          : disabledSnapshotBarDelegate
                    }
                }

                Rectangle {
                    id      : noSnapshotsOverlay

                    anchors {
                        left         : parent.left
                        top          : parent.top
                        bottom       : parent.bottom
                        leftMargin   : Kirigami.Units.gridUnit * 0.80
                        topMargin    : Kirigami.Units.gridUnit * 2.75
                        bottomMargin : Kirigami.Units.gridUnit * 0.80
                    }
                    width   : Kirigami.Units.gridUnit * 15
                    color   : Kirigami.Theme.backgroundColor
                    visible : snapshotModel.count === 0

                    Controls.Label {
                        anchors {
                            top        : parent.top;
                            left       : parent.left;
                            right      : parent.right;
                            leftMargin : Kirigami.Units.gridUnit * 0.5
                            topMargin  : Kirigami.Units.gridUnit * 0.5
                        }

                        text     : '<i>Snapshots will appear here once created</i>'
                        color    : Kirigami.Theme.disabledTextColor
                        wrapMode : Text.WordWrap
                    }
                }

                Rectangle {
                    anchors {
                        left        : snapshotListView.right
                        right       : parent.right
                        top         : mainAreaLabel.bottom
                        leftMargin  : Kirigami.Units.gridUnit * 0.85
                        rightMargin : Kirigami.Units.gridUnit * 0.80
                        topMargin   : Kirigami.Units.gridUnit * 0.75
                    }

                    height : 1
                    color  : Kirigami.Theme.disabledTextColor
                }

                SnapshotInfoItem {
                    id          : snapshotView
                    date        : snapshotModel.get(
                      snapshotBar.currentIndex).date
                    name        : snapshotModel.get(
                      snapshotBar.currentIndex).name
                    reason      : snapshotModel.get(
                      snapshotBar.currentIndex).reason
                    pinned      : snapshotModel.get(
                      snapshotBar.currentIndex).pinned
                    description : snapshotModel.get(
                      snapshotBar.currentIndex).description
                    visible     : false

                    onDeleteClicked  : {
                        prepDeleteSnapshotFn( snapshotBar.currentIndex );
                    }
                    onRestoreClicked : {
                        prepRestoreSnapshotFn( snapshotBar.currentIndex );
                    }
                    onCompareClicked : {
                        switchViewFn( snapshotView, compareSnapshotView );
                    }
                    onEditingChanged : {
                        disabledSnapshotBarIndex = snapshotBar.currentIndex;
                        uiLocked = editing;
                    }
                    onSaved          : {
                        saveSnapshotEditsFn( snapshotBar.currentIndex );
                    }
                    onCancelled      : {
                        restoreSnapshotViewBindingsFn();
                    }
                }

                BlockItem {
                    id       : noSnapshotsView
                    infoText : {
                        let outputStr
                          = '<p>No snapshots exist. Create one '
                          + 'by clicking "' + createSnapshotLabel + '" '
                          + 'above.</p>'
                          + '<br>';
                        if ( automaticSnapshotsSwitch.checked ) {
                              outputStr
                                += '<p>The system will automatically '
                                + 'take snapshots periodically.</p>';
                        } else {
                              outputStr
                                += '<p>If you would like snapshots '
                                + 'to be taken automatically, switch on '
                                + '<a href="enable-automatic-snapshots">'
                                + 'automatic snapshots</a>.</p>';
                        }
                        return outputStr;
                    }
                    onLinkActivated : {
                        if ( link === 'enable-automatic-snapshots' ) {
                            automaticSnapshotsSwitch.checked = true
                            switchAutomaticSnapshotsFn();
                        }
                    }
                    visible         : false
                }

                ConfirmScreenItem {
                    id          : createSnapshotView
                    visible     : false
                    infoText    : '<p>System Rollback is now ready to create '
                      + 'a new snapshot.</p>'
                      + '<br>'
                      + '<p><b><font color="#f7941d">IMPORTANT: Virtual '
                      + 'machine data (libvirt) will NOT be included in the '
                      + 'snapshot.</font></b></p>'
                    acceptText  : 'Take Snapshot'
                    acceptIcon  : 'document-new'

                    onOkAction  : createSnapshotFn()
                    onCancelled : {
                        switchViewFn( createSnapshotView, snapshotView );
                    }
                }

                WaitScreenItem {
                    id         : createSnapshotWaitView
                    visible    : false
                    headerText : 'Creating new snapshot...'
                }

                ErrorScreenItem {
                    id          : createSnapshotErrorView
                    visible     : false
                    infoText    : '<p>Something went wrong and a system file '
                      + 'snapshot could not be created. No changes have been '
                      + 'made to the system.</p>'
                      + '<br>'
                      + '<p>Please try to create a snapshot again. If this '
                      + 'issue persists, please contact technical support.'
                      + '</p>'

                    onOkClicked : {
                        switchViewFn( createSnapshotErrorView, snapshotView );
                    }
                }

                ErrorScreenItem {
                    id          : criticalErrorView
                    visible     : false
                    infoText    : '<p>System Rollback was interrupted while '
                      + 'attempting to manage snapshots on this system! This '
                      + 'may be the result of failing hardware or a software '
                      + 'conflict.</p>'
                      + '<br>'
                      + 'Please do NOT reboot. Back up your data as soon as '
                      + 'possible. Failure to do so may result in data loss. '
                      + 'See '
                      + '<a href="https://kfocus.org/wf/backup#bkm_take_a_snapshot">'
                      + 'https://kfocus.org/wf/backup#bkm_take_a_snapshot'
                      + '</a> for instructions on how to safeguard your data.'
                    isCritical  : true
                    onOkClicked : Qt.quit();
                }

                ConfirmScreenItem {
                    id            : optimizeDiskView
                    visible       : false
                    infoText      : '<p>System Rollback is now ready to '
                      + 'clean up the boot disk.</p>'
                      + '<br>'
                      + '<p><b><font color="#da4453">WARNING: This will '
                      + 'delete all snapshots on the system! This cannot be '
                      + 'undone!</font></b></p>'
                    acceptText    : 'Clean Up'
                    acceptIcon    : 'clean-up-destructive'
                    isDestructive : true

                    onOkAction    : optimizeDiskFn()
                    onCancelled   : {
                        switchViewFn( optimizeDiskView, snapshotView );
                    }
                }

                WaitScreenItem {
                    id          : optimizeDiskWaitView
                    visible     : false
                    headerText  : 'Cleaning Up Boot Disk...'
                    description : 'This may take several minutes. '
                      + 'You may continue to use your system in the mean '
                      + 'time.'
                }

                WaitScreenItem {
                    id          : calculateSnapshotWaitView
                    visible     : false
                    headerText  : 'Calculating snapshot sizes...'
                    description : 'This generally takes about 30 seconds, '
                      + 'but can take longer depending on how much data you '
                      + 'have saved.'
                }

                WaitScreenItem {
                    id          : automaticSnapshotSwitchView
                    visible     : false
                    headerText  : 'Toggling automatic snapshots...'
                }

                ErrorScreenItem {
                    id          : deleteSnapshotDeniedView
                    visible     : false
                    infoText    : 'This snapshot cannot be deleted because it is '
                      + 'pinned. To delete this item, unpin it first.'
                    isCritical  : false
                    onOkClicked : {
                        switchViewFn( deleteSnapshotDeniedView, snapshotView )
                    }
                }

                ConfirmSnapshotActionItem {
                    id            : deleteSnapshotView
                    visible       : false
                    startInfoText : '<p>System Rollback is ready to delete '
                      + 'the following snapshot:</p>'
                    endInfoText   : '<br><p><b><font color="#da4453">'
                      + 'WARNING: Deleting a snapshot cannot be undone!'
                      + '</font></b></p>'
                    acceptText    : 'Delete'
                    acceptIcon    : 'edit-delete-remove'
                    isDestructive : true

                    onOkAction    : {
                        deleteSnapshotFn( snapshotBar.currentIndex );
                    }
                    onCancelled   : {
                        switchViewFn( deleteSnapshotView, snapshotView );
                    }
                }

                WaitScreenItem {
                    id         : deleteSnapshotWaitView
                    visible    : false
                    headerText : 'Deleting snapshot...'
                }

                ErrorSnapshotActionItem {
                    id            : deleteSnapshotErrorView
                    visible       : false
                    startInfoText : '<p>The following snapshot could NOT be '
                      + 'deleted:</p>';
                    endInfoText   : '<br><p>Most likely it was already '
                      + 'removed by automatic snapshot maintenance. No '
                      + 'changes have been made. Please contact support if '
                      + 'this issue persists.</p>';

                    onOkClicked   : {
                        switchViewFn( deleteSnapshotErrorView, snapshotView );
                    }
                }

                ConfirmSnapshotActionItem {
                    id            : restoreSnapshotView
                    visible       : false
                    startInfoText : '<p>System Rollback is ready to restore '
                      + 'the following snapshot:</p>'
                    endInfoText   : '<br><p>Please save any open work before '
                      + 'restoring. <b><font color="#da4453">WARNING: This '
                      + 'will immediately reboot the system!</font></b></p>'
                    acceptText    : 'Restore'
                    acceptIcon    : 'edit-undo-symbolic'
                    isDestructive : true

                    onOkAction    : {
                        restoreSnapshotFn( snapshotBar.currentIndex );
                    }
                    onCancelled   : {
                        switchViewFn( restoreSnapshotView, snapshotView );
                    }
                }

                WaitScreenItem {
                    id         : restoreSnapshotWaitView
                    visible    : false
                    headerText : 'Restoring snapshot...';
                }

                ErrorSnapshotActionItem {
                    id            : restoreSnapshotErrorView
                    visible       : false
                    startInfoText : '<p>The following snapshot could NOT be '
                      + 'restored:</p>';
                    endInfoText   : '<br><p>No changes have been made to the '
                      + 'system. Please try to restore again. If this fails, '
                      + 'see <a href="https://kfocus.org/wf/recovery">'
                      + 'https://kfocus.org/wf/recovery</a> for other '
                      + 'recovery options. Contact support if this issue '
                      + 'persists.</p>'

                    onOkClicked   : {
                        switchViewFn( restoreSnapshotErrorView, snapshotView )
                    }
                }

                SnapshotCompareItem {
                    id               : compareSnapshotView
                    visible          : false
                    snapshotList     : derivSnapshotModel

                    onCompareClicked : {
                        compareSnapshotsFn(
                          snapshotBar.currentIndex, compareIndex
                        );
                    }
                    onCancelled      : {
                        switchViewFn( compareSnapshotView, snapshotView );
                    }
                }

                WaitScreenItem {
                    id          : compareSnapshotWaitView
                    visible     : false
                    headerText  : 'Comparing snapshots...'
                    description : 'All data in the selected snapshots '
                      + 'is being compared. This may take five minutes or '
                      + 'more.'
                }

                WaitScreenItem {
                    id         : saveEditsWaitView
                    visible    : false
                    headerText : 'Saving edits...'
                }
            }
        }

        OverlayAlertItem {
            id: lowDiskOverlay
            isVisible: false
            mainIcon: 'dialog-error'
            headerText: 'Low Disk Space Warning'
            mainText: 'This system needs more disk space. You '
              + 'could delete some files to open up space, '
              + 'which is often a good idea.'
            secondaryText: 'Another way to free space is to remove '
              + 'snapshots. Click on “'
              + calculateSnapshotSizesLabel
              + '” below to calculate and show the size of '
              + 'all snapshots. This usually takes 30 to 90 '
              + 'seconds to complete, so please be patient.'
            primaryButtonText: 'Show Snapshot Sizes'
            primaryButtonIcon: 'disk-quota'
            secondaryButtonText: 'Skip'
            secondaryButtonIcon: 'go-next-skip'
            showSecondaryButton: true

            onPrimaryButtonClicked: {
                calculateSnapshotSizesFn();
                lowDiskOverlay.visible = false;
            }
            onSecondaryButtonClicked: {
                lowDiskOverlay.visible = false;
            }
        }

        Rectangle {
            id: postRestoreOverlay
            visible: false

            anchors.fill: parent
            color: Kirigami.Theme.backgroundColor

            ColumnLayout {
                anchors {
                    verticalCenter: parent.verticalCenter
                    horizontalCenter: parent.horizontalCenter
                }

                RowLayout {
                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignTop
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 4
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        Layout.rightMargin:
                          Kirigami.Units.gridUnit * 1.05
                        Layout.topMargin:
                          Kirigami.Units.gridUnit * 1.90
                        source: 'dialog-information'
                    }

                    ColumnLayout {
                        Kirigami.Heading {
                            Layout.bottomMargin:
                              Kirigami.Units.gridUnit * 0.5
                            text: 'Rollback Successful'
                            level: 1
                        }

                        Controls.Label {
                            Layout.preferredWidth:
                              Kirigami.Units.gridUnit * 20
                            Layout.bottomMargin:
                              Kirigami.Units.gridUnit * 0.5
                            text:
                              'Files from the snapshot below have been '
                              + 'restored to the system.'
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            Layout.preferredWidth:
                              Kirigami.Units.gridUnit * 20
                            Layout.bottomMargin:
                              Kirigami.Units.gridUnit * 0.5

                            Kirigami.Icon {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.rightMargin: Kirigami.Units.gridUnit * 0.25
                                source: getIconForReasonFn( backend.postRestoreReason )
                            }

                            ColumnLayout {
                                Kirigami.Heading {
                                    text: backend.postRestoreDate
                                    level: 2
                                }

                                Controls.Label {
                                    text: '<i>' + backend.postRestoreName + '</i>'
                                    color: Kirigami.Theme.disabledTextColor
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }
                        }

                        Controls.Label {
                            Layout.preferredWidth:
                              Kirigami.Units.gridUnit * 20
                            Layout.bottomMargin:
                              Kirigami.Units.gridUnit * 0.5
                            text:
                              'Click "OK" to return to the rollback '
                              + 'dashboard, or "Compare" to see what files '
                              + 'changed during the rollback.'
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            Layout.preferredWidth:
                              Kirigami.Units.gridUnit * 20

                            Item {
                                Layout.fillWidth: true
                            }

                            Controls.Button {
                                Layout.rightMargin:
                                  Kirigami.Units.gridUnit * 0.5
                                text: 'OK'
                                icon.name: 'dialog-ok'
                                onClicked: {
                                    postRestoreOverlay.visible = false;
                                }
                            }

                            Controls.Button {
                                text: 'Compare'
                                icon.name: 'document-duplicate'
                                onClicked: {
                                    postRestoreOverlay.visible = false;
                                    compareSnapshotsFn( 0, 0 );
                                }
                            }
                        }
                    }
                }
            }
        }

        OverlayAlertItem {
            isVisible: backend.btrfsStateUnusable
            mainIcon: 'dialog-warning'
            headerText: 'System Unsupported'
            mainText: 'This system does not appear to support '
              + 'snapshotting and rollback. Please see '
              + '<a href="https://kfocus.org/wf/recovery">https://kfocus.org/wf/recovery</a> '
              + 'for other recovery steps you can take.'
            primaryButtonText: 'Exit'
            primaryButtonIcon: 'go-previous-symbolic'
            showSecondaryButton: false

            onPrimaryButtonClicked: {
                Qt.quit();
            }
        }

        OverlayAlertItem {
            isVisible: backend.postRestoreSubvolsMounted
            mainIcon: 'dialog-warning'
            headerText: 'Restore Incomplete'
            mainText: 'A snapshot was restored, but the system has not been '
              + 'rebooted. Please reboot to finalize the restore. If this '
              + 'does not fix the system, you can attempt another rollback.'
            primaryButtonText: 'Exit'
            primaryButtonIcon: 'go-previous-symbolic'
            showSecondaryButton: false

            onPrimaryButtonClicked: {
                Qt.quit();
            }
        }

        OverlayAlertItem {
            isVisible: backend.mainWorkingSubvolExists
            mainIcon: 'dialog-warning'
            headerText: 'Strange BTRFS Subvolume Exists'
            mainText: 'The BTRFS subvolume at '
              + backend.rollbackMainWorkingDir
              + ' should not exist, but does. System Rollback cannot proceed '
              + 'with this subvolume present. Please ensure this subvolume '
              + 'does not contain any important data, then remove it with '
              + '"sudo btrfs subvolume delete".'
            primaryButtonText: 'Exit'
            primaryButtonIcon: 'go-previous-symbolic'
            showSecondaryButton: false

            onPrimaryButtonClicked: {
                Qt.quit();
            }
        }

        OverlayAlertItem {
            isVisible: backend.bootWorkingSubvolExists
            mainIcon: 'dialog-warning'
            headerText: 'Strange BTRFS Subvolume Exists'
            mainText: 'The BTRFS subvolume at '
              + backend.rollbackBootWorkingDir
              + ' should not exist, but does. System Rollback cannot proceed '
              + 'with this subvolume present. Please ensure this subvolume '
              + 'does not contain any important data, then remove it with '
              + '"sudo btrfs subvolume delete".'
            primaryButtonText: 'Exit'
            primaryButtonIcon: 'go-previous-symbolic'
            showSecondaryButton: false

            onPrimaryButtonClicked: {
                Qt.quit();
            }
        }
    }
    // == . END Views =================================================

    // == BEGIN Controllers ===========================================
    ShellEngine {
        id          : createSnapshotEngine
        onAppExited : {
            sysRefreshSourceView = createSnapshotWaitView
            if ( exitCode === 0 || exitCode === 127 ) {
                sysRefreshTargetView = snapshotView;
            } else if ( exitCode === 1 ) {
                sysRefreshTargetView = createSnapshotErrorView;
            } else {
                sysRefreshTargetView = criticalErrorView;
            }
            refreshSystemDataFn( false );
        }
    }

    ShellEngine {
        id          : optimizeDiskEngine
        onAppExited : {
            sysRefreshSourceView = optimizeDiskWaitView;
            if ( exitCode === 0 || exitCode === 127 ) {
                sysRefreshTargetView = snapshotView;
            } else {
                sysRefreshTargetView = criticalErrorView;
            }
            refreshSystemDataFn( false );
        }
    }

    ShellEngine {
        id          : automaticSnapshotToggleEngine
        onAppExited : {
            sysRefreshSourceView = automaticSnapshotSwitchView;
            sysRefreshTargetView = snapshotView;
            refreshSystemDataFn( false );
        }
    }

    ShellEngine {
        id          : deleteSnapshotEngine
        onAppExited : {
            sysRefreshSourceView = deleteSnapshotWaitView;
            if ( exitCode === 0 || exitCode === 127 ) {
                sysRefreshTargetView = snapshotView;
            } else if ( exitCode === 1 ) {
                sysRefreshTargetView = deleteSnapshotErrorView;
            } else {
                sysRefreshTargetView = criticalErrorView;
            }
            refreshSystemDataFn( false );
        }
    }

    ShellEngine {
        id          : restoreSnapshotEngine
        onAppExited : {
            if ( exitCode === 0 ) {
                execSync( 'systemctl reboot -i' );
            } else if ( exitCode === 127 ) {
                switchViewFn( restoreSnapshotWaitView, snapshotView );
            } else if ( exitCode === 1 ) {
                switchViewFn( restoreSnapshotWaitView, restoreSnapshotErrorView );
            } else {
                switchViewFn( restoreSnapshotWaitView, criticalErrorView );
            }
        }
    }

    ShellEngine {
        id          : compareSnapshotsEngine
        onAppExited : {
            let snapInfo
              = snapshotModel.get(snapshotBar.currentIndex);
            let dupSnapInfo
              = derivSnapshotModel.get(compareSnapshotView.compareIndex)
            compareSourceIdStr
              = snapInfo.date + ' - ' + snapInfo.name;
            compareTargetIdStr
              = dupSnapInfo.date + ' - ' + dupSnapInfo.name;
            compareResultStr = stdout;
            showWindowFn( snapshotCompareWindowComponent );
            switchViewFn( compareSnapshotWaitView, snapshotView );
        }
    }

    ShellEngine {
        id: saveEditsEngine
        onAppExited: {
            if ( exitCode === 0 ) {
                snapshotModel.get(snapshotBar.currentIndex).name
                  = snapshotView.name;
                snapshotModel.get(snapshotBar.currentIndex).description
                  = snapshotView.description;
                snapshotModel.get(snapshotBar.currentIndex).pinned
                  = snapshotView.pinned;
                restoreSnapshotViewBindingsFn();
                snapshotView.saving  = false;
                snapshotView.editing = false;
                backend.inhibitClose = false;
                switchViewFn( saveEditsWaitView, snapshotView );
            } else {
                restoreSnapshotViewBindingsFn();
                sysRefreshSourceView = saveEditsWaitView;
                sysRefreshTargetView = snapshotView;
                snapshotView.saving  = false;
                snapshotView.editing = false;
                backend.inhibitClose = false;
                refreshSystemDataFn( false );
            }
        }
    }

    function getIconForReasonFn( reason ) {
        return reason === 'System Schedule'
          ? 'clock'
          : reason    === 'Before Package Change'
            ? 'system-upgrade'
            : reason  === 'Pre-Rollback'
              ? 'edit-undo-symbolic'
              : 'user'
    }

    function getSnapshotViewHeaderFn() {
        return snapshotBar.count == 0 ? 'No Snapshots' : 'Snapshots';
    }

    /*
     * WARNING: Do NOT pass `this` as the first argument to switchViewFn! If
     * you do so anywhere except in an object's inline signal handler, it
     * will cause the program's window to vanish without actually terminating
     * the program. (That's because `this` only exists in the context of the
     * signal handler, not in the context of a function called by it.) Always
     * explicitly reference both views to avoid this.
     */
    function switchViewFn( current_view, target_view ) {
        // Preamble
        // Lock the peripheral UI elements for almost all views
        uiLocked = true;
        // Remove the contextual help button for almost all views
        mainAreaHelpButton.visible = false;

        // Handlers for current view
        if ( current_view === snapshotView ) {
            if ( snapshotBar.count === 0 ) {
                current_view = noSnapshotsView;
            }
        }

        // Handlers for target view
        if ( target_view === snapshotView ) {
            if ( snapshotBar.count === 0 ) {
                target_view = noSnapshotsView;
            }
            mainAreaLabel.text         = getSnapshotViewHeaderFn();
            uiLocked                   = false;
            mainAreaHelpButton.visible = true;
        } else if ( target_view === createSnapshotView ) {
            mainAreaLabel.text = createSnapshotLabel;
        } else if ( target_view === createSnapshotErrorView ) {
            mainAreaLabel.text = createSnapshotErrorLabel;
        } else if ( target_view === optimizeDiskView ) {
            mainAreaLabel.text = optimizeDiskLabel;
        } else if ( target_view === automaticSnapshotSwitchView ) {
            mainAreaLabel.text = automaticSnapshotsLabel;
        } else if ( target_view === deleteSnapshotView ) {
            mainAreaLabel.text = deleteSnapshotLabel;
        } else if ( target_view === restoreSnapshotView ) {
            mainAreaLabel.text = restoreSnapshotLabel;
        } else if ( target_view === compareSnapshotView ) {
            mainAreaLabel.text = compareSnapshotLabel;
        } else if ( target_view === deleteSnapshotDeniedView ) {
            mainAreaLabel.text = deleteSnapshotDeniedLabel;
        } else if ( target_view === deleteSnapshotErrorView ) {
            mainAreaLabel.text = deleteSnapshotErrorLabel;
        } else if ( target_view === restoreSnapshotErrorView ) {
            mainAreaLabel.text = restoreSnapshotErrorLabel;
        } else if ( target_view === calculateSnapshotWaitView ) {
            mainAreaLabel.text = calculateSnapshotSizesLabel;
        }

        // Switch view
        current_view.visible = false;
        target_view.visible = true;
    }

    function createSnapshotFn() {
        backend.inhibitClose = true;
        switchViewFn( createSnapshotView, createSnapshotWaitView )
        createSnapshotEngine.exec(
          rollbackStr + 'systemSnapshot "$(id -nu)"'
        );
    }

    function optimizeDiskFn() {
        backend.inhibitClose = true;
        switchViewFn( optimizeDiskView, optimizeDiskWaitView );
        optimizeDiskEngine.exec( rollbackStr + 'btrfsDeepClean' );
    }

    function switchAutomaticSnapshotsFn() {
        backend.inhibitClose = true;
        switchViewFn( snapshotView, automaticSnapshotSwitchView );
        automaticSnapshotToggleEngine.exec(
          rollbackStr + 'setManualSwitchState '
            + (automaticSnapshotsSwitch.checked
              ? 'auto'
              : 'manual')
        );
    }

    function calculateSnapshotSizesFn() {
        switchViewFn( snapshotView, calculateSnapshotWaitView );
        sysRefreshSourceView = calculateSnapshotWaitView;
        sysRefreshTargetView = snapshotView;
        refreshSystemDataFn( true );
    }

    function prepDeleteSnapshotFn( snapshot_idx ) {
        if ( snapshotView.pinned ) {
            switchViewFn( snapshotView, deleteSnapshotDeniedView );
        } else {
            deleteSnapshotView.reason      = snapshotModel.get(snapshot_idx).reason;
            deleteSnapshotView.date        = snapshotModel.get(snapshot_idx).date;
            deleteSnapshotView.name        = snapshotModel.get(snapshot_idx).name;
            deleteSnapshotErrorView.date   = snapshotModel.get(snapshot_idx).date;
            deleteSnapshotErrorView.name   = snapshotModel.get(snapshot_idx).name;
            deleteSnapshotErrorView.reason = snapshotModel.get(snapshot_idx).reason;
            switchViewFn( snapshotView, deleteSnapshotView );
        }
    }

    function deleteSnapshotFn( snapshot_idx ) {
        backend.inhibitClose = true;
        switchViewFn( deleteSnapshotView, deleteSnapshotWaitView );
        deleteSnapshotEngine.exec(
          rollbackStr
            + 'deleteSnapshot '
            + snapshotModel.get(snapshot_idx).id
        );
    }

    function prepRestoreSnapshotFn( snapshot_idx ) {
        restoreSnapshotView.reason = snapshotModel.get(snapshot_idx).reason;
        restoreSnapshotView.date   = snapshotModel.get(snapshot_idx).date;
        restoreSnapshotView.name   = snapshotModel.get(snapshot_idx).name;
        restoreSnapshotErrorView.reason = snapshotModel.get(snapshot_idx).reason;
        restoreSnapshotErrorView.date   = snapshotModel.get(snapshot_idx).date;
        restoreSnapshotErrorView.name   = snapshotModel.get(snapshot_idx).name;
        switchViewFn( snapshotView, restoreSnapshotView );
    }

    function restoreSnapshotFn( snapshot_idx ) {
        backend.inhibitClose = true;
        switchViewFn( restoreSnapshotView, restoreSnapshotWaitView );
        restoreSnapshotEngine.exec(
          rollbackStr
            + 'restoreSnapshot '
            + snapshotModel.get(snapshot_idx).id
        );
    }

    function compareSnapshotsFn( source_idx, target_idx ) {
        compareSnapshotsEngine.exec(
          rollbackStr + "compareState '"
            + snapshotModel.get(source_idx).stateDir
            + "' '"
            + derivSnapshotModel.get(target_idx).stateDir
            + "'"
        );
        if (compareSnapshotView.visible) {
            switchViewFn( compareSnapshotView, compareSnapshotWaitView );
        } else {
            switchViewFn( snapshotView, compareSnapshotWaitView );
        }
    }

    function saveSnapshotEditsFn( snapshot_idx ) {
        backend.inhibitClose = true;
        switchViewFn( snapshotView, saveEditsWaitView );
        let snapInfo = snapshotModel.get(snapshot_idx);
        saveEditsEngine.exec(
          rollbackStr
            + 'setSnapshotMetadata '
            + snapInfo.id
            + ' "'
            + backend.toBase64(snapshotView.name)
            + '" "'
            + backend.toBase64(snapshotView.description)
            + '" "'
            + (snapshotView.pinned === true
              ? 'y'
              : 'n')
            + '"'
        );
    }

    function restoreSnapshotViewBindingsFn() {
        snapshotView.name = Qt.binding(function() {
            return snapshotModel.get(snapshotBar.currentIndex).name;
        });
        snapshotView.description = Qt.binding(function() {
            return snapshotModel.get(snapshotBar.currentIndex).description;
        });
        snapshotView.pinned = Qt.binding(function() {
            return snapshotModel.get(snapshotBar.currentIndex).pinned;
        });
    }

    function showWindowFn( window_component ) {
        let window = window_component.createObject(root);
        window.show();
    }

    function refreshSystemDataFn( calc_size ) {
        backend.refreshSystemData( calc_size );
    }

    function populateSnapshotModelFn() {
        snapshotModel.clear();
        for ( let i = 0; i < backend.getSnapshotCount(); i++ ) {
            snapshotModel.append({
                date        : backend.getSnapshotInfo(i, 'date'),
                name        : backend.getSnapshotInfo(i, 'name'),
                description : backend.getSnapshotInfo(i, 'description'),
                reason      : backend.getSnapshotInfo(i, 'reason'),
                pinned      : backend.getSnapshotInfo(i, 'pinned') === 'true'
                  ? true
                  : false,
                size        : backend.getSnapshotInfo(i, 'size'),
                stateDir    : backend.getSnapshotInfo(i, 'stateDir'),
                id          : backend.getSnapshotInfo(i, 'id')
            });
        }
        if (snapshotBar.currentIndex >= snapshotBar.count
          || snapshotBar.currentIndex === -1) {
          snapshotBar.currentIndex = 0;
        }
        snapshotBar.currentIndexChanged();
    }

    function derivateSnapshotModelFn() {
        derivSnapshotModel.clear();

        for (let i = 0; i < snapshotModel.count; i++) {
            derivSnapshotModel.append(snapshotModel.get(i));
        }

        let currentDate  = new Date(Date.now());
        const tzOffsetMs = currentDate.getTimezoneOffset();
        currentDate = new Date(
          currentDate.getTime()
          - (tzOffsetMs * 60 * 1000)
        );
        const dateStr    = currentDate.toISOString().split('T')[0];
        derivSnapshotModel.insert(0, {
            date     : dateStr,
            name     : 'Current State',
            reason   : 'current',
            pinned   : false,
            stateDir : '/btrfs_main/@'
        });
        compareSnapshotView.resetSelector();
    }

    function fillPartitionHealthTableFn() {
        mainPartStatusStr.text  = backend.getFsData('main', 'status');
        mainPartSizeStr.text    = backend.getFsData('main', 'size');
        mainPartRemainStr.text  = backend.getFsData('main', 'remain');
        mainPartUnallocStr.text = backend.getFsData('main', 'unalloc');
        bootPartStatusStr.text  = backend.getFsData('boot', 'status');
        bootPartSizeStr.text    = backend.getFsData('boot', 'size');
        bootPartRemainStr.text  = backend.getFsData('boot', 'remain');
        bootPartUnallocStr.text = backend.getFsData('boot', 'unalloc');
    }

    // Kick-off rendering on completion
    Component.onCompleted: {
        mainAreaLabel.text = getSnapshotViewHeaderFn();
        refreshSystemDataFn( false );
    }
    // == . END Controllers ===========================================
}

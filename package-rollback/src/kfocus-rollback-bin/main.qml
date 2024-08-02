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
            helpText: `<p><b><font color="#f7941d">Create New
              Snapshot:</b></font> Immediately create a snapshot of the
              current system state. This includes the /boot and root
              filesystems. This snapshot can be restored later as needed.</p>

              <p><b><font color="#f7941d">Optimize Disk:</font></b>
              Maximize available free space. This deletes all
              snapshots, defragments files as needed, recovers unreachable
              space, and consolidates data on the boot disk. Use this if
              databases, virtual machines, or other apps have become
              sluggish; or if the system prompts you to run it to recover
              disk space.</p>

              <p><b><font color="#f7941d">Automatic Snapshots:</font></b>
              Enable this to take snapshots without intervention before apt
              software changes, or at least once a week.</p>`
            helpTitle: 'Global Actions Help'
        }
    }

    Component {
        id: partitionHealthHelpWindowComponent
        HelpWindow {
            helpText: `<p><font color="#f7941d"><b>Mount:</b></font>
              Indicates which filesystem each row corresponds to. System
              Rollback keeps snapshots for both the root (<code>/</code>)
              and boot (<code>/boot</code>) filesystems correlated so
              there are no data inconsistencies.</p>

              <p><font color="#f7941d"><b>Status:</b></font> Shows whether
              the filesystem's disk space is sufficient or not. A status of
              "<font color="#27ae60"><code>Good</code></font>" means that disk
              space is sufficient, while a status of
              "<font color="#da4453"><code>ALERT</code></font>" means that
              disk space is low. Delete files or snapshots to free up disk
              space.</p>

              <p><font color="#f7941d"><b>Size GiB:</b></font> Shows the size
              of the filesystem, in gigabytes.</p>

              <p><font color="#f7941d"><b>Remain GiB:</b></font> Shows the
              remaining free space on the filesystem.</p>

              <p><font color="#f7941d"><b>Unalloc %:</b></font> Shows the
              percentage of unallocated space left on the filesystem.
              Unallocated space can be exhausted quicker than free space,
              which will cause problems. We recommend having at least 15%
              unallocated space on the root and boot filesystems at all
              times.</p>`
            helpTitle: 'Partition Health Help'
        }
    }

    Component {
        id: snapshotsHelpWindowComponent
        HelpWindow {
            helpText: `<p><b><font color="#f7941d">Delete</font></b> -
              Removes the selected snapshot from the disk permanently.</p>
              <br>
              <p><b><font color="#f7941d">Restore</font></b> - Rolls back
              the system to the state saved in the selected snapshot. The
              system will reboot automatically during the restore
              process.</p>
              <br>
              <p><b><font color="#f7941d">Compare With</font></b> -
              Allows you to see what files are different between any two
              snapshots, or between a snapshot and the current system
              state.</p>
              <br>
              <p><b><font color="#f7941d">Edit</font></b> - Allows you to
              edit the name, description, and pinning of the selected
              snapshot.</p>
              <br>
              <p><b><font color="#f7941d">Pin this Snapshot</font></b> -
              Pinned snapshots will not be removed during automatic
              snapshot maintenance. They can be deleted manually by the
              user. You may pin and unpin a snapshot by editing it.</p>`
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
                                text               : 'Automatic Snapshots'
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
                            text                  : 'Show Snapshot Sizes'
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
                            text                  : 'Create New Snapshot'
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
                            text                  : 'Optimize Disk'
                            icon.name             : 'edit-clear-all'
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
                          + 'by clicking "Create New Snapshot" above.</p>'
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
                    id          : optimizeDiskView
                    visible     : false
                    infoText    : '<p>System Rollback is now ready to '
                      + 'optimize the boot disk.</p>'
                      + '<br>'
                      + '<p><b><font color="#da4453">WARNING: This will '
                      + 'delete all snapshots on the system! This cannot be '
                      + 'undone!</font></b></p>'
                    acceptText  : 'Optimize'
                    acceptIcon  : 'edit-clear-all'

                    onOkAction  : optimizeDiskFn()
                    onCancelled : {
                        switchViewFn( optimizeDiskView, snapshotView );
                    }
                }

                WaitScreenItem {
                    id          : optimizeDiskWaitView
                    visible     : false
                    headerText  : 'Optimizing Boot Disk...'
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

                ConfirmSnapshotActionItem {
                    id            : deleteSnapshotView
                    visible       : false
                    startInfoText : '<p>System Rollback is ready to delete '
                      + 'the following snapshot:</p>'
                    endInfoText   : '<br><p><b><font color="#da4453">'
                      + 'WARNING: Deleting a snapshot cannot be undone!'
                      + '</font></b></p>'
                    acceptText    : 'Delete'
                    acceptIcon    : 'delete'

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

                ErrorSnapshotActionItem {
                    id            : deleteSnapshotCriticalErrorView
                    visible       : false
                    startInfoText : '<p>System Rollback was interrupted '
                      + 'while deleting the following snapshot:</p>';
                    endInfoText   : '<br><p>This may be the result of '
                      + 'failing hardware or a software conflict. Please do '
                      + 'NOT reboot. Back up your data as soon as possible. '
                      + 'Failure to do so may result in data loss. See '
                      + '<a href="https://kfocus.org/wf/backup#bkm_take_a_snapshot">'
                      + 'https://kfocus.org/wf/backup#bkm_take_a_snapshot'
                      + '</a> for instructions on how to safeguard your '
                      + 'data.</p>'
                    isCritical    : true

                    onOkClicked   : Qt.quit()
                }

                ConfirmSnapshotActionItem {
                    id            : restoreSnapshotView
                    visible       : false
                    startInfoText : '<p>The following snapshot is now ready '
                     + 'to be restored:</p>'
                    endInfoText   : '<br><p>Please save any open work before '
                      + 'restoring. <b><font color="#da4453">WARNING: This '
                      + 'will immediately reboot the system!</font></b></p>'
                    acceptText    : 'Restore'
                    acceptIcon    : 'edit-undo-symbolic'

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

        Rectangle {
            id           : lowDiskOverlay
            visible      : false

            anchors.fill : parent
            color        : Kirigami.Theme.backgroundColor

            ColumnLayout {
                anchors {
                    verticalCenter: parent.verticalCenter
                    horizontalCenter: parent.horizontalCenter
                }
                RowLayout {
                    Kirigami.Icon {
                        Layout.alignment       : Qt.AlignTop
                        Layout.preferredHeight : Kirigami.Units.gridUnit * 4
                        Layout.preferredWidth  : Kirigami.Units.gridUnit * 4
                        Layout.rightMargin     :
                          Kirigami.Units.gridUnit * 1.05
                        Layout.topMargin       :
                          Kirigami.Units.gridUnit * 1.90
                        source                 : 'dialog-error'
                    }
                    ColumnLayout {
                        Kirigami.Heading {
                            Layout.bottomMargin :
                              Kirigami.Units.gridUnit * 0.5
                            text                : 'Low Disk Space Warning'
                            level               : 1
                        }
                        Controls.Label {
                            Layout.preferredWidth :
                              Kirigami.Units.gridUnit * 20
                            Layout.bottomMargin   :
                              Kirigami.Units.gridUnit * 0.5
                            text                  :
                              'This system needs more disk space. You '
                              + 'could delete some files to open up space, '
                              + 'which is often a good idea.'
                            wrapMode              : Text.WordWrap
                        }
                        Controls.Label {
                            Layout.preferredWidth :
                              Kirigami.Units.gridUnit * 20
                            Layout.bottomMargin   :
                              Kirigami.Units.gridUnit * 0.5
                            text                  :
                              'Another way to free space is to remove '
                              + 'snapshots. Click on “Show Snapshot Sizes” '
                              + 'below to calculate and show the size of all '
                              + 'snapshots. This usually takes 30 to 90 '
                              + 'seconds to complete, so please be patient.'
                            wrapMode              : Text.WordWrap
                        }
                    }
                }
                Controls.Button {
                    Layout.alignment : Qt.AlignHCenter
                    Layout.topMargin : Kirigami.Units.gridUnit * 1.15
                    id               : ldSnapshotSizeButton
                    text             : 'Show Snapshot Sizes'
                    icon.name        : 'disk-quota'
                    onClicked        : {
                        calculateSnapshotSizesFn();
                        lowDiskOverlay.visible = false;
                    }
                }
            }

            Controls.Button {
                text      : 'Skip'
                icon.name : 'go-next-skip'
                anchors {
                    right  : parent.right
                    bottom : parent.bottom
                }
                onClicked : {
                    lowDiskOverlay.visible = false;
                }
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
            sysRefreshSourceView = saveEditsWaitView;
            sysRefreshTargetView = snapshotView;
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
                sysRefreshSourceView = snapshotView;
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
            mainAreaLabel.text = 'Create New Snapshot';
        } else if ( target_view === createSnapshotErrorView ) {
            mainAreaLabel.text = 'Snapshot Creation Failed';
        } else if ( target_view === optimizeDiskView ) {
            mainAreaLabel.text = 'Optimize Disk';
        } else if ( target_view === automaticSnapshotSwitchView ) {
            mainAreaLabel.text = 'Automatic Snapshots';
        } else if ( target_view === deleteSnapshotView ) {
            mainAreaLabel.text = 'Delete Snapshot';
        } else if ( target_view === compareSnapshotView ) {
            mainAreaLabel.text = 'Compare Snapshots';
        } else if ( target_view === calculateSnapshotWaitView ) {
            mainAreaLabel.text = 'Show Snapshot Sizes';
        }

        // Switch view
        current_view.visible = false;
        target_view.visible = true;
    }

    function createSnapshotFn() {
        backend.inhibitClose = true;
        switchViewFn( createSnapshotView, createSnapshotWaitView )
        createSnapshotEngine.exec(
          rollbackStr + 'createSnapshot "$(id -nu)"'
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
        deleteSnapshotView.reason = snapshotModel.get(snapshot_idx).reason;
        deleteSnapshotView.date   = snapshotModel.get(snapshot_idx).date;
        deleteSnapshotView.name   = snapshotModel.get(snapshot_idx).name;
        switchViewFn( snapshotView, deleteSnapshotView );
    }

    function deleteSnapshotFn( snapshot_idx ) {
        backend.inhibitClose = true;
        switchViewFn( deleteSnapshotView, deleteSnapshotWaitView )
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
          'pkexec diff -r --brief "'
            + snapshotModel.get(source_idx).stateDir
            + '" "'
            + derivSnapshotModel.get(target_idx).stateDir
            + '"'
        );
        switchViewFn( compareSnapshotView, compareSnapshotWaitView );
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
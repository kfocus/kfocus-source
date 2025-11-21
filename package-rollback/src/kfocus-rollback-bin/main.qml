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

            if ( !firstInitDone ) {
                switchViewFn( snapshotView );
                if ( backend.mainSpaceLow ) {
                    lowDiskOverlay.visible = true;
                } else if ( backend.bootSpaceLow ) {
                    lowBootOverlay.visible = true;
                }

                pageStack.pop();
                pageStack.push( mainPage );
                firstInitDone = true;
            } else {
                switchViewFn( sysRefreshTargetView );
            }
            resetUiStateFn()
        }
    }

    // == BEGIN Models ================================================
    // Set Global Properties
    property bool   firstInitDone            : false
    property var    lastSetView
    property var    sysRefreshSourceView
    property var    sysRefreshTargetView
    property int    disabledSnapshotBarIndex : 0
    property bool   uiLocked                 : false
    property string compareSourceIdStr       : ''
    property string compareTargetIdStr       : ''
    property string compareResultStr         : ''
    property string authAttemptAction        : ''
    property string rollbackStr              : backend.pkexecExe
      + ' '
      + backend.rollbackBackendExe
      + ' '
    property string rollbackDeepCleanStr     : backend.systemdInhibitExe
      + ' '
      + '--who="System Rollback"'
      + ' '
      + '--why="Freeing up disk space"'
      + ' '
      + rollbackStr
      + 'btrfsDeepClean'

    // Set Constant Names
    property string automaticSnapshotsLabel     : 'Automatic Snapshots'
    property string calculateSnapshotSizesLabel : 'Show Snapshot Sizes'
    property string compareSnapshotLabel        : 'Compare Snapshots'
    property string createSnapshotErrorLabel    : 'Snapshot Creation Failed'
    property string createSnapshotLabel         : 'Create New Snapshot'
    property string refreshSnapshotLabel        : 'Refresh Info'
    property string deleteSnapshotErrorLabel    : 'Snapshot Deletion Failed'
    property string deleteSnapshotLabel         : 'Delete Snapshot'
    property string optimizeDiskLabel           : 'Free Up Disk Space'
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
    width         : Kirigami.Units.gridUnit * 47
    height        : Kirigami.Units.gridUnit * 33
    minimumWidth  : Kirigami.Units.gridUnit * 47
    minimumHeight : Kirigami.Units.gridUnit * 33

    // BEGIN Define sidebar views
    Component {
        id: enabledSnapshotBarDelegate

        Kirigami.BasicListItem {
            font.family : "courier"
            label       : date + ' ' + genSnapshotSizeStrFn(mainSize, bootSize)
            subtitle    : name
            icon        : getIconForReasonFn( reason )
            trailing    : Kirigami.Icon {
                source  : pinned ? 'lock' : ''
            }
        }
    }

    Component {
        id: disabledSnapshotBarDelegate

        Kirigami.BasicListItem {
            font.family : "courier"
            label       : date + ' ' + genSnapshotSizeStrFn(mainSize, bootSize)
            subtitle    : name
            icon        : getIconForReasonFn( reason )
            trailing    : Kirigami.Icon {
                source  : pinned ? 'lock' : ''
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
            helpText: `<p>These are actions that do not pertain to a
              specific snapshot.</p>

              <p><b><font color="#f7941d">` + automaticSnapshotsLabel
              + `</font></b> - When enabled, take snapshots without
              intervention before system (<code>APT</code>) software
              changes, or at least once per week.</p>

              <p><i>This option provides more frequent snapshots, but
              requires additional oversight to avoid filling the root
              (<code>/</code>) and boot (<code>/boot</code>)
              filesystems.</i></p>

              <p><b><font color="#f7941d">` + calculateSnapshotSizesLabel
              + `</font></b> - Calculate and display the estimated space
              used by each snapshot. Deleting a snapshot will free the
              amount of space shown.</p>

              <p><b><font color="#f7941d">` + createSnapshotLabel
              + `</font></b> - Create a snapshot of the current root
              (<code>/</code>) and boot (<code>/boot</code>) filesystems.</p>

              <p><b><font color="#f7941d">` + optimizeDiskLabel
              + `</font></b> - Use Quick Clean to free up unallocated space.
              Use Deep Clean to delete all snapshots, defragment files,
              recover unreachable space, and consolidate data.</p>`

            helpTitle: 'Global Actions Help'
        }
    }

    // System Rollback correlates
    // same-point-in-time snapshots for both the root (<code>/</code>)
    // and boot (<code>/boot</code>) filesystems. This helps ensure
    // that rollback data is always consistent.</p>
    Component {
        id: partitionHealthHelpWindowComponent
        HelpWindow {
            helpText: `<p>These are health metrics of the partitions
              used in snapshots.</p>

              <p><b><font color="#f7941d">Mount</font></b> -
              The filesystem mount point, either root (<code>/</code>)
              or boot (<code>/boot</code>).</p>

              <p><b><font color="#f7941d">Size GiB</font></b> -
              Filesystem size, in gigabytes.</p>

              <p><b><font color="#f7941d">Remain GiB</font></b> -
              Remaining free space on the filesystem.</p>

              <p><b><font color="#f7941d">Unalloc</font></b> -
              Percentage of unallocated space available on the filesystem.
              Root (<code>/</code>) unallocated space should always exceed
              15%, and boot (<code>/boot</code>) should always exceed 25%.</p>

              <p><b><font color="#f7941d">Status</font></b> - Disk space
              status. "<font color="#27ae60"><code>Good</code></font>" means
              that disk space is sufficient.
              "<font color="#da4453"><code>ALERT</code></font>" means that
              disk space is low. Delete files or snapshots to free up disk
              space.</p>`

            helpTitle: 'Partition Health Help'
        }
    }

    Component {
        id: snapshotsHelpWindowComponent
        HelpWindow {
            helpText: `<p>These are actions for the selected snapshot.</p>

              <p><b><font color="#f7941d">Restore</font></b> -
              Rollback the system to the selected snapshot. The
              system reboots automatically during the restore process. Data in
              the <code>/home</code> directory is unaffected.</p>

              <p><b><font color="#f7941d">Compare</font></b> -
              Show the differences between the selected snapshot and
              the current system state. Or compare to another snapshot.</p>

              <p><b><font color="#f7941d">Delete</font></b> -
              Remove the selected snapshot from the disk permanently.</p>

              <p><b><font color="#f7941d">Protect</font></b> -
              Toggle protection on the selected snapshot. System Rollback may
              automatically remove older, unprotected snapshots to reclaim
              disk space.</p>

              <p><b><font color="#f7941d">Edit</font></b> -
              Change the name, description, or protection of the selected
              snapshot.</p>`

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
                        Layout.maximumWidth : mainPage.width / 2

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
                        Item {
                            Layout.fillWidth: true
                        }
                        Controls.Label {
                            text: backend.bulkDataList.length === 0
                              ? 'Avoid big data on root FS. See '
                              + '<a href="https://kfocus.org/wf/big-data.html">'
                              + 'this advice</a>.'
                              : '⚠️ <font color="#f7941d">Big data found on '
                              + 'root.</font> '
                              + '<a href="large-snapshot-warn">Learn to '
                              + 'fix</a><font color=\"#f7941d\">.</font>'
                            enabled: !uiLocked
                            color            : uiLocked
                              ? Kirigami.Theme.disabledTextColor
                              : Kirigami.Theme.textColor
                            linkColor        : uiLocked
                              ? Kirigami.Theme.disabledTextColor
                              : Kirigami.Theme.linkColor
                            onLinkActivated : {
                                if ( link === 'large-snapshot-warn' ) {
                                    backend.enableBulkDataWarning();
                                    bulkDataOverlay.visible = true;
                                } else {
                                    Qt.openUrlExternally(link);
                                }
                            }
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

                        Rectangle {
                            Layout.bottomMargin    :
                              Kirigami.Units.gridUnit * 0.45
                            Layout.preferredWidth  : (mainPage.width / 4)
                              - Kirigami.Units.gridUnit * 0.36
                            Layout.alignment       : Qt.AlignRight
                            Layout.preferredHeight :
                              createSnapshotButton.implicitHeight
                            color                  :
                              Kirigami.Theme.alternateBackgroundColor

                            Controls.Button {
                                id           : createSnapshotButton
                                anchors.fill : parent
                                text         : createSnapshotLabel
                                icon.name    : 'document-new'
                                enabled      : !uiLocked
                                  && !backend.mainSpaceLow
                                  && !backend.bootSpaceLow
                                onClicked    : {
                                    switchViewFn( createSnapshotView );
                                }

                                HoverHandler {
                                    cursorShape: Qt.PointingHandCursor
                                }
                            }

                            Rectangle {
                                width   : createSnapshotButton.width
                                height  : createSnapshotButton.height
                                visible : backend.mainSpaceLow
                                  || backend.bootSpaceLow
                                opacity : 0

                                HoverHandler {
                                    id: createSnapshotDisableHover
                                }

                                Controls.ToolTip {
                                    visible :
                                      createSnapshotDisableHover.hovered
                                    text    :
                                      'Disk space low, cannot create snapshot'
                                }
                            }
                        }

                        Controls.Button {
                            text                  :
                                calculateSnapshotSizesLabel
                            icon.name             : 'disk-quota'
                            Layout.preferredWidth : (mainPage.width / 4)
                              - Kirigami.Units.gridUnit * 0.36
                            Layout.alignment      : Qt.AlignLeft
                            enabled               : !uiLocked

                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }

                            onClicked             :
                                switchViewFn( calculateSnapshotView );
                        }

                        Controls.Button {
                            text                  : optimizeDiskLabel
                            icon.name             : 'clean-up-destructive'
                            Layout.preferredWidth : (mainPage.width / 4)
                              - Kirigami.Units.gridUnit * 0.36
                            Layout.alignment      : Qt.AlignRight
                            enabled               : !uiLocked;
                            onClicked             : {
                                switchViewFn( optimizeDiskView );
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
                        Item {
                            Layout.fillWidth: true
                        }
                        Controls.Button {
                            icon.name : 'view-refresh'
                            text      : 'Refresh All'
                            enabled   : !uiLocked
                            onClicked : {
                                sysRefreshSourceView = refreshSnapshotView;
                                sysRefreshTargetView = snapshotView;
                                switchViewFn( refreshSnapshotView );
                                refreshSystemDataFn( false );
                            }
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
                            text             : 'Unalloc'
                            Layout.alignment : Qt.AlignRight
                            color            : uiLocked
                              ? Kirigami.Theme.disabledTextColor
                              : Kirigami.Theme.textColor
                        }
                        Controls.Label {
                            text  : 'Status'
                            Layout.alignment : Qt.AlignRight
                            color : uiLocked
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
                        Controls.Label {
                            id          : mainPartStatusStr
                            text        : ''
                            font.family : 'courier'
                            Layout.alignment : Qt.AlignRight
                            color : uiLocked
                              ? Kirigami.Theme.disabledTextColor
                              : text === 'Good >15%'
                                ? Kirigami.Theme.positiveTextColor
                                : Kirigami.Theme.negativeTextColor
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
                        Controls.Label {
                            id          : bootPartStatusStr
                            text        : ''
                            font.family : 'courier'
                            Layout.alignment : Qt.AlignRight
                            color       : uiLocked
                              ? Kirigami.Theme.disabledTextColor
                              : text === 'Good >25%'
                                ? Kirigami.Theme.positiveTextColor
                                : Kirigami.Theme.negativeTextColor
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

                Controls.Label {
                    text        : '               Size GiB:  / [/boot]'
                    font.family : 'courier'
                    visible     : backend.snapshotSizeInfoPresent
                    color       : uiLocked
                      ? Kirigami.Theme.disabledTextColor
                      : Kirigami.Theme.textColor
                    anchors {
                        left         : parent.left
                        bottom       : snapshotListView.top
                        bottomMargin : Kirigami.Units.gridUnit * 0.20
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
                    width      : Kirigami.Units.gridUnit * 16
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
                        interactive : !uiLocked

                        Rectangle {
                            anchors.fill : snapshotBar
                            color        : '#000000'
                            opacity      : 0
                            visible      : uiLocked

                            MouseArea {
                                anchors.fill : parent
                            }

                            HoverHandler {}
                        }
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
                    width   : Kirigami.Units.gridUnit * 16
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
                    dayofweek   : snapshotModel.get(
                      snapshotBar.currentIndex).dayofweek
                    mainSize    : snapshotModel.get(
                      snapshotBar.currentIndex).mainSize
                    bootSize    : snapshotModel.get(
                      snapshotBar.currentIndex).bootSize
                    name        : snapshotModel.get(
                      snapshotBar.currentIndex).name
                    reason      : snapshotModel.get(
                      snapshotBar.currentIndex).reason
                    pinned      : snapshotModel.get(
                      snapshotBar.currentIndex).pinned
                    description : snapshotModel.get(
                      snapshotBar.currentIndex).description
                    diskLow     : backend.mainSpaceLow || backend.bootSpaceLow
                    visible     : false

                    onDeleteClicked  : {
                        prepDeleteSnapshotFn( snapshotBar.currentIndex );
                    }
                    onRestoreClicked : {
                        prepRestoreSnapshotFn( snapshotBar.currentIndex );
                    }
                    onCompareClicked : {
                        switchViewFn( compareSnapshotView );
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
                          + 'above.</p><br>';
                        if ( automaticSnapshotsSwitch.checked ) {
                          outputStr
                            += '<p>' + automaticSnapshotsLabel + ' are '
                            + 'enabled. The system will take snapshots '
                            + 'without intervention before system '
                            + '(<code>APT</code>) software changes, or at '
                            + 'least once per week.<p>'

                            + '<p><i>This option provides more frequent '
                            + 'snapshots, but requires additional oversight '
                            + 'to avoid filling the root (/) or boot (/boot) '
                            + 'filesystems.</i></p>';
                        }
                        else {
                          outputStr
                            += '<p>' + automaticSnapshotsLabel + ' are '
                            + 'disabled. The system will only take '
                            + 'snapshots on your command.</p>';
                        }
                        return outputStr;
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
                        switchViewFn( snapshotView );
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
                        switchViewFn( snapshotView );
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
                    id               : optimizeDiskView
                    visible          : false
                    infoText         :
                        '<p>System Rollback is now ready to '
                      + 'clean up the boot disk.</p>'
                      + '<br>'
                      + '<p><b>Quick Clean</b> frees up '
                      + 'unallocated space in a few seconds. Existing '
                      + 'snapshots are retained.</p>'
                      + '<br>'
                      + '<p><b>Deep Clean</b> frees up as much space as possible. This '
                      + 'typically takes 30-60 seconds. '
                      + '<b><font color="#da4453">WARNING: This will delete '
                      + 'ALL snapshots, including ALL PINNED SNAPSHOTS. This '
                      + 'cannot be undone.</font></b></p>'

                    acceptText       : 'Quick Clean'
                    acceptIcon       : 'edit-clear-all'
                    accept2Text      : 'Deep Clean'
                    accept2Icon      : 'clean-up-destructive'
                    isOk2Destructive : true
                    ok2Visible       : true

                    onOkAction    : balanceDiskFn()
                    onOk2Action   : optimizeDiskFn()
                    onCancelled   : {
                        switchViewFn( snapshotView );
                    }
                }

                WaitScreenItem {
                    id          : balanceDiskWaitView
                    visible     : false
                    headerText  : 'Quick Cleaning System Disk...'
                }

                WaitScreenItem {
                    id          : optimizeDiskWaitView
                    visible     : false
                    headerText  : 'Deep Cleaning System Disk...'
                    description : 'This may take several minutes. '
                      + 'You may continue to use your system while '
                      + 'this is processing. However, to avoid file corruption, '
                      + '<b><font color="#da4453">DO NOT turn off '
                      + 'or reboot the system until this is finished!</font></b>'
                }

                ConfirmScreenItem {
                    id               : calculateSnapshotView
                    visible          : false
                    infoText         : '<p>System Rollback is now ready to '
                      + 'calculate snapshot sizes.</p>'
                      + '<br>'
                      + '<p>This calculation usually requires 10-20 seconds '
                      + 'per snapshot. Therefore, if you have six snapshots, '
                      + 'this calculation may require 60-120 seconds to '
                      + 'finish.</p>'

                    acceptText       : 'Calculate'
                    acceptIcon       : 'disk-quota'

                    onOkAction    : calculateSnapshotSizesFn();
                    onCancelled   : {
                        switchViewFn( snapshotView );
                    }
                }

                WaitScreenItem {
                    id          : calculateSnapshotWaitView
                    visible     : false
                    headerText  : 'Calculating snapshot sizes...'
                    description : 'This calculation usually requires '
                      + '10-20 seconds per snapshot. Therefore, if you have '
                      + 'six snapshots, the calculation may require 60-120 '
                      + 'seconds to finish.'
                }

                WaitScreenItem {
                    id          : automaticSnapshotSwitchView
                    visible     : false
                    headerText  : 'Toggling ' + automaticSnapshotsLabel + '...'
                }

                ErrorScreenItem {
                    id          : automaticSnapshotSwitchFailedView
                    visible     : false
                    infoText    : '<p>System Rollback failed to toggle '
                      + 'autonatic snapshotting. Please close and restart '
                      + 'this tool and try again. If this issue persists, '
                      + 'please contact your system administrator.</p>'
                    onOkClicked : {
                        switchViewFn( snapshotView );
                    }
                }

                WaitScreenItem {
                    id         : refreshSnapshotView
                    visible    : false
                    headerText : 'Refreshing snapshot info...'
                }

                ConfirmSnapshotActionItem {
                    id              : deleteSnapshotView
                    visible         : false
                    startInfoText   : '<p>System Rollback is ready to delete '
                      + 'the following snapshot:</p>'
                    endInfoText     : '<br><p><b><font color="#da4453">'
                      + 'WARNING: Deleting a snapshot cannot be undone!'
                      + '</font></b></p>'
                    acceptText      : 'Delete'
                    acceptIcon      : 'edit-delete-remove'
                    isOkDestructive : true

                    onOkAction    : {
                        deleteSnapshotFn( snapshotBar.currentIndex );
                    }
                    onCancelled   : {
                        switchViewFn( snapshotView );
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
                        switchViewFn( snapshotView );
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
                    isOkDestructive : true

                    onOkAction    : {
                        restoreSnapshotFn( snapshotBar.currentIndex );
                    }
                    onCancelled   : {
                        switchViewFn( snapshotView );
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
                        switchViewFn( snapshotView );
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
                        switchViewFn( snapshotView );
                    }
                }

                WaitScreenItem {
                    id          : compareSnapshotWaitView
                    visible     : false
                    headerText  : 'Comparing snapshots...'
                    description : 'All data in the selected system states '
                      + 'is being compared. This may take five minutes or '
                      + 'more.'
                }

                WaitScreenItem {
                    id         : saveEditsWaitView
                    visible    : false
                    headerText : 'Saving edits...'
                }

                ErrorScreenItem {
                    id          : saveEditsFailedView
                    visible     : false
                    infoText    : '<p>System Rollback failed to save your '
                      + 'changes to this snapshot. The snapshot may have '
                      + 'been removed by automatic snapshot maintenance, or '
                      + 'you may have failed to enter your password when '
                      + 'prompted.</p>'
                    onOkClicked : {
                        switchViewFn( snapshotView );
                    }
                }

                ErrorScreenItem {
                    id          : authFailedView
                    visible     : false
                    infoText    : '<p>' + authAttemptAction + ' was cancelled because valid authorization was not provided.</p>'
                    onOkClicked : {
                        resetUiStateFn()
                        switchViewFn( snapshotView );
                    }
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

        OverlayAlertItem {
            id: lowBootOverlay
            isVisible: false
            mainIcon: 'dialog-error'
            headerText: 'Low Boot Space Warning'
            mainText: 'This system needs more boot space. You '
              + 'should run the Kernel Cleaner utility by clicking Start '
              + 'Menu > Kubuntu Focus Tools > Kernel Cleaner. This will '
              + 'delete unused kernel and purge ALL snapshots on the system.'
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
                lowBootOverlay.visible = false;
            }
            onSecondaryButtonClicked: {
                lowBootOverlay.visible = false;
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

        OverlayAlertItem {
            id: bulkDataOverlay
            isVisible: ((backend.bulkDataList.length !== 0)
              && (backend.bulkDataWarningEnabled))
            mainIcon: 'dialog-warning'
            headerText: 'Big Data Found on Root FS'
            mainText: 'You have big data on the following locations of the '
              + 'root filesystem:<br><ul>'
              + genBulkDataListStrFn( backend.bulkDataList )
              + '</ul><br>'
              + 'This data will be included in snapshots. If left as-is, '
              + 'big data apps, such as databases or containers, may cause '
              + 'snapshots to rapidly grow in size during routine operation '
              + 'and maintenance.<br>'
              + '<br>'
              + 'We strongly recommend you move this data to a mount point '
              + 'that is not included in snapshots, such as /home. See '
              + '<a href="https://kfocus.org/wf/big-data.html">'
              + 'this advice</a> for guidance.'
            primaryButtonText: 'Continue'
            primaryButtonIcon: 'go-next-symbolic'
            secondaryButtonText: 'Don\'t Show Again'
            secondaryButtonIcon: 'go-next-skip'
            showSecondaryButton: true

            onPrimaryButtonClicked: {
                bulkDataOverlay.visible = false;
            }
            onSecondaryButtonClicked: {
                backend.disableBulkDataWarning();
                bulkDataOverlay.visible = false;
            }
        }
    }
    // == . END Views =================================================

    // == BEGIN Controllers ===========================================
    ShellEngine {
        id          : createSnapshotEngine
        onAppExited : {
            if ( exitCode === 127 ) {
                switchViewFn( authFailedView );
                return;
            }
            sysRefreshSourceView = createSnapshotWaitView;
            if ( exitCode === 0 ) {
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
        id          : balanceDiskEngine
        onAppExited : {
            if ( exitCode === 127 ) {
                switchViewFn( authFailedView );
                return;
            }
            sysRefreshSourceView = balanceDiskWaitView;
            if ( exitCode === 0 ) {
                sysRefreshTargetView = snapshotView;
            } else {
                sysRefreshTargetView = criticalErrorView;
            }
            refreshSystemDataFn( false );
        }
    }

    ShellEngine {
        id          : optimizeDiskEngine
        onAppExited : {
            if ( exitCode === 127 ) {
                switchViewFn( authFailedView );
                return;
            }
            sysRefreshSourceView = optimizeDiskWaitView;
            if ( exitCode === 0 ) {
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
            if ( exitCode === 127 ) {
                switchViewFn( authFailedView );
                automaticSnapshotsSwitch.checked = Qt.binding(function() {
                    return backend.automaticSnapshotsEnabled;
                });
                return;
            }
            sysRefreshSourceView = automaticSnapshotSwitchView;
            if ( exitCode === 0 ) {
                sysRefreshTargetView = snapshotView;
            } else {
                sysRefreshTargetView = automaticSnapshotSwitchFailedView;
            }
            refreshSystemDataFn( false );
        }
    }

    ShellEngine {
        id          : deleteSnapshotEngine
        onAppExited : {
            if ( exitCode === 127 ) {
                switchViewFn( authFailedView );
                return;
            }
            sysRefreshSourceView = deleteSnapshotWaitView;
            if ( exitCode === 0 ) {
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
                switchViewFn( authFailedView );
            } else if ( exitCode === 1 ) {
                switchViewFn( restoreSnapshotErrorView );
            } else {
                switchViewFn( criticalErrorView );
            }
            backend.inhibitClose = false;
            restoreSnapshotView.actionsEnabled = true;
        }
    }

    ShellEngine {
        id          : compareSnapshotsEngine
        onAppExited : {
            if ( exitCode === 127 ) {
                switchViewFn( authFailedView );
                return;
            }
            let snapInfo = snapshotModel.get(snapshotBar.currentIndex);
            let dupSnapInfo
              = derivSnapshotModel.get(compareSnapshotView.compareIndex);
            compareSourceIdStr = snapInfo.date + ' - ' + snapInfo.name;
            compareTargetIdStr = dupSnapInfo.date + ' - ' + dupSnapInfo.name;
            compareResultStr   = stdout;
            showWindowFn( snapshotCompareWindowComponent );
            switchViewFn( snapshotView );
        }
    }

    ShellEngine {
        id: saveEditsEngine
        onAppExited: {
            if ( exitCode === 127 ) {
                switchViewFn( authFailedView );
                restoreSnapshotViewBindingsFn();
                return;
            }
            if ( exitCode === 0 ) {
                snapshotModel.get(snapshotBar.currentIndex).name
                  = snapshotView.name;
                snapshotModel.get(snapshotBar.currentIndex).description
                  = snapshotView.description;
                snapshotModel.get(snapshotBar.currentIndex).pinned
                  = snapshotView.pinned;
                backend.inhibitClose = false;
                // Ensure that "Compare" is properly updated in the event pinning was changed
                derivateSnapshotModelFn();
                resetUiStateFn();
                restoreSnapshotViewBindingsFn();
                switchViewFn( snapshotView );
            } else {
                sysRefreshSourceView = saveEditsWaitView;
                sysRefreshTargetView = saveEditsFailedView;
                resetUiStateFn();
                restoreSnapshotViewBindingsFn();
                refreshSystemDataFn( false );
            }
        }
    }

    function genSnapshotSizeStrFn( mainSize, bootSize ) {
        if ( mainSize === '' || bootSize === '' ) {
            return '';
        }
        let outStr = mainSize + ' [' + bootSize + ']';
        let lenPad = 10 - outStr.length;
        for (let i = 0; i < lenPad; i++) {
           outStr = ' ' + outStr;
        }
        return outStr;
    }

    function genBulkDataListStrFn( bulkDataList ) {
        let solve_str = '';
        for ( let i = 0; i < bulkDataList.length; i++ ) {
            solve_str += '<li>' + bulkDataList[i] + '</li>';
        }
        return solve_str;
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

    function switchViewFn( target_view ) {
        // Preamble
        // Lock the peripheral UI elements for almost all views
        uiLocked = true;
        // Remove the contextual help button for almost all views
        mainAreaHelpButton.visible = false;

        // See if we can switch to a routine that uses the last view
        // instead of requiring hard-coded, prior knowledge of the view
        // that is going to be replaced, which is very fragile.
        console.log( 'DEBUG: Switching views ...');
        if ( ! lastSetView ) { lastSetView = target_view; }

        // Handlers for current view
        if ( lastSetView === snapshotView ) {
            if ( snapshotBar.count === 0 ) {
                lastSetView = noSnapshotsView;
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
        } else if ( target_view === refreshSnapshotView ) {
            mainAreaLabel.text = refreshSnapshotLabel;
        } else if ( target_view === deleteSnapshotView ) {
            mainAreaLabel.text = deleteSnapshotLabel;
        } else if ( target_view === restoreSnapshotView ) {
            mainAreaLabel.text = restoreSnapshotLabel;
        } else if ( target_view === compareSnapshotView ) {
            mainAreaLabel.text = compareSnapshotLabel;
        } else if ( target_view === deleteSnapshotErrorView ) {
            mainAreaLabel.text = deleteSnapshotErrorLabel;
        } else if ( target_view === restoreSnapshotErrorView ) {
            mainAreaLabel.text = restoreSnapshotErrorLabel;
        } else if ( target_view === calculateSnapshotView ) {
            mainAreaLabel.text = calculateSnapshotSizesLabel;
        }

        // Switch view
        lastSetView.visible = false;
        target_view.visible = true;
        lastSetView = target_view;
    }

    function createSnapshotFn() {
        backend.inhibitClose = true;
        authAttemptAction = '"Take Snapshot"';
        switchViewFn( createSnapshotWaitView );
        createSnapshotEngine.exec(
          rollbackStr + 'systemSnapshot "$(id -nu)"'
        );
    }

    function balanceDiskFn() {
        backend.inhibitClose = true;
        authAttemptAction = '"Quick Clean"';
        switchViewFn( balanceDiskWaitView );
        balanceDiskEngine.exec( rollbackStr + 'btrfsMaintain' );
    }

    function optimizeDiskFn() {
        backend.inhibitClose = true;
        authAttemptAction = '"Deep Clean"';
        switchViewFn( optimizeDiskWaitView );
        optimizeDiskEngine.exec( rollbackDeepCleanStr );
    }

    function switchAutomaticSnapshotsFn() {
        backend.inhibitClose = true;
        authAttemptAction = '"Toggle ' + automaticSnapshotsLabel + '"';
        switchViewFn( automaticSnapshotSwitchView );
        automaticSnapshotToggleEngine.exec(
          rollbackStr + 'setManualSwitchState '
            + (automaticSnapshotsSwitch.checked
              ? 'auto'
              : 'manual')
        );
    }

    function calculateSnapshotSizesFn() {
        authAttemptAction = '"Calculate Snapshot Sizes"';
        switchViewFn( calculateSnapshotWaitView );
        sysRefreshSourceView = calculateSnapshotWaitView;
        sysRefreshTargetView = snapshotView;
        refreshSystemDataFn( true );
    }

    function prepDeleteSnapshotFn( snapshot_idx ) {
        deleteSnapshotView.reason      = snapshotModel.get(snapshot_idx).reason;
        deleteSnapshotView.date        = snapshotModel.get(snapshot_idx).date;
        deleteSnapshotView.name        = snapshotModel.get(snapshot_idx).name;
        deleteSnapshotErrorView.date   = snapshotModel.get(snapshot_idx).date;
        deleteSnapshotErrorView.name   = snapshotModel.get(snapshot_idx).name;
        deleteSnapshotErrorView.reason = snapshotModel.get(snapshot_idx).reason;
        switchViewFn( deleteSnapshotView );
    }

    function deleteSnapshotFn( snapshot_idx ) {
        backend.inhibitClose = true;
        authAttemptAction = '"Delete Snapshot"';
        switchViewFn( deleteSnapshotWaitView );
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
        switchViewFn( restoreSnapshotView );
    }

    function restoreSnapshotFn( snapshot_idx ) {
        backend.inhibitClose = true;
        authAttemptAction = '"Restore Snapshot"';
        switchViewFn( restoreSnapshotWaitView );
        restoreSnapshotEngine.exec(
          rollbackStr
            + 'restoreSnapshot '
            + snapshotModel.get(snapshot_idx).id
        );
    }

    function compareSnapshotsFn( source_idx, target_idx ) {
        authAttemptAction = '"Compare Snapshots"';
        compareSnapshotsEngine.exec(
          rollbackStr + "compareState '"
            + snapshotModel.get(source_idx).stateDir
            + "' '"
            + derivSnapshotModel.get(target_idx).stateDir
            + "'"
        );
        if (compareSnapshotView.visible) {
            switchViewFn( compareSnapshotWaitView );
        } else {
            switchViewFn( compareSnapshotWaitView );
        }
    }

    function saveSnapshotEditsFn( snapshot_idx ) {
        backend.inhibitClose = true;
        authAttemptAction = '"Save Changes"';
        switchViewFn( saveEditsWaitView );
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

    function refreshSystemDataFn( do_calc_size ) {
        backend.refreshSystemData( do_calc_size );
    }

    function populateSnapshotModelFn() {
        snapshotModel.clear();
        for ( let i = 0; i < backend.getSnapshotCount(); i++ ) {
            snapshotModel.append({
                date        : backend.getSnapshotInfo(i, 'date'),
                dayofweek   : backend.getSnapshotInfo(i, 'dayofweek'),
                name        : backend.getSnapshotInfo(i, 'name'),
                description : backend.getSnapshotInfo(i, 'description'),
                reason      : backend.getSnapshotInfo(i, 'reason'),
                pinned      : backend.getSnapshotInfo(i, 'pinned') === 'true'
                  ? true
                  : false,
                mainSize    : backend.getSnapshotInfo(i, 'mainSize'),
                bootSize    : backend.getSnapshotInfo(i, 'bootSize'),
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
        let dateStr      = currentDate.toISOString().split('T')[0];
        dateStr         += ' ' + currentDate.toISOString().split('T')[1].split('-')[0].slice(0, 5)
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

    function resetUiStateFn() {
        calculateSnapshotView.actionsEnabled = true;
        createSnapshotView.actionsEnabled    = true;
        deleteSnapshotView.actionsEnabled    = true;
        optimizeDiskView.actionsEnabled      = true;
        snapshotView.editing = false;
        snapshotView.saving  = false;
        backend.inhibitClose = false;
    }

    // Kick-off rendering on completion
    Component.onCompleted: {
        mainAreaLabel.text = getSnapshotViewHeaderFn();
        refreshSystemDataFn( false );
    }
    // == . END Controllers ===========================================
}

// vim: set syntax=javascript:
import QtQuick 2.15
import QtQuick.Controls 2.0 as Controls
import QtQuick.Layouts 1.2
import QtQuick.Window 2.2
import org.kde.kirigami 2.15 as Kirigami
import shellengine 1.1
import startupdata 1.0

Kirigami.ApplicationWindow {
    id: root
    title: 'Kubuntu Focus Welcome Wizard'

    // == BEGIN Models ================================================
    // Set Global Properties
    property string actionName                  : ''
    property string networkReturnPage           : ''
    property string networkReturnAction         : ''
    property string networkDisconnectTitleImage : ''
    property int disabledSidebarIndex           : 0
    property bool firstRun                      : true
    property var interImageList                 : []
    property var defaultCryptList               : []
    property string cryptChangeMode             : ""
    property int cryptDiskChangeCount           : 0
    property string pageTitleText               : ''
    property string pageTitleImage              : ''
    property string imgDir                      : 'assets/images/'
    property var stateMatrix                    : ({})
    property string liveUsbWarnStr              : '<b>This step is '
        + 'not available in a live USB session</b>. Please '
        + 'install to a system disk to run this step.'

    property string ding01Str : '<font size="5">\u2776</font>&nbsp;'
    property string ding02Str : '<font size="5">\u2777</font>&nbsp;'
    property string ding03Str : '<font size="5">\u2778</font>&nbsp;'
    property string ding04Str : '<font size="5">\u2779</font>&nbsp;'
    property string ding05Str : '<font size="5">\u277A</font>&nbsp;'
    property string ding06Str : '<font size="5">\u277B</font>&nbsp;'
    property string ding07Str : '<font size="5">\u277C</font>&nbsp;'

    // Purpose: Describes steps used in wizard
    // See property currentIndex
    // TODO 2024-09-16 cool arainbolt: add CLI argument to list in terminal
    //
    ListModel {
        id: sidebarModel
        ListElement {
            jsId     : 'introductionItem'
            task     : 'Introduction'
            taskIcon : 'user-home-symbolic'
        }
        ListElement {
            jsId     : 'diskPassphraseItem'
            task     : 'Disk Passphrase'
            taskIcon : 'lock'
        }
        ListElement {
            jsId     : 'extraSoftwareItem'
            task     : 'Extra Software'
            taskIcon : 'install'
        }
        ListElement {
            jsId     : 'systemRollbackItem'
            task     : 'System Rollback'
            taskIcon : 'edit-undo-symbolic'
        }
        ListElement {
            jsId     : 'fileBackupItem'
            task     : 'File Backup'
            taskIcon : 'backup'
        }
         ListElement {
             jsId     : 'passwordManagerItem'
             task     : 'Password Manager'
             taskIcon : 'password-copy'
         }
        ListElement {
            jsId     : 'emailCalendarItem'
            task     : 'Email'
            taskIcon : 'gnumeric-link-email'
        }
        ListElement {
            jsId     : 'dropboxItem'
            task     : 'Dropbox'
            taskIcon : 'cloudstatus'
        }
        ListElement {
            jsId     : 'insyncItem'
            task     : 'Insync'
            taskIcon : 'folder-sync'
        }
        ListElement {
            jsId     : 'jetbrainsToolboxItem'
            task     : 'JetBrains Toolbox'
            taskIcon : 'THEMED|jetbrains_toolbox_line'
        }
        ListElement {
            jsId     : 'avatarItem'
            task     : 'Avatar'
            taskIcon : 'user'
        }
        ListElement {
            jsId     : 'curatedAppsItem'
            task     : 'Curated Apps'
            taskIcon : 'THEMED|kfocus_bug_apps_line'
        }
        ListElement {
            jsId     : 'finishItem'
            task     : 'Finish'
            taskIcon : 'emblem-system-symbolic'
        }
    }

    StartupData {
        id: systemDataMap
        // Provided by main.cpp:
        //   binDir, cryptDiskList, homeDir,
        //   isLiveSession, userName, WelcomeCmd, startPage
        //
    }
    // == . END Models ================================================

    // == BEGIN Views =================================================
    // Define page size and columns
    width  : Kirigami.Units.gridUnit * 40
    height : Kirigami.Units.gridUnit * 29
    minimumWidth  : Kirigami.Units.gridUnit * 40
    minimumHeight : Kirigami.Units.gridUnit * 28

    pageStack.defaultColumnWidth : Kirigami.Units.gridUnit * 12

    // BEGIN Define sidebar views
    Kirigami.ScrollablePage {
        id      : enabledSidebarPage
        visible : false // Avoids a graphical glitch, DO NOT SET TO TRUE

        ListView {
            id       : enabledSidebar
            model    : sidebarModel
            delegate : enabledSidebarDelegate
        }
    }

    Kirigami.ScrollablePage {
        id: disabledSidebarPage
        visible: false // Avoids a graphical glitch, DO NOT SET TO TRUE

        ListView {
            id          : disabledSidebar
            model       : sidebarModel
            delegate    : disabledSidebarDelegate
            interactive : false

            Rectangle {
                anchors.fill : disabledSidebar
                color        : '#000000'
                opacity      : 0.3

                MouseArea {
                    anchors.fill : parent
                }

                HoverHandler {}
            }
        }
    }

    Component {
        id: enabledSidebarDelegate
        Kirigami.BasicListItem {
            label     : task
            iconColor : Kirigami.Theme.textColor
            iconSize  : Kirigami.Units.gridUnit * 1.5
            trailing  : Kirigami.Icon {
                source: ''
            }
            onClicked : switchPageFn( jsId )
            Component.onCompleted: {
                var taskIcon_part_list = taskIcon.split( '|' );
                if ( taskIcon_part_list[0] === 'THEMED' ) {
                    this.icon = getThemedImageFn( taskIcon_part_list[1], 'svg' );
                } else {
                    this.icon = taskIcon
                }
            }
        }
    }

    Component {
        id: disabledSidebarDelegate
        Kirigami.BasicListItem {
            label       : task
            icon        : taskIcon
            iconSize    : Kirigami.Units.gridUnit * 1.5
            trailing  : Kirigami.Icon {
                source: ''
            }
            fadeContent : true
            onClicked   : {
                disabledSidebar.currentIndex = disabledSidebarIndex;
            }
            Component.onCompleted: {
                var taskIcon_part_list = taskIcon.split( '|' );
                if ( taskIcon_part_list[0] === 'THEMED' ) {
                    this.icon = getThemedImageFn( taskIcon_part_list[1], 'svg' );
                } else {
                    this.icon = taskIcon
                }
            }
        }
    }
    // . END Define sidebar views

    // Page title renderer
    Component {
        id: titleRenderer

        RowLayout {
            Layout.fillWidth: true

            Kirigami.Heading {
                id   : titleText
                text : pageTitleText
                Layout.leftMargin : Kirigami.Units.gridUnit
                Layout.fillWidth  : true
            }

            Image {
                id     : titleImage
                source : pageTitleImage
                mipmap : true
                Layout.rightMargin: Kirigami.Units.gridUnit
                Layout.alignment       : Qt.AlignRight + Qt.AlignVCenter
                Layout.preferredHeight : Kirigami.Units.gridUnit * 1.4
                Layout.preferredWidth  :
                    ( this.implicitWidth / this.implicitHeight )
                    * (Kirigami.Units.gridUnit * 1.4)
            }
        }
    }

    // Template - Front Page
    Kirigami.Page {
        id: frontTemplatePage
        visible: false // Avoids a graphical glitch, DO NOT SET TO TRUE
        titleDelegate: titleRenderer

        ColumnLayout {
            anchors {
                left  : parent.left
                right : parent.right
                top   : parent.top
            }

            Image {
                id       : frontImage
                fillMode : Image.PreserveAspectFit
                mipmap   : true
                Layout.preferredHeight : Kirigami.Units.gridUnit * 10
                Layout.preferredWidth  : Kirigami.Units.gridUnit * 25
                Layout.bottomMargin    : Kirigami.Units.gridUnit * 1
                Layout.topMargin       : Kirigami.Units.gridUnit * 1
                Layout.alignment       : Qt.AlignHCenter
            }

            Kirigami.Heading {
                id : frontHeading
                horizontalAlignment : Text.AlignHCenter
                Layout.bottomMargin : Kirigami.Units.gridUnit
                Layout.alignment    : Qt.AlignHCenter
            }

            Controls.Label {
                id       : frontText
                wrapMode : Text.WordWrap
                onLinkActivated     : Qt.openUrlExternally(link)
                Layout.fillWidth    : true
                Layout.bottomMargin : Kirigami.Units.gridUnit
            }
        }

        RowLayout {
            anchors {
                right  : parent.right
                bottom : parent.bottom
            }

            Controls.Button {
                id        : frontButton
                text      : 'Continue'
                icon.name : 'arrow-right'
                onClicked : gotoNextPageFn()
            }
        }
    }

    // Template - Normal Page
    Kirigami.Page {
        id: baseTemplatePage
        visible: false // Avoids a graphical glitch, DO NOT SET TO TRUE
        titleDelegate: titleRenderer

        ColumnLayout {
            anchors {
                left  : parent.left
                right : parent.right
                top   : parent.top
            }

            Image {
                id       : topImage
                mipmap   : true
                fillMode : Image.PreserveAspectFit
                Layout.alignment       : Qt.AlignHCenter
                Layout.bottomMargin    : Kirigami.Units.gridUnit * 2
                Layout.preferredHeight : Kirigami.Units.gridUnit * 6
                Layout.preferredWidth  : Kirigami.Units.gridUnit * 20
                Layout.topMargin       : Kirigami.Units.gridUnit * 1
            }

            Controls.BusyIndicator {
                id       : busyIndicator
                running  : true
                Layout.alignment       : Qt.AlignHCenter
                Layout.bottomMargin    : Kirigami.Units.gridUnit * 2
                Layout.preferredHeight : Kirigami.Units.gridUnit * 6
                Layout.preferredWidth  : Kirigami.Units.gridUnit * 6
                Layout.topMargin       : Kirigami.Units.gridUnit * 1
            }

            Kirigami.Heading {
                id : topHeading
                horizontalAlignment : Text.AlignHCenter
                Layout.bottomMargin : Kirigami.Units.gridUnit
                Layout.alignment    : Qt.AlignHCenter
            }

            Controls.Label {
                id       : primaryText
                wrapMode : Text.WordWrap

                onLinkActivated     : Qt.openUrlExternally(link)
                Layout.fillWidth    : true
                Layout.bottomMargin : Kirigami.Units.gridUnit
            }

            Kirigami.InlineMessage {
                id               : pageWarn
                type             : Kirigami.MessageType.Warning
                Layout.fillWidth : true
            }
        }

        RowLayout {
            anchors {
                left   : parent.left
                bottom : parent.bottom
            }

            Controls.Button {
                id        : previousButton
                text      : 'Previous'
                icon.name : 'arrow-left'
                onClicked : gotoPreviousPageFn()
            }

            Controls.Button {
                id        : clearButton
                text      : 'Clear Checkmarks'
                icon.name : 'edit-clear-history'
                onClicked : {
                    const check_map = stateMatrix.check_map;
                    Object.keys( check_map ).forEach(
                        ( key ) => { delete check_map[ key ]; }
                    );
                    populateCheckboxesFn();
                }
            }
        }

        RowLayout {
            anchors {
                right  : parent.right
                bottom : parent.bottom
            }

            Controls.CheckBox {
                id: loginStartCheckbox

                text: 'Run again on Login'
                checkState: Qt.Unchecked
                Layout.rightMargin: Kirigami.Units.gridUnit * 0.5
            }

            Controls.Button {
                id          : actionButton
                palette { button: getThemedColorFn( 'green' ) }
                onClicked   : takeActionFn()
            }

            Controls.Button {
                id        : skipButton
                text      : 'Skip'
                icon.name : 'go-next-skip'
                onClicked : gotoNextPageFn()
            }
        }
    }

    // Template - Interstitial Page
    Kirigami.Page {
        id      : interTemplatePage
        visible : false // Avoids a graphical glitch, DO NOT SET TO TRUE
        titleDelegate: titleRenderer

        Rectangle {
            id : headerHighlightRect

            anchors {
                left  : parent.left
                right : parent.right
                top   : parent.top
            }

            radius : 5
            height : Kirigami.Units.gridUnit * 2
        }

        Kirigami.Heading {
            id : interTopHeading

            anchors {
                left       : headerHighlightRect.left
                right      : headerHighlightRect.right
                top        : headerHighlightRect.top
                bottom     : headerHighlightRect.bottom
                leftMargin : Kirigami.Units.gridUnit * 0.7
            }
        }

        RowLayout {
            anchors {
                top       : headerHighlightRect.bottom
                right     : parent.right
                left      : parent.left
                bottom    : parent.bottom
                topMargin : Kirigami.Units.gridUnit
            }

            Controls.Label {
                id                  : instructionsText
                wrapMode            : Text.WordWrap
                onLinkActivated     : Qt.openUrlExternally(link)
                Layout.fillWidth    : true
                Layout.bottomMargin : Kirigami.Units.gridUnit
                Layout.alignment    : Qt.AlignTop
            }

            ColumnLayout {
                Layout.alignment  : Qt.AlignTop
                Layout.leftMargin : Kirigami.Units.gridUnit * 0.2

                Repeater {
                    id: pictureColumn

                    model: interImageList

                    Image {
                        source   : imgDir + interImageList[index]
                        fillMode : Image.PreserveAspectFit
                        mipmap   : true

                        Layout.alignment       : Qt.AlignHCenter
                        Layout.bottomMargin    : Kirigami.Units.gridUnit * 0.2
                        Layout.preferredWidth  : Kirigami.Units.gridUnit * 10
                        Layout.preferredHeight :
                          ( this.implicitHeight / this.implicitWidth )
                          * (Kirigami.Units.gridUnit * 10)
                    }
                }
            }
        }

        RowLayout {
            anchors {
                right     : parent.right
                bottom    : parent.bottom
            }

            Controls.Button {
                id        : interActionButton
                onClicked : takeActionFn()
            }
            Controls.Button {
                id        : interSkipButton
                icon.name : 'go-next-skip'
                onClicked : gotoNextPageFn()
            }
        }

        Controls.Label {
            id : interContinueLabel

            anchors {
                left   : parent.left
                bottom : parent.bottom
            }
            width : Kirigami.Units.gridUnit * 15

            text  : '<b>Once you are finished,</b> please return here and '
                  + 'click “Continue” to proceed to the next step.'
            wrapMode: Text.WordWrap
        }
    }

    // Template - Encryption Changer Interstitial
    Kirigami.Page {
        id      : cryptTemplatePage
        visible : false // Avoids a graphical glitch, DO NOT SET TO TRUE
        titleDelegate: titleRenderer

        Rectangle {
            id : cryptHighlightRect

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }

            radius : 5
            height : Kirigami.Units.gridUnit * 2
        }

        Kirigami.Heading {
            id : cryptTopHeading
            anchors {
                left       : cryptHighlightRect.left
                right      : cryptHighlightRect.right
                top        : cryptHighlightRect.top
                bottom     : cryptHighlightRect.bottom
                leftMargin : Kirigami.Units.gridUnit * 0.7
            }
        }

        ColumnLayout {
            anchors {
                top       : cryptHighlightRect.bottom
                right     : parent.right
                left      : parent.left
                topMargin : Kirigami.Units.gridUnit
            }

            Kirigami.InlineMessage {
                id               : cryptErrorMessage
                type             : Kirigami.MessageType.Error
                Layout.fillWidth : true
            }

            Controls.Label {
                id                  : cryptInstructionsText
                wrapMode            : Text.WordWrap
                Layout.fillWidth    : true
                Layout.bottomMargin : Kirigami.Units.gridUnit
            }

            GridLayout {
                id      : passphraseChangeForm

                Layout.alignment    : Qt.AlignHCenter
                Layout.bottomMargin : Kirigami.Units.gridUnit

                Controls.Label {
                    id               : oldPassphraseLabel
                    text             : 'Old passphrase'
                    Layout.alignment : Qt.AlignRight
                    Layout.row       : 0
                    Layout.column    : 0
                }

                Controls.TextField {
                    id            : oldPassphraseBox
                    echoMode      : TextInput.Password
                    Layout.row    : 0
                    Layout.column : 1
                }

                Controls.Label {
                    text             : 'New passphrase'
                    Layout.alignment : Qt.AlignRight
                    Layout.row       : 1
                    Layout.column    : 0
                }

                Controls.TextField {
                    id            : newPassphraseBox
                    echoMode      : TextInput.Password
                    Layout.row    : 1
                    Layout.column : 1
                }

                Controls.Label {
                    text             : 'Confirm new passphrase'
                    Layout.alignment : Qt.AlignRight
                    Layout.row       : 2
                    Layout.column    : 0
                }

                Controls.TextField {
                    id            : confirmPassphraseBox
                    echoMode      : TextInput.Password
                    Layout.row    : 2
                    Layout.column : 1
                }

                Controls.Button {
                    id            : passphrasePeekButton
                    icon.name     : 'password-show-off'
                    Layout.row    : 2
                    Layout.column : 2
                    onClicked: {
                        if ( this.icon.name === 'password-show-off' ) {
                            this.icon.name = 'password-show-on';
                            oldPassphraseBox.echoMode
                              = TextInput.Normal;
                            newPassphraseBox.echoMode
                              = TextInput.Normal;
                            confirmPassphraseBox.echoMode
                              = TextInput.Normal;
                        } else {
                            this.icon.name = 'password-show-off';
                            oldPassphraseBox.echoMode
                              = TextInput.Password;
                            newPassphraseBox.echoMode
                              = TextInput.Password;
                            confirmPassphraseBox.echoMode
                              = TextInput.Password;
                        }
                    }
                }
            }

            Controls.Label {
                id               : cryptSecondaryText
                wrapMode         : Text.WordWrap
                onLinkActivated  : Qt.openUrlExternally(link)
                Layout.fillWidth : true
            }
        }

        RowLayout {
            anchors {
                right  : parent.right
                bottom : parent.bottom
            }

            Controls.Button {
                id        : cryptActionButton
                palette   { button: "#ff9900" }
                onClicked : takeActionFn()
            }

            Controls.Button {
                id        : cryptSkipButton
                text      : 'No Thanks'
                icon.name : 'go-next-skip'
                onClicked : gotoNextPageFn()
            }
        }
    }
    // == . END Views =================================================

    // == BEGIN Controllers ===========================================
    function initPageFn ( visible_elements_list ) {
        var all_elements_list = [
            actionButton,        busyIndicator,
            clearButton,
            headerHighlightRect, instructionsText,
            interActionButton,   interContinueLabel,
            interSkipButton,     interTopHeading,
            loginStartCheckbox,  pageWarn,
            previousButton,      primaryText,
            skipButton,          topHeading,
            topImage
        ];
        var i;

        for ( i = 0; i < all_elements_list.length; i++ ) {
          all_elements_list[i].visible = false;
        }

        interImageList = [];
        pageTitleImage = '';
        for ( i = 0;i < visible_elements_list.length;i++ ) {
          visible_elements_list[i].visible = true;
        }
    }

    function getCurrentPageIdFn () {
        return sidebarModel.get(enabledSidebar.currentIndex).jsId;
    }

    function getCryptDiskTextFn (text_type, disk_list) {
        if ( disk_list.length === 1 ) {
            return text_type;
        } else {
            switch(text_type) {
            case 'Disk Passphrase':
                return 'Disk Passphrases';

            case 'one encrypted disk':
                if (disk_list.length === 2) {
                    return 'two encrypted disks';
                } else {
                    return disk_list.length + ' encrypted disks';
                }

            case 'One Encrypted Disk':
                if (disk_list.length === 2) {
                    return 'Two Encrypted Disks';
                } else {
                    return disk_list.length + ' Encrypted Disks';
                }

            case 'One Encrypted Disk Found':
                if (disk_list.length === 2) {
                    return 'Two Encrypted Disks Found';
                } else {
                    return disk_list.length + ' Encrypted Disks Found';
                }

            case 'passphrase':
                return 'passphrases';

            case 'this disk':
                return 'these disks';

            case 'The encrypted disk uses':
                if ( systemDataMap.cryptDiskList.length === 2 ) {
                    return 'Both encrypted disks use';
                } else {
                    return 'All encrypted disks use';
                }

            case 'One disk is':
                if (disk_list.length === 2) {
                    return 'Two disks are';
                } else {
                    return disk_list.length + ' disks are';
                }

            case 'it':
                return 'them';

            case 'Disk Encryption Passphrase Appears':
                return 'Disk Encryption Passphrases Appear';

            case 'disk\'s passphrase':
                return 'disk passphrases';

            case 'Check Disk Passphrase Now':
                return 'Check Disk Passphrases Now';
            }
        }
    }

    function getCryptDiskChangeTextFn () {
        switch ( cryptDiskChangeCount ) {
        case 0:
            return '';
        case 1:
            return 'One disk had its passphrase changed.';
        case 2:
            return 'Two disks had their passphrase changed.';
        default:
            return cryptDiskChangeCount
                     + ' disks had their passphrase changed.';
        }
    }

    function getThemedImageFn (icon_name, file_type) {
        if ( Kirigami.Theme.textColor.hsvValue < 0.5 ) {
            return 'qrc:/assets/images/' + icon_name + '_light.' + file_type;
        } else {
            return 'qrc:/assets/images/' + icon_name + '_dark.' + file_type;
        }
    }

    function getThemedColorFn (color_name) {
        if ( Kirigami.Theme.textColor.hsvValue > 0.5 ) {
            return color_name;
        } else {
            switch( color_name ) {
            case 'green':
                return 'lightgreen';
            }
         }
    }

    function setCheckMarkFn () {
        const current_page_id = getCurrentPageIdFn();
        const check_map = stateMatrix.check_map;
        check_map[current_page_id] = Date.now();
        enabledSidebar.currentItem.trailing.source = 'checkbox';
        disabledSidebar.currentIndex = enabledSidebar.currentIndex;
        disabledSidebar.currentItem.trailing.source = 'checkbox';
    }

    function gotoNextPageFn () {
        // Trigger the checkbox for the current page if applicable
        setCheckMarkFn();

        // Advance to next page
        enabledSidebar.currentIndex++;
        switchPageFn(getCurrentPageIdFn());
    }

    function gotoPreviousPageFn () {
        enabledSidebar.currentIndex--;
        switchPageFn(getCurrentPageIdFn());
    }


    function populateCheckboxesFn () {
        const check_map = stateMatrix.check_map;
        for ( var i = 0; i < sidebarModel.count; i++ ) {
            var js_id = sidebarModel.get( i ).jsId;
            for ( let target_obj of [ enabledSidebar, disabledSidebar ] ) {
                var item_obj = target_obj.itemAtIndex(i);
                if ( item_obj && typeof item_obj.trailing === 'object' ) {
                    item_obj.trailing.source = ( check_map[ js_id ] > 0 )
                      ? 'checkbox' : '';
                }
            }
        }
    }

    function regenUiFn ( current_page, sidebar_enabled ) {
        if ( sidebar_enabled ) {
            pageStack.push(enabledSidebarPage);
        } else {
            disabledSidebar.currentIndex = enabledSidebar.currentIndex;
            disabledSidebarIndex = disabledSidebar.currentIndex;
            pageStack.push(disabledSidebarPage);
        }
        pageStack.push(current_page);
    }

    function removeSidebarItemFn ( js_id ) {
        for ( var i = 0; i < sidebarModel.count; i++ ) {
            if ( sidebarModel.get(i).jsId === js_id ) {
                sidebarModel.remove(i);
                break;
            }
        }
    }

    function findSidebarItemFn ( js_id ) {
        for ( var i = 0; i < sidebarModel.count; i++ ) {
            if ( sidebarModel.get(i).jsId === js_id ) {
                return i;
            }
        }
        return -1;
    }

    function setLiveUsbFieldsFn () {
        if ( systemDataMap.isLiveSession ) {
            pageWarn.text        = liveUsbWarnStr;
            pageWarn.visible     = true;
            actionButton.visible = false;
        }
    }

    function switchPageFn ( page_id ) {
        pageStack.clear();

        switch ( page_id ) {
        case 'introductionItem':
            pageTitleText     = 'Introduction';
            frontImage.source = getThemedImageFn( 'frontpage', 'webp' );
            frontHeading.text = 'Welcome To The Kubuntu Focus!';
            frontText.text
              = '<p><b>This Welcome Wizard helps you get '
              + 'started as quickly as possible</b>. We have included '
              + 'many tools we feel most developers should '
              + 'consider.<br></p>'

              + '<p><b>This is not an endorsement of any product,</b> and '
              + 'the Focus Team is not compensated in any way for '
              + 'these suggestions. You may always run this wizard '
              + 'later using Start Menu &gt; Kubuntu Focus Tools &gt; '
              + 'Welcome Wizard or visit '
              + 'the <a href="https://kfocus.org/wf/tools#wizard">'
              + 'documentation.</a></p>'
              ;
            actionName        = 'nextPage';
            regenUiFn( frontTemplatePage, true );
            break;

        case 'internetCheckItem':
            initPageFn([topHeading, busyIndicator]);

            topHeading.text = 'Checking for Internet connectivity...';
            regenUiFn( baseTemplatePage, false );
            break;

        case 'connectInternetItem':
            initPageFn([
              headerHighlightRect, interTopHeading,
              instructionsText,    interSkipButton,
              interActionButton,   pictureColumn
            ]);

            pageTitleImage            = networkDisconnectTitleImage;
            headerHighlightRect.color = '#ff9900';
            interTopHeading.text      = 'Please Connect to the Internet';
            instructionsText.text
              = '<p><b>The system is not currently '
              + 'connected to the Internet</b>. Please connect to '
              + 'complete this step.<br></p>'

              + '<p>' + ding01Str
              + '<b>If you have a wired connection</b>, you should see a '
              + '“network button” like this. Check the network cable and '
              + 'reseat the connections on both ends. Then proceed to step '
              + '3.<br></p>'

              + '<p>' + ding02Str
              + '<b>If you have a WiFi adaptor</b>, you should see a “network '
              + 'button” like this in the system tray.<br></p>'

              + '<p>' + ding03Str
              + '<b>Click the “network button”</b> to see a list of '
              + 'connections. Then click on connect and enter your'
              + 'password if required.<br></p>'

              + '<p><b>If you cannot connect, click “No Thanks”</b> to '
              + 'proceed to the next step.</p>'
              ;
            interImageList = [
              'network_disconnect.svg',
              'network_button_pointer.svg',
              'network_connect_dialog.webp'
            ];
            interActionButton.text      = 'Continue';
            interActionButton.icon.name = 'arrow-right';
            interSkipButton.text        = 'No Thanks';
            regenUiFn( interTemplatePage, false );
            actionName = 'checkNetwork';
            break;

        case 'diskPassphraseItem':
            initPageFn([
              topImage,    topHeading,
              primaryText, actionButton,
              skipButton,  previousButton
            ]);

            pageTitleText   = getCryptDiskTextFn( 'Disk Passphrase',
                                systemDataMap.cryptDiskList );
            topImage.source = imgDir + 'encrypted_drive.svg';
            topHeading.text = getCryptDiskTextFn( 'One Encrypted Disk Found',
                                systemDataMap.cryptDiskList );
            primaryText.text
              = '<p><b>The wizard has detected '
              + getCryptDiskTextFn('one encrypted disk',
                  systemDataMap.cryptDiskList)
              + '</b> on this system. If you bought a system with disk '
              + 'encryption enabled and you have yet to change the '
              + getCryptDiskTextFn('passphrase',
                  systemDataMap.cryptDiskList)
              + ', you should do so now. Otherwise, you can skip this '
              + 'step.<br></p>'

              + '<p><b>You may check '
              + getCryptDiskTextFn('this disk',
                  systemDataMap.cryptDiskList)
              + ' for the default passphrase now</b>. As a security '
              + 'measure, this app will not perform this check until '
              + 'you enter your valid user password.</p>'
              ;
            actionButton.text      = getCryptDiskTextFn(
                                       'Check Disk Passphrase Now',
                                       systemDataMap.cryptDiskList );
            actionButton.icon.name = 'lock';
            actionName             = 'checkCrypt';

            setLiveUsbFieldsFn();
            regenUiFn( baseTemplatePage, true );
            break;

        case 'diskPassphraseCheckerItem':
            initPageFn([topHeading, busyIndicator, primaryText]);

            pageTitleText   = getCryptDiskTextFn(
              'Disk Passphrase', systemDataMap.cryptDiskList
            );
            pageTitleImage  = imgDir + 'encrypted_drive.svg';
            topHeading.text = 'Checking Disk Passphrases...';
            primaryText.text
              = '<p><b>You will be prompted</b> to enter your password. Once '
              + 'the check is complete, you will be directed on the '
              + 'recommended course of action.</p>'
              ;
            regenUiFn( baseTemplatePage, false );
            break;

        case 'pkexecDeclineCryptCheckItem':
            initPageFn([
              headerHighlightRect, interTopHeading,
              instructionsText,    pictureColumn,
              interActionButton,   interSkipButton
            ]);

            pageTitleText = getCryptDiskTextFn('Disk Passphrase',
                              systemDataMap.cryptDiskList);
            pageTitleImage = imgDir + 'encrypted_drive.svg';
            headerHighlightRect.color = '#ff9900';
            interTopHeading.text
              = 'Authorization Has Failed';
            instructionsText.text
              = '<p><b>Sorry, authorization is required to check disk '
              + 'passphrases for security</b>. If you would like to check '
              + 'your '
              + getCryptDiskTextFn( 'disk\'s passphrase',
                  systemDataMap.cryptDiskList)
              + ' for security, click “Try Again.”.</p>'
              ;
            interActionButton.text      = 'Try Again';
            interActionButton.icon.name = 'arrow-right';
            interSkipButton.text        = 'No Thanks';
            interImageList = [ 'locked.svg' ];
            actionName = 'checkCrypt';
            regenUiFn( interTemplatePage, false );
            break;

        case 'diskPassphraseChangeItem':
            oldPassphraseLabel.visible    = false;
            oldPassphraseBox.visible      = false;
            cryptErrorMessage.visible     = false;
            newPassphraseBox.echoMode     = TextInput.Password;
            confirmPassphraseBox.echoMode = TextInput.Password;

            pageTitleText             = getCryptDiskTextFn( 'Disk Passphrase',
                                          systemDataMap.cryptDiskList );
            pageTitleImage            = imgDir + 'encrypted_drive.svg';
            newPassphraseBox.text     = '';
            confirmPassphraseBox.text = '';
            cryptHighlightRect.color  = '#ff9900';
            cryptTopHeading.text
              = 'Change Passphrase for '
              + getCryptDiskTextFn('One Encrypted Disk',
                  defaultCryptList);
            cryptInstructionsText.text
              = '<p><b>'
              + getCryptDiskTextFn('One disk is',
                  defaultCryptList)
              + ' using the default passphrase</b>. This is insecure, '
              + 'and we recommend you use the form below to change it '
              + 'to a unique passphrase. <b>IMPORTANT:</b> All disks using '
              + 'the default passphrase will be changed to use the new '
              + 'passphrase.</p>'
              ;
            cryptSecondaryText.text
              = '<p><b>Please keep a copy of '
              + 'your passphrase in a safe place</b>. If this is lost, '
              + 'there is no recovery except to reformat your disks '
              + 'and restore from backup.<br></p>'

              + '<p><b>For your security, the Kubuntu Focus Team does NOT '
              + 'install tools that could assist in any recovery</b>. '
              + 'In other words, if you lose your passphrase, they have no '
              + 'way to help you recover it!</p>'
              ;
            cryptActionButton.text      = 'Change Now';
            cryptActionButton.icon.name = 'arrow-right';
            actionName                  = 'changeCrypt';
            regenUiFn( cryptTemplatePage, false );
            break;

        case 'diskPassphraseChangeInProgressItem':
            initPageFn([topHeading, busyIndicator]);

            pageTitleText   = getCryptDiskTextFn('Disk Passphrase',
                                systemDataMap.cryptDiskList);
            pageTitleImage  = imgDir + 'encrypted_drive.svg';
            topHeading.text
              = 'Changing Disk Passphrases...\n'
            regenUiFn( baseTemplatePage, false );
            break;

        case 'pkexecDeclineCryptChangeItem':
            initPageFn([
              headerHighlightRect, interTopHeading,
              instructionsText,    pictureColumn,
              interActionButton,   interSkipButton
            ]);

            pageTitleText             = getCryptDiskTextFn('Disk Passphrase',
                                          systemDataMap.cryptDiskList);
            pageTitleImage            = imgDir + 'encrypted_drive.svg';
            headerHighlightRect.color = '#ff9900';
            interTopHeading.text
              = 'Authorization Has Failed';
            instructionsText.text
              = '<p><b>Sorry, authorization is required to change disk '
              + 'passphrases</b>. If you would like to change '
              + 'your '
              + getCryptDiskTextFn( 'disk\'s passphrase',
                  systemDataMap.cryptDiskList )
              + ', click “Try Again.”</p>';
              ;
            interActionButton.text      = 'Try Again';
            interActionButton.icon.name = 'arrow-right';
            interSkipButton.text        = 'No Thanks';
            interImageList              = [ 'locked.svg' ];
            actionName                  = 'retryCrypt';
            regenUiFn( interTemplatePage, false );
            break;

        case 'diskPassphraseChangeFailedItem':
            initPageFn([
              headerHighlightRect, interTopHeading,
              instructionsText,    pictureColumn,
              interActionButton,   interSkipButton
            ]);

            pageTitleText = getCryptDiskTextFn('Disk Passphrase',
                              systemDataMap.cryptDiskList);
            pageTitleImage = imgDir + 'encrypted_drive.svg';
            headerHighlightRect.color = '#ff9900';
            interTopHeading.text
              = 'Disk Passphrase Changing Failed';

            instructionsText.text
              = '<p><b>No disks had their passphrase changed</b>. You may have '
              + 'mistyped your old passphrase.<br></p>'

              + '<p>If you would like to change your '
              + getCryptDiskTextFn( 'disk\'s passphrase',
                  systemDataMap.cryptDiskList )
              + ', click “Try Again.”</p>';
              ;

            interActionButton.text      = 'Try Again';
            interActionButton.icon.name = 'arrow-right';
            interSkipButton.text        = 'No Thanks';
            interImageList = [ 'exclamation.svg' ];
            actionName = 'changePassphrasesNonDefault';
            regenUiFn( interTemplatePage, false );
            break;

        case 'diskPassphraseGoodItem':
            initPageFn([
              headerHighlightRect, interTopHeading,
              instructionsText,    pictureColumn,
              interActionButton,   interSkipButton
            ]);

            pageTitleText             = getCryptDiskTextFn('Disk Passphrase',
                                          systemDataMap.cryptDiskList);
            pageTitleImage            = imgDir + 'encrypted_drive.svg';
            interImageList            = [ 'finished.svg' ];
            headerHighlightRect.color = '#27ae60';
            interTopHeading.text
              = getCryptDiskTextFn( 'Disk Encryption Passphrase Appears',
                  systemDataMap.cryptDiskList )
              + ' Secure';
            instructionsText.text
              = '<p><b>' + getCryptDiskTextFn( 'The encrypted disk uses',
                          systemDataMap.cryptDiskList )
              + ' a unique passphrase</b>. '
              + getCryptDiskChangeTextFn()
              + '<br></p>'

              + '<p><b>We do not recommend changing your disk '
              + getCryptDiskTextFn( 'passphrase',
                  systemDataMap.cryptDiskList )
              + '</b>. However, if you would like to anyway, you may.<br></p>'

              + '<p><b>Please keep a copy of your passphrase in a safe '
              + 'place</b>. If this is lost, there is no recovery '
              + 'except to reformat your disks and restore from '
              + 'backup.<br></p>'

              + '<p><b>For your security, the Kubuntu Focus Team does NOT '
              + 'install tools</b> that could assist in any recovery.</p>'
              ;
            interActionButton.text      = 'Change Passphrases';
            interActionButton.icon.name = 'arrow-right';
            interSkipButton.text        = 'Keep Passphrases';
            actionName                  = 'changePassphrasesNonDefault';
            regenUiFn( interTemplatePage, false) ;
            break;

        case 'diskPassphraseChangesSuccessfulItem':
            initPageFn([
              headerHighlightRect, interTopHeading,
              instructionsText,    pictureColumn,
              interActionButton,   interSkipButton
            ]);

            pageTitleText             = getCryptDiskTextFn('Disk Passphrase',
                                          systemDataMap.cryptDiskList);
            pageTitleImage            = imgDir + 'encrypted_drive.svg';
            interImageList            = [ 'finishedOrange.svg' ];
            headerHighlightRect.color = '#ff9900';
            interTopHeading.text = "Passphrase Changes Successful";
            instructionsText.text
              = '<p><b>Requested passphrase changes were successful</b>. '
              + getCryptDiskChangeTextFn()
              + '<br></p>'

              + '<p><b>Please keep a copy of your passphrase in a safe '
              + 'place</b>. If this is lost, there is no recovery '
              + 'except to reformat your disks and restore from '
              + 'backup.<br></p>'

              + '<p><b>For your security, the Kubuntu Focus Team does NOT '
              + 'install tools</b> that could assist in any recovery.</p>'
              ;
            interActionButton.text      = 'Change Passphrases';
            interActionButton.icon.name = 'arrow-right';
            interSkipButton.text        = 'Keep Passphrases';
            actionName                  = 'changePassphrasesNonDefault';
            regenUiFn( interTemplatePage, false) ;
            break;

        case 'diskPassphraseChangeNonDefaultItem':
            oldPassphraseLabel.visible    = true;
            oldPassphraseBox.visible      = true;
            cryptErrorMessage.visible     = false;
            oldPassphraseBox.echoMode     = TextInput.Password;
            newPassphraseBox.echoMode     = TextInput.Password;
            confirmPassphraseBox.echoMode = TextInput.Password;

            pageTitleText             = getCryptDiskTextFn( 'Disk Passphrase',
                                          systemDataMap.cryptDiskList );
            pageTitleImage            = imgDir + 'encrypted_drive.svg';
            oldPassphraseBox.text     = '';
            newPassphraseBox.text     = '';
            confirmPassphraseBox.text = '';
            cryptHighlightRect.color  = '#ff9900';
            cryptTopHeading.text      = 'Change Passphrases';
            cryptInstructionsText.text
              = '<p><b>Please enter the old passphrase of the disk(s) you want '
              + 'to modify</b>. Then provide the passphrase you would like '
              + 'to use instead. <b>All disks using the specified old '
              + 'passphrase will be modified to use the new one.</p>'
              ;
            cryptSecondaryText.text
              = '<p><b>Please keep a copy of '
              + 'your passphrase</b> in a safe place. If this is lost, '
              + 'there is no recovery except to reformat your disks '
              + 'and restore from backup.<br></p>'

              + '<p><b>For your security</b>, the Kubuntu Focus Team does NOT '
              + 'install tools that could assist in any recovery. '
              + 'In other words, if you lose your password, they have no '
              + 'way to help you recover it!</p>'
              ;
            cryptActionButton.text      = 'Continue';
            cryptActionButton.icon.name = 'arrow-right';
            actionName                  = 'changeCryptNonDefault';
            regenUiFn( cryptTemplatePage, false );
            break;

        case 'extraSoftwareItem':
            initPageFn([
              topImage,       topHeading,
              primaryText,    actionButton,
              previousButton, skipButton
            ]);

            pageTitleText   = 'Extra Software';
            topImage.source = imgDir + 'extra_software.svg';
            topHeading.text
              = 'Install MS Fonts, VirtualBox Extensions, and More';
            primaryText.text
              = '<p><b>Some software is restricted,</b> '
              + 'meaning you have to approve certain agreements before '
              + 'you install it. We recommend you at least install the '
              + 'MS fonts to assist in compatibility. If you use '
              + 'VirtualBox, we also recommend adding the VirtualBox '
              + 'Extension Pack.<br></p>'

              + '<p><b>You may always revisit this later</b> using Start '
              + 'Menu &gt; Kubuntu Focus Tools &gt; Extra Software Installer.</p>'
              ;
            actionButton.text           = 'Install Extra Software Now';
            actionButton.icon.name      = 'arrow-right';

            actionName                  = 'checkNetwork';
            networkDisconnectTitleImage = imgDir + 'extra_software.svg';
            networkReturnAction         = 'installExtraSoftware';

            setLiveUsbFieldsFn();
            regenUiFn( baseTemplatePage, true );
            break;

        case 'extraSoftwareInstallItem':
            initPageFn([
              headerHighlightRect, interTopHeading,
              instructionsText,    interActionButton,
              pictureColumn,       interContinueLabel
            ]);

            pageTitleText             = 'Extra Software';
            pageTitleImage            = imgDir + 'extra_software.svg';
            headerHighlightRect.color = '#27ae60';
            interTopHeading.text      = 'Proceed with Terminal...';
            instructionsText.text
              = '<p>' + ding01Str + '<b>You should now see</b> a '
              + 'terminal as shown at right with a prompt for '
              + 'installation. Please enter your password to '
              + 'proceed.<br></p>'

              + '<p>' + ding02Str + '<b>As you follow the steps,</b> '
              + 'you will be prompted to accept license terms. If you do not '
              + 'agree with the terms for a particular software '
              + 'component, you may skip installing it.</p>'
              ;
            interActionButton.text      = 'Continue';
            interActionButton.icon.name = 'arrow-right';
            interImageList = [
              'extra_software_terminal.webp',
              'extra_software_license.webp'
            ];
            actionName = 'nextPage';
            regenUiFn( interTemplatePage, false );
            break;

        case 'systemRollbackItem':
            initPageFn([
              topImage,       topHeading,
              primaryText,    actionButton,
              previousButton, skipButton
            ]);

            pageTitleText   = 'System Rollback';
            topImage.source = imgDir + 'rollback.svg';
            topHeading.text = 'Manage and Restore Snapshots';
            primaryText.text
              = '<p><b>The System Rollback tool</b> snapshots and restores '
              + 'system files upon request, allowing you to quickly recover '
              + 'from failed upgrades, kernel issues, and other OS problems. '
              + 'If desired, it can automatically take snapshots both '
              + 'periodically and before software updates, however '
              + '<b>automatic snapshots are not enabled by '
              + 'default.</b><br></p>'

              + '<p><b>System Rollback does not snapshot files in /home.</b> '
              + 'For more info, see the '
              + '<a href="https://kfocus.org/wf/tools#rollback">Tools Guided '
              + 'Solution.</a></p>'
              ;
            actionButton.text           = 'Launch System Rollback Now';
            actionButton.icon.name      = 'arrow-right';
            actionName                  = 'launchSystemRollback';
            regenUiFn( baseTemplatePage, true );
            break;

        case 'systemRollbackLaunchedItem':
            initPageFn([
              headerHighlightRect, interTopHeading,
              instructionsText,    interActionButton,
              pictureColumn,       interContinueLabel
            ]);

            pageTitleText             = 'System Rollback';
            pageTitleImage            = imgDir + 'rollback.svg';
            headerHighlightRect.color = '#27ae60';
            interTopHeading.text      = 'Proceed with System Rollback...';
            instructionsText.text
              = '<p>' + ding01Str + '<b>Click on the drop-down menu</b> to '
              + 'view all available actions.<br></p>'

              + '<p>' + ding02Str + '<b>To enable automatic snapshots</b>, '
              + 'select <b>SWITCH between AUTO and MANUAL modes</b>, and '
              + 'select <b>AUTO</b> on the next screen.<br></p>'

              + '<p>' + ding03Str + '<b>The rollback quick launch icon</b> '
              + 'will immediately display the System Rollback app. You can '
              + 'create snapshots here at any time.<br></p>'

              + '<p>' + ding04Str + '<b>To restore a snapshot</b>, select '
              + '<b>RESTORE Snapshot</b>, then select the desired snapshot. '
              + 'The system will reboot.<br></p>'

              + '<p><b>See more in the</b> '
              + '<a href="https://kfocus.org/wf/tools#rollback">Tools Guided '
              + 'Solution.</a></p>'
              ;
            interActionButton.text      = 'Continue';
            interActionButton.icon.name = 'arrow-right';
            interImageList = [
              'rollback-welcome.svg',
              'rollback-systray.svg',
              'rollback-restore.svg'
            ];
            actionName = 'nextPage';
            regenUiFn( interTemplatePage, false );
            break;


        case 'fileBackupItem':
            initPageFn([
              topImage,       topHeading,
              primaryText,    actionButton,
              previousButton, skipButton
            ]);

            pageTitleText   = 'File Backup';
            topImage.source = imgDir + 'file_backup.svg';
            topHeading.text = 'Snapshot and Recover Files';
            primaryText.text
              = '<p><b>BackInTime takes snapshots of your home '
              + 'directory</b> so you can recover information that was '
              + 'later changed or removed. We\'ve configured it to '
              + 'ignore folders where cloud drives and software repos '
              + 'are usually located.<br></p>'

              + '<p><b>See more in the</b> '
              + '<a href="https://kfocus.org/wf/backup">Backups Guided '
              + 'Solution.</a></p>'
              ;
            actionButton.text      = 'Launch BackInTime Now';
            actionButton.icon.name = 'arrow-right';
            actionName             = 'launchBackInTime';

            setLiveUsbFieldsFn();
            regenUiFn( baseTemplatePage, true );
            break;

        case 'fileBackupLaunchedItem':
            initPageFn([
              headerHighlightRect, interTopHeading,
              instructionsText,    interActionButton,
              pictureColumn,       interContinueLabel
            ]);

            pageTitleText             = 'File Backup';
            pageTitleImage            = imgDir + 'file_backup.svg';
            headerHighlightRect.color = '#27ae60';
            interTopHeading.text      = 'Proceed with BackInTime...';
            instructionsText.text
              = '<p>' + ding01Str + '<b>If BackInTime is not '
              + 'installed,</b> you will be asked to install it, and '
              + 'will need to provide your password to do so. ' + ding02Str
              + '<b>Once installed, the BackInTime app</b> should appear as '
              + 'shown.<br></p>'

              + '<p>' + ding03Str + '<b>Take snapshots with the Disk '
              + 'icon</b>. ' + ding04Str + 'Browse snapshots on the left, '
              + ding05Str + 'select files on the right, and '
              + ding06Str + 'adjust settings. See General > Schedule at the '
              + 'bottom to set automatic snapshots.<br></p>'

              + '<p>' + ding07Str
              + '<b>Click on the disk icon next to the system tray</b> to '
              + 'launch BackInTime.<br></p>'

              + '<p><b>See more in the</b> '
              + '<a href="https://kfocus.org/wf/backup">Backups Guided '
              + 'Solution.</a></p>'
              ;
            interActionButton.text      = 'Continue';
            interActionButton.icon.name = 'arrow-right';
            interImageList = [
              'kfocus_mime_backintime.svg',
              'backintime_ui.webp',
              'backintime_panel.svg'
            ];
            actionName = 'nextPage';
            regenUiFn( interTemplatePage, false );
            break;

        case 'passwordManagerItem':
            initPageFn([
              topImage,       topHeading,
              primaryText,    actionButton,
              previousButton, skipButton
            ]);

            pageTitleText   = 'Password Manager';
            topImage.source = imgDir + 'keepassxc_logo.svg';
            topHeading.text = 'Generate, Save, and View Secrets';
            primaryText.text
              = '<p><b>KeePassXC is a powerful password manager</b> and '
              + 'generator that takes the hassle out of staying secure. It '
              + 'saves your passwords offline and in an encrypted form, '
              + 'avoiding the security issues of cloud-based password '
              + 'managers. It can help keep you safe even if your computer '
              + 'is stolen.<br></p>'

              + '<p><b>KeePassXC can also be used</b> for two-factor '
              + 'authentication, application secrets, and smartphone '
              + 'secrets. See more in the '
              + '<a href="https://kfocus.org/wf/passwords#bkm_keepassxc">'
              + 'Passwords Guided Solution.</a></p>'
              ;
            actionButton.text      = 'Launch KeePassXC Now';
            actionButton.icon.name = 'arrow-right';
            actionName             = 'launchKeePassXC';
            regenUiFn( baseTemplatePage, true );
            break;

        case 'passwordManagerLaunchedItem':
            initPageFn([
              headerHighlightRect, interTopHeading,
              instructionsText,    interActionButton,
              pictureColumn,       interContinueLabel
            ]);

            pageTitleText             = 'Password Manager';
            pageTitleImage            = imgDir + 'keepassxc_logo.svg';
            headerHighlightRect.color = '#27ae60';
            interTopHeading.text      = 'Proceed with KeePassXC...'
            instructionsText.text
              = '<p>' + ding01Str + '<b>If KeePassXC is not installed</b>, '
              + 'you will be asked to install it, and will need to provide '
              + 'your password to do so.<br></p>'

              + '<p>' + ding02Str + '<b>Once installed,</b> you may need to '
              + 'click on the icon in the system tray as shown.<br></p>'

              + '<p>' + ding03Str + '<b>The main window should then '
              + 'appear</b>. From here, you can create a new vault to start '
              + 'managing passwords.<br></p>'

              + '<p><b>See more in the</b> '
              + '<a href="https://kfocus.org/wf/passwords#bkm_keepassxc">'
              + 'Passwords Guided Solution</a> and the '
              + '<a href="https://keepassxc.org/docs/">official '
              + 'documentation</a>.</p> You will need this to '
              + 'enable browser integration!'
              ;
            interActionButton.text      = 'Continue';
            interActionButton.icon.name = 'arrow-right';
            interImageList = [
              'kfocus_mime_keepassxc.svg',
              'keepassxc_systray.svg',
              'keepassxc_ui.svg'
            ];
            actionName = 'nextPage';
            regenUiFn( interTemplatePage, false );
            break;

        case 'emailCalendarItem':
            initPageFn([
              topImage,       topHeading,
              primaryText,    actionButton,
              previousButton, skipButton
            ]);

            pageTitleText   = 'Email';
            topImage.source = imgDir + 'thunderbird_logo.svg';
            topHeading.text = 'Manage Emails, Calendar, and Contacts';
            primaryText.text
              = '<p><b>Thunderbird is a fast, convenient, and powerful email '
              + 'client</b>. It provides privacy and security features not '
              + 'generally found in webmail systems, and works with many '
              + 'email providers such as GMail and Yahoo. It can be used '
              + 'with multiple email accounts at once, letting you see '
              + 'all your mail in one place.<br></p>'

              + '<p><b>See more in the</b> '
              + '<a href="https://kfocus.org/wf/email">Email Guided '
              + 'Solution.</a></p>'
              ;
            actionButton.text           = 'Launch Thunderbird Now';
            actionButton.icon.name      = 'arrow-right';
            actionName                  = 'checkNetwork';
            networkDisconnectTitleImage = imgDir + 'thunderbird_logo.svg';
            networkReturnAction         = 'launchThunderbird';

            setLiveUsbFieldsFn();
            regenUiFn( baseTemplatePage, true );
            break;

        case 'emailCalendarLaunchedItem':
            initPageFn([
              headerHighlightRect, interTopHeading,
              instructionsText,    interActionButton,
              pictureColumn,       interContinueLabel
            ]);

            pageTitleText             = 'Email';
            pageTitleImage            = imgDir + 'thunderbird_logo.svg'
            headerHighlightRect.color = '#27ae60';
            interTopHeading.text      = 'Proceed with Thunderbird...';
            instructionsText.text
              = '<p>' + ding01Str
              + '<b>If Thunderbird is not installed,</b> you will be '
              + 'asked to install it, and will need to provide your password '
              + 'to do so.<br></p>'

              + '<p>' + ding02Str
              + '<b>If this is the first time</b> you are running '
              + 'Thunderbird, you will be shown the Account Setup screen. '
              + 'Enter your account details to connect.<br></p>'

              + '<p>' + ding03Str
              + '<b>After connecting to an account</b>, the Mail interface will '
              + 'appear as shown.<br></p>'

              + '<p><b>See the</b> '
              + '<a href="https://kfocus.org/wf/email.html">Email Guided '
              + 'Solution</a> to set up '
              + 'calendars, manage contacts, and more.</p>'
              ;
            interActionButton.text      = 'Continue';
            interActionButton.icon.name = 'arrow-right';
            interImageList = [
              'kfocus_mime_thunderbird.svg',
              'thunderbird_login.svg',
              'thunderbird_ui.webp'
            ];
            actionName = 'nextPage';
            regenUiFn( interTemplatePage, false );
            break;

        case 'dropboxItem':
            initPageFn([
              topImage,       topHeading,
              primaryText,    actionButton,
              previousButton, skipButton
            ]);

            pageTitleText   = 'Dropbox';
            topImage.source = imgDir + 'dropbox_logo.svg';
            topHeading.text = 'Access Your Files From Anywhere';
            primaryText.text
              = '<p><b>Dropbox is a fast, flexible cloud storage system</b> '
              + 'that automatically keeps your files synced to your computer '
              + 'for offline access. You can use it to keep backups, archive '
              + 'old data, access files from multiple computers, and more. '
              + 'Up to 2 GB of data can be stored for free, and additional '
              + 'storage is quite affordable.<br></p>'

              + '<p><b>See more in the</b> '
              + '<a href="https://kfocus.org/wf/drives.html">Cloud Drives '
              + 'Guided Solution.</a></p>'
              ;
            actionButton.text           = 'Launch Dropbox Now';
            actionButton.icon.name      = 'arrow-right';
            actionName                  = 'checkNetwork';
            networkDisconnectTitleImage = imgDir + 'dropbox_logo.svg';
            networkReturnAction         = 'launchDropbox';

            setLiveUsbFieldsFn();
            regenUiFn( baseTemplatePage, true );
            break;

        case 'dropboxLaunchedItem':
            initPageFn([
              headerHighlightRect, interTopHeading,
              instructionsText,    interActionButton,
              pictureColumn,       interContinueLabel
            ]);

            pageTitleText             = 'Dropbox';
            pageTitleImage            = imgDir + 'dropbox_logo.svg';
            headerHighlightRect.color = '#27ae60';
            interTopHeading.text      = 'Proceed with Dropbox...';
            instructionsText.text
              = '<p>' + ding01Str
              + '<b>If Dropbox is not installed,</b> you will be asked to '
              + 'install it, and will need to provide your password to do '
              + 'so.<br></p>'

              + '<p>' + ding02Str
              + '<b>Once installed,</b> you may need to click on the icon '
              + 'in the system tray as shown.<br></p>'

              + '<p>' + ding03Str
              + '<b>Sign into your Dropbox account</b> or create '
              + 'a new one using the web page that should appear '
              + 'in your browser.<br></p>'

              + '<p><b>See more in the</b> '
              + '<a href="https://kfocus.org/wf/drives.html">Cloud Drives '
              + 'Guided Solution.</a></p>'
              ;
            interActionButton.text      = 'Continue'
            interActionButton.icon.name = 'arrow-right';
            interImageList = [
              'kfocus_mime_dropbox.svg',
              'dropbox_systray.svg',
              'dropbox_ui.svg'
            ];
            actionName = 'nextPage';

            regenUiFn( interTemplatePage, false );
            break;

        case 'insyncItem':
            initPageFn([
              topImage,       topHeading,
              primaryText,    actionButton,
              previousButton, skipButton
            ]);

            pageTitleText   = 'Insync';
            topImage.source = imgDir + 'insync_logo.svg';
            topHeading.text = 'Manage Cloud Drives Easily';
            primaryText.text
              = '<p><b>Insync is a cloud storage sync app</b> that works '
              + 'with Google Drive, OneDrive, and Dropbox. It can sync '
              + 'with multiple accounts and providers at the same '
              + 'time. It is paid software, although it has a free trial '
              + 'period. We have found it reasonably priced and useful '
              + 'for projects that require the use of cloud drives.<br></p>'

              + '<p><b>See more in the</b> '
              + '<a href="https://kfocus.org/wf/drives.html'
              + '#bkm_sync_with_google">Cloud Drives Guided Solution.</a></p>'
              ;
            actionButton.text           = 'Launch Insync Now'
            actionButton.icon.name      = 'arrow-right';
            actionName                  = 'checkNetwork';
            networkDisconnectTitleImage = imgDir + 'insync_logo.svg';
            networkReturnAction         = 'launchInsync';

            setLiveUsbFieldsFn();
            regenUiFn( baseTemplatePage, true );
            break;

        case 'insyncLaunchedItem':
            initPageFn([
              headerHighlightRect, interTopHeading,
              instructionsText,    interActionButton,
              pictureColumn,       interContinueLabel
            ]);

            pageTitleText             = 'Insync';
            pageTitleImage            = imgDir + 'insync_logo.svg';
            headerHighlightRect.color = '#27ae60';
            interTopHeading.text      = 'Proceed with Insync...';
            instructionsText.text
              = '<p>' + ding01Str
              + '<b>If Insync is not installed,</b> you will be asked to '
              + 'install it, and will need to provide your password to do '
              + 'so.<br></p>'

              + '<p>' + ding02Str
              + '<b>When you first start Insync,</b> you will be shown '
              + 'account options. Select your drive type to proceed.<br></p>'

              + '<p>' + ding03Str
              + '<b>Sign into to the drive account</b> you specified in '
              + 'step 2.<br></p>'

              + '<p>' + ding04Str
              + '<b>Click on the Insync icon in the system tray</b> '
              + 'to open the management interface.</p>'
              ;
            interActionButton.text      = 'Continue'
            interActionButton.icon.name = 'arrow-right';
            interImageList = [
              'kfocus_mime_insync.svg',
              'insync_start.webp',
              'insync_login.webp',
              'insync_systray.svg'
            ];
            actionName = 'nextPage';
            regenUiFn( interTemplatePage, false );
            break;

        case 'jetbrainsToolboxItem':
            initPageFn([
              topImage,       topHeading,
              primaryText,    actionButton,
              previousButton, skipButton
            ]);

            pageTitleText   = 'JetBrains Toolbox';
            topImage.source = imgDir + 'jetbrains_toolbox_logo.svg';
            topHeading.text = 'Install and Manage JetBrains IDEs';
            primaryText.text
              = '<p><b>JetBrains Toolbox provides a convenient interface to '
              + 'use their products</b>. You can install, browse, remove, '
              + 'upgrade, configure, and otherwise manage their many popular '
              + 'developer tools. These includes IDEs like IntelliJ, '
              + 'PyCharm, WebStorm, Android Studio, and DataGrip. Several '
              + 'IDEs have free community editions, while others have '
              + 'generous free trial periods.<br></p>'

              + '<p><b>See more in the</b> '
              + '<a href="https://kfocus.org/wf/ide.html">IDEs Guided '
              + 'Solution.</a></p>'
              ;
            actionButton.text      = 'Launch JetBrains Toolbox Now';
            actionButton.icon.name = 'arrow-right';
            actionName             = 'launchJetbrainsToolbox';

            regenUiFn( baseTemplatePage, true );
            break;

        case 'jetbrainsToolboxLaunchedItem':
            initPageFn([
              headerHighlightRect, interTopHeading,
              instructionsText,    interActionButton,
              pictureColumn,       interContinueLabel
            ]);

            pageTitleText             = 'JetBrains Toolbox';
            pageTitleImage            = imgDir + 'jetbrains_toolbox_logo.svg';
            headerHighlightRect.color = '#27ae60';
            interTopHeading.text      = 'Proceed with JetBrains Toolbox...';
            instructionsText.text
              = '<p>' + ding01Str
              + '<b>If JetBrains Toolbox is not installed,</b> you will '
              + 'be asked to install it, and will need to provide your '
              + 'password to do so.<br></p>'

              + '<p>' + ding02Str
              + '<b>If you’re launching the Toolbox for the first '
              + 'time,</b> you will be asked to configure it and accept the '
              + 'JetBrains User Agreement. It may take up to 30 seconds for '
              + 'the Toolbox to launch.<br></p>'

              + '<p>' + ding03Str
              + '<b>Click on the Toolbox icon</b> in the system tray to open '
              + 'the management interface. '
              + '</p>'
              ;
            interActionButton.text      = 'Continue';
            interActionButton.icon.name = 'arrow-right';
            interImageList = [
              'kfocus_mime_jetbrains_toolbox.svg',
              'jetbrains_toolbox_ui.webp',
              'jetbrains_toolbox_systray.svg'
            ];
            actionName = 'nextPage';

            regenUiFn( interTemplatePage, false );
            break;

        case 'avatarItem':
            initPageFn([
              topImage,       topHeading,
              primaryText,    actionButton,
              previousButton, skipButton
            ]);

            pageTitleText   = 'Avatar';
            topImage.source = imgDir + 'avatar.svg';
            topHeading.text = 'Personalize your Profile Picture';
            primaryText.text
              = '<p><b>Your profile picture is displayed in the Start Menu and '
              + 'on the lock screen</b>. By default, this picture is a '
              + 'Kubuntu logo, but it’s easy to change to a picture of your '
              + 'choice.<br></p>'

              + '<p><b>You may always revisit this later</b> by opening the '
              + 'Start Menu and clicking on the user avatar image in the '
              + 'upper-left corner of the menu.</p>'
              ;
            actionButton.text      = 'Change Your Avatar Now';
            actionButton.icon.name = 'arrow-right';
            actionName             = 'changeAvatar';
            regenUiFn( baseTemplatePage, true );
            break;

        case 'avatarChangeItem':
            initPageFn([
              headerHighlightRect, interTopHeading,
              instructionsText,    interActionButton,
              pictureColumn,       interContinueLabel
            ]);

            pageTitleText             = 'Avatar';
            pageTitleImage            = imgDir + 'avatar.svg';
            headerHighlightRect.color = '#27ae60';
            interTopHeading.text      = 'Proceed with User Manager...';
            instructionsText.text
              = '<p>' + ding01Str
              + '<b>Click on the profile picture</b> in the User Manager '
              + 'interface.<br></p>'

              + '<p>' + ding02Str
              + '<b>Pick one of the preinstalled avatars,</b> or click '
              + '“Choose File” to use a custom avatar.<br></p>'
              // TODO: Specify image type and size?

              + '<p>' + ding03Str
              + '<b>Click “Apply” and provide your password</b> to change '
              + 'your avatar.</p>'
              ;
            interActionButton.text      = 'Continue';
            interActionButton.icon.name = 'arrow-right';
            interImageList = [
              'user_manager.webp',
              'avatar_changer.webp',
              'avatar_password.webp'
            ];
            actionName = 'nextPage';
            regenUiFn( interTemplatePage, false );
            break;

        case 'curatedAppsItem':
            initPageFn([
              topImage,       topHeading,
              primaryText,    actionButton,
              previousButton, skipButton
            ]);

            pageTitleText   = 'Curated Apps';
            topImage.source = imgDir + 'kfocus_bug_apps.svg';
            topHeading.text = 'Find and Install Apps Quickly';
            primaryText.text
              = '<p><b>The Curated Apps Page lists recommended apps </b> '
              + 'that work well with Kubuntu Focus systems. Click on an '
              + 'icon to launch an app. If it is not installed, the system '
              + 'will install the repository and the package before '
              + 'launching it.<br></p>'

              + '<p><b>We encourage you to review the list of curated '
              + 'apps</b> and install the ones you need now.<br></p>'

              + '<p><b>Curated apps are supported by</b> '
              + '<a href="https://kfocus.org/wf/">Guided Solutions</a>. '
              + 'Use these HOWTOs to get advice on many popular topics, '
              + 'such as attaching external displays, disabling Ubuntu Pro '
              + 'notifications, or configuring YubiKeys.</p>'
              ;
            actionButton.text           = 'Browse Curated Apps Now';
            actionButton.icon.name      = 'arrow-right';
            actionName                  = 'checkNetwork';
            networkDisconnectTitleImage = imgDir + 'kfocus_bug_apps.svg';
            networkReturnAction         = 'browseCuratedApps';
            regenUiFn( baseTemplatePage, true );
            break;

        case 'browseCuratedAppsItem':
            initPageFn([
              headerHighlightRect, interTopHeading,
              instructionsText,    interActionButton,
              pictureColumn,       interContinueLabel
            ]);

            pageTitleText             = 'Curated Apps';
            pageTitleImage            = imgDir + 'kfocus_bug_apps.svg';
            headerHighlightRect.color = '#27ae60';
            interTopHeading.text      = 'Proceed with Curated Apps...';
            instructionsText.text
              = '<p>' + ding01Str
              + '<b>The Curated Apps web page</b> should now be visible '
              + 'in the default web browser.<br></p>'

              + '<p>' + ding02Str
              + '<b>Scroll down to the list of apps</b> and click the '
              + 'icon of the app you would like to launch.<br></p>'

              + '<p>' + ding03Str
              + '<b>The system will launch the app</b>. If needed, '
              + 'it will install the key, repository, and package as '
              + 'needed before launching the app. If any of these steps are '
              + 'required, the system will ask for your authorization '
              + 'before proceeding.</p>'
              ;
            interActionButton.text      = 'Continue';
            interActionButton.icon.name = 'arrow-right';
            interImageList = [
              'curated_apps_page.webp',
              'curated_apps_list.webp',
              'kfocus_mime_filezilla.svg'
            ];
            actionName = 'nextPage';
            regenUiFn( interTemplatePage, false );
            break;

        case 'finishItem':
            initPageFn([
              topImage,       topHeading,
              primaryText,    actionButton,
              previousButton, loginStartCheckbox,
              clearButton
            ]);

            pageTitleText   = 'Finish';
            topImage.source = imgDir + 'finished.svg';
            topHeading.text = 'All Done';
            primaryText.text
              = '<p><b>You have considered</b> all steps shown with a '
              + 'checkmark. Click the “Clear Checkmarks” button below to '
              + 'reset them.<br></p>'

              + '<p><b>To get more help,</b> click Start Menu &gt; Kubuntu Focus '
              + 'Tools &gt; Help.<br></p>'

              + '<p><b>To run this wizard again,</b> click Start Menu &gt; '
              + 'Kubuntu Focus Tools &gt; Welcome Wizard.</p>'
              ;
            actionButton.text      = 'Finish';
            actionButton.icon.name = 'arrow-right';
            actionName             = 'finishWizard';
            regenUiFn( baseTemplatePage, true );
            break;
        }
    }


    function storeStateMatrixFn () {
        let serial_str;

        try { serial_str = JSON.stringify( stateMatrix ); }
        catch (e) {
            console.warn( 'Trouble serializing stateMatrix', e );
            serial_str = '{}'
        }

        exeRun.execSync(
          'tee '
          + systemDataMap.homeDir
          + '/.config/kfocus-firstrun-wizard-data.json',
          serial_str
       );
    }

    /**************
     * Logic code *
     **************/

    // Check all encrypted disks for the default passphrase
    ShellEngine {
        id          : handleDefaultCryptListEngine
        onAppExited : {
            if ( exitCode > 0 ) {
                switchPageFn( 'pkexecDeclineCryptCheckItem' );
            } else {
                // The newline following the last entry creates an "extra"
                // blank entry that needs to be removed
                defaultCryptList = stdout.split('\n').slice(0, -1);

                if ( defaultCryptList.length > 0 ) {
                    switchPageFn( 'diskPassphraseChangeItem' );
                } else {
                    switchPageFn( 'diskPassphraseGoodItem' );
                }
            }
        }
    }

    // Changes the passphrase on all encrypted disks that use the default
    ShellEngine {
        id          : handleCryptoChangeEngine
        onAppExited : {
            if ( exitCode === 127 ) {
                switchPageFn( 'pkexecDeclineCryptChangeItem' );
            } else {
                let stdout_list = stdout.split('\n').slice(0, -1);
                if ( cryptChangeMode === 'changeCrypt' ) {
                    cryptDiskChangeCount
                      = defaultCryptList.length - stdout_list.length;
                    switchPageFn( 'diskPassphraseGoodItem' );
                } else {
                    cryptDiskChangeCount
                      = systemDataMap.cryptDiskList.length - stdout_list.length;
                    if ( cryptDiskChangeCount === 0 ) {
                        switchPageFn( 'diskPassphraseChangeFailedItem' );
                    } else {
                        if ( cryptChangeMode === 'changeCrypt' ) {
                            switchPageFn( 'diskPassphraseGoodItem' );
                        } else {
                            switchPageFn( 'diskPassphraseChangesSuccessfulItem' );
                        }
                    }
                }
            }
        }
    }

    // Used for checking for a network connection
    ShellEngine {
        id          : internetCheckerEngine
        onAppExited : {
            if ( exitCode === 0 ) {
                actionName = networkReturnAction;
                takeActionFn();
            } else {
                switchPageFn( 'connectInternetItem' );
            }
        }
    }

    // Reads JSON data tracking what steps are completed or not
    ShellEngine {
        id: stateMatrixReaderEngine
        onAppExited : {
            let setMap;
            try {
                setMap = JSON.parse( stdout );
            }
            catch (e) {
                console.warn( 'Trouble parsing setMap:', e, stdout );
            }

            // Ensure we have a stateMatrix object
            if ( typeof setMap === 'object' ) {
                stateMatrix = setMap;
            }
            // ... else use the default set on init

            // Ensure we have a check_map object
            if ( typeof stateMatrix.check_map !== 'object' ) {
                stateMatrix.check_map = {};
            }
            // ... else use whatever object was already there

            populateCheckboxesFn();
        }
   }

    // Used for shell commands that don't require a callback
    ShellEngine { id : exeRun }

    // BEGIN takeActionFn
    // Purpose : Provide controls for click handlers and other events
    function takeActionFn () {
        switch ( actionName ) {
        case 'nextPage':
            gotoNextPageFn();
            break;

        case 'previousPage':
            gotoPreviousPageFn();
            break;

        case 'checkNetwork':
            internetCheckerEngine.exec('nslookup cloudflare.com');
            // DEBUG: Use the following to simulate a broken connection
            // internetCheckerEngine.exec('false');
            switchPageFn( 'internetCheckItem' );
            break;

        case 'checkCrypt':
            // TODO: INFO: Possibly make it so that when the user finishes
            // authenticating the wizard reacts while the task is still
            // running?
            handleDefaultCryptListEngine.exec(
              'pkexec '
              + systemDataMap.binDir
              + '/kfocus-check-crypt -c ' );
            switchPageFn( 'diskPassphraseCheckerItem' );
            break;

        case 'changeCrypt':
            // TODO: NOTICE: Detect if the user re-inputs the default
            // passphrase here?
            cryptChangeMode = 'changeCrypt';
            if ( newPassphraseBox.text === confirmPassphraseBox.text ) {
                if ( newPassphraseBox.text === '' ) {
                    cryptErrorMessage.text
                      = 'No passphrase was entered. Please try again.';
                    cryptErrorMessage.visible = true;
                } else {
                    handleCryptoChangeEngine.exec(
                      'pkexec '
                      + systemDataMap.binDir
                      + '/kfocus-check-crypt -m '
                      + defaultCryptList.join(' '),
                      newPassphraseBox.text + '\n' );
                    switchPageFn( 'diskPassphraseChangeInProgressItem' );
                }
            } else {
                cryptErrorMessage.text
                  = 'The provided passphrases do not '
                    + 'match. Please try again.';
                cryptErrorMessage.visible = true;
            }
            break;

        case 'retryCrypt':
            if ( cryptChangeMode === 'changeCrypt' ) {
                switchPageFn( 'diskPassphraseChangeItem' );
            } else {
                switchPageFn( 'diskPassphraseChangeNonDefaultItem' );
            }
            break;

        case 'changePassphrasesNonDefault':
            switchPageFn( 'diskPassphraseChangeNonDefaultItem' );
            break;

        case 'changeCryptNonDefault':
            cryptChangeMode = 'changeCryptNonDefault';
            if ( newPassphraseBox.text === confirmPassphraseBox.text ) {
                if ( newPassphraseBox.text === '' ) {
                    cryptErrorMessage.text
                      = 'No passphrase was entered. Please try again.';
                    cryptErrorMessage.visible = true;
                } else if ( oldPassphraseBox.text === '' ) {
                    /* TODO: Do we really want to do this? What if the user is
                     * trying to change away from a blank passphrase? */
                    cryptErrorMessage.text
                      = 'The old passphrase was not entered. Please try again.';
                    cryptErrorMessage.visible = true;
                } else {
                    handleCryptoChangeEngine.exec(
                      'pkexec '
                      + systemDataMap.binDir
                      + '/kfocus-check-crypt -r '
                      + systemDataMap.cryptDiskList.join(' '),
                      oldPassphraseBox.text
                      + '\n'
                      + newPassphraseBox.text
                      + '\n' );
                    switchPageFn( 'diskPassphraseChangeInProgressItem' );
                }
            } else {
                cryptErrorMessage.text
                  = 'The provided passphrases do not match. Please try '
                  + 'again.';
                cryptErrorMessage.visible = true;
            }

            break;

        case 'installExtraSoftware':
            exeRun.exec(
              'xterm -fa \'Monospace\' -fs 12 -b 28 -geometry 80x24 -T '
              + '\'Install Extras\' -xrm \'xterm*iconHint: '
              + '/usr/share/pixmaps/kfocus-bug-wizard\' -e pkexec '
              + systemDataMap.binDir + '/kfocus-extra' );
            switchPageFn( 'extraSoftwareInstallItem' );
            break;

        case 'launchSystemRollback':
            exeRun.exec( '/usr/lib/kfocus/bin/kfocus-rollback' );
            switchPageFn( 'systemRollbackLaunchedItem' );
            break;

        case 'launchBackInTime':
            exeRun.exec( systemDataMap.binDir + '/kfocus-mime -k backintime' );
            switchPageFn( 'fileBackupLaunchedItem' );
            break;

        case 'launchKeePassXC':
            exeRun.exec( systemDataMap.binDir + '/kfocus-mime -kf keepassxc' );
            switchPageFn( 'passwordManagerLaunchedItem' );
            break;

        case 'launchThunderbird':
            exeRun.exec( systemDataMap.binDir + '/kfocus-mime -k thunderbird' );
            switchPageFn( 'emailCalendarLaunchedItem' );
            break;

        case 'launchDropbox':
            exeRun.exec( systemDataMap.binDir + '/kfocus-mime -k dropbox' );
            switchPageFn( 'dropboxLaunchedItem' );
            break;

        case 'launchInsync':
            exeRun.exec( systemDataMap.binDir + '/kfocus-mime -k insync' );
            switchPageFn( 'insyncLaunchedItem' );
            break;

        case 'launchJetbrainsToolbox':
            exeRun.exec( systemDataMap.binDir
              + '/kfocus-mime -k jetbrains-toolbox-plain' );
            switchPageFn( 'jetbrainsToolboxLaunchedItem' );
            break;

        case 'changeAvatar':
            exeRun.exec( 'kcmshell5 users' );
            switchPageFn( 'avatarChangeItem' );
            break;

        case 'browseCuratedApps':
            Qt.openUrlExternally( 'https://kfocus.org/wf/apps.html' );
            switchPageFn( 'browseCuratedAppsItem' );
            break;

        case 'finishWizard':
            if ( loginStartCheckbox.checkState === Qt.Unchecked ) {
                exeRun.execSync( 'touch ' + systemDataMap.homeDir
                   + '/.config/kfocus-firstrun-wizard'
                );
            } else {
                exeRun.execSync( 'rm ' + systemDataMap.homeDir
                  + '/.config/kfocus-firstrun-wizard'
                );
            }
            setCheckMarkFn();
            storeStateMatrixFn();
            Qt.quit();
        }
    }

    // Kick-off rendering on completion
    Component.onCompleted: {
        let startPageIdx = 0;
        stateMatrix = { check_map: {} }; // Default stateMatrix
        if ( systemDataMap.cryptDiskList.length === 0 ) {
            removeSidebarItemFn('diskPassphraseItem');
        }

        if ( systemDataMap.rollbackCmd === '' ) {
          removeSidebarItemFn( 'systemRollbackItem' );
        }

        startPageIdx = findSidebarItemFn( systemDataMap.startPage );
        if ( startPageIdx === -1 ) {
            startPageIdx = 0;
            systemDataMap.startPage = "introductionItem";
        }

        switchPageFn( systemDataMap.startPage );
        enabledSidebar.currentIndex = startPageIdx;
        disabledSidebar.currentIndex = startPageIdx;

        const json_file = systemDataMap.homeDir
            + '/.config/kfocus-firstrun-wizard-data.json';
        stateMatrixReaderEngine.exec( '/usr/bin/cat ' + json_file );
    }

    onClosing: {
        storeStateMatrixFn();
    }
    // == . END Controllers ===========================================
}

import QtQuick 2.6
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
    property string actionName          : ''
    property string networkReturnPage   : ''
    property string networkReturnAction : ''
    property int disabledSidebarIndex   : 0
    property bool firstRun              : true
    property var interImageList         : []
    property int defaultPassphraseDisks : 0
    property string pageTitleText       : ''
    property string pageTitleImage      : ''
    property string imgDir              : 'assets/images/'

    //
    // Purpose: Describes steps used in wizard
    // See property currentIndex
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
            jsId     : 'fileBackupItem'
            task     : 'File Backup'
            taskIcon : 'backup'
        }
         ListElement {
             jsId     : 'passwordManagerItem'
             task     : 'Password Manager'
             taskIcon : 'lock'
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
            taskIcon : 'checkbox'
        }
    }

    StartupData {
        id: systemDataMap
        // cryptDiskList is provided by main.cpp
        // binDir is provided by main.cpp
        // homeDir is provided by main.cpp
    }
    // == . END Models ================================================

    // == BEGIN Views =================================================
    // Define page size and columns
    width  : Kirigami.Units.gridUnit * 38
    height : Kirigami.Units.gridUnit * 27

    pageStack.defaultColumnWidth : Kirigami.Units.gridUnit * 10

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
            id       : disabledSidebar
            model    : sidebarModel
            delegate : disabledSidebarDelegate
        }
    }

    Component {
        id: enabledSidebarDelegate
        Kirigami.BasicListItem {
            label     : task
            iconColor : Kirigami.Theme.textColor
            iconSize  : Kirigami.Units.gridUnit * 1.5
            onClicked : {
                switchPageFn( jsId );
            }
            Component.onCompleted: {
                var taskIcon_part_list = taskIcon.split( '|' );
                if ( taskIcon_part_list[0] === 'THEMED' ) {
                    this.icon = getThemedIcon( taskIcon_part_list[1] );
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
            fadeContent : true
            onClicked   : {
                disabledSidebar.currentIndex = disabledSidebarIndex;
            }
            Component.onCompleted: {
                var taskIcon_part_list = taskIcon.split( '|' );
                if ( taskIcon_part_list[0] === 'THEMED' ) {
                    this.icon = getThemedIcon( taskIcon_part_list[1] );
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
                onClicked : { nextPageFn(); }
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

                Layout.preferredHeight : Kirigami.Units.gridUnit * 6
                Layout.preferredWidth  : Kirigami.Units.gridUnit * 20
                Layout.bottomMargin    : Kirigami.Units.gridUnit * 2
                Layout.topMargin       : Kirigami.Units.gridUnit * 1
                Layout.alignment       : Qt.AlignHCenter
            }

            Kirigami.Heading {
                id : topHeading

                horizontalAlignment : Text.AlignHCenter
                Layout.bottomMargin : Kirigami.Units.gridUnit
                Layout.alignment    : Qt.AlignHCenter
            }

            Controls.BusyIndicator {
                id : busyIndicator
                running          : true
                Layout.alignment : Qt.AlignHCenter
            }

            Controls.Label {
                id       : primaryText
                wrapMode : Text.WordWrap

                onLinkActivated     : Qt.openUrlExternally(link)
                Layout.fillWidth    : true
                Layout.bottomMargin : Kirigami.Units.gridUnit
            }
        }

        Controls.Button {
            id : previousButton

            anchors {
                left   : parent.left
                bottom : parent.bottom
            }

            text      : 'Previous'
            icon.name : 'arrow-left'
            onClicked : {
                previousPageFn();
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
                id        : actionButton
                onClicked : {
                    takeActionFn();
                }
            }

            Controls.Button {
                id        : skipButton
                text      : 'Skip'
                icon.name : 'go-next-skip'
                onClicked : {
                    nextPageFn();
                }
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
                id        : interSkipButton
                text      : 'Skip'
                icon.name : 'go-next-skip'
                onClicked : {
                    nextPageFn();
                }
            }

            Controls.Button {
                id        : interActionButton
                onClicked : {
                    takeActionFn();
                }
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
                  + 'click "Continue" to proceed to the next step.'
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
                columns : 3

                Layout.alignment    : Qt.AlignHCenter
                Layout.bottomMargin : Kirigami.Units.gridUnit

                Controls.Label {
                    text             : 'New passphrase'
                    Layout.alignment : Qt.AlignRight
                }

                Controls.TextField {
                    id       : newPassphraseBox
                    echoMode : TextInput.Password
                }

                Controls.Button {
                    id        : newPassphrasePeekButton
                    icon.name : 'password-show-off'
                    onClicked : {
                        if ( this.icon.name === 'password-show-off' ) {
                            this.icon.name = 'password-show-on';
                            newPassphraseBox.echoMode
                              = TextInput.Normal;
                            confirmPassphraseBox.echoMode
                              = TextInput.Normal;
                        } else {
                            this.icon.name = 'password-show-off';
                            newPassphraseBox.echoMode
                              = TextInput.Password;
                            confirmPassphraseBox.echoMode
                              = TextInput.Password;
                        }
                    }
                }

                Controls.Label {
                    text : 'Confirm new passphrase'
                    Layout.alignment: Qt.AlignRight
                }

                Controls.TextField {
                    id       : confirmPassphraseBox
                    echoMode : TextInput.Password
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
                id        : cryptSkipButton
                text      : 'Skip'
                icon.name : 'go-next-skip'
                onClicked : {
                    nextPageFn();
                }
            }

            Controls.Button {
                id        : cryptActionButton
                onClicked : {
                    takeActionFn();
                }
            }
        }
    }
    // == . END Views =================================================

    // == BEGIN Controllers ===========================================
    function removeSidebarItemFn(js_id) {
        for ( var i = 0;i < sidebarModel.count;i++ ) {
            if ( sidebarModel.get(i).jsId === js_id ) {
                sidebarModel.remove(i);
                break;
            }
        }
    }

    function switchPageFn(page_id) {
        pageStack.clear();

        switch(page_id) {
        case 'introductionItem':
            pageTitleText     = 'Introduction';
            frontImage.source = imgDir + 'frontpage.webp';
            frontHeading.text = 'Welcome To The Kubuntu Focus!';
            frontText.text
              = '<b>This Welcome Wizard helps you get '
              + 'started as quickly as possible.</b> We have included '
              + 'many tools we feel most developers should '
              + 'consider.<br>'
              + '<br>'
              + '<b>This is not an endorsement of any product,</b> and '
              + 'the Focus Team is not compensated in any way for '
              + 'these suggestions. You may always run this wizard '
              + 'later using Start Menu > Kubuntu Focus > Welcome Wizard '
              + 'or visit the <a href="https://kfocus.org/wf/tools#wizard">'
              + 'documentation.</a>'
              ;
            actionName        = 'nextPage';
            regenUiFn( frontTemplatePage, true );
            break;

        case 'internetCheckItem':
            initPage([topHeading, busyIndicator]);

            topHeading.text = 'Checking for Internet connectivity...';
            regenUiFn( baseTemplatePage, false );
            break;

        case 'connectInternetItem':
            initPage([
              headerHighlightRect, interTopHeading,
              instructionsText,    interSkipButton,
              interActionButton,   pictureColumn
            ]);

            pageTitleImage            = imgDir + 'network_disconnect.svg';
            headerHighlightRect.color = '#ff9900';
            interTopHeading.text      = 'Please Connect to the Internet';
            instructionsText.text
              = '<b>The system is not currently '
              + 'connected to the Internet.</b> Please connect to '
              + 'complete this step.<br>'
              + '<br>'
              + '<b>1. Click on the network icon</b> in the system '
              + 'tray to see a list of available connections.<br>'
              + '<br>'
              + '<b>2. Click the "Connect" button</b> on the network '
              + 'you wish to connect to.<br>'
              + '<br>'
              + '<b>3. If necessary, enter your Wi-Fi password</b> and '
              + 'press Enter to connect to the network.<br>'
              + '<br>'
              + '<b>Click on the "Continue" button when finished.</b> '
              + 'If the connection is not established, you will be '
              + 'returned to this page.<br>'
              + '<br>'
              + '<b>If you cannot connect, click Skip</b> to move to '
              + 'the next step.'
              ;
            interImageList = [
              'network_disconnect.svg',
              'network_button_pointer.svg',
              'network_connect_dialog.svg'
            ];
            interActionButton.text      = 'Continue';
            interActionButton.icon.name = 'arrow-right';
            regenUiFn( interTemplatePage, false );
            actionName = 'checkNetwork';
            break;

        case 'diskPassphraseItem':
            initPage([
              topImage,    topHeading,
              primaryText, actionButton,
              skipButton,  previousButton
            ]);

            pageTitleText   = getCryptDiskTextFn('Disk Passphrase');
            topImage.source = imgDir + 'encrypted_drive.svg';
            topHeading.text = 'Check Disk Encryption Security';
            primaryText.text
              = '<b>The wizard has detected '
              + getCryptDiskTextFn('1 encrypted disk')
              + '</b> on this system. If you bought a system with disk '
              + 'encryption enabled and you have yet to change the '
              + getCryptDiskTextFn('passphrase')
              + ', you should do so now. Otherwise, you can skip this '
              + 'step.<br>'
              + '<br>'
              + '<b>You may check '
              + getCryptDiskTextFn('this disk')
              + ' for the default password now.</b> As a security '
              + 'measure, this app will not perform this check until '
              + 'you enter your valid user password.'
              ;
            actionButton.text      = 'Check Disk Passphrases Now';
            actionButton.icon.name = 'lock';
            actionName             = 'checkCrypt';
            regenUiFn( baseTemplatePage, true );
            break;

        case 'diskPassphraseCheckerItem':
            initPage([topHeading, busyIndicator]);

            pageTitleText   = getCryptDiskTextFn('Disk Passphrase');
            pageTitleImage  = imgDir + 'encrypted_drive.svg';
            topHeading.text
              = 'Checking Disk Encryption Security...\n'
              + 'This might take a minute.';
            regenUiFn( baseTemplatePage, false );
            break;

        case 'diskPassphraseChangeInProgressItem':
            initPage([topHeading, busyIndicator]);

            pageTitleText   = getCryptDiskTextFn('Disk Passphrase');
            pageTitleImage  = imgDir + 'encrypted_drive.svg';
            topHeading.text
              = 'Changing Disk Passphrases...\n'
              + 'This might take a minute.';
            regenUiFn( baseTemplatePage, false );
            break;

        case 'diskPassphraseChangeItem':
            pageTitleText            = getCryptDiskTextFn('Disk Passphrase');
            pageTitleImage           = imgDir + 'encrypted_drive.svg';
            cryptHighlightRect.color = '#ff9900';
            cryptTopHeading.text
              = 'Change Passphrase for '
              + getCryptDiskTextFn('1 Encrypted Disk');
            cryptInstructionsText.text
              = '<b>'
              + getCryptDiskTextFn('This disk is')
              + ' using the default passphrase.</b> This is insecure, '
              + 'and we recommend you use the form below to change '
              + getCryptDiskTextFn('it')
              + ' to a unique passphrase. <b>IMPORTANT:</b> All disks using '
              + 'the default passphrase will be changed to use the new '
              + 'passphrase.</b>'
            cryptSecondaryText.text
              = '<b>Please keep a copy of '
              + 'your passphrase</b> in a safe place. If this is lost, '
              + 'there is no recovery except to reformat your disks '
              + 'and restore from backup.<br>'
              + '<br>'
              + '<b>For your security</b>, the Kubuntu Focus Team does NOT '
              + 'install tools that could assist in any recovery. '
              + 'In other words, if you lose your password, they have no '
              + 'way to help you recover it!'
              ;
            cryptActionButton.text      = 'Continue';
            cryptActionButton.icon.name = 'arrow-right';
            actionName                  = 'changeCrypt';
            regenUiFn( cryptTemplatePage, false );
            break;

        case 'diskPassphraseGoodItem':
            initPage([
              headerHighlightRect, interTopHeading,
              instructionsText,    pictureColumn,
              interActionButton
            ]);

            pageTitleText             = getCryptDiskTextFn('Disk Passphrase');
            pageTitleImage            = imgDir + 'encrypted_drive.svg';
            interImageList            = [ 'finished.svg' ];
            headerHighlightRect.color = '#27ae60';
            interTopHeading.text
              = 'Disk Encryption Passphrases Appear Secure';
            instructionsText.text
              = '<b>' + getCryptDiskTextFn( 'The encrypted disk uses' )
              + ' a unique passphrase.</b><br>'
              + '<br>'
              + '<b>Please keep a copy of your passphrase in a safe '
              + 'place.</b> If this is lost, there is no recovery '
              + 'except to reformat your disks and restore from '
              + 'backup.<br>'
              + '<br>'
              + '<b>For your security, the Kubuntu Focus Team does NOT '
              + 'install tools</b> that could assist in any recovery.'
              ;
            interActionButton.text      = 'Continue';
            interActionButton.icon.name = 'arrow-right';
            actionName                  = 'nextPage';
            regenUiFn( interTemplatePage, false) ;
            break;

        case 'extraSoftwareItem':
            initPage([
              topImage,       topHeading,
              primaryText,    actionButton,
              previousButton, skipButton
            ]);

            pageTitleText   = 'Extra Software';
            topImage.source = imgDir + 'extra_software.svg';
            topHeading.text
              = 'Install MS Fonts, VirtualBox Extensions, and More';
            primaryText.text
              = '<b>Some software is restricted,</b> '
              + 'meaning you have to approve certain agreements before '
              + 'you install it. We recommend you at least install the '
              + 'MS fonts to assist in compatibility. If you use '
              + 'VirtualBox, we also recommend adding the VirtualBox '
              + 'Extension Pack.<br>'
              + '<br>'
              + 'You may always revisit this later using <b>Start Menu '
              + '> Kubuntu Focus Tools > Extra Software Installer.</b>'
              ;
            actionButton.text      = 'Install Extra Software Now';
            actionButton.icon.name = 'arrow-right';
            actionName             = 'checkNetwork';
            networkReturnAction    = 'installExtraSoftware';
            regenUiFn( baseTemplatePage, true );
            break;

        case 'extraSoftwareInstallItem':
            initPage([
              headerHighlightRect, interTopHeading,
              instructionsText,    interActionButton,
              pictureColumn,       interContinueLabel
            ]);

            pageTitleText             = 'Extra Software';
            pageTitleImage            = imgDir + 'extra_software.svg';
            headerHighlightRect.color = '#27ae60';
            interTopHeading.text      = 'Proceed with Terminal...';
            instructionsText.text
              = '<b>1. You should now see</b> a '
              + 'terminal as shown at right with a prompt for '
              + 'installation. Please enter your password to '
              + 'proceed.<br>'
              + '<br>'
              + '<b>2. As you follow the steps,</b> you will be '
              + 'prompted to accept license terms. If you do not '
              + 'agree with the terms for a particular software '
              + 'component, you may skip installing it.'
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

        case 'fileBackupItem':
            initPage([
              topImage,       topHeading,
              primaryText,    actionButton,
              previousButton, skipButton
            ]);

            pageTitleText   = 'File Backup';
            topImage.source = imgDir + 'file_backup.svg';
            topHeading.text = 'Snapshot and Recover Files';
            primaryText.text
              = '<b>BackInTime takes snapshots of your home '
              + 'directory</b> so you can recover information that was '
              + 'later changed or removed. We\'ve configured it to '
              + 'ignore folders where cloud drives and software repos '
              + 'are usually located.<br>'
              + '<br>'
              + '<b>See more in the</b> '
              + '<a href="https://kfocus.org/wf/backup">Backups Guided '
              + 'Solution.</a>'
              ;
            actionButton.text      = 'Launch BackInTime Now';
            actionButton.icon.name = 'arrow-right';
            actionName             = 'launchBackInTime';
            regenUiFn( baseTemplatePage, true );
            break;

        case 'fileBackupLaunchedItem':
            initPage([
              headerHighlightRect, interTopHeading,
              instructionsText,    interActionButton,
              pictureColumn,       interContinueLabel
            ]);

            pageTitleText             = 'File Backup';
            pageTitleImage            = imgDir + 'file_backup.svg';
            headerHighlightRect.color = '#27ae60';
            interTopHeading.text      = 'Proceed with BackInTime...';
            instructionsText.text
              = '<b>1. If BackInTime is not '
              + 'installed,</b> you will be asked to install it, and '
              + 'will need to provide your password to do so.<br>'
              + '<br>'
              + '<b>2. Once installed, the BackInTime app</b> should '
              + 'appear as shown.<br>'
              + '<br>'
              + '<b>3. Take snapshots with the Disk icon.</b> You may '
              + 'also browse snapshots on the left (4), select files '
              + 'on the right (5), and adjust settings (6).<br>'
              + '<br>'
              + '<b>See more in the</b> '
              + '<a href="https://kfocus.org/wf/backup">Backups Guided '
              + 'Solution.</a>'
              ;
            interActionButton.text      = 'Continue';
            interActionButton.icon.name = 'arrow-right';
            interImageList = [
              'kfocus_mime_backintime.svg',
              'backintime_ui.svg'
            ];
            actionName = 'nextPage';
            regenUiFn( interTemplatePage, false );
            break;

        case 'passwordManagerItem':
            initPage([
              topImage,       topHeading,
              primaryText,    actionButton,
              previousButton, skipButton
            ]);

            pageTitleText   = 'Password Manager';
            topImage.source = imgDir + 'keepassxc_logo.svg';
            topHeading.text = 'Generate, Save, and View Secrets';
            primaryText.text
              = 'KeePassXC is a powerful password manager and generator '
              + 'that takes the hassle out of staying secure. It saves your '
              + 'passwords offline and in an encrypted form, avoiding the '
              + 'security issues of cloud-based password managers and keeping '
              + 'you safe even if your computer is stolen.'
              + '<br><br>'
              + '<b>See more in the</b> '
              + '<a href="https://kfocus.org/wf/passwords">Passwords Guided '
              + 'Solution.</a>'
              ;
            actionButton.text      = 'Launch KeePassXC Now';
            actionButton.icon.name = 'arrow-right';
            actionName             = 'launchKeePassXC';
            regenUiFn( baseTemplatePage, true );
            break;

        case 'passwordManagerLaunchedItem':
            initPage([
              headerHighlightRect, interTopHeading,
              instructionsText,    interActionButton,
              pictureColumn,       interContinueLabel
            ]);

            pageTitleText             = 'Password Manager';
            pageTitleImage            = imgDir + 'keepassxc_logo.svg';
            headerHighlightRect.color = '#27ae60';
            interTopHeading.text      = 'Proceed with KeePassXC...'
            instructionsText.text
              = '<b>1. If KeePassXC is not installed,</b> you will be asked '
              + 'to install it, and will need to provide your password to do '
              + 'so.<br>'
              + '<br>'
              + '<b>2. Once installed,</b> you may need to click on the icon '
              + 'in the system tray as shown.<br>'
              + '<br>'
              + '<b>3. The main window should then appear.</b> From here, '
              + 'you can create a new vault to start managing passwords.<br>'
              + '<br>'
              + '<b>See more in the</b> '
              + '<a href="https://kfocus.org/wf/passwords#bkm_keepassxc">'
              + 'Passwords Guided Solution</a> and the '
              + '<a href="https://keepassxc.org/docs/">official '
              + 'documentation.</a>'
              ;
            interActionButton.text      = 'Continue';
            interActionButton.icon.name = 'arrow-right';
            interImageList = [
              'kfocus_mime_keepassxc.svg',
              'keepassxc_systray.svg',
              'keepassxc_ui.png'
            ];
            actionName = 'nextPage';
            regenUiFn( interTemplatePage, false );
            break;

        case 'emailCalendarItem':
            initPage([
              topImage,       topHeading,
              primaryText,    actionButton,
              previousButton, skipButton
            ]);

            pageTitleText   = 'Email';
            topImage.source = imgDir + 'thunderbird_logo.svg';
            topHeading.text = 'Manage Emails, Calendar, and Contacts';
            primaryText.text
              = 'Thunderbird is a fast, convenient, and powerful email '
              + 'client. It provides privacy and security features not '
              + 'generally found in webmail systems, and works with many '
              + 'email providers such as GMail and Yahoo. It can be used '
              + 'with multiple email accounts at once, letting you see '
              + 'all your mail in one place.'
              + '<br><br>'
              + '<b>See more in the</b> '
              + '<a href="https://kfocus.org/wf/email">Email Guided '
              + 'Solution.</a>'
              ;
            actionButton.text      = 'Launch Thunderbird Now';
            actionButton.icon.name = 'arrow-right';
            actionName             = 'checkNetwork';
            networkReturnAction    = 'launchThunderbird';
            regenUiFn( baseTemplatePage, true );
            break;

        case 'emailCalendarLaunchedItem':
            initPage([
              headerHighlightRect, interTopHeading,
              instructionsText,    interActionButton,
              pictureColumn,       interContinueLabel
            ]);

            pageTitleText             = 'Email';
            pageTitleImage            = imgDir + 'thunderbird_logo.svg'
            headerHighlightRect.color = '#27ae60';
            interTopHeading.text      = 'Proceed with Thunderbird...';
            instructionsText.text
              = '<b>1. If Thunderbird is not installed,</b> you will be '
              + 'asked to install it, and will need to provide your password '
              + 'to do so.<br>'
              + '<br>'
              + '<b>2. Once installed,</b> the Thunderbird app should appear '
              + 'as shown.<br>'
              + '<br>'
              + '<b>3. Connect your email account</b> by entering your name, '
              + 'email address, and password into the Account Setup '
              + 'screen.<br>'
              + '<br>'
              + '<b>See more in the</b> '
              + '<a href="https://kfocus.org/wf/email.html">Email Guided '
              + 'Solution.</a> There, you will find how to set up calendars, '
              + 'contacts, and more.'
              ;
            interActionButton.text      = 'Continue';
            interActionButton.icon.name = 'arrow-right';
            interImageList = [
              'kfocus_mime_thunderbird.svg',
              'thunderbird_ui.png'
            ];
            actionName = 'nextPage';
            regenUiFn( interTemplatePage, false );
            break;

        case 'dropboxItem':
            initPage([
              topImage,       topHeading,
              primaryText,    actionButton,
              previousButton, skipButton
            ]);

            pageTitleText   = 'Dropbox';
            topImage.source = imgDir + 'dropbox_logo.svg';
            topHeading.text = 'Access Your Files From Anywhere';
            primaryText.text
              = '<b>Dropbox is a fast, flexible cloud storage system</b> '
              + 'that automatically keeps your files synced to your computer '
              + 'for offline access. You can use it to keep backups, archive '
              + 'old data, access files from multiple computers, and more. '
              + 'Up to 2 GB of data can be stored for free, and additional '
              + 'storage is quite affordable.<br>'
              + '<br>'
              + '<b>See more in the</b> '
              + '<a href="https://kfocus.org/wf/drives.html">Cloud Drives '
              + 'Guided Solution.</a>'
              ;
            actionButton.text      = 'Launch Dropbox Now';
            actionButton.icon.name = 'arrow-right';
            actionName             = 'checkNetwork';
            networkReturnAction    = 'launchDropbox';
            regenUiFn( baseTemplatePage, true );
            break;

        case 'dropboxLaunchedItem':
            initPage([
              headerHighlightRect, interTopHeading,
              instructionsText,    interActionButton,
              pictureColumn,       interContinueLabel
            ]);

            pageTitleText             = 'Dropbox';
            pageTitleImage            = imgDir + 'dropbox_logo.svg';
            headerHighlightRect.color = '#27ae60';
            interTopHeading.text      = 'Proceed with Dropbox...';
            instructionsText.text
              = '<b>1. If Dropbox is not installed,</b> you will be asked to '
              + 'install it, and will need to provide your password to do '
              + 'so.<br>'
              + '<br>'
              + '<b>2. Once installed,</b> you may need to click on the icon '
              + 'in the system tray as shown.<br>'
              + '<br>'
              + '<b>3. Create a new Dropbox account or log into your '
              + 'existing one</b> in the browser window that pops up.<br>'
              + '<br>'
              + '<b>See more in the</b> '
              + '<a href="https://kfocus.org/wf/drives.html">Cloud Drives '
              + 'Guided Solution.</a>'
              ;
            interActionButton.text      = 'Continue'
            interActionButton.icon.name = 'arrow-right';
            interImageList = [
              'kfocus_mime_dropbox.svg',
              'dropbox_systray.svg',
              'dropbox_ui.png'
            ];
            actionName = 'nextPage';
            regenUiFn( interTemplatePage, false );
            break;

        case 'insyncItem':
            initPage([
              topImage,       topHeading,
              primaryText,    actionButton,
              previousButton, skipButton
            ]);

            pageTitleText   = 'Insync';
            topImage.source = imgDir + 'insync_logo.svg';
            topHeading.text = 'Manage Cloud Drives Easily';
            primaryText.text
              = '<b>Insync is a cloud storage synchronizer</b> that works '
              + 'with Google Drive, OneDrive, and Dropbox. It is '
              + 'significantly more powerful than other cloud drive '
              + 'synchronizers, and can work with multiple cloud drive '
              + 'accounts at the same time. It comes with a free trial '
              + 'period and offers both subscription and one-time purchase '
              + 'options.<br>'
              + '<br>'
              + '<b>See more in the</b> '
              + '<a href="https://kfocus.org/wf/drives.html'
              + '#bkm_sync_with_google">Cloud Drives Guided Solution.</a>'
              ;
            actionButton.text      = 'Launch Insync Now'
            actionButton.icon.name = 'arrow-right';
            actionName             = 'checkNetwork';
            networkReturnAction    = 'launchInsync';
            regenUiFn( baseTemplatePage, true );
            break;

        case 'insyncLaunchedItem':
            initPage([
              headerHighlightRect, interTopHeading,
              instructionsText,    interActionButton,
              pictureColumn,       interContinueLabel
            ]);

            pageTitleText             = 'Insync';
            pageTitleImage            = imgDir + 'insync_logo.svg';
            headerHighlightRect.color = '#27ae60';
            interTopHeading.text      = 'Proceed with Insync...';
            instructionsText.text
              = '<b>1. If Insync is not installed,</b> you will be asked to '
              + 'install it, and will need to provide your password to do '
              + 'so.<br>'
              + '<br>'
              + 'TODO: Insert remaining steps and images.'
              ;
            interActionButton.text      = 'Continue'
            interActionButton.icon.name = 'arrow-right';
            interImageList = [
              'kfocus_mime_insync.svg'
            ];
            actionName = 'nextPage';
            regenUiFn( interTemplatePage, false );
            break;

        case 'jetbrainsToolboxItem':
            initPage([
              topImage,       topHeading,
              primaryText,    actionButton,
              previousButton, skipButton
            ]);

            pageTitleText   = 'JetBrains Toolbox';
            topImage.source = imgDir + 'jetbrains_toolbox_logo.svg';
            topHeading.text = 'Install and Manage JetBrains IDEs';
            primaryText.text
              = '<b>JetBrains Toolbox allows you to install, launch, and '
              + 'uninstall JetBrains development products</b> with just a '
              + 'few clicks. It’s the preferred tool for installing programs '
              + 'such as IntelliJ IDEA, PyCharm, and Google’s Android '
              + 'Studio. Several of JetBrains’ products have a free '
              + 'community edition, and many of their paid products have a '
              + 'free trial.<br>'
              + '<br>'
              + '<b>See more in the</b> '
              + '<a href="https://kfocus.org/wf/ide.html">IDEs Guided '
              + 'Solution.</a>'
              ;
            actionButton.text      = 'Launch JetBrains Toolbox Now';
            actionButton.icon.name = 'arrow-right';
            actionName             = 'launchJetbrainsToolbox';
            regenUiFn( baseTemplatePage, true );
            break;

        case 'jetbrainsToolboxLaunchedItem':
            initPage([
              headerHighlightRect, interTopHeading,
              instructionsText,    interActionButton,
              pictureColumn,       interContinueLabel
            ]);

            pageTitleText             = 'JetBrains Toolbox';
            pageTitleImage            = imgDir + 'jetbrains_toolbox_logo.svg';
            headerHighlightRect.color = '#27ae60';
            interTopHeading.text      = 'Proceed with JetBrains Toolbox...';
            instructionsText.text
              = '<b>1. If JetBrains Toolbox is not installed,</b> you will '
              + 'be asked to install it, and will need to provide your '
              + 'password to do so.<br>'
              + '<br>'
              + '<b>2. If you’re launching the Toolbox for the first '
              + 'time,</b> you will be asked to configure it and accept the '
              + 'JetBrains User Agreement. It may take up to 30 seconds for '
              + 'the Toolbox to launch.<br>'
              + '<br>'
              + '<b>3. Visit the System Tray</b> to interact with the Toolbox.'
              ;
            interActionButton.text      = 'Continue';
            interActionButton.icon.name = 'arrow-right';
            interImageList = [
              'kfocus_mime_jetbrains_toolbox.svg',
              'jetbrains_toolbox_ui.png',
              'jetbrains_toolbox_systray.svg'
            ];
            actionName = 'nextPage';
            regenUiFn( interTemplatePage, false );
            break;

        case 'avatarItem':
            initPage([
              topImage,       topHeading,
              primaryText,    actionButton,
              previousButton, skipButton
            ]);

            pageTitleText   = 'Avatar';
            topImage.source = imgDir + 'avatar.svg';
            topHeading.text = 'Personalize your Profile Picture';
            primaryText.text
              = '<b>Your profile picture is displayed in the Start Menu and '
              + 'on the lock screen.</b> By default, this picture is a '
              + 'Kubuntu logo, but it’s easy to change to a picture of your '
              + 'choice.<br>'
              + '<br>'
              + '<b>You may always revisit this later</b> by opening the '
              + 'Start Menu and clicking on the user avatar image in the '
              + 'upper-left corner of the menu.'
              ;
            actionButton.text      = 'Change Your Avatar Now';
            actionButton.icon.name = 'arrow-right';
            actionName             = 'changeAvatar';
            regenUiFn( baseTemplatePage, true );
            break;

        case 'avatarChangeItem':
            initPage([
              headerHighlightRect, interTopHeading,
              instructionsText,    interActionButton,
              pictureColumn,       interContinueLabel
            ]);

            pageTitleText             = 'Avatar';
            pageTitleImage            = imgDir + 'avatar.svg';
            headerHighlightRect.color = '#27ae60';
            interTopHeading.text      = 'Proceed with User Manager...';
            instructionsText.text
              = '<b>1. Click on the profile picture</b> in the User Manager '
              + 'interface.<br>'
              + '<br>'
              + '<b>2. Pick one of the preinstalled avatars,</b> or click '
              + '“Choose File” to use a custom avatar.<br>'
              + '<br>'
              + '<b>3. Click “Apply” and provide your password</b> to change '
              + 'your avatar.'
              ;
            interActionButton.text      = 'Continue';
            interActionButton.icon.name = 'arrow-right';
            interImageList = [
              'avatar_steps.png',
              'avatar_password.png'
            ];
            actionName = 'nextPage';
            regenUiFn( interTemplatePage, false );
            break;

        case 'curatedAppsItem':
            initPage([
              topImage,       topHeading,
              primaryText,    actionButton,
              previousButton, skipButton
            ]);

            pageTitleText   = 'Curated Apps';
            topImage.source = imgDir + 'kfocus_bug_apps.svg';
            topHeading.text = 'Find and Install Apps Quickly';
            primaryText.text
              = '<b>The Kubuntu Focus team maintains a Curated Apps page</b> '
              + 'that lists recommended apps that work well with Kubuntu '
              + 'Focus computers. Click on an icon to launch an app. If it’s '
              + 'not installed, the system will install the repository and '
              + 'the package before launching it.<br>'
              + '<br>'
              + '<b>We encourage you to take a moment</b> to review the list '
              + 'of curated apps and install the ones you need now.'
              ;
            actionButton.text      = 'Browse Curated Apps Now';
            actionButton.icon.name = 'arrow-right';
            actionName             = 'checkNetwork';
            networkReturnAction    = 'browseCuratedApps';
            regenUiFn( baseTemplatePage, true );
            break;

        case 'browseCuratedAppsItem':
            initPage([
              headerHighlightRect, interTopHeading,
              instructionsText,    interActionButton,
              pictureColumn,       interContinueLabel
            ]);

            pageTitleText             = 'Curated Apps';
            pageTitleImage            = imgDir + 'kfocus_bug_apps.svg';
            headerHighlightRect.color = '#27ae60';
            interTopHeading.text      = 'Proceed with Curated Apps...';
            instructionsText.text
              = '<b>1. The Curated Apps web page</b> should now be visible '
              + 'in your default web browser.<br>'
              + '<br>'
              + '<b>2. Scroll down to the list of apps</b> and click the '
              + 'icon of the app you would like to launch.<br>'
              + '<br>'
              + '<b>3. If the app needs installed, confirm that you want to '
              + 'install it and provide your password.</b> The application '
              + 'will be installed and will automatically launch once '
              + 'installation is complete.'
              ;
            interActionButton.text      = 'Continue';
            interActionButton.icon.name = 'arrow-right';
            interImageList = [
              'curated_apps.png'
            ];
            actionName = 'nextPage';
            regenUiFn( interTemplatePage, false );
            break;

        case 'finishItem':
            initPage([
              topImage,       topHeading,
              primaryText,    actionButton,
              previousButton, loginStartCheckbox
            ]);

            pageTitleText   = 'Finish';
            topImage.source = imgDir + 'finished.svg';
            topHeading.text = 'All Done';
            primaryText.text
              = '<b>All steps are complete.</b> We hope you found this '
              + 'useful and enjoy using your system.<br>'
              + '<br>'
              + '<b>To get more help,</b> click Start Menu > Kubuntu Focus '
              + 'Tools > Help.<br>'
              + '<br>'
              + '<b>To run this wizard again,</b> click Start Menu > Kubuntu '
              + 'Focus Tools > Welcome Wizard.'
              ;
            actionButton.text      = 'Finish';
            actionButton.icon.name = 'arrow-right';
            actionName             = 'finishWizard';
            regenUiFn( baseTemplatePage, true );
            break;
        }
    }

    function initPage(visible_elements_list) {
        var all_elements_list = [
            actionButton,        busyIndicator,
            headerHighlightRect, instructionsText,
            interActionButton,   interContinueLabel,
            interSkipButton,     interTopHeading,
            loginStartCheckbox,  previousButton,
            primaryText,         skipButton,
            topHeading,          topImage
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

    function regenUiFn(current_page, sidebar_enabled) {
        if ( sidebar_enabled ) {
            pageStack.push(enabledSidebarPage);
        } else {
            disabledSidebar.currentIndex = enabledSidebar.currentIndex;
            disabledSidebarIndex = disabledSidebar.currentIndex;
            pageStack.push(disabledSidebarPage);
        }
        pageStack.push(current_page);
    }

    function getCurrentPageIdFn() {
        return sidebarModel.get(enabledSidebar.currentIndex).jsId;
    }

    function nextPageFn() {
        enabledSidebar.currentIndex++;
        switchPageFn(getCurrentPageIdFn());
    }

    function previousPageFn() {
        enabledSidebar.currentIndex--;
        switchPageFn(getCurrentPageIdFn());
    }

    function getCryptDiskTextFn(text_type) {
        if ( systemDataMap.cryptDiskList.length === 1 ) {
            return text_type;
        } else {
            switch(text_type) {
            case 'Disk Passphrase':
                return 'Disk Passphrases';

            case '1 encrypted disk':
                return systemDataMap.cryptDiskList.length + ' encrypted disks';

            case '1 Encrypted Disk':
                return systemDataMap.cryptDiskList.length + ' Encrypted Disks';

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

            case 'This disk is':
                return 'These disks are';

            case 'it':
                return 'them';
            }
        }
    }

    function getThemedIcon(icon_name) {
        if ( Kirigami.Theme.textColor.hsvValue < 0.5 ) {
            return "qrc:/assets/images/" + icon_name + "_light.svg";
        } else {
            return "qrc:/assets/images/" + icon_name + "_dark.svg";
        }
    }

    /**************
     * Logic code *
     **************/

    // Check all encrypted disks for the default passphrase
    ShellEngine {
        id          : cryptDiskCheckerEngine
        onAppExited : {
            defaultPassphraseDisks = exitCode
            if ( exitCode > 0 ) {
                switchPageFn( 'diskPassphraseChangeItem' );
            } else {
                switchPageFn( 'diskPassphraseGoodItem' );
            }
        }
    }

    // Changes the passphrase on all encrypted disks that use the default
    ShellEngine {
        id          : cryptDiskChangeEngine
        onAppExited : {
            switchPageFn( 'diskPassphraseGoodItem' );
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

    // Used for shell commands that don't require a callback
    ShellEngine { id : exeRun }

    // BEGIN takeActionFn
    // Purpose : Provide controls for click handlers and other events
    function takeActionFn() {
        switch ( actionName ) {
        case 'nextPage':
            nextPageFn();
            break;

        case 'previousPage':
            previousPageFn();
            break;

        case 'checkNetwork':
            internetCheckerEngine.exec('ping -c 1 8.8.8.8');
            switchPageFn( 'internetCheckItem' );
            break;

        case 'checkCrypt':
            cryptDiskCheckerEngine.exec(
              systemDataMap.binDir + 'kfocus-check-crypt -c '
              + systemDataMap.cryptDiskList.join( ' ' ) );
            switchPageFn( 'diskPassphraseCheckerItem' );
            break;

        case 'changeCrypt':
            if ( newPassphraseBox.text === confirmPassphraseBox.text ) {
                cryptDiskChangeEngine.exec(
                  systemDataMap.binDir
                  + 'kfocus-check-crypt -m '
                  + systemDataMap.cryptDiskList.join(' '),
                  'kubuntu\n'
                  + newPassphraseBox.text + '\n' );
                switchPageFn( 'diskPassphraseChangeInProgressItem' );
            } else {
                interErrorMessage.text
                  = 'The provided passphrases do not '
                    + 'match. Please try again.';
                interErrorMessage.visible = true;
            }
            break;

        case 'installExtraSoftware':
            exeRun.exec(
              'xterm -fa \'Monospace\' -fs 12 -b 28 -geometry 80x24 -T '
              + '\'Install Extras\' -xrm \'xterm*iconHint: '
              + '/usr/share/pixmaps/kfocus-bug-wizard\' -e pkexec '
              + systemDataMap.binDir + 'kfocus-extra' );
            switchPageFn( 'extraSoftwareInstallItem' );
            break;

        case 'launchBackInTime':
            exeRun.exec( systemDataMap.binDir + 'kfocus-mime -k backintime' );
            switchPageFn( 'fileBackupLaunchedItem' );
            break;

        case 'launchKeePassXC':
            exeRun.exec( systemDataMap.binDir + 'kfocus-mime -kf keepassxc' );
            switchPageFn( 'passwordManagerLaunchedItem' );
            break;

        case 'launchThunderbird':
            exeRun.exec( systemDataMap.binDir + 'kfocus-mime -k thunderbird' );
            switchPageFn( 'emailCalendarLaunchedItem' );
            break;

        case 'launchDropbox':
            exeRun.exec( systemDataMap.binDir + 'kfocus-mime -k dropbox' );
            switchPageFn( 'dropboxLaunchedItem' );
            break;

        case 'launchInsync':
            exeRun.exec( systemDataMap.binDir + 'kfocus-mime -k insync' );
            switchPageFn( 'insyncLaunchedItem' );
            break;

        case 'launchJetbrainsToolbox':
            exeRun.exec( systemDataMap.binDir
              + 'kfocus-mime -k jetbrains-toolbox-plain' );
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
                exeRun.exec(
                  'touch '
                   + systemDataMap.homeDir
                   + '/.config/kfocus-firstrun-wizard')
            }
            Qt.quit();
        }
    }

    // Kick-off rendering on completion
    Component.onCompleted: {
        if ( systemDataMap.cryptDiskList.length === 0 ) {
            removeSidebarItemFn('diskPassphraseItem');
        }
        switchPageFn('introductionItem');
    }
    // == . END Controllers ===========================================
}

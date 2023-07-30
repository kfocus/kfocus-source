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
    }

    StartupData {
        id: systemDataMap
        // cryptDiskList is provided by main.cpp
        // binDir is provided by main.cpp
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
            icon      : taskIcon
            iconSize  : Kirigami.Units.gridUnit * 1.5
            onClicked : {
                switchPageFn( jsId );
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
        }
    }
    // . END Define sidebar views

    // Template - Front Page
    Kirigami.Page {
        id: frontTemplatePage
        visible: false // Avoids a graphical glitch, DO NOT SET TO TRUE

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
                        source   : 'assets/images/' + interImageList[index]
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
            frontTemplatePage.title = 'Introduction';
            frontImage.source       = 'assets/images/frontpage.webp';
            frontHeading.text       = 'Welcome To The Kubuntu Focus!';
            frontText.text
              = '<b>This Welcome Wizard helps you get '
              + 'started as quickly as possible.</b> We have included '
              + 'many tools we feel most developers should '
              + 'consider.<br>'
              + '<br>'
              + '<b>This is not an endorsement of any product,</b> and '
              + 'the Focus Team is not compensated in any way for '
              + 'these suggestions. You may always run this wizard '
              + 'later using Start Menu > Kubuntu Focus > Welcome Wizard.';
            actionName              = 'nextPage';
            regenUiFn(frontTemplatePage, true);
            break;

        case 'internetCheckItem':
            initPage([topHeading, busyIndicator]);
            topHeading.text = "Checking for Internet connectivity...";
            regenUiFn(baseTemplatePage, false);
            break;

        case 'connectInternetItem':
            initPage([
              headerHighlightRect, interTopHeading,
              instructionsText,    interSkipButton,
              interActionButton,   pictureColumn
            ]);

            interTemplatePage.title   = baseTemplatePage.title;
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
              + 'the next step.';
            interImageList = [
              'network_disconnect.svg',
              'network_button_pointer.svg',
              'network_connect_dialog.svg'
            ];
            interActionButton.text      = 'Continue';
            interActionButton.icon.name = 'arrow-right';
            regenUiFn(interTemplatePage, false);

            actionName = 'checkNetwork';
            break;

        case 'diskPassphraseItem':
            initPage([
              topImage,    topHeading,
              primaryText, actionButton,
              skipButton,  previousButton
            ]);

            baseTemplatePage.title = getCryptDiskTextFn('Disk Passphrase');
            topImage.source        = 'assets/images/encrypted_drive.svg';
            topHeading.text        = 'Check Disk Encryption Security';
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
              + 'you enter your valid user password.';
            actionButton.text      = 'Check Disk Passphrases Now';
            actionButton.icon.name = 'lock';
            actionName             = 'checkCrypt';
            regenUiFn(baseTemplatePage, true);
            break;

        case 'diskPassphraseCheckerItem':
            initPage([topHeading, busyIndicator]);
            baseTemplatePage.title = getCryptDiskTextFn('Disk Passphrase');
            topHeading.text        = 'Checking Disk Encryption Security...\n'
              + 'This might take a minute.';
            regenUiFn(baseTemplatePage, false);
            break;

        case 'diskPassphraseChangeInProgressItem':
            initPage([topHeading, busyIndicator]);

            baseTemplatePage.title = getCryptDiskTextFn('Disk Passphrase');
            topHeading.text        = 'Changing Disk Passphrases...\n'
              + 'This might take a minute.';
            regenUiFn(baseTemplatePage, false);
            break;

        case 'diskPassphraseChangeItem':
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
              + ' now.';
            cryptSecondaryText.text
              = '<b>Please keep a copy of '
              + 'your passphrase in a safe place.</b> If this is lost, '
              + 'there is no recovery except to reformat your disks '
              + 'and restore from backup.<br>'
              + '<br>'
              + '<b>For your security, the Kubuntu Focus Team does NOT '
              + 'install tools</b> that could assist in any recovery.';
            cryptActionButton.text      = 'Continue';
            cryptActionButton.icon.name = 'arrow-right';
            actionName                  = 'changeCrypt';
            regenUiFn(cryptTemplatePage, false);
            break;

        case 'diskPassphraseGoodItem':
            initPage([
              headerHighlightRect, interTopHeading,
              instructionsText,    pictureColumn,
              interActionButton
            ]);

            interTemplatePage.title   = getCryptDiskTextFn('Disk Passphrase');
            interImageList            = [ 'finished.svg' ];
            headerHighlightRect.color = '#27ae60';
            interTopHeading.text      = 'Disk Encryption Passphrases Appear Secure';
            instructionsText.text
              = '<b>'
              + getCryptDiskTextFn('The encrypted disk uses')
              + ' a non-default passphrase.</b><br>'
              + '<br>'
              + '<b>Please keep a copy of your passphrase in a safe '
              + 'place.</b> If this is lost, there is no recovery '
              + 'except to reformat your disks and restore from '
              + 'backup.<br>'
              + '<br>'
              + '<b>For your security, the Kubuntu Focus Team does NOT '
              + 'install tools</b> that could assist in any recovery.';
            interActionButton.text      = 'Continue';
            interActionButton.icon.name = 'arrow-right';
            actionName                  = 'nextPage';
            regenUiFn(interTemplatePage, false);
            break;

        case 'extraSoftwareItem':
            initPage([
              topImage,       topHeading,
              primaryText,    actionButton,
              previousButton, skipButton
            ]);

            baseTemplatePage.title = 'Extra Software';
            topImage.source        = 'assets/images/extra_software.svg';
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
              + '> Kubuntu Focus Tools > Extra Software Installer.</b>';
            actionButton.text      = 'Install Extra Software Now';
            actionButton.icon.name = 'arrow-right';
            actionName             = 'checkNetwork';
            networkReturnPage      = 'extraSoftwareInstallItem';
            networkReturnAction    = 'installExtraSoftware';
            regenUiFn(baseTemplatePage, true);
            break;

        case 'extraSoftwareInstallItem':
            initPage([
              headerHighlightRect, interTopHeading,
              instructionsText,    interActionButton,
              pictureColumn,       interContinueLabel
            ]);

            interTemplatePage.title   = 'Extra Software';
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
              + 'component, you may skip installing it.';
            interActionButton.text      = 'Continue';
            interActionButton.icon.name = 'arrow-right';

            interImageList = [
              'extra_software_terminal.png',
              'extra_software_license.svg'
            ];
            actionName = 'nextPage';
            regenUiFn(interTemplatePage, false);
            break;

        case 'fileBackupItem':
            initPage([
              topImage,       topHeading,
              primaryText,    actionButton,
              previousButton, skipButton
            ]);

            baseTemplatePage.title = 'File Backup';
            topImage.source        = 'assets/images/file_backup.svg';
            topHeading.text        = 'Snapshot and Recover Files';
            primaryText.text
              = '<b>BackInTime takes snapshots of your home '
              + 'directory</b> so you can recover information that was '
              + 'later changed or removed. We\'ve configured it to '
              + 'ignore folders where cloud drives and software repos '
              + 'are usually located.<br>'
              + '<br>'
              + '<b>See more in the</b> '
              + '<a href="https://kfocus.org/wf/backup">Backups Guided '
              + 'Solution.</a>';
            actionButton.text      = 'Launch BackInTime Now';
            actionButton.icon.name = 'arrow-right';
            actionName             = 'launchBackInTime';
            regenUiFn(baseTemplatePage, true);
            break;

        case 'fileBackupLaunchedItem':
            initPage([
              headerHighlightRect, interTopHeading,
              instructionsText,    interActionButton,
              pictureColumn,       interContinueLabel
            ]);

            interTemplatePage.title   = 'File Backup';
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
              + 'Solution.</a>';
            interActionButton.text      = 'Continue';
            interActionButton.icon.name = 'arrow-right';
            interImageList = [
              'kfocus_mime_backintime.svg',
              'backintime_ui.svg'
            ];
            actionName = 'nextPage';
            regenUiFn(interTemplatePage, false);
            break;

        case 'passwordManagerItem':
            initPage([
              topImage,       topHeading,
              primaryText,    actionButton,
              previousButton, skipButton
            ]);

            baseTemplatePage.title = 'Password Manager';
            topImage.source        = 'assets/images/keepassxc_logo.svg';
            topHeading.text        = 'Generate, Save, and View Secrets';
            primaryText.text
              = 'KeePassXC is a powerful password manager and generator '
              + 'that takes the hassle out of staying secure. It saves your'
              + 'passwords offline and in an encrypted form, avoiding the'
              + 'security issues of cloud-based password managers and keeping'
              + 'you safe even if your computer is stolen.'
              + '<br><br>'
              + '<b>See more in the</b> '
              + '<a href="https://kfocus.org/wf/passwords">Passwords Guided '
              + 'Solution.</a>';
            actionButton.text      = 'Launch KeePassXC Now';
            actionButton.icon.name = 'arrow-right';
            actionName             = 'launchKeePassXC';
            regenUiFn(baseTemplatePage, true);
            break;

        case 'passwordManagerLaunchedItem':
            initPage([
              headerHighlightRect, interTopHeading,
              instructionsText,    interActionButton,
              pictureColumn,       interContinueLabel
            ]);

            interTemplatePage.title   = 'Password Manager';
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
              + 'documentation.</a>';
            interActionButton.text      = 'Continue';
            interActionButton.icon.name = 'arrow-right';
            interImageList = [
              'kfocus_mime_keepassxc.svg',
              'keepassxc_systray.svg',
              'keepassxc_ui.png'
            ];
            actionName = 'nextPage';
            regenUiFn(interTemplatePage, false);
            break;

        case 'emailCalendarItem':
            initPage([
              topImage,       topHeading,
              primaryText,    actionButton,
              previousButton, skipButton
            ]);

            baseTemplatePage.title = 'Email';
            topImage.source        = 'assets/images/thunderbird_logo.svg';
            topHeading.text        = 'Manage Emails, Calendar, and Contacts';
            primaryText.text
              = 'Thunderbird is a fast, convenient, and powerful email'
              + 'client. It provides privacy and security features not'
              + 'generally found in webmail systems, and works with many'
              + 'email providers such as GMail and Yahoo. It can be used'
              + 'with multiple email accounts at once, letting you see'
              + 'all your mail in one place.'
              + '<br><br>'
              + '<b>See more in the</b> '
              + '<a href="https://kfocus.org/wf/email">Email Guided '
              + 'Solution.</a>';
            actionButton.text      = 'Launch Thunderbird Now';
            actionButton.icon.name = 'arrow-right';
            actionName             = 'launchThunderbird';
            regenUiFn(baseTemplatePage, true);
            break;
        }
    }

    function initPage(visible_elements_list) {
        var all_elements_list = [
            actionButton,         busyIndicator,
            headerHighlightRect,  instructionsText,
            interActionButton,    interContinueLabel,
            interSkipButton,      interTopHeading,
            previousButton,       primaryText,
            skipButton,           topHeading,
            topImage
        ];
        var i;

        for ( i = 0; i < all_elements_list.length; i++ ) {
          all_elements_list[i].visible = false;
        }

        interImageList = [];
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

    /**************
     * Logic code *
     **************/

    // Check all encrypted disks for the default passphrase

    ShellEngine {
        id          : cryptDiskCheckerEngine
        onAppExited : {
            defaultPassphraseDisks = exitCode
            if ( exitCode > 0 ) {
                switchPageFn('diskPassphraseChangeItem');
            } else {
                switchPageFn('diskPassphraseGoodItem');
            }
        }
    }

    // Changes the passphrase on all encrypted disks that use the default

    ShellEngine {
        id          : cryptDiskChangeEngine
        onAppExited : {
            switchPageFn('diskPassphraseGoodItem');
        }
    }

    // Used for checking for a network connection
    ShellEngine {
        id          : internetCheckerEngine
        onAppExited : {
            if ( exitCode === 0 ) {
                actionName = networkReturnAction;
                takeActionFn();
                switchPageFn(networkReturnPage);
            } else {
                switchPageFn('connectInternetItem');
            }
        }
    }

    /* Anything that doesn't require a callback on exit is run with this
       engine */

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
            switchPageFn('internetCheckItem');
            break;

        case 'checkCrypt':
            cryptDiskCheckerEngine.exec(
              systemDataMap.binDir + 'kfocus-check-crypt -c ' +
              systemDataMap.cryptDiskList.join(' '));
            switchPageFn('diskPassphraseCheckerItem');
            break;

        case 'changeCrypt':
            if ( newPassphraseBox.text === confirmPassphraseBox.text ) {
                cryptDiskChangeEngine.exec(
                  systemDataMap.binDir
                  + 'kfocus-check-crypt -m '
                  + systemDataMap.cryptDiskList.join(' '),
                  'kubuntu\n'
                  + newPassphraseBox.text + '\n');
                switchPageFn('diskPassphraseChangeInProgressItem');
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
              + systemDataMap.binDir + 'kfocus-extra');
            break;

        case 'launchBackInTime':
            exeRun.exec('kfocus-mime -k backintime');
            switchPageFn('fileBackupLaunchedItem');
            break;

        case 'launchKeePassXC':
            exeRun.exec('kfocus-mime -k keepassxc');
            switchPageFn('passwordManagerLaunchedItem');
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

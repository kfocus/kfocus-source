import QtQuick 2.6
import QtQuick.Controls 2.0 as Controls
import QtQuick.Layouts 1.2
import QtQuick.Window 2.2
import org.kde.kirigami 2.15 as Kirigami
import shellengine 1.0

Kirigami.ApplicationWindow {
    id: root
    title: "Kubuntu Focus Welcome Wizard"
    width: Kirigami.Units.gridUnit * 38
    height: Kirigami.Units.gridUnit * 25

    pageStack.defaultColumnWidth: Kirigami.Units.gridUnit * 10
    pageStack.initialPage: [ sidebarPage ]

    /***************
     * Constructor *
     ***************/

    Component.onCompleted: {
        switchPage("introductionItem")
    }

    /***********
     * Sidebar *
     ***********/

    Kirigami.ScrollablePage {
        id: sidebarPage
        visible: false // Avoids a graphical glitch, DO NOT SET TO TRUE

        ListView {
            id: stepsList
            model: stepsModel
            delegate: stepsEnabledDelegate
        }
    }

    Kirigami.ScrollablePage {
        id: disabledSidebarPage
        visible: false // Avoids a graphical glitch, DO NOT SET TO TRUE

        ListView {
            id: disabledStepsList
            model: stepsModel
            delegate: stepsDisabledDelegate
        }
    }

    ListModel {
        id: stepsModel

        ListElement {
            jsId: "introductionItem"
            task: "Introduction"
            taskIcon: "user-home-symbolic"
        }
        ListElement {
            jsId: "diskPassphraseItem"
            task: "Disk Passphrase"
            taskIcon: "lock"
        }
        ListElement {
            jsId: "extraSoftwareItem"
            task: "Extra Software"
            taskIcon: "install"
        }
        ListElement {
            jsId: "fileBackupItem"
            task: "File Backup"
            taskIcon: "backup"
        }
    }

    Component {
        id: stepsEnabledDelegate

        Kirigami.BasicListItem {
            label: task
            icon: taskIcon
            iconSize: Kirigami.Units.gridUnit * 1.5
            onClicked: switchPage(jsId)
        }
    }

    Component {
        id: stepsDisabledDelegate

        Kirigami.BasicListItem {
            label: task
            icon: taskIcon
            iconSize: Kirigami.Units.gridUnit * 1.5
            fadeContent: true
            onClicked: disabledStepsList.currentIndex = stepsListLockIndex
        }
    }

    /***************************
     * Template - Normal Pages *
     ***************************/

    Kirigami.Page {
        id: baseTemplatePage
        visible: false // Avoids a graphical glitch, DO NOT SET TO TRUE

        ColumnLayout {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }

            Image {
                id: topImage
                fillMode: Image.PreserveAspectFit
                height: Kirigami.Units.gridUnit * 5
                Layout.bottomMargin: Kirigami.Units.gridUnit
                Layout.alignment: Qt.AlignHCenter
            }

            Kirigami.Heading {
                id: topHeading
                horizontalAlignment: Text.AlignHCenter
                Layout.bottomMargin: Kirigami.Units.gridUnit
                Layout.alignment: Qt.AlignHCenter
            }

            Controls.BusyIndicator {
                id: busyIndicator
                running: true
                Layout.alignment: Qt.AlignHCenter
            }

            Controls.Label {
                id: primaryText
                wrapMode: Text.WordWrap
                onLinkActivated: Qt.openUrlExternally(link)
                Layout.fillWidth: true
                Layout.bottomMargin: Kirigami.Units.gridUnit
            }
        }

        Controls.Button {
            id: previousButton

            anchors {
                left: parent.left
                bottom: parent.bottom
            }

            text: "Previous"
            icon.name: "arrow-left"
            onClicked: previousPage()
        }

        RowLayout {
            anchors {
                right: parent.right
                bottom: parent.bottom
            }

            Controls.Button {
                id: actionButton
                onClicked: takeAction()
            }

            Controls.Button {
                id: skipButton

                text: "Skip"
                icon.name: "go-next-skip"
                onClicked: nextPage()
            }
        }
    }

    /*********************************
     * Template - Interstitial Pages *
     *********************************/

    Kirigami.Page {
        id: interTemplatePage
        visible: false // Avoids a graphical glitch, DO NOT SET TO TRUE

        Rectangle {
            id: headerHighlightRect

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }

            radius: 5
            height: Kirigami.Units.gridUnit * 2
        }

        Kirigami.Heading {
            id: interTopHeading

            anchors {
                left: headerHighlightRect.left
                right: headerHighlightRect.right
                top: headerHighlightRect.top
                bottom: headerHighlightRect.bottom
                leftMargin: Kirigami.Units.gridUnit * 0.7
            }
        }

        RowLayout {
            anchors {
                top: headerHighlightRect.bottom
                right: parent.right
                left: parent.left
                bottom: parent.bottom
                topMargin: Kirigami.Units.gridUnit
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignTop

                Controls.Label {
                    id: instructionsText
                    wrapMode: Text.WordWrap
                    onLinkActivated: Qt.openUrlExternally(link)
                    Layout.fillWidth: true
                    Layout.bottomMargin: Kirigami.Units.gridUnit
                }

                GridLayout {
                    id: passphraseChangeForm

                    columns: 3
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: Kirigami.Units.gridUnit

                    Controls.Label {
                        text: "New passphrase"
                        Layout.alignment: Qt.AlignRight
                    }

                    Controls.TextField {
                        id: newPassphraseBox
                        echoMode: TextInput.Password
                    }

                    Controls.Button {
                        id: newPassphrasePeekButton
                        icon.name: "password-show-off"
                        onClicked: {
                            if(this.icon.name === "password-show-off") {
                                this.icon.name = "password-show-on"
                                newPassphraseBox.echoMode = TextInput.Normal
                                confirmPassphraseBox.echoMode = TextInput.Normal
                            } else {
                                this.icon.name = "password-show-off"
                                newPassphraseBox.echoMode = TextInput.Password
                                confirmPassphraseBox.echoMode = TextInput.Password
                            }
                        }
                    }

                    Controls.Label {
                        text: "Confirm new passphrase"
                        Layout.alignment: Qt.AlignRight
                    }

                    Controls.TextField {
                        id: confirmPassphraseBox
                        echoMode: TextInput.Password
                    }
                }

                Controls.Label {
                    id: secondaryInstructionsText
                    wrapMode: Text.WordWrap
                    onLinkActivated: Qt.openUrlExternally(link)
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignTop

                Repeater {
                    id: pictureColumn

                    model: interImageList

                    Image {
                        source: "assets/images/" + interImageList[index]
                        fillMode: Image.PreserveAspectFit
                        Layout.bottomMargin: Kirigami.Units.gridUnit
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }

        RowLayout {
            anchors {
                right: parent.right
                bottom: parent.bottom
            }

            Controls.Button {
                id: interSkipButton
                text: "Skip"
                icon.name: "go-next-skip"
                onClicked: nextPage()
            }

            Controls.Button {
                id: interActionButton
                onClicked: takeAction()
            }
        }
    }

    /*********************
     * Page Control Code *
     *********************/

    function switchPage(pageId) {
        pageStack.clear()

        switch(pageId) {
        case "introductionItem":
            initPage([topImage, topHeading, primaryText, actionButton])

            baseTemplatePage.title = "Introduction"
            topImage.source = "assets/images/focus_lineup.svg"
            topHeading.text = "Welcome To The Kubuntu Focus!"
            primaryText.text = "<b>This Welcome Wizard helps you get " +
                    "started as quickly as possible.</b> We have included " +
                    "many tools we feel most developers should " +
                    "consider.<br>" +
                    "<br>" +
                    "<b>This is not an endorsement of any product,</b> and " +
                    "the Focus Team is not compensated in any way for " +
                    "these suggestions. You may always run this wizard " +
                    "later using Start Menu > Kubuntu Focus > Welcome Wizard."
            actionButton.text = "Continue"
            actionButton.icon.name = "arrow-right"
            actionName = "nextPage"
            regenUI(baseTemplatePage, true)
            break

        case "diskPassphraseItem":
            initPage([topImage, topHeading, primaryText, actionButton,
                      skipButton, previousButton])

            while (cryptDiskList.length === 0) {} // wait for blkid

            baseTemplatePage.title = getCryptDiskText("Disk Passphrase")
            topImage.source = "assets/images/encrypted_drive.svg"
            topHeading.text = "Check Disk Encryption Security"
            primaryText.text = "<b>The wizard has detected " +
                    getCryptDiskText("1 encrypted disk") +
                    "</b> on this system. If you bought a system with disk " +
                    "encryption enabled and you have yet to change the " +
                    getCryptDiskText("passphrase") +
                    ", you should do so now. Otherwise, you can skip this " +
                    "step.<br>" +
                    "<br>" +
                    "<b>You may check " +
                    getCryptDiskText("this disk") +
                    " for the default password now.</b> As a security " +
                    "measure, this app will not perform this check until " +
                    "you enter your valid user password."
            actionButton.text = "Check Disk Passphrases Now"
            actionButton.icon.name = "lock"
            actionName = "checkCrypt"
            regenUI(baseTemplatePage, true)
            break

        case "diskPassphraseCheckerItem":
            initPage([topHeading, busyIndicator])

            baseTemplatePage.title = getCryptDiskText("Disk Passphrase")
            topHeading.text = "Checking Disk Encryption Security...\n" +
                    "This might take a minute."
            regenUI(baseTemplatePage, false)
            break

        case "diskPassphraseChangeInProgressItem":
            initPage([topHeading, busyIndicator])

            baseTemplatePage.title = getCryptDiskText("Disk Passphrase")
            topHeading.text = "Changing Disk Passphrases...\n" +
                   "This might take a minute."
            regenUI(baseTemplatePage, false)
            break

        case "diskPassphraseChangeItem":
            initPage([headerHighlightRect, interTopHeading, instructionsText,
                      interSkipButton, interActionButton, passphraseChangeForm,
                      secondaryInstructionsText])

            headerHighlightRect.color = "#ff9900"
            interTopHeading.text = "Change Passphrase for " + getCryptDiskText("1 Encrypted Disk")
            instructionsText.text = "<b>" +
                    getCryptDiskText("This disk is") +
                    " using the default passphrase.</b> This is insecure, " +
                    "and we recommend you use the form below to change " +
                    getCryptDiskText("it") +
                    " now."
            secondaryInstructionsText.text = "<b>Please keep a copy of " +
                    "your passphrase in a safe place.</b> If this is lost, " +
                    "there is no recovery except to reformat your disks " +
                    "and restore from backup.<br>" +
                    "<br>" +
                    "<b>For your security, the Kubuntu Focus Team does NOT " +
                    "install tools</b> that could assist in any recovery."
            interActionButton.text = "Continue"
            interActionButton.icon.name = "arrow-right"
            regenUI(interTemplatePage, false)
            actionName = "changeCrypt"
            break

        case "diskPassphraseGoodItem":
            initPage([headerHighlightRect, interTopHeading, instructionsText,
                      pictureColumn, interActionButton])

            interTemplatePage.title = getCryptDiskText("Disk Passphrase")
            interImageList = [ "finished.svg" ]
            headerHighlightRect.color = "#27ae60"
            interTopHeading.text = "Disk Encryption Passphrases Appear Secure"
            instructionsText.text = "<b>" +
                    getCryptDiskText("The encrypted disk uses") +
                    " a non-default passphrase.</b><br>" +
                    "<br>" +
                    "<b>Please keep a copy of your passphrase in a safe " +
                    "place.</b> If this is lost, there is no recovery " +
                    "except to reformat your disks and restore from " +
                    "backup.<br>" +
                    "<br>" +
                    "<b>For your security, the Kubuntu Focus Team does NOT " +
                    "install tools</b> that could assist in any recovery."
            interActionButton.text = "Continue"
            interActionButton.icon.name = "arrow-right"
            actionName = "nextPage"
            regenUI(interTemplatePage, false)
            break
        }
    }

    function initPage(visibleElementList) {
        var allElementsList = [topImage, topHeading, primaryText,
                                previousButton, actionButton, skipButton,
                                busyIndicator, headerHighlightRect,
                                interTopHeading, instructionsText,
                                interActionButton, passphraseChangeForm,
                                secondaryInstructionsText]
        var i = 0;

        for (i = 0;i < allElementsList.length;i++) {
            allElementsList[i].visible = false
        }
        interImageList = []


        for (i = 0;i < visibleElementList.length;i++) {
            visibleElementList[i].visible = true
        }
    }

    function regenUI(currentPage, sidebarEnabled) {
        if (sidebarEnabled) {
            pageStack.push(sidebarPage)
        } else {
            disabledStepsList.currentIndex = stepsList.currentIndex
            stepsListLockIndex = stepsList.currentIndex
            pageStack.push(disabledSidebarPage)
        }
        pageStack.push(currentPage)
    }

    function getCurrentPageId() {
        return stepsModel.get(stepsList.currentIndex).jsId
    }

    function nextPage() {
        stepsList.currentIndex++
        switchPage(getCurrentPageId())
    }

    function previousPage() {
        stepsList.currentIndex--
        switchPage(getCurrentPageId())
    }

    function getCryptDiskText(textType) {
        if(cryptDiskList.length === 1) {
            return textType
        } else {
            switch(textType) {
            case "Disk Passphrase":
                return "Disk Passphrases"

            case "1 encrypted disk":
                return cryptDiskList.length + " encrypted disks"

            case "1 Encrypted Disk":
                return cryptDiskList.length + " Encrypted Disks"

            case "passphrase":
                return "passphrases"

            case "this disk":
                return "these disks"

            case "The encrypted disk uses":
                if (cryptDiskList.length === 2){
                    return "Both encrypted disks use"
                } else {
                    return "All encrypted disks use"
                }

            case "This disk is":
                return "These disks are"

            case "it":
                return "them"
            }
        }

    }

    /**************
     * Logic code *
     **************/

    // Poll for Internet access

    ShellEngine {
        id: internetCheckerEngine

        onAppExited: {
            if (exitCode === 0) {
                internetConnected = true
            } else {
                internetConnected = false
            }
        }
    }

    Timer {
        interval: 2000 // Ping once every 2 seconds, might be too frequent?
        running: true
        repeat: true
        onTriggered: internetCheckerEngine.exec("ping -c 1 8.8.8.8")
    }

    // Get list of encrypted disks on the system (one time, runs at launch)

    ShellEngine {
        id: cryptDiskListEngine

        commandStr: "for i in " +
                    "$(blkid " +
                    "| grep 'TYPE=\"crypto_LUKS\"' " +
                    "| cut -d' ' -f1); " +
                    "do echo $(echo $i | head -c-2); done"

        onAppExited: {
            cryptDiskList = stdout.split("\n").slice(0, -1)
        }
    }

    // Check all encrypted disks for the default passphrase

    ShellEngine {
        id: cryptDiskCheckerEngine

        onAppExited: {
            defaultPassphraseDisks = exitCode
            if (exitCode > 0) {
                switchPage("diskPassphraseChangeItem")
            } else {
                switchPage("diskPassphraseGoodItem")
            }
        }
    }

    // Changes the passphrase on all encrypted disks that use the default

    ShellEngine {
        id: cryptDiskChangeEngine

        onAppExited: {
            /* TODO: If we get an exit code of 2 here, something has gone
               dreadfully wrong (disk failure?), in which case we really
               should tell the user that something just blew up. An exit code
               of 1 is ignorable. */
            switchPage("diskPassphraseGoodItem")
        }
    }

    /* Event handlers for action button onClicked events - we do this since
       Controls.Button.onClicked can't be changed from within JS */

    function takeAction() {
        switch(actionName) {
        case "nextPage":
            nextPage()
            break

        case "previousPage":
            previousPage()
            break

        case "checkCrypt":
            cryptDiskCheckerEngine.exec("pkexec " +
                                         binDir +
                                        "kfocus-check-crypt -c " +
                                        cryptDiskList.join(' '))
            switchPage("diskPassphraseCheckerItem")
            break

        case "changeCrypt":
            cryptDiskChangeEngine.exec("pkexec " +
                                        binDir +
                                        "kfocus-check-crypt -m " +
                                        cryptDiskList.join(' '),
                                        "kubuntu\n" + newPassphraseBox.text +
                                        "\n")
            switchPage("diskPassphraseChangeInProgressItem")
        }
    }

    /*********************
     * Global Properties *
     *********************/

    property string binDir: "/please/change/this/to/your/package-main/usr/lib/kfocus/bin"
    property string actionName: ""
    property int stepsListLockIndex: 0
    property bool firstRun: true
    property var interImageList: []
    property bool internetConnected: false
    property var cryptDiskList: []
    property int defaultPassphraseDisks: 0
}

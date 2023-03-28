import QtQuick 2.6
import QtQuick.Controls 2.0 as Controls
import QtQuick.Layouts 1.2
import org.kde.kirigami 2.13 as Kirigami
import org.kde.plasma.core 2.1 as PlasmaCore

Kirigami.ApplicationWindow {
    id: root
    title: "Kubuntu Focus Power Tool"
    width: 560
    height: 670
    minimumWidth: 560
    minimumHeight: 670

    pageStack.initialPage: Kirigami.Page {
        title: "KFocus Power and Fan"
        ColumnLayout {
            id: layout
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            spacing: PlasmaCore.Units.mediumSpacing

            Kirigami.Heading {
                visible: plasmaProfilesSlider.visible
                text: 'Power Profile'
                level: 1
            }

            Controls.Slider {
                id: plasmaProfilesSlider
                visible: root.activeProfileIndex !== -1
                value: root.activeProfileIndex
                onValueChanged: {
                    activateProfile(root.profiles[value])
                }
                to: 2
                stepSize: 1
                Layout.fillWidth: true
            }

            RowLayout {
                visible: plasmaProfilesSlider.visible
                spacing: 0
                Layout.fillWidth: true

                Controls.Label{
                    text: "🔋 Powersave"
                }

                Item {
                    Layout.fillWidth: true
                }

                Controls.Label{
                    text: "Performance ⚡"
                }
                Layout.bottomMargin: PlasmaCore.Units.largeSpacing
            }

            Kirigami.Heading {
                // text: plasmaProfilesSlider.visible ? "Fine Tuning" : "Power Profile"
                id: powerHeading
                visible: false
                text: 'Frequency Profile'
                level: 1
            }

            GridLayout {
                id: grid
                visible: false
                columnSpacing: 0
                rowSpacing: 3
                // Number of columns is set by the logic part
                Layout.fillWidth: true
                Repeater {
                    model: profilesModel
                    // Each cell of the grid is a rectangle; we have magic properties that are defined in the
                    // logic part, namely elementName, bold, elementColor, firstElementName
                    Rectangle {
                        property bool firstElement: elementColor != 'transparent'
                        property bool selectedRow: !firstElement && firstElementName == profilesModel.selectedProfile
                        Controls.RadioButton {
                            id: radioButton
                            visible: firstElement
                            checked: profilesModel.selectedProfile == elementName
                            onCheckedChanged: {
                                powerTimer.triggeredOnStart = false
                                powerTimer.stop()
                                if (checked) profilesModel.selectedProfile = elementName;
                                powerTimer.start()
                            }
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 5
                        }
                        color: selectedRow ? "gray" : elementColor
                        Layout.preferredWidth: (layout.width - Layout.rightMargin * grid.columns) / grid.columns
                        Layout.rightMargin: 2
                        Layout.preferredHeight: 30
                        Controls.Label {
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.left: firstElement ? radioButton.right : parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: firstElement ? 3 : 20
                            text: bold ? '<b>' + elementName + '</b>' : elementName
                        }
                    }
                }
            }

            Kirigami.InlineMessage {
                id: powerError
                Layout.fillWidth: true
                text: "Frequency Modes not Found"
                visible: false
            }

            Controls.Label {
              id: powerLegend
              visible: false
              text: "psave = powersave, PERF = performance"
              Layout.bottomMargin: PlasmaCore.Units.largeSpacing
            }

            Kirigami.Heading {
                id: fanControlHeading
                text: "Fan Profile"
                level: 1
            }

            Kirigami.InlineMessage {
                id: inlineMessage
                Layout.fillWidth: true
                text: "Fan Profile not Found"
                visible:  !fanSlider.visible
            }

            Controls.Slider {
                id: fanSlider
                visible: fanProfilesModel.fanAvailable
                onValueChanged: {
                    fanTimer.triggeredOnStart = false
                    fanTimer.stop()
                    fanProfilesChecker.connectSource('pkexec ' + binDir + '/kfocus-fan-set ' + fanProfilesModel.profileNames[value])
                    fanDescription.text = "<i>Description:</i> " + fanProfilesModel.profileDescriptions[fanSlider.value]
                    fanTimer.start()
                }
                to: fanProfilesModel.count - 1
                stepSize: 1
                Layout.fillWidth: true
            }

            RowLayout {
                id: fanLabels
                visible: fanSlider.visible
                spacing: 0
                Layout.fillWidth: true

                Repeater {
                    model: fanProfilesModel
                    delegate: Controls.Label {
                        text: name
                        Layout.preferredWidth: layout.width / (fanProfilesModel.count)
                        horizontalAlignment: index == 0 ? Text.AlignLeft : (
                            index == fanProfilesModel.count - 1 ? Text.AlignRight : Text.AlignHCenter)
                    }
                }
            }

            Controls.Label {
                id: fanDescription
                visible: fanSlider.visible
                text: "<i>Description:</i> " + fanProfilesModel.profileDescriptions[fanSlider.value]
                Layout.bottomMargin: PlasmaCore.Units.largeSpacing
            }

        }
        // --- LOGIC ---
        ListModel {
            id: profilesModel
            property string selectedProfile
            property var validIndexes: []
            // Longer List:
            //  property var gridColors: ['transparent', '#F63114', '#F7941E',
            //  '#E4A714', '#8EB519', '#33cc33', '#39ceba', '#3caae4', '#007dc6',
            //  '#006091'].reverse()
            property var gridColors: ['transparent', '#F63114', '#F7941E',
            '#33cc33', '#3caae4', '#006091'].reverse()
            onSelectedProfileChanged: profilesChecker.connectSource('pkexec '
            + binDir + '/kfocus-power-set ' + selectedProfile)
        }

        // Loads and parse the available profiles
        PlasmaCore.DataSource {
            engine: "executable"
            connectedSources: [ binDir + '/kfocus-power-set -x']
            onNewData: {
                let stdout = data["stdout"]
                let freqMissingMsg = false
                let buildStr = ""
                stdout.split('\n').forEach(function (line, index) {
                    if (line === '') return;
                    if (line.substring(0,5) == "title") {
                        freqMissingMsg = true
                        let lineParts = line.split('|')
                        let titleMsg = lineParts[0].substring(6, lineParts[0].length)
                        let bodyMsg = lineParts[1].substring(8, lineParts[1].length)
                        powerHeading.text = titleMsg
                        powerHeading.visible = true
                        buildStr += bodyMsg
                    } else {
                        if (freqMissingMsg) {
                            buildStr += line
                            return
                        }
                        let firstElementName = '';
                        line.split(';').forEach(function (value, subindex) {
                            if (index == 0 && value !== '') {
                                profilesModel.validIndexes.push(subindex)
                            }
                            if (subindex == 0) {
                                firstElementName = value
                            }
                            if (profilesModel.validIndexes.includes(subindex)) {
                               profilesModel.append({'elementName': value, 'bold': index == 0,
                                    'elementColor': subindex == 0 ? profilesModel.gridColors.pop() : 'transparent',
                                    'firstElementName': firstElementName
                                })
                                // There are items in the table, display them
                                powerHeading.visible = true
                                grid.visible = true
                                powerLegend.visible = true
                            }
                        })
                        grid.columns = profilesModel.validIndexes.length
                    }
                })
                if (buildStr != "") {
                    powerError.text = buildStr
                    powerError.visible = true
                }
                disconnectSource(sourceName)
            }
        }

        // Checks the current profile
        PlasmaCore.DataSource {
            id: profilesChecker
            engine: "executable"
            connectedSources: []
            onNewData: {
                if (data["stdout"].trim() !== '' && data["stdout"].trim().substring(0, 6).toLowerCase() != "custom") {
                    profilesModel.selectedProfile = data["stdout"].trim()
                }
                disconnectSource(sourceName)
            }
        }
        // This checkes the current profile every 5 seconds
        Timer {
            id: powerTimer
            interval: 5000
            triggeredOnStart: true
            running: true
            repeat: true
            onTriggered: profilesChecker.connectSource(binDir + '/kfocus-power-set -r')
        }

        ListModel {
            id: fanProfilesModel
            property var profileNames: []
            property var profileDescriptions : []
            property bool fanAvailable: false
        }

        // Loads and parse the available fan profiles
        PlasmaCore.DataSource {
            engine: "executable"
            connectedSources: [binDir + '/kfocus-fan-set -x']
            onNewData: {
                let fanMissingMsg = false
                let buildStr = ""
                data["stdout"].split('\n').forEach(function (line) {
                    if (line === '') return;
                    if (line.substring(0, 5) == "title") {
                        fanMissingMsg = true;
                        root.height = 700
                        let lineParts = line.split('|');
                        let titleMsg = lineParts[0].split(':')[1];
                        let bodyMsg = lineParts[1].split(':')[1];
                        fanControlHeading.text = titleMsg;
                        buildStr += bodyMsg;
                    }
                    if (fanMissingMsg) {
                        buildStr += line
                    } else {
                        let [name, description] = line.split('(')
                        fanProfilesModel.append({'name': name.trim()})
                        fanProfilesModel.profileNames.push(name.trim())
                        fanProfilesModel.profileDescriptions.push(description.replace(")", "").trim())
                        fanProfilesModel.fanAvailable = true
                    }
                })
                if (fanMissingMsg) {
                    inlineMessage.text = buildStr
                    fanSlider.visible = false
                }
                fanTimer.running = true
                disconnectSource(sourceName)
            }
        }

        // Checks the current fan profile
        PlasmaCore.DataSource {
            id: fanProfilesChecker
            engine: "executable"
            connectedSources: []
            onNewData: {
                if (data["stdout"].trim() !== '') {
                    fanSlider.value = fanProfilesModel.profileNames.indexOf(data["stdout"].trim())
                    fanDescription.text = "<i>Description:</i> " + fanProfilesModel.profileDescriptions[fanSlider.value]
                }
                disconnectSource(sourceName)
            }
        }
        Timer {
            id: fanTimer
            interval: 5000
            triggeredOnStart: true
            repeat: true
            onTriggered: {
                fanProfilesChecker.connectSource(binDir + '/kfocus-fan-set -r | cut -d\' \' -f1')
            }
        }
    }
    // Managing Plasma Profiles
    PlasmaCore.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: sources
        onSourceAdded: {
            disconnectSource(source);
            connectSource(source);
        }
        onSourceRemoved: {
            disconnectSource(source);
        }
    }
    // The actuallyActiveProfile is the current profile that's set in power settings;
    // the activeProfile is usually the same value, however since changes take a bit to apply,
    // whenever we change the profile we manually set activeProfile to the new value (otherwise the slider
    // would still be at the old value) and then set it back to follow actuallyActiveProfile as soon
    // as that one is updated.
    readonly property string actuallyActiveProfile: pmSource.data["Power Profiles"] ? (pmSource.data["Power Profiles"]["Current Profile"] || "") : ""
    onActuallyActiveProfileChanged: {
        if (root.actuallyActiveProfile === root.activeProfile) {
            root.activeProfile = Qt.binding(() => root.actuallyActiveProfile);
        }
    }
    property string activeProfile: actuallyActiveProfile
    function activateProfile(profile) {
        if (!profile) return;
        if (!root.activeProfile) return;
        if (profile == root.activeProfile) return;
        const service = pmSource.serviceForSource("PowerDevil");
        const op = service.operationDescription("setPowerProfile");
        op.profile = profile;
        const job = service.startOperationCall(op);
        root.activeProfile = profile
        job.finished.connect(job => {
            if (!job.result) {
                console.log('Something went wrong, could not activate profile', profile)
            }
        })
    }
    readonly property var profiles: ['power-saver', 'balanced', 'performance']
    // Requires qmlscene ./kfocus.qml "${pathToBin}" to set binDir for
    //   kfocus-fan-set and kfocus-power-set
    readonly property var binDir: Qt.application.arguments[1] || '/usr/lib/kfocus/bin'
    readonly property int activeProfileIndex: root.profiles.indexOf(root.activeProfile)
}

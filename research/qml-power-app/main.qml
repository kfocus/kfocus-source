import QtQuick 2.6
import QtQuick.Controls 2.0 as Controls
import QtQuick.Layouts 1.2
import org.kde.kirigami 2.13 as Kirigami
import org.kde.plasma.core 2.1 as PlasmaCore

Kirigami.ApplicationWindow {
    id: root

    title: "Kubuntu Focus Power Tool"
    width: 550
    height: 700
    minimumWidth: 400
    minimumHeight: 600

    pageStack.initialPage: Kirigami.Page {


        title: "Power Management Options"

        ColumnLayout {
            id: layout
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            spacing: PlasmaCore.Units.mediumSpacing

            Kirigami.Heading {
                text: "Fan Curve"
                level: 1
            }

            Kirigami.InlineMessage {
                id: inlineMessage
                Layout.fillWidth: true
                text: "This NX GEN 1 Has Fan controls in the BIOS. Open the BIOS using F2 during boot and select Performance and Cooling > Fan Control."
                visible:  !fanSlider.visible
            }

            Controls.Slider {
                id: fanSlider
                visible: fanProfilesModel.fanAvailable
                onValueChanged: {
                    fanTimer.triggeredOnStart = false
                    fanTimer.stop()
                    fanProfilesChecker.connectSource('pkexec /usr/lib/kfocus/bin/kfocus-fan-set ' + fanProfilesModel.profileNames[value])
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
                Layout.bottomMargin: PlasmaCore.Units.smallSpacing * 7
            }

            Kirigami.Heading {
                visible: plasmaProfilesSlider.visible
                text: "Power Profiles"
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
                spacing: 0
                Layout.bottomMargin: PlasmaCore.Units.smallSpacing * 7
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
            }

            Kirigami.Heading {
                text: plasmaProfilesSlider.visible ? "SPLINE Tuning" : "Power Profile"
                level: 1
            }

            GridLayout {
                id: grid
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

        }

        // --- LOGIC ---

        ListModel {
            id: profilesModel
            property string selectedProfile
            property var validIndexes: []
            property var gridColors: ['transparent', '#F63114', '#F7941E',
            '#E4A714', '#8EB519', '#33cc33', '#39ceba', '#3caae4', '#007dc6',
            '#006091'].reverse()
            onSelectedProfileChanged: profilesChecker.connectSource('pkexec /usr/lib/kfocus/bin/kfocus-power-set ' + selectedProfile)
        }

        // Loads and parse the available profiles
        PlasmaCore.DataSource {
            engine: "executable"
            connectedSources: ['echo "Profile;GHz;Governor;;LEDs"; /usr/lib/kfocus/bin/kfocus-power-set -p']
            onNewData: {
                let stdout = data["stdout"]
                stdout.split('\n').forEach(function (line, index) {
                    if (line === '') return;
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
                        }
                    })
                    grid.columns = profilesModel.validIndexes.length
                })
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
            onTriggered: profilesChecker.connectSource('/usr/lib/kfocus/bin/kfocus-power-set -r')
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
            connectedSources: ['/usr/lib/kfocus/bin/kfocus-fan-set -p | tac']
            onNewData: {
                data["stdout"].split('\n').forEach(function (line) {
                    if (line === '') return;
                    let [name, description] = line.split('(')
                    fanProfilesModel.append({'name': name.trim()})
                    fanProfilesModel.profileNames.push(name.trim())
                    fanProfilesModel.profileDescriptions.push(description.replace(")", "").trim())
                    fanProfilesModel.fanAvailable = true
                })
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
                fanProfilesChecker.connectSource('/usr/lib/kfocus/bin/kfocus-fan-set -r | cut -d\' \' -f1')
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
    readonly property int activeProfileIndex: root.profiles.indexOf(root.activeProfile)
}

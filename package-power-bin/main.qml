import QtQuick 2.6
import QtQuick.Controls 2.0 as Controls
import QtQuick.Layouts 1.2
import QtQuick.Window 2.2
import org.kde.kirigami 2.13 as Kirigami
import org.kde.plasma.core 2.1 as PlasmaCore
import shellengine 1.0

Kirigami.ApplicationWindow {
    id: root
    title: "Kubuntu Focus"
    width:  baseWidth  * scaleRatio
    height: baseHeight * scaleRatio
    minimumWidth:  (baseWidth  - 50) * scaleRatio
    minimumHeight: (baseHeight - 50) * scaleRatio

    pageStack.initialPage: Kirigami.Page {
        title: 'Power and Fan'
        ColumnLayout {
            id: layout
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }

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

                Controls.Label {
                    // DEBUG + scaleRatio.toFixed(3)
                    text: '🔋 Powersave'
                }

                Item {
                    Layout.fillWidth: true
                }

                Controls.Label {
                    // DEBUG + scaleMap.spread_num.toFixed(3)
                    text: 'Performance ⚡'
                }
                Layout.bottomMargin: PlasmaCore.Units.largeSpacing
            }

            Kirigami.Heading {
                visible: plasmaBrightnessSlider.visible
                text: 'Brightness'
                level: 1
            }

            Controls.Slider {
                id: plasmaBrightnessSlider
                visible: isBrightnessAvailable
                value: activeBrightness
                onValueChanged: {
                    changeBrightnessFn( value, 'internal' );
                }
                Layout.fillWidth: true
                snapMode: Controls.Slider.NoSnap
            }

            RowLayout {
                visible: plasmaBrightnessSlider.visible
                spacing: 0
                Layout.fillWidth: true

                Controls.Label {
                    text: '🔅 Dimmer'
                    Layout.leftMargin: 3 * scaleRatio
                }

                Item {
                    Layout.fillWidth: true
                }

                Controls.Label {
                    text: 'Brighter 🔆'
                    Layout.rightMargin: 3 * scaleRatio
                }

                Layout.bottomMargin: PlasmaCore.Units.largeSpacing
            }

            Kirigami.Heading {
                // text: plasmaProfilesSlider.visible ?
                //   "Fine Tuning" : "Power Profile"
                id: powerHeading
                visible: false
                text: 'Frequency Profile'
                level: 1
            }

            GridLayout {
                id: grid
                visible: false
                columnSpacing: Math.round( scaleRatio )
                rowSpacing: Math.round( 3 * scaleRatio )
                // Number of columns is set by the logic part
                Layout.fillWidth: true
                Repeater {
                    model: profilesModel
                    // Each cell of the grid is a rectangle; we have magic properties that are defined in the
                    // logic part, namely elementName, bold, elementColor, firstElementName
                    Rectangle {
                        property bool firstElement: elementColor !== 'transparent'
                        property bool selectedRow: !firstElement && firstElementName === profilesModel.selectedProfile
                        Controls.RadioButton {
                            id: radioButton
                            visible: firstElement
                            checked: profilesModel.selectedProfile === elementName
                            onCheckedChanged: {
                                powerTimer.triggeredOnStart = false
                                powerTimer.stop()
                                if (checked) {
                                  profilesModel.selectedProfile = elementName;
                                }
                                powerTimer.start()
                            }
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 5
                        }
                        color: selectedRow ? "gray" : elementColor
                        Layout.preferredWidth: (layout.width - Layout.rightMargin * grid.columns) / grid.columns
                        Layout.rightMargin: 2
                        Layout.preferredHeight: 30 * scaleRatio
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
                Layout.bottomMargin: PlasmaCore.Units.largeSpacing
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
                    altFanProfilesChecker.exec('pkexec ' + binDir + '/kfocus-fan-set ' + fanProfilesModel.profileNames[value])
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
                        horizontalAlignment: index === 0 ? Text.AlignLeft : (
                            index === fanProfilesModel.count - 1 ? Text.AlignRight : Text.AlignHCenter)
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

        // BEGIN Logic
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
            onSelectedProfileChanged: {
                altProfilesChecker.exec(
                    'pkexec ' + binDir + '/kfocus-power-set ' + selectedProfile
                );
                doSkipNextFreqPoll = true;
            }
        }

        // Loads and parse the available profiles
        ShellEngine {
            commandStr: 'pkexec ' + binDir + '/kfocus-power-set -x'
            onStdoutChanged: {
                let
                  is_freq_missing_msg = false,
                  solve_msg = '';
                stdout.split('\n').forEach(function (line, index) {
                    if ( line === '' ) { return; }
                    if ( line.substring(0,5) === 'title' ) {
                        is_freq_missing_msg = true;
                        let
                          bit_list = line.split('|'),
                          title_msg = bit_list[0].substring(6, bit_list[0].length),
                          body_msg = bit_list[1].substring(8, bit_list[1].length);

                        powerHeading.text = title_msg;
                        powerHeading.visible = true;
                        solve_msg += body_msg;
                    }
                    else {
                        if ( is_freq_missing_msg ) {
                            solve_msg += line;
                            return;
                        }

                        let first_el_name = '';
                        line.split(';').forEach(function (value, subindex) {
                            if ( index === 0 && value !== '' ) {
                                profilesModel.validIndexes.push( subindex );
                            }
                            if ( subindex === 0 ) {
                                first_el_name = value;
                            }

                            if (profilesModel.validIndexes.includes( subindex )) {
                               profilesModel.append({
                                   'elementName' : value,
                                   'bold'        : index === 0,
                                   'elementColor': subindex === 0
                                      ? profilesModel.gridColors.pop() : 'transparent',
                                   'firstElementName': first_el_name
                                })

                                // There are items in the table, display them
                                powerHeading.visible = true;
                                grid.visible = true;
                                powerLegend.visible = true;
                            }
                        })
                        grid.columns = profilesModel.validIndexes.length;
                    }
                })
                if ( solve_msg != '' ) {
                    powerError.text = solve_msg;
                    powerError.visible = true;
                }
            }
        }

        // Refresh the current power profile
        ShellEngine {
            id: altProfilesChecker
            onStdoutChanged: {
                const chkCustomRegex = /^\s*custom/i
                const trimmedStdout = stdout.trim();
                if (trimmedStdout !== ''
                    && ! chkCustomRegex.test( trimmedStdout )
                ) {
                    profilesModel.selectedProfile = trimmedStdout
                }
            }
        }

        // This polls Frequency profile every pollingMs
        Timer {
            id: powerTimer
            interval: pollingMs
            triggeredOnStart: true
            running: true
            repeat: true
            onTriggered: {
                // Do nothing if the user recently selected a profile
                // This prevents profiles being jumped back to a prior
                // value before the set completes.
                if ( doSkipNextFreqPoll ) {
                    doSkipNextFreqPoll = false;
                    return;
                }
                altProfilesChecker.exec(
                  'pkexec ' + binDir + '/kfocus-power-set -r'
                )
            }
        }

        ListModel {
            id: fanProfilesModel
            property var profileNames: []
            property var profileDescriptions : []
            property bool fanAvailable: false
        }

        // Loads and parse the available fan profiles
        ShellEngine {
            commandStr: binDir + '/kfocus-fan-set -x'
            onStdoutChanged: {
                const check_regex = /^\s*title:[^|]+|\s*message:/;
                if ( check_regex.test( stdout ) ) {
                    root.height += ( 50 * scaleRatio );
                    const
                      msg_list = stdout.split('|'),
                      title_str = msg_list[0].replace( /^\s*title:\s*/, '' ).trim(),
                      trimmed_msg = msg_list[1].replace( /^\s*message:\s*/, '' ).trim();

                    fanControlHeading.text = title_str;
                    inlineMessage.text = trimmed_msg;
                    fanSlider.visible = false;
                }
                else {
                    stdout.split('\n').forEach(function (line) {
                        if (line === '') { return }
                        const [name, description] = line.split('(');
                        fanProfilesModel.append({'name': name.trim()});
                        fanProfilesModel.profileNames.push(name.trim());
                        fanProfilesModel.profileDescriptions.push(
                            description.replace(')', '').trim()
                        );
                        fanProfilesModel.fanAvailable = true;
                    })
                }
                fanTimer.running = true;
            }
        }

        ShellEngine {
            id: altFanProfilesChecker
            onStdoutChanged: {
                let trimmed_str = stdout.trim()
                if (trimmed_str !== '') {
                    fanSlider.value = fanProfilesModel.profileNames.indexOf(trimmed_str)
                    fanDescription.text = '<i>Description:</i> '
                        + fanProfilesModel.profileDescriptions[fanSlider.value]
                }
            }
        }

        // This polls Fan profile every pollingMs
        Timer {
            id: fanTimer
            interval: pollingMs
            triggeredOnStart: true
            repeat: true
            onTriggered: {
                altFanProfilesChecker.exec(
                    binDir + '/kfocus-fan-set -r | cut -d " " -f1'
                )
            }
        }
    }

    // Managing Plasma Profiles
    PlasmaCore.DataSource {
        id: pmSource
        engine: 'powermanagement'
        connectedSources: sources
        onSourceAdded: {
            disconnectSource(source);
            connectSource(source);
        }
        onSourceRemoved: {
            disconnectSource(source);
        }
        onDataChanged: {
            changeBrightnessFn(
                readStructFn( this, [
                  'data', 'PowerDevil', 'Screen Brightness' ], 1
                ) / 100 / (root.maximumBrightness / 100),
                'external'
            );
        }
    }

    // The actuallyActiveProfile is the current profile that is set in
    // power settings; the activeProfile is usually the same value,
    // however since changes take a bit to apply, whenever we change
    // the profile we manually set activeProfile to the new value
    // (otherwise the slider would still be at the old value) and
    // then set it back to follow actuallyActiveProfile as soon as
    // that one is updated.
    readonly property string actuallyActiveProfile:
        readStructFn( pmSource, [ 'data', 'Power Profiles' ] )
            ? readStructFn( pmSource, [
                'data', 'Power Profiles', 'Current Profile' ], ''
            ) : '';

    onActuallyActiveProfileChanged: {
        if ( root.actuallyActiveProfile === root.activeProfile ) {
            root.activeProfile = Qt.binding(() => root.actuallyActiveProfile);
        }
    }
    property string activeProfile: actuallyActiveProfile

    function activateProfile(profile) {
        if ( ! profile ) { return; }
        if ( ! root.activeProfile ) { return; }
        if ( profile === root.activeProfile ) { return; }
        const 
          service_obj = pmSource.serviceForSource('PowerDevil'),
          operate_obj = service_obj.operationDescription('setPowerProfile');

        operate_obj.profile = profile;
        const job = service_obj.startOperationCall(operate_obj);
        root.activeProfile = profile
        job.finished.connect(job => {
            if ( ! job.result ) {
                console.log('Could not activate profile', profile)
            }
        })
    }

    Timer {
        interval: 25
        running: true
        repeat: false
        onTriggered: {
            if ( readStructFn( pmSource, [ 'data', 'PowerDevil',
                'Screen Brightness Available' ] ) === true
            ) {
                root.isBrightnessAvailable = true;
                root.maximumBrightness     = readStructFn( pmSource, [
                    'data', 'PowerDevil', 'Maximum Screen Brightness' ], 1);
                root.activeBrightness      = readStructFn( pmSource, [
                    'data', 'PowerDevil', 'Screen Brightness' ], 1);
                root.activeBrightness = root.activeBrightness / 100
                    / (root.maximumBrightness / 100);
                root.height += (110 * scaleRatio);
            }
            else {
                root.isBrightnessAvailable = false;
            }
        }
    }

    Timer {
        id: brightnessModeExpireTimer
        interval: 250
        running: false
        repeat: false
        onTriggered: {
            root.brightnessInputMode = 'expired';
        }
    }

    function changeBrightnessFn( arg_bright_num, arg_source_str ) {
        if ( root.brightnessInputMode === 'internal' ) {
            if ( arg_source_str === 'external' ) {
                brightnessModeExpireTimer.restart();
                return;
            }
        } else if (root.brightnessInputMode === 'external' ) {
            if ( arg_source_str === 'internal' ) {
                brightnessModeExpireTimer.restart();
                return;
            }
        }

        if ( arg_source_str === 'external' ) {
            root.activeBrightness = arg_bright_num;
            root.brightnessInputMode = 'external';
        } else {
            changeBrightnessInternalFn( arg_bright_num );
            root.brightnessInputMode = 'internal';
        }
        brightnessModeExpireTimer.restart();
    }

    function changeBrightnessInternalFn( arg_bright_num ) {
        let
          solve_bright_num = 0,
          calc_bright_num = 0;
        if ( ! root.isBrightnessAvailable ) { return; }

        // Do not let the brightness value get so low as to cause screen blackout
        solve_bright_num = arg_bright_num <= 0.01 ? 0.01 : arg_bright_num;

        const 
          service_obj = pmSource.serviceForSource( 'PowerDevil' ),
          operate_obj = service_obj.operationDescription( 'setBrightness' );

        operate_obj.silent = true;
        operate_obj.brightness = solve_bright_num * 100
          * (root.maximumBrightness / 100);
        root.activeBrightness = arg_bright_num;
        const job_obj = service_obj.startOperationCall(operate_obj);
        job_obj.finished.connect( arg_obj => {
            if ( ! arg_obj.result ) {
                console.log('Could not change screen brightness');
            }
        })
    }

    // BEGIN Utilities
    function readStructFn ( arg_obj, arg_key_list, arg_alt_data ) {
        let key_count, point_obj, idx, key, val_data;
        key_count = arg_key_list.length;
        point_obj = arg_obj;

        for ( idx = 0; idx < key_count; idx++ ) {
            key      = arg_key_list[ idx ];
            val_data = point_obj[ key ];
            if ( typeof val_data === 'object' ) {
                point_obj = val_data;
            }
            else { break; }
        }
        if ( idx < key_count - 1 ) { return arg_alt_data; }
        return val_data;
    }

    function calcScaleRatioFn () {
      let spread_num = 0;
      const
        density_num  = Screen.pixelDensity,
        base_num     = 3.78, // 96 DPI
        quantize_num = 0.125;

      if ( density_num > base_num ) {
        spread_num = (density_num - base_num) / ( 1.75 * base_num );
      }
      return {
        spread_num: spread_num,
        scale_ratio: 1 + Math.round(spread_num / quantize_num) * quantize_num
      }
    }
    // . END Utilities

    // BEGIN Global Properties
    property real activeBrightness: 0
    property real maximumBrightness: 0
    property bool isBrightnessAvailable: false
    property string brightnessInputMode: 'expired'

    readonly property var profiles: ['power-saver', 'balanced', 'performance']
    readonly property var binDir: Qt.application.arguments[1] || '/usr/lib/kfocus/bin'
    readonly property int activeProfileIndex: root.profiles.indexOf(root.activeProfile)
    readonly property int pollingMs: 5000
    readonly property var scaleMap: calcScaleRatioFn()
    readonly property real scaleRatio: scaleMap.scale_ratio
    property bool doSkipNextFreqPoll: false

    readonly property int baseWidth: 460
    readonly property int baseHeight: 593
    // . END Global Properties
}


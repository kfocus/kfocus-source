import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import QtQuick.Window
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
  id: root
  title: 'Power and Fan'
  width: Kirigami.Units.gridUnit * 35
  height: Kirigami.Units.gridUnit * 40
  minimumWidth: Kirigami.Units.gridUnit * 35
  minimumHeight: Kirigami.Units.gridUnit * 40

  pageStack.initialPage: Kirigami.Page {
    title: 'Power and Fan'

    ColumnLayout {
      id: coreLayout
      anchors {
        left: parent.left
        right: parent.right
        top: parent.top
      }
      spacing: Kirigami.Units.smallSpacing

      Kirigami.Heading {
        visible: plasmaProfilesSlider.visible
        enabled: plasmaProfilesSlider.enabled
        text: 'Power Profile'
        level: 3
      }

      Controls.Slider {
        id: plasmaProfilesSlider
        Layout.fillWidth: true
        visible: true
        enabled: false
        value: 0
        to: 2
        stepSize: 1

        onValueChanged: {
          powerProfileTimer.stop();
          getPowerProfileEngine.ignoreResult();
          switch ( value ) {
          case 0:
            setPowerProfileEngine.exec('powerprofilesctl set power-saver');
            break;
          case 1:
            setPowerProfileEngine.exec('powerprofilesctl set balanced');
            break;
          case 2:
            setPowerProfileEngine.exec('powerprofilesctl set performance');
            break;
          }
        }
      }

      Rectangle {
        visible: plasmaProfilesSlider.visible
        Layout.fillWidth: true
        Layout.preferredHeight: childrenRect.height
        Layout.bottomMargin: Kirigami.Units.largeSpacing
        color: 'transparent'

        Controls.Label {
          text: '🔋 Powersave'
          anchors {
            left: parent.left
            top: parent.top
          }
        }

        Controls.Label{
          horizontalAlignment: Text.AlignHCenter
          text: 'Balanced'
          anchors {
            left: parent.left
            right: parent.right
            top: parent.top
          }
        }

        Controls.Label {
          text: 'Performance ⚡'
          anchors {
            right: parent.right
            top: parent.top
          }
        }
      }

      Kirigami.Heading {
        visible: plasmaBrightnessSlider.visible
        text: 'Brightness'
        level: 3
      }

      Controls.Slider {
        id: plasmaBrightnessSlider
        Layout.fillWidth: true
        visible: false
        snapMode: Controls.Slider.NoSnap
        onValueChanged: {
          getBrightnessTimer.stop();
          getBrightnessEngine.ignoreResult();
          setBrightnessEngine.exec(
            'dbus-send --print-reply=literal --session --dest=org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl org.kde.Solid.PowerManagement.Actions.BrightnessControl.setBrightness int32:' + plasmaBrightnessSlider.value.toString()
          );
        }
      }

      RowLayout {
        visible: plasmaBrightnessSlider.visible
        spacing: 0
        Layout.fillWidth: true
        Layout.bottomMargin: Kirigami.Units.largeSpacing

        Controls.Label {
          text: '🔅 Dimmer'
          Layout.leftMargin: 3
        }

        Item {
          Layout.fillWidth: true
        }

        Controls.Label {
          text: 'Brighter 🔆'
          Layout.rightMargin: 8
        }
      }

      RowLayout {
        Kirigami.Heading {
          id: powerHeading
          property string cpuId: ''
          visible: true
          text: 'Frequency Profile (' + cpuId + ')'
          level: 3
          Layout.bottomMargin: Kirigami.Units.smallSpacing
        }

        Controls.BusyIndicator {
          id: powerChangeSpinner
          Layout.preferredWidth: Kirigami.Units.gridUnit
          Layout.preferredHeight: Kirigami.Units.gridUnit
          visible: false
        }
      }

      Controls.ButtonGroup {
        id: freqRadioGroup
      }

      GridLayout {
        id: frequencyGrid
        visible: false
        columnSpacing: 1
        rowSpacing: 3
        Layout.bottomMargin: Kirigami.Units.smallSpacing
        Layout.fillWidth: true

        // Number of columns is set by freqProfileModelFillEngine
        Repeater {
          id: freqRepeater
          model: freqProfilesModel

          // Each cell of the grid is a rectangle; we have magic properties
          // that are defined in the model, namely elementName, rowIndex,
          // colIndex, elementColor, and firstElementName.
          Rectangle {
            property bool firstElement: colIndex === 0
            property bool highlightCell: !firstElement
              && firstElementName === freqProfilesModel.selectedProfile
            property bool isHeaderRow: rowIndex === 0
            property bool bold: isHeaderRow || firstElement || highlightCell

            color: isHeaderRow || highlightCell ? 'gray' : elementColor
            // Column size ratio is controlled by the colIndex ternary
            Layout.rightMargin: 2
            Layout.preferredWidth: (coreLayout.width
              - (Layout.rightMargin * frequencyGrid.columns * 2))
              * (firstElement ? 0.25 : colIndex === 1 ? 0.30 : 0.45
                / (frequencyGrid.columns - 2))
            Layout.preferredHeight: 30
            radius: Kirigami.Units.gridUnit / 6

            Controls.RadioButton {
              id: radioButton
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              anchors.leftMargin: 5
              visible: firstElement && !isHeaderRow
              checked: freqProfilesModel.selectedProfile === elementName
              Controls.ButtonGroup.group: freqRadioGroup

              onClicked: {
                frequencyGrid.enabled = false;
                powerChangeSpinner.visible = true;
                readFreqProfileTimer.stop();
                readFreqProfileEngine.ignoreResult();
                setFreqProfileEngine.exec( 'pkexec ' + binDir
                  + '/kfocus-power-set ' + elementName );
                freqProfilesModel.selectedProfile = elementName;
              }
            }

            Controls.Label {
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: firstElement ? radioButton.right : parent.left
              anchors.right: parent.right
              anchors.leftMargin: firstElement ? 3 : 20
              font.family: isHeaderRow || firstElement
                ? 'Noto Sans' : 'Courier'

              text: {
                let elementText = elementName
                if ( bold ) {
                  elementText = elementText.replace( ' ', '&nbsp;' );
                  elementText = '<b><font color="white">' + elementText
                    + '</font></b>';
                }
                return elementText;
              }
            }
          }
        }
      }

      Kirigami.InlineMessage {
        id: powerError
        Layout.fillWidth: true
        visible: false
        text: 'Frequency Modes Not Found'
        Layout.bottomMargin: Kirigami.Units.largeSpacing
      }

      Controls.Label {
        id: cpuTypeLegend
        visible: false
        text: 'P = perf core, E = efficient core'
        // Default margin is too large, tighten things up with a negative
        // margin
        Layout.bottomMargin: 0 - Kirigami.Units.smallSpacing
      }

      Controls.Label {
        id: powerLegend
        visible: frequencyGrid.visible
        text: 'psave = powersave, PERF = performance'
      }

      Kirigami.Heading {
        id: fanControlHeading
        property string modelId: ''
        text: 'Fan Profile (' + modelId + ')'
        Layout.topMargin: Kirigami.Units.largeSpacing
        level: 3
      }

      Kirigami.InlineMessage {
        id: fanError
        Layout.fillWidth: true
        text: 'Fan Profile Not Found'
        visible: !fanSlider.visible
      }

      Controls.Slider {
        id: fanSlider
        Layout.fillWidth: true
        visible: false
        to: fanProfilesModel.count - 1
        stepSize: 1

        onValueChanged: {
          getFanProfileTimer.stop();
          getFanProfileEngine.ignoreResult();
          setFanProfileEngine.exec( 'pkexec ' + binDir + '/kfocus-fan-set '
            + fanProfilesModel.profileNames[value] );
          fanDescription.text = getFanProfileDesc( value );
        }
      }

      RowLayout {
        id: fanLabelLayout
        visible: fanSlider.visible
        spacing: 0
        Layout.fillWidth: true

        Repeater {
          model: fanProfilesModel
          delegate: Controls.Label {
            text: name
            Layout.preferredWidth: coreLayout.width / (fanProfilesModel.count)
            horizontalAlignment: index === 0
              ? Text.AlignLeft
              : (index === fanProfilesModel.count - 1
                ? Text.AlignRight : Text.AlignHCenter)
          }
        }
      }

      Controls.Label {
        id: fanDescription
        visible: fanSlider.visible
        text: ''
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
        Layout.bottomMargin: Kirigami.Units.smallSpacing
      }
    }

    ListModel {
      id: freqProfilesModel
      property string selectedProfile: ''
      property var gridColors: ['transparent', '#F63114', '#F7941E',
        '#33cc33', '#3caae4', '#0085be'].reverse()
    }

    ListModel {
      id: fanProfilesModel
      // It's very difficult to get the index of an item in a model, so this
      // provides a lookup mechanism.
      property var profileNames: []
    }

    ShellEngine {
      id: getPowerProfileEngine
      onStdoutChanged: {
        switch ( stdout.trim() ) {
        case 'performance':
          plasmaProfilesSlider.value = 2;
          break;
        case 'balanced':
          plasmaProfilesSlider.value = 1;
          break;
        case 'power-saver':
          plasmaProfilesSlider.value = 0;
          break;
        }
        plasmaProfilesSlider.enabled = true;
      }
    }

    ShellEngine {
      id: setPowerProfileEngine
      onStdoutChanged: {
        powerProfileTimer.start();
      }
    }

    Timer {
      id: powerProfileTimer
      interval: 2000
      triggeredOnStart: true
      running: true
      repeat: true
      onTriggered: {
        getPowerProfileEngine.exec('powerprofilesctl get');
      }
    }

    ShellEngine {
      id: getMaxBrightnessEngine
      commandStr: 'dbus-send --print-reply=literal --session --dest=org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl org.kde.Solid.PowerManagement.Actions.BrightnessControl.brightnessMax | awk \'{ print $2 }\''
      onStdoutChanged: {
        plasmaBrightnessSlider.to = Number(stdout.trim());
        plasmaBrightnessSlider.visible = true;
        getBrightnessTimer.start();
      }
    }

    ShellEngine {
      id: getBrightnessEngine
      onStdoutChanged: {
        plasmaBrightnessSlider.value = Number(stdout.trim());
      }
    }

    ShellEngine {
      id: setBrightnessEngine
      onStdoutChanged: {
        getBrightnessTimer.start();
      }
    }

    Timer {
      id: getBrightnessTimer
      interval: 2000
      triggeredOnStart: true
      repeat: true
      onTriggered: {
        getBrightnessEngine.exec('dbus-send --print-reply=literal --session --dest=org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl org.kde.Solid.PowerManagement.Actions.BrightnessControl.brightness | awk \'{ print $2 }\'');
      }
    }

    ShellEngine {
      id: freqProfileModelFillEngine
      commandStr: 'pkexec ' + binDir + '/kfocus-power-set -x'
      onStdoutChanged: {
        let stdout_arr = [], col_count = 0;

        stdout_arr = stdout.split( '\n' );
        stdout_arr[0].split( ';' ).forEach(function ( value, index ) {
          if ( index === 0 ) {
            // System model
            fanControlHeading.modelId = value;
          } else if ( index === 1 ) {
            // CPU model
            powerHeading.cpuId = value;
          } else if ( index === 2 ) {
            // Is hybrid CPU?
            if ( value === 'y' ) {
              cpuTypeLegend.visible = true;
            }
          }
        } );

        stdout_arr.splice( 0, 1 );

        if ( stdout_arr[0].substring( 0, 8 ) == 'message:' ) {
          let body_msg = ''
          body_msg = stdout_arr[0].split( ':' )[1];
          stdout_arr.splice( 0, 1 );
          stdout_arr.forEach( function ( line, index ) {
            body_msg += line;
          } );
          powerError.text = body_msg;
          powerError.visible = true;
          return;
        }

        stdout_arr.forEach( function ( line, index ) {
          let first_el_name = '';

          if ( line === '' ) { return; }

          line.split( ';' ).forEach( function ( value, subindex ) {
            if ( index === 0 && value !== '' ) {
              col_count++;
            }
            if ( subindex === 0 ) {
              first_el_name = value;
            }

            if ( subindex < col_count ) {
              freqProfilesModel.append( {
                'elementName'      : value,
                'rowIndex'         : index,
                'colIndex'         : subindex,
                'elementColor'     : subindex === 0
                  ? freqProfilesModel.gridColors.pop() : 'transparent',
                'firstElementName' : first_el_name
              } );
            }
          } );
        } );

        frequencyGrid.visible = true;
        frequencyGrid.columns = col_count;
      }
    }

    ShellEngine {
      id: readFreqProfileEngine
      onStdoutChanged: {
        let trimmed_stdout = '';

        trimmed_stdout = stdout.trim();
        if ( trimmed_stdout === 'Unknown' ) {
          freqProfilesModel.selectedProfile = '';
        } else {
          freqProfilesModel.selectedProfile = trimmed_stdout;
        }
      }
    }

    ShellEngine {
      id: setFreqProfileEngine
      onStdoutChanged: {
        readFreqProfileTimer.start()
        frequencyGrid.enabled = true;
        powerChangeSpinner.visible = false;
      }
    }

    Timer {
      id: readFreqProfileTimer
      interval: 2000
      triggeredOnStart: true
      running: true
      repeat: true
      onTriggered: {
        readFreqProfileEngine.exec('pkexec ' + binDir
          + '/kfocus-power-set -r');
      }
    }

    ShellEngine {
      id: fanProfileModelFillEngine
      commandStr: binDir + '/kfocus-fan-set -x'
      onStdoutChanged: {
        let stdout_arr = [];

        stdout_arr =  stdout.split( '\n' );
        if ( stdout_arr[0].substring( 0, 8 ) == 'message:' ) {
          let body_msg = ''
          body_msg = stdout_arr[0].split( ':' )[1];
          stdout_arr.split( 0, 1 );
          stdout_arr.forEach( function ( line, index ) {
            body_msg += line;
          } );
          fanError.text = body_msg;
          return;
        }

        stdout_arr.forEach( function ( line, index ) {
          if ( line === '' ) { return; }
          let [name, description] = line.split( '(' );
          name = name.trim();
          description = description.split( ')' )[0];
          description = description.trim();
          fanProfilesModel.append( {
            'name': name,
            'description': description,
          } );
          fanProfilesModel.profileNames.push(name);
        } );

        fanSlider.visible = true;
        getFanProfileTimer.start();
      }
    }
  }

  ShellEngine {
    id: getFanProfileEngine
    onStdoutChanged: {
      let profile_str = '', profile_idx = 0;

      profile_str = stdout.split( "\n" )[0].split( ' ' )[0].trim();
      profile_idx = fanProfilesModel.profileNames.indexOf(profile_str);

      if ( profile_idx === -1 ) {
        fanDescription.text = 'Unknown';
      } else {
        fanSlider.value = profile_idx;
        fanDescription.text = getFanProfileDesc( profile_idx );
      }
    }
  }

  ShellEngine {
    id: setFanProfileEngine
    onStdoutChanged: {
      getFanProfileTimer.start();
    }
  }

  Timer {
    id: getFanProfileTimer
    interval: 2000
    triggeredOnStart: true
    repeat: true
    onTriggered: {
      getFanProfileEngine.exec( binDir + '/kfocus-fan-set -r' );
    }
  }

  function getFanProfileDesc ( profile_idx ) {
    const profile_obj = fanProfilesModel.get( profile_idx );
    return profile_obj.name + ' (' + profile_obj.description + ')';
  }

  readonly property string binDir: '/usr/lib/kfocus/bin'
}

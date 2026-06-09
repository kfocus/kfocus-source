import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import QtQuick.Window
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
  id            : root
  title         : 'Power and Fan'
  width         : Kirigami.Units.gridUnit * 35
  height        : Kirigami.Units.gridUnit * 40
  minimumWidth  : Kirigami.Units.gridUnit * 35
  minimumHeight : Kirigami.Units.gridUnit * 40

  pageStack.initialPage: Kirigami.Page {
    title: 'Power and Fan'

    ColumnLayout {
      id      : coreLayout
      spacing : Kirigami.Units.smallSpacing

      anchors {
        left  : parent.left
        right : parent.right
        top   : parent.top
      }

      Kirigami.Heading {
        visible : powerProfileSlider.visible
        enabled : powerProfileSlider.enabled
        text    : 'Power Profile'
        level   : 3
      }

      Controls.Slider {
        id       : powerProfileSlider
        visible  : true
        enabled  : false
        value    : 0
        to       : 2
        stepSize : 1

        Layout.fillWidth : true

        onValueChanged : {
          readPowerProfileTimer.stop();
          readPowerProfileEngine.ignoreResult();
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
        visible : powerProfileSlider.visible
        color   : 'transparent'

        Layout.fillWidth       : true
        Layout.preferredHeight : childrenRect.height
        Layout.bottomMargin    : Kirigami.Units.largeSpacing

        Controls.Label {
          text : '🔋 Powersave'

          anchors {
            left : parent.left
            top  : parent.top
          }
        }

        Controls.Label{
          horizontalAlignment : Text.AlignHCenter
          text                : 'Balanced'

          anchors {
            left  : parent.left
            right : parent.right
            top   : parent.top
          }
        }

        Controls.Label {
          text : 'Performance ⚡'

          anchors {
            right : parent.right
            top   : parent.top
          }
        }
      }

      Kirigami.Heading {
        visible : brightnessSlider.visible
        text    : 'Brightness'
        level   : 3
      }

      Controls.Slider {
        id       : brightnessSlider
        visible  : false
        snapMode : Controls.Slider.NoSnap

        Layout.fillWidth : true

        onValueChanged : {
          readBrightnessTimer.stop();
          readBrightnessEngine.ignoreResult();
          setBrightnessEngine.exec('dbus-send --print-reply=literal '
            + '--session --dest=org.kde.Solid.PowerManagement '
            + '/org/kde/Solid/PowerManagement/Actions/BrightnessControl '
            + 'org.kde.Solid.PowerManagement.Actions.BrightnessControl.setBrightness '
            + 'int32:' + brightnessSlider.value.toString());
        }
      }

      RowLayout {
        visible : brightnessSlider.visible
        spacing : 0

        Layout.fillWidth    : true
        Layout.bottomMargin : Kirigami.Units.largeSpacing

        Controls.Label {
          text : '🔅 Dimmer'

          Layout.leftMargin : 3
        }

        Item {
          Layout.fillWidth : true
        }

        Controls.Label {
          text : 'Brighter 🔆'

          Layout.rightMargin : 8
        }
      }

      RowLayout {
        Kirigami.Heading {
          property string cpuId : ''

          id      : powerHeading
          visible : true
          text    : 'Frequency Profile (' + cpuId + ')'
          level   : 3

          Layout.bottomMargin : Kirigami.Units.smallSpacing
        }

        Controls.BusyIndicator {
          id      : powerChangeSpinner
          visible : false

          Layout.preferredWidth  : Kirigami.Units.gridUnit
          Layout.preferredHeight : Kirigami.Units.gridUnit
        }
      }

      Controls.ButtonGroup {
        id : freqRadioGroup
      }

      GridLayout {
        id            : freqGrid
        visible       : false
        columnSpacing : 1
        rowSpacing    : 3

        Layout.bottomMargin : Kirigami.Units.smallSpacing
        Layout.fillWidth    : true

        // Number of columns is set by freqProfileModelFillEngine
        Repeater {
          id    : freqRepeater
          model : freqProfilesModel

          // Each cell of the grid is a rectangle; we have magic properties
          // that are defined in the model, namely elementName, rowIndex,
          // colIndex, elementColor, and firstElementName.
          Rectangle {
            property bool isFirstElement  : colIndex === 0
            property bool doHighlightCell : !isFirstElement
              && firstElementName === freqProfilesModel.selectedProfile
            property bool isHeaderRow     : rowIndex === 0
            property bool bold            : isHeaderRow || isFirstElement
              || doHighlightCell

            color  : isHeaderRow || doHighlightCell ? 'gray' : elementColor
            radius : Kirigami.Units.gridUnit / 6

            // Column size ratio is controlled by the colIndex ternary
            Layout.rightMargin     : 2
            Layout.preferredWidth  : (coreLayout.width
              - (Layout.rightMargin * freqGrid.columns * 2))
              * (isFirstElement ? 0.25 : colIndex === 1 ? 0.30 : 0.45
                / (freqGrid.columns - 2))
            Layout.preferredHeight : 30

            Controls.RadioButton {
              id      : freqRadioButton
              visible : isFirstElement && !isHeaderRow
              checked : freqProfilesModel.selectedProfile === elementName

              Controls.ButtonGroup.group : freqRadioGroup

              anchors.verticalCenter : parent.verticalCenter
              anchors.left           : parent.left
              anchors.leftMargin     : 5

              onClicked : {
                freqGrid.enabled = false;
                powerChangeSpinner.visible = true;
                readFreqProfileTimer.stop();
                readFreqProfileEngine.ignoreResult();
                setFreqProfileEngine.exec( 'pkexec ' + binDir
                  + '/kfocus-power-set ' + elementName );
                freqProfilesModel.selectedProfile = elementName;
              }
            }

            Controls.Label {
              text : {
                let elementText = elementName
                if ( bold ) {
                  elementText = elementText.replace( ' ', '&nbsp;' );
                  elementText = '<b><font color="white">' + elementText
                    + '</font></b>';
                }
                return elementText;
              }

              font.family : isHeaderRow || isFirstElement
                ? 'Noto Sans' : 'Courier'

              anchors {
                left           : isFirstElement
                  ? freqRadioButton.right : parent.left
                right          : parent.right
                verticalCenter : parent.verticalCenter
                leftMargin     : isFirstElement ? 3 : 20
              }
            }
          }
        }
      }

      Kirigami.InlineMessage {
        id      : powerInlineMsg
        visible : false
        text    : 'Frequency Modes Not Found'

        Layout.fillWidth    : true
        Layout.bottomMargin : Kirigami.Units.largeSpacing
      }

      Controls.Label {
        id      : cpuTypeLegend
        visible : false
        text    : 'P = perf core, E = efficient core'

        // Default margin is too large, tighten things up with a negative
        // margin
        Layout.bottomMargin : 0 - Kirigami.Units.smallSpacing
      }

      Controls.Label {
        id      : powerLegend
        visible : freqGrid.visible
        text    : 'psave = powersave, PERF = performance'
      }

      Kirigami.Heading {
        property string modelId : ''

        id    : fanControlHeading
        text  : 'Fan Profile (' + modelId + ')'
        level : 3

        Layout.topMargin : Kirigami.Units.largeSpacing
      }

      Kirigami.InlineMessage {
        id      : fanInlineMsg
        text    : 'Fan Profile Not Found'
        visible : !fanSlider.visible

        Layout.fillWidth : true
      }

      Controls.Slider {
        id       : fanSlider
        visible  : false
        to       : fanProfilesModel.count - 1
        stepSize : 1

        Layout.fillWidth : true

        onValueChanged : {
          readFanProfileTimer.stop();
          readFanProfileEngine.ignoreResult();
          setFanProfileEngine.exec( 'pkexec ' + binDir + '/kfocus-fan-set '
            + fanProfilesModel.profileNames[value] );
          fanDescription.text = getFanProfileDesc( value );
        }
      }

      RowLayout {
        id      : fanLabelLayout
        visible : fanSlider.visible
        spacing : 0

        Layout.fillWidth : true

        Repeater {
          model : fanProfilesModel

          Item {
            height : childrenRect.height
            width  : coreLayout.width / 3

            Item {
              height : childrenRect.height
              width  : childrenRect.width

              anchors {
                left             : index === 0 ? parent.left : undefined
                right            : index === fanProfilesModel.count - 1
                  ? parent.right : undefined
                horizontalCenter : index !== 0
                  && index !== fanProfilesModel.count - 1
                  ? parent.horizontalCenter : undefined
              }

              Image {
                id       : fanProfileLeftImage
                visible  : index === 0
                source   : 'images/kfocus-fand-quiet.svg'
                height   : fanProfileLabel.height
                fillMode : Image.PreserveAspectFit

                anchors.left : parent.left
              }

              Controls.Label {
                id   : fanProfileLabel
                text : name

                anchors.left       : fanProfileLeftImage.right
                anchors.leftMargin : Kirigami.Units.gridUnit / 4
              }

              Image {
                id        : fanProfileRightImage
                visible   : index === fanProfilesModel.count - 1
                source    : 'images/kfocus-fand-loud.svg'
                height    : fanProfileLabel.height
                fillModei : Image.PreserveAspectFit

                anchors.left       : fanProfileLabel.right
                anchors.leftMargin : Kirigami.Units.gridUnit / 4
              }
            }
          }
        }
      }

      Controls.Label {
        id                  : fanDescription
        visible             : fanSlider.visible
        text                : ''
        horizontalAlignment : Text.AlignHCenter

        Layout.fillWidth    : true
        Layout.bottomMargin : Kirigami.Units.smallSpacing
      }
    }

    ListModel {
      property string selectedProfile : ''
      property var gridColors         : ['transparent', '#F63114', '#F7941E',
        '#33cc33', '#3caae4', '#0085be'].reverse()

      id : freqProfilesModel
    }

    ListModel {
      // It's very difficult to get the index of an item in a model, so this
      // provides a lookup mechanism.
      property var profileNames : []

      id : fanProfilesModel
    }

    ShellEngine {
      id : readPowerProfileEngine

      onStdoutChanged : {
        switch ( stdout.trim() ) {
        case 'performance':
          powerProfileSlider.value = 2;
          break;
        case 'balanced':
          powerProfileSlider.value = 1;
          break;
        case 'power-saver':
          powerProfileSlider.value = 0;
          break;
        }
        powerProfileSlider.enabled = true;
      }
    }

    ShellEngine {
      id : setPowerProfileEngine

      onStdoutChanged : {
        readPowerProfileTimer.start();
      }
    }

    Timer {
      id               : readPowerProfileTimer
      interval         : 2000
      triggeredOnStart : true
      running          : true
      repeat           : true

      onTriggered : {
        readPowerProfileEngine.exec('powerprofilesctl get');
      }
    }

    ShellEngine {
      id         : readMaxBrightnessEngine
      commandStr : 'dbus-send --print-reply=literal --session '
        + '--dest=org.kde.Solid.PowerManagement '
        + '/org/kde/Solid/PowerManagement/Actions/BrightnessControl '
        + 'org.kde.Solid.PowerManagement.Actions.BrightnessControl.brightnessMax '
        + '| awk \'{ print $2 }\''

      onStdoutChanged: {
        brightnessSlider.to = Number(stdout.trim());
        brightnessSlider.visible = true;
        readBrightnessTimer.start();
      }
    }

    ShellEngine {
      id : readBrightnessEngine

      onStdoutChanged : {
        brightnessSlider.value = Number(stdout.trim());
      }
    }

    ShellEngine {
      id : setBrightnessEngine

      onStdoutChanged : {
        readBrightnessTimer.start();
      }
    }

    Timer {
      id               : readBrightnessTimer
      interval         : 2000
      triggeredOnStart : true
      repeat           : true

      onTriggered : {
        readBrightnessEngine.exec('dbus-send --print-reply=literal --session '
          + '--dest=org.kde.Solid.PowerManagement '
          + '/org/kde/Solid/PowerManagement/Actions/BrightnessControl '
          + 'org.kde.Solid.PowerManagement.Actions.BrightnessControl.brightness '
          + '| awk \'{ print $2 }\'');
      }
    }

    ShellEngine {
      id         : freqProfileModelFillEngine
      commandStr : 'pkexec ' + binDir + '/kfocus-power-set -x'

      onStdoutChanged : {
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
          powerInlineMsg.text = body_msg;
          powerInlineMsg.visible = true;
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

        freqGrid.visible = true;
        freqGrid.columns = col_count;
      }
    }

    ShellEngine {
      id : readFreqProfileEngine

      onStdoutChanged : {
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
      id : setFreqProfileEngine

      onStdoutChanged : {
        readFreqProfileTimer.start()
        freqGrid.enabled = true;
        powerChangeSpinner.visible = false;
      }
    }

    Timer {
      id               : readFreqProfileTimer
      interval         : 2000
      triggeredOnStart : true
      running          : true
      repeat           : true

      onTriggered : {
        readFreqProfileEngine.exec('pkexec ' + binDir
          + '/kfocus-power-set -r');
      }
    }

    ShellEngine {
      id         : fanProfileModelFillEngine
      commandStr : 'pkexec ' + binDir + '/kfocus-fan-set -x'

      onStdoutChanged : {
        let stdout_arr = [];

        stdout_arr =  stdout.split( '\n' );
        if ( stdout_arr[0].substring( 0, 8 ) == 'message:' ) {
          let body_msg = ''
          body_msg = stdout_arr[0].split( ':' )[1];
          stdout_arr.split( 0, 1 );
          stdout_arr.forEach( function ( line, index ) {
            body_msg += line;
          } );
          fanInlineMsg.text = body_msg;
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
        readFanProfileTimer.start();
      }
    }
  }

  ShellEngine {
    id : readFanProfileEngine

    onStdoutChanged : {
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
    id : setFanProfileEngine

    onStdoutChanged : {
      readFanProfileTimer.start();
    }
  }

  Timer {
    id               : readFanProfileTimer
    interval         : 2000
    triggeredOnStart : true
    repeat           : true

    onTriggered : {
      readFanProfileEngine.exec( 'pkexec ' + binDir + '/kfocus-fan-set -r' );
    }
  }

  function getFanProfileDesc ( profile_idx ) {
    const profile_obj = fanProfilesModel.get( profile_idx );
    return profile_obj.description
  }

  readonly property string binDir: '/usr/lib/kfocus/bin'
}

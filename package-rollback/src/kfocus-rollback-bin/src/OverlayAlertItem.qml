import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Rectangle {
    property bool isVisible: false
    property string mainIcon: ''
    property string headerText: ''
    property string mainText: ''
    property string secondaryText: ''
    property string primaryButtonText: 'Ok'
    property string secondaryButtonText: 'Cancel'
    property string primaryButtonIcon: ''
    property string secondaryButtonIcon: ''
    property bool showSecondaryButton: true

    signal primaryButtonClicked();
    signal secondaryButtonClicked();

    id: postRestoreOverlay
    visible: isVisible

    anchors.fill: parent
    color: Kirigami.Theme.backgroundColor

    MouseArea {
        anchors.fill: parent
    }

    ColumnLayout {
        anchors {
            verticalCenter: parent.verticalCenter
            horizontalCenter: parent.horizontalCenter
        }

        RowLayout {
            Kirigami.Icon {
                Layout.alignment: Qt.AlignTop
                Layout.preferredHeight: Kirigami.Units.gridUnit * 4
                Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                Layout.rightMargin:
                  Kirigami.Units.gridUnit * 1
                Layout.topMargin:
                  Kirigami.Units.gridUnit * 2
                source: mainIcon
            }

            ColumnLayout {
                Kirigami.Heading {
                    Layout.bottomMargin:
                      Kirigami.Units.gridUnit * 0.5
                    text: headerText
                    level: 1
                }

                Controls.Label {
                    Layout.preferredWidth:
                      Kirigami.Units.gridUnit * 20
                    Layout.bottomMargin:
                      Kirigami.Units.gridUnit * 0.5
                    text: mainText
                    wrapMode: Text.WordWrap
                    onLinkActivated: Qt.openUrlExternally(link)
                }

                Controls.Label {
                    Layout.preferredWidth:
                      Kirigami.Units.gridUnit * 20
                    text: secondaryText
                    visible: secondaryText !== ''
                    wrapMode: Text.WordWrap
                    onLinkActivated: Qt.openUrlExternally(link)
                }

                RowLayout {
                    Layout.preferredWidth:
                      Kirigami.Units.gridUnit * 20

                    Item {
                        Layout.fillWidth: true
                    }

                    Controls.Button {
                        text: primaryButtonText
                        icon.name: primaryButtonIcon
                        onClicked: primaryButtonClicked()
                    }

                    Controls.Button {
                        Layout.leftMargin:
                          Kirigami.Units.gridUnit * 0.6
                        visible: showSecondaryButton
                        text: secondaryButtonText
                        icon.name: secondaryButtonIcon
                        onClicked: secondaryButtonClicked()
                    }
                }
            }
        }
    }
}

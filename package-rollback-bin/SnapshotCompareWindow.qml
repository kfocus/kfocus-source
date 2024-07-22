import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as Controls
import org.kde.kirigami 2.20 as Kirigami

Kirigami.ApplicationWindow {
    id: root
    property string compareText      : ''
    property string sourceSnapshotId : ''
    property string targetSnapshotId : ''

    title         : 'Compare Snapshots'

    width         : Kirigami.Units.gridUnit * 30
    height        : Kirigami.Units.gridUnit * 22
    minimumWidth  : Kirigami.Units.gridUnit * 30
    minimumHeight : Kirigami.Units.gridUnit * 22

    pageStack.initialPage: Kirigami.Page {
        title : 'Compare Snapshots'

        ColumnLayout {
            anchors.fill : parent

            Kirigami.Heading {
                text                : 'Comparison results:'
                level               : 1
                Layout.bottomMargin : Kirigami.Units.gridUnit * 0.25
            }

            Controls.Label {
                text : '<p>Base snapshot: <b><font color="#f7941d">'
                  + sourceSnapshotId
                  + '</font></b></p>'
                  + 'Snapshot being compared to: <b><font color="#f7941d">'
                  + targetSnapshotId
                  + '</font></b>'
                Layout.bottomMargin : Kirigami.Units.gridUnit * 0.25
            }

            Controls.ScrollView {
                Layout.fillWidth  : true
                Layout.fillHeight : true

                Controls.TextArea {
                    text        : compareText
                    readOnly    : true
                    font.family : 'Monospace'
                }
            }
        }
    }
}

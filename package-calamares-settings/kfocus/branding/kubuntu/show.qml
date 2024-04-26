import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }
    Slide {
        Image {
            id: image1
            anchors.centerIn: parent
            anchors.verticalCenterOffset: - parent.y / 3.6
            height: parent.masterHeight * 0.95
            width: parent.masterWidth * 0.95
            fillMode: Image.PreserveAspectFit
            smooth: true
            source: "01_Easy_Install.png"
        }
    }
    Slide {
        Image {
            id: image2
            anchors.centerIn: parent
            anchors.verticalCenterOffset: - parent.y / 3.6
            height: parent.masterHeight * 0.95
            width: parent.masterWidth * 0.95
            fillMode: Image.PreserveAspectFit
            smooth: true
            source: "02_Customizable_Desktop.png"
        }
    }
    Slide {
        Image {
            id: image3
            anchors.centerIn: parent
            anchors.verticalCenterOffset: - parent.y / 3.6
            height: parent.masterHeight * 0.95
            width: parent.masterWidth * 0.95
            fillMode: Image.PreserveAspectFit
            smooth: true
            source: "03_Built-in_Applications.png"
        }
    }
    Slide {
        Image {
            id: image4
            anchors.centerIn: parent
            anchors.verticalCenterOffset: - parent.y / 3.6
            height: parent.masterHeight * 0.95
            width: parent.masterWidth * 0.95
            fillMode: Image.PreserveAspectFit
            smooth: true
            source: "04_Performant.png"
        }
    }
    Slide {
        Image {
            id: image5
            anchors.centerIn: parent
            anchors.verticalCenterOffset: - parent.y / 3.6
            height: parent.masterHeight * 0.95
            width: parent.masterWidth * 0.95
            fillMode: Image.PreserveAspectFit
            smooth: true
            source: "05_Secure_and_Private.png"
        }
    }
    Slide {
        Image {
            id: image6
            anchors.centerIn: parent
            anchors.verticalCenterOffset: - parent.y / 3.6
            height: parent.masterHeight * 0.95
            width: parent.masterWidth * 0.95
            fillMode: Image.PreserveAspectFit
            smooth: true
            source: "06_Community_Support.png"
        }

    }
    Slide {
        Image {
            id: image7
            anchors.centerIn: parent
            anchors.verticalCenterOffset: - parent.y / 3.6
            height: parent.masterHeight * 0.95
            width: parent.masterWidth * 0.95
            fillMode: Image.PreserveAspectFit
            smooth: true
            source: "07_Free_and_Open_Source.png"
        }

    }
    Slide {
        Image {
            id: image8
            anchors.centerIn: parent
            anchors.verticalCenterOffset: - parent.y / 3.6
            height: parent.masterHeight * 0.95
            width: parent.masterWidth * 0.95
            fillMode: Image.PreserveAspectFit
            smooth: true
            source: "08_Software_Compatibility.png"
        }

    }
    Slide {
        Image {
            id: image9
            anchors.centerIn: parent
            anchors.verticalCenterOffset: - parent.y / 3.6
            height: parent.masterHeight * 0.95
            width: parent.masterWidth * 0.95
            fillMode: Image.PreserveAspectFit
            smooth: true
            source: "09_Beautiful_Aesthetics.png"
        }

    }
    Slide {
        Image {
            id: image10
            anchors.centerIn: parent
            anchors.verticalCenterOffset: - parent.y / 3.6
            height: parent.masterHeight * 0.95
            width: parent.masterWidth * 0.95
            fillMode: Image.PreserveAspectFit
            smooth: true
            source: "10_Kubuntu_Focus.png"
        }

    }
    Slide {
        Image {
            id: image11
            anchors.centerIn: parent
            anchors.verticalCenterOffset: - parent.y / 3.6
            height: parent.masterHeight * 0.95
            width: parent.masterWidth * 0.95
            fillMode: Image.PreserveAspectFit
            smooth: true
            source: "11_Testimonials_of_Success.png"
        }

    }
        Slide {
        Image {
            id: image12
            anchors.centerIn: parent
            anchors.verticalCenterOffset: - parent.y / 3.6
            height: parent.masterHeight * 0.95
            width: parent.masterWidth * 0.95
            fillMode: Image.PreserveAspectFit
            smooth: true
            source: "12_Get_Involved.png"
        }

    }
}

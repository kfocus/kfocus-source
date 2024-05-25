#include "backgroundscreen.h"

#include <QMessageBox>
#include <QGuiApplication>
#include <QScreen>

BackgroundScreen::BackgroundScreen(QWidget *parent)
    : QWidget(parent) {

}

BackgroundScreen::~BackgroundScreen()
{
}

void BackgroundScreen::activateBackground()
{
    // Set the background image and scale it
    QImage image(":/background");
    if (image.isNull()) {
        return;
    }

    qreal imgRatio = static_cast<qreal>(image.width()) / image.height();
    qreal screenRatio = static_cast<qreal>(this->width()) / this->height();
    QImage scaled;
    if (imgRatio < screenRatio) {
        scaled = image.scaledToWidth(this->width(), Qt::SmoothTransformation);
        int yGap = (scaled.height() - this->height()) / 2;
        scaled = scaled.copy(0, yGap, scaled.width(), this->height());
    } else {
        scaled = image.scaledToHeight(this->height(), Qt::SmoothTransformation);
        int xGap = (scaled.width() - this->width()) / 2;
        scaled = scaled.copy(xGap, 0, this->width(), scaled.height());
    }
    QPixmap bg = QPixmap::fromImage(scaled);
    QPalette palette;
    palette.setBrush(QPalette::Window, bg);
    this->setPalette(palette);
}

#include "backgroundscreen.h"

#include <QMessageBox>
#include <QGuiApplication>
#include <QScreen>
#include <QPainter>

BackgroundScreen::BackgroundScreen(QWidget *parent)
    : QWidget(parent) {

}

BackgroundScreen::~BackgroundScreen()
{
}

void BackgroundScreen::activateBackground()
{
    // Set the background image and scale it
    QImage rawImage(":/background");
    if (rawImage.isNull()) {
        return;
    }

    qreal imgRatio = static_cast<qreal>(rawImage.width()) / rawImage.height();
    qreal screenRatio = static_cast<qreal>(this->width()) / this->height();
    QImage scaled;
    if (imgRatio < screenRatio) {
        scaled = rawImage.scaledToWidth(this->width(), Qt::SmoothTransformation);
        int yGap = (scaled.height() - this->height()) / 2;
        scaled = scaled.copy(0, yGap, scaled.width(), this->height());
    } else {
        scaled = rawImage.scaledToHeight(this->height(), Qt::SmoothTransformation);
        int xGap = (scaled.width() - this->width()) / 2;
        scaled = scaled.copy(xGap, 0, this->width(), scaled.height());
    }
    background = scaled;
}

void BackgroundScreen::paintEvent(QPaintEvent *event) {
    QPainter painter(this);
    painter.drawImage(0, 0, background);
}

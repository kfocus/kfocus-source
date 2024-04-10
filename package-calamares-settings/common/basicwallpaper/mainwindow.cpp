#include "mainwindow.h"
#include "./ui_mainwindow.h"

#include <QDebug>
#include <QImage>

MainWindow::MainWindow(const QString &wallpaperFile, QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    m_wallpaperFile = wallpaperFile;
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::applyWallpaper()
{
    QImage image(m_wallpaperFile);
    if (!image.isNull()) {
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
    } else {
        qCritical() << "ERROR: Wallpaper does not exist!";
    }
}

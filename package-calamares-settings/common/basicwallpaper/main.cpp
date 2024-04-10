#include "mainwindow.h"

#include <QApplication>
#include <QScreen>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);

    QString wallpaperFile;

    if (argc > 1) {
        wallpaperFile = QString(argv[1]);
    } else {
        return 1;
    }

    for (QScreen *screen : QApplication::screens()) {
        MainWindow *w = new MainWindow(wallpaperFile);
        w->setWindowFlags(Qt::WindowStaysOnBottomHint);
        w->setGeometry(screen->geometry());
        w->showFullScreen();
        w->show();
        w->applyWallpaper();
    }

    return a.exec();
}

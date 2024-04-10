#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>

QT_BEGIN_NAMESPACE
namespace Ui { class MainWindow; }
QT_END_NAMESPACE

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(const QString &wallpaperFile, QWidget *parent = nullptr);
    ~MainWindow();

    void applyWallpaper();

private:
    Ui::MainWindow *ui;
    QString m_wallpaperFile;
};
#endif // MAINWINDOW_H

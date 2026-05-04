#ifndef BACKGROUNDSCREEN_H
#define BACKGROUNDSCREEN_H

#include <QWidget>

class BackgroundScreen : public QWidget {
    Q_OBJECT

public:
    explicit BackgroundScreen(QWidget *parent = nullptr);
    virtual ~BackgroundScreen();
    void activateBackground();

private:
    void paintEvent(QPaintEvent *event) override;
    QImage background;
};

#endif // BACKGROUNDSCREEN_H

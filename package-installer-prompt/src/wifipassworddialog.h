#ifndef WIFIPASSWORDDIALOG_H
#define WIFIPASSWORDDIALOG_H

#include <QDialog>

namespace Ui {
class WifiPasswordDialog;
}

class WifiPasswordDialog : public QDialog
{
    Q_OBJECT

public:
    explicit WifiPasswordDialog(QString ssid, QWidget *parent = nullptr);
    ~WifiPasswordDialog();
    QString getPassword();

protected slots:
    void closeEvent(QCloseEvent *event) override;

private slots:
    void onConnectClicked();

private:
    Ui::WifiPasswordDialog *ui;
    QString password;
};

#endif // WIFIPASSWORDDIALOG_H

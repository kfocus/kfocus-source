#ifndef CONNECTIONPROGRESSDIALOG_H
#define CONNECTIONPROGRESSDIALOG_H

#include <QDialog>

namespace Ui {
class ConnectionProgressDialog;
}

class ConnectionProgressDialog : public QDialog
{
    Q_OBJECT

public:
    explicit ConnectionProgressDialog(QWidget *parent = nullptr);
    ~ConnectionProgressDialog();
    void setNetworkName(QString name);

protected slots:
    void closeEvent(QCloseEvent *event) override;

private:
    Ui::ConnectionProgressDialog *ui;
};

#endif // CONNECTIONPROGRESSDIALOG_H

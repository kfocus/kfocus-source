#ifndef WARNINGDIALOG_H
#define WARNINGDIALOG_H

#include <QDialog>

namespace Ui {
class WarningDialog;
}

class WarningDialog : public QDialog
{
    Q_OBJECT

public:
    explicit WarningDialog(QString warningText, QWidget *parent = nullptr);
    ~WarningDialog();
    static void showWarning(QString warningText);

private slots:
    void onOkClicked();

private:
    Ui::WarningDialog *ui;
};

#endif // WARNINGDIALOG_H

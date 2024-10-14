#ifndef TBTCTLDIALOG_H
#define TBTCTLDIALOG_H

#include <QDialog>
#include <QPalette>

QT_BEGIN_NAMESPACE
namespace Ui {
class TbtCtlDialog;
}
QT_END_NAMESPACE

class TbtCtlEngine;

class TbtCtlDialog : public QDialog
{
    Q_OBJECT

public:
    TbtCtlDialog(QWidget *parent = nullptr);
    ~TbtCtlDialog();

private:
    Ui::TbtCtlDialog *ui;
    TbtCtlEngine *m_engine;
    bool m_tbtEnabled;
    bool m_tbtPersistEnabled;
    QPalette m_checkboxNormalPalette;
    QPalette m_checkboxChangedPalette;

    void setOkButtonState();

private slots:
    void onTbtEnabledCheckboxChanged();
    void onTbtPersistEnabledCheckboxChanged();
    void onEnableInfoButtonClicked();
    void onEnablePersistInfoButtonClicked();
    void onOkClicked();
    void onCancelClicked();
    void onStateSetSuccess();
    void onStateSetFailure();
};
#endif // TBTCTLDIALOG_H

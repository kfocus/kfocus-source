#include "warningdialog.h"
#include "ui_warningdialog.h"

WarningDialog::WarningDialog(QString warningText, QWidget *parent) :
    QDialog(parent),
    ui(new Ui::WarningDialog)
{
    ui->setupUi(this);
    ui->warningLabel->setText(warningText);
    connect (ui->okButton, &QPushButton::clicked, this, &WarningDialog::onOkClicked);
}

WarningDialog::~WarningDialog()
{
    delete ui;
}

void WarningDialog::showWarning(QString warningText)
{
    WarningDialog warn(warningText);
    warn.exec();
}

void WarningDialog::onOkClicked()
{
    this->done(0);
}

#include "connectionprogressdialog.h"
#include "ui_connectionprogressdialog.h"

#include <QCloseEvent>

ConnectionProgressDialog::ConnectionProgressDialog(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::ConnectionProgressDialog)
{
    ui->setupUi(this);
}

ConnectionProgressDialog::~ConnectionProgressDialog()
{
    delete ui;
}

void ConnectionProgressDialog::setNetworkName(QString name)
{
    ui->label->setText(tr("Connecting to %1...").arg(name));
}

void ConnectionProgressDialog::closeEvent(QCloseEvent *event)
{
    event->ignore();
}

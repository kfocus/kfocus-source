#include "wifipassworddialog.h"
#include "ui_wifipassworddialog.h"

#include <QCloseEvent>

WifiPasswordDialog::WifiPasswordDialog(QString ssid, QWidget *parent) :
    QDialog(parent),
    ui(new Ui::WifiPasswordDialog)
{
    ui->setupUi(this);

    ui->wifiLabel->setText(tr("Enter password for %1:").arg(ssid));
    connect(ui->connectButton, &QPushButton::clicked, this, &WifiPasswordDialog::onConnectClicked);
}

WifiPasswordDialog::~WifiPasswordDialog()
{
    delete ui;
}

void WifiPasswordDialog::onConnectClicked()
{
    password = ui->passwordBox->text();
    this->done(0);
}

QString WifiPasswordDialog::getPassword()
{
    return password;
}

void WifiPasswordDialog::closeEvent(QCloseEvent *event)
{
    event->ignore();
}

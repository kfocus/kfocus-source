#ifndef INSTALLERPROMPT_H
#define INSTALLERPROMPT_H

#include <QMainWindow>
#include <QComboBox>
#include <QProcess>
#include <QPushButton>
#include <QLabel>
#include <QDialog>
#include <QMutex>
#include <QLineEdit>
#include <QProcess>
#include <QImage>
#include <NetworkManagerQt/Device>
#include <NetworkManagerQt/WirelessDevice>
#include <NetworkManagerQt/WiredDevice>
#include <NetworkManagerQt/WirelessNetwork>

class ConnectionProgressDialog;

namespace Ui { class InstallerPrompt; }

class InstallerPrompt : public QMainWindow {
    Q_OBJECT

public:
    explicit InstallerPrompt(QWidget *parent = nullptr);
    ~InstallerPrompt() override;
    void activateBackground();

private slots:
    void onTryClicked();
    void onInstallClicked();
    void onLanguageSelected(int index);
    void onNetworkSelected(int index);
    void updateConnectionInfo();
    void handleWiFiConnectionChange(NetworkManager::Device::State newstate, NetworkManager::Device::State oldstate, NetworkManager::Device::StateChangeReason reason);
    void languageProcessError(QProcess::ProcessError error);

private:
    Ui::InstallerPrompt *ui;
    ConnectionProgressDialog *cpd;
    NetworkManager::WirelessDevice::Ptr wifiDevice;
    bool hitWifiDevice = false;
    QString wifiSsid;
    bool wifiWrongHandling = false;
    QMap<QString, QString> languageLocaleMap;
    bool firstUpdateConnectionInfoCall = true;
    void paintEvent(QPaintEvent *event) override;

    void initLanguageComboBox();
    QStringList getAvailableLanguages();
    QString getDisplayNameForLocale(const QLocale &locale);
    QImage background;
};

#endif // INSTALLERPROMPT_H

/*
 * Copyright (C) 2022-2023 Lubuntu Developers <lubuntu-devel@lists.ubuntu.com>
 * Copyright (C) 2024      Kubuntu Developers <kubuntu-devel@lists.ubuntu.com>
 * Authored by: Simon Quigley <tsimonq2@lubuntu.me>
 *              Aaron Rainbolt <arraybolt3@lubuntu.me>
 *
 * This is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * This is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 */

#include <NetworkManagerQt/ConnectionSettings>
#include <NetworkManagerQt/Manager>
#include <NetworkManagerQt/Device>
#include <NetworkManagerQt/Ipv4Setting>
#include <NetworkManagerQt/Ipv6Setting>
#include <NetworkManagerQt/WirelessDevice>
#include <NetworkManagerQt/WirelessNetwork>
#include <NetworkManagerQt/WirelessSecuritySetting>
#include <NetworkManagerQt/WirelessSetting>
#include <NetworkManagerQt/Settings>
#include <QProcess>
#include <QScreen>
#include <QTimer>
#include <QFile>
#include <QUuid>
#include <QDBusPendingReply>
#include "installerprompt.h"
#include "wifipassworddialog.h"
#include "languagechangedialog.h"
#include "warningdialog.h"
#include "connectionprogressdialog.h"
#include "./ui_installerprompt.h"

InstallerPrompt::InstallerPrompt(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::InstallerPrompt) {
    ui->setupUi(this);

    cpd = new ConnectionProgressDialog();

    initLanguageComboBox();

    connect(ui->tryKubuntu, &QPushButton::clicked, this, &InstallerPrompt::onTryClicked);
    connect(ui->installKubuntu, &QPushButton::clicked, this, &InstallerPrompt::onInstallClicked);
    connect(ui->languageComboBox, SIGNAL(activated(int)), this, SLOT(onLanguageSelected(int)));
    connect(ui->networkComboBox, SIGNAL(activated(int)), this, SLOT(onNetworkSelected(int)));

    auto nm = NetworkManager::notifier();
    connect(nm, &NetworkManager::Notifier::deviceAdded, this, &InstallerPrompt::updateConnectionInfo);
    connect(nm, &NetworkManager::Notifier::deviceRemoved, this, &InstallerPrompt::updateConnectionInfo);
    connect(nm, &NetworkManager::Notifier::activeConnectionsChanged, this, &InstallerPrompt::updateConnectionInfo);
    connect(nm, &NetworkManager::Notifier::wirelessEnabledChanged, this, &InstallerPrompt::updateConnectionInfo);
    connect(nm, &NetworkManager::Notifier::activeConnectionAdded, this, &InstallerPrompt::updateConnectionInfo);
    connect(nm, &NetworkManager::Notifier::connectivityChanged, this, &InstallerPrompt::updateConnectionInfo);
    connect(nm, &NetworkManager::Notifier::primaryConnectionChanged, this, &InstallerPrompt::updateConnectionInfo);

    QTimer *repeater = new QTimer();
    connect(repeater, SIGNAL(timeout()), this, SLOT(updateConnectionInfo()));
    repeater->start(15000);
    
    updateConnectionInfo();
}

InstallerPrompt::~InstallerPrompt()
{

}

void InstallerPrompt::activateBackground()
{
    // Set the background image and scale it
    QImage image(":/background");
    if (image.isNull()) {
        WarningDialog::showWarning(tr("Background image cannot be loaded."));
        return;
    }

    qreal imgRatio = static_cast<qreal>(image.width()) / image.height();
    qreal screenRatio = static_cast<qreal>(this->width()) / this->height();
    QImage scaled;
    if (imgRatio < screenRatio) {
        scaled = image.scaledToWidth(this->width(), Qt::SmoothTransformation);
        int yGap = (scaled.height() - this->height()) / 2;
        scaled = scaled.copy(0, yGap, scaled.width(), this->height());
    } else {
        scaled = image.scaledToHeight(this->height(), Qt::SmoothTransformation);
        int xGap = (scaled.width() - this->width()) / 2;
        scaled = scaled.copy(xGap, 0, this->width(), scaled.height());
    }
    QPixmap bg = QPixmap::fromImage(scaled);
    QPalette palette;
    palette.setBrush(QPalette::Window, bg);
    this->setPalette(palette);
}

void InstallerPrompt::onTryClicked()
{
    QApplication::quit();
}

void InstallerPrompt::onInstallClicked()
{
    ui->tryKubuntu->setEnabled(false);
    ui->installKubuntu->setEnabled(false);
    ui->tryKubuntu->setToolTip("");
    ui->installKubuntu->setToolTip("");
    ui->languageComboBox->setEnabled(false);
    QProcess *calamares = new QProcess(this);
    calamares->setProgram("/usr/bin/sudo");
    calamares->setArguments(QStringList() << "-E" << "calamares" << "-D8");
    calamares->start();

    // If Calamares exits, it either crashed or the user cancelled the installation. Exit the installer prompt (and start Plasma).
    connect(calamares, SIGNAL(finished(int)), this, SLOT(onTryClicked()));
}

void InstallerPrompt::onLanguageSelected(int index)
{
    QString selectedLanguage = ui->languageComboBox->itemText(index);
    QString localeName = languageLocaleMap.value(selectedLanguage);
    qDebug() << selectedLanguage << localeName;

    // Split the locale name to get language and country code
    QStringList localeParts = localeName.split('_');
    QString languageCode = localeParts.value(0);
    QString countryCode = localeParts.value(1);

    // If there is no internet connection and we don't ship the langpack, tell them
    QStringList allowedLanguages = {"zh-hans", "hi", "es", "fr", "ar", "en"};

    bool only_plasma = false;
    if (!allowedLanguages.contains(languageCode) && NetworkManager::status() != NetworkManager::Status::Connected) {
        only_plasma = true;
    }

    // Some of the LibreOffice language packs need special-casing, do that here
    QString libreOfficeLang;
    if (localeParts[0] == "zh") {
        libreOfficeLang = (countryCode == "CN" || countryCode == "SG" || countryCode == "MY") ? "zh-cn" : "zh-tw";
    } else {
        static const QMap<QString, QString> localeMap = {
            {"en_GB", "en-gb"}, {"en_ZA", "en-za"}, {"pa_IN", "pa-in"}, {"pt_BR", "pt-br"}
        };
        libreOfficeLang = localeMap.value(localeParts.join('_'), languageCode);
    }

    // Construct the command to run the script with parameters
    QProcess *process = new QProcess(this);
    QStringList arguments;

    process->setProgram("sudo");
    arguments << "/usr/libexec/change-system-language" << languageCode << countryCode << libreOfficeLang;
    if (only_plasma) arguments << "1";
    process->setArguments(arguments);

    connect(process, &QProcess::errorOccurred, this, &InstallerPrompt::languageProcessError);
    process->start();

    LanguageChangeDialog lcd;
    lcd.exec();
}

void InstallerPrompt::languageProcessError(QProcess::ProcessError error) {
    qDebug() << "Process failed with error:" << error;
}

void InstallerPrompt::onNetworkSelected(int index)
{
    QString networkId = ui->networkComboBox->itemData(index).toString();
    if (!networkId.isNull()) {
        if (networkId.left(4) == "UNI_") { // this is an Ethernet device
            QString deviceUni = networkId.right(networkId.count() - 4);
            NetworkManager::WiredDevice wiredDevice(deviceUni);
            QDBusPendingReply reply = wiredDevice.disconnectInterface();
            reply.waitForFinished();

            NetworkManager::Connection::List availableConnections = wiredDevice.availableConnections();
            if (availableConnections.count() > 0) {
                QString ethernetName = ui->networkComboBox->itemText(index).split(":")[0];
                NetworkManager::activateConnection(availableConnections[0]->path(), wiredDevice.uni(), QString());
                cpd->setNetworkName(ethernetName);
            } else {
                WarningDialog::showWarning(tr("Selected Ethernet device has no network!"));
            }
        } else { // this is a Wifi connection
            wifiSsid = networkId.right(networkId.length() - 4);
            bool isPasswordProtected = true;

            for (const auto &network : wifiDevice->networks()) {
                if (network->ssid() == wifiSsid) {
                    NetworkManager::AccessPoint::Ptr ap = network->referenceAccessPoint();
                    if (!ap->capabilities().testFlag(NetworkManager::AccessPoint::Privacy)) {
                        isPasswordProtected = false;
                    }
                }
            }

            QDBusPendingReply reply = wifiDevice->disconnectInterface();
            reply.waitForFinished();
            NetworkManager::Connection::Ptr targetConnection;

            foreach (const NetworkManager::Connection::Ptr &connection, NetworkManager::listConnections()) {
                if (connection->settings()->connectionType() == NetworkManager::ConnectionSettings::Wireless) {
                    auto wirelessSetting = connection->settings()->setting(NetworkManager::Setting::Wireless).dynamicCast<NetworkManager::WirelessSetting>();
                    if (wirelessSetting && wirelessSetting->ssid() == wifiSsid) {
                        targetConnection = connection;
                    }
                }
            }

            if (targetConnection) {
                NetworkManager::activateConnection(targetConnection->path(), wifiDevice->uni(), QString());
                cpd->setNetworkName(wifiSsid);
            } else {
                NMVariantMapMap wifiSettings;
                if (!wifiDevice) {
                    qWarning() << "WiFi device not found. Unable to set interface name.";
                    return;
                }
                NetworkManager::ConnectionSettings::Ptr newConnectionSettings(new NetworkManager::ConnectionSettings(NetworkManager::ConnectionSettings::Wireless));
                newConnectionSettings->setId(wifiSsid);
                newConnectionSettings->setUuid(NetworkManager::ConnectionSettings::createNewUuid());
                newConnectionSettings->setInterfaceName(wifiDevice->interfaceName());
                QVariantMap wirelessSetting;
                wirelessSetting.insert("ssid", wifiSsid.toUtf8());
                wifiSettings.insert("802-11-wireless", wirelessSetting);
                const auto settingsMap = newConnectionSettings->toMap();
                for (const auto &key : settingsMap.keys()) {
                    QVariant value = settingsMap.value(key);
                    wifiSettings.insert(key, value.toMap());
                }

                if (isPasswordProtected) {
                    WifiPasswordDialog wpd(wifiSsid);
                    wpd.exec();
                    QString password = wpd.getPassword();
                    if (password.isEmpty()) {
                        return;
                    }
                    QVariantMap wirelessSecurity;
                    wirelessSecurity["key-mgmt"] = "wpa-psk";
                    wirelessSecurity["psk"] = password;
                    wifiSettings["802-11-wireless-security"] = wirelessSecurity;
                }

                QDBusPendingReply<QDBusObjectPath> reply = NetworkManager::addConnection(wifiSettings);
                reply.waitForFinished();
                if (reply.isError()) {
                    WarningDialog::showWarning(tr("Failed to add WiFi connection."));
                    return;
                }

                QDBusObjectPath path = reply.value();
                NetworkManager::activateConnection(path.path(), wifiDevice->uni(), QString());
                cpd->setNetworkName(wifiSsid);
            }
        }
    }
}

void InstallerPrompt::updateConnectionInfo()
{
    ui->networkComboBox->clear();
    int ethDevices = 0;
    int connectedDevice = 0;
    bool hitConnectedNetwork = false;
    if (NetworkManager::isNetworkingEnabled()) {
        for (const auto &device : NetworkManager::networkInterfaces()) {
            if (device->type() == NetworkManager::Device::Ethernet) {
                ethDevices++;
                bool isDeviceConnected = device->state() == NetworkManager::Device::Activated;
                if (isDeviceConnected) {
                    hitConnectedNetwork = true;
                }
                QString isConnected = isDeviceConnected ? tr("Connected") : tr("Disconnected");
                if (!hitConnectedNetwork) {
                    connectedDevice++;
                }
                ui->networkComboBox->addItem(tr("Ethernet %1: %2").arg(ethDevices).arg(isConnected), QString("UNI_") + device->uni());
            } else if (device->type() == NetworkManager::Device::Wifi && NetworkManager::isWirelessEnabled() && !hitWifiDevice) {
                hitWifiDevice = true;
                wifiDevice = device.staticCast<NetworkManager::WirelessDevice>();
                connect(wifiDevice.data(), &NetworkManager::Device::stateChanged, this, &InstallerPrompt::handleWiFiConnectionChange);
            }
        }
        if (hitWifiDevice) {
            NetworkManager::ActiveConnection::Ptr activeConnection = wifiDevice->activeConnection();
            NetworkManager::Connection::Ptr underlyingActiveConnection;
            if (activeConnection != nullptr) {
                underlyingActiveConnection = activeConnection->connection();
            }
            for (const auto &network : wifiDevice->networks()) {
                QString ssid = network->ssid();
                bool isNetworkConnected = false;
                if (activeConnection != nullptr && activeConnection->state() == NetworkManager::ActiveConnection::Activated) {
                    NetworkManager::WirelessSetting::Ptr underlyingWirelessSetting = underlyingActiveConnection->settings()->setting(NetworkManager::Setting::Wireless).staticCast<NetworkManager::WirelessSetting>();
                    if (network->ssid() == QString(underlyingWirelessSetting->ssid())) {
                        isNetworkConnected = true;
                        hitConnectedNetwork = true;
                    }
                }
                QString isConnected = isNetworkConnected ? tr("Connected") : tr("Disconnected");
                if (!hitConnectedNetwork) {
                    connectedDevice++;
                }
                ui->networkComboBox->addItem(tr("WiFi %1: %2").arg(ssid).arg(isConnected), QString("SSID") + ssid);
            }
        }
    }
    if (hitConnectedNetwork) {
        ui->networkComboBox->setCurrentIndex(connectedDevice);
    }

    if (!firstUpdateConnectionInfoCall) {
        if (NetworkManager::status() == NetworkManager::Connecting) {
            cpd->exec();
        } else {
            cpd->done(0);
        }
    } else {
        firstUpdateConnectionInfoCall = false;
    }
}

void InstallerPrompt::handleWiFiConnectionChange(NetworkManager::Device::State newstate, NetworkManager::Device::State oldstate, NetworkManager::Device::StateChangeReason reason)
{
    if (reason == NetworkManager::Device::NoSecretsReason && !wifiWrongHandling) {
        wifiWrongHandling = true;

        foreach (const NetworkManager::Connection::Ptr &connection, NetworkManager::listConnections()) {
            if (connection->settings()->connectionType() == NetworkManager::ConnectionSettings::Wireless) {
                auto wirelessSetting = connection->settings()->setting(NetworkManager::Setting::Wireless).dynamicCast<NetworkManager::WirelessSetting>();
                if (wirelessSetting && wirelessSetting->ssid() == wifiSsid) {
                    qDebug() << "Wiping connection with wrong password: " << wifiSsid;
                    QDBusPendingReply removeReply = connection->remove();
                    removeReply.waitForFinished();
                    WarningDialog::showWarning(tr("WiFi password was incorrect."));
                }
            }
        }
        wifiWrongHandling = false;
    }
}

void InstallerPrompt::initLanguageComboBox() {
    languageLocaleMap.clear();
    QStringList languages = getAvailableLanguages();
    for (const auto &language : languages) {
        ui->languageComboBox->addItem(language);
    }

    QLocale currentLocale = QLocale::system();
    QString currentLocaleDisplayName = getDisplayNameForLocale(currentLocale);

    int defaultIndex = ui->languageComboBox->findText(currentLocaleDisplayName);
    if (defaultIndex != -1) {
        ui->languageComboBox->setCurrentIndex(defaultIndex);
    } else {
        // Fallback to English (United States) if current locale is not in the list
        defaultIndex = ui->languageComboBox->findText("English (United States)");
        if (defaultIndex != -1) {
            ui->languageComboBox->setCurrentIndex(defaultIndex);
        }
    }
}

QStringList InstallerPrompt::getAvailableLanguages() {
    QMap<QString, QString> language_map; // Default sorting by QString is case-sensitive
    QStringList supported_languages;

    QFile supported_locale_file("/usr/share/i18n/SUPPORTED");
    char lineBuf[2048];
    if (supported_locale_file.open(QFile::ReadOnly)) {
        while (!supported_locale_file.atEnd()) {
            supported_locale_file.readLine(lineBuf, 2048);
            QString line(lineBuf);
            if (!line.contains("UTF-8")) continue;
            QStringList lineParts = line.split('.');
            if (lineParts.count() == 1) {
                lineParts = line.split(' ');
                if (lineParts.count() == 1) {
                    WarningDialog::showWarning(tr("Something has gone very wrong trying to parse the list of supported languages!"));
                }
            }
            supported_languages.append(lineParts[0]);
        }
        supported_locale_file.close();
    }

    QList<QLocale> all_locales = QLocale::matchingLocales(QLocale::AnyLanguage, QLocale::AnyScript, QLocale::AnyCountry);
    for (const QLocale &locale : all_locales) {
        QString check_locale_name = locale.name();
        if (check_locale_name.contains(".UTF-8")) {
            check_locale_name = check_locale_name.left(check_locale_name.length() - 6);
        }
        if (!supported_languages.contains(check_locale_name)) continue;
        QString display_name = getDisplayNameForLocale(locale);
        if (display_name.isEmpty()) continue;

        language_map.insert(display_name, locale.name());
    }

    // Sort the language display names
    QStringList sorted_languages = language_map.keys();
    std::sort(sorted_languages.begin(), sorted_languages.end(), [](const QString &a, const QString &b) {
        return a.compare(b, Qt::CaseInsensitive) < 0;
    });

    // Clear the existing languageLocaleMap and repopulate it based on sortedLanguages
    languageLocaleMap.clear();
    for (const QString &language_name : sorted_languages) {
        languageLocaleMap.insert(language_name, language_map[language_name]);
    }

    return sorted_languages;
}

QString InstallerPrompt::getDisplayNameForLocale(const QLocale &locale) {
    auto sanitize = [](QString s) -> QString {
        s.replace("St.", "Saint", Qt::CaseInsensitive);
        s.replace("&", "and", Qt::CaseInsensitive);
        return s;
    };

    QLocale currentAppLocale = QLocale::system();
    QString nativeName = locale.nativeLanguageName();
    QString nativeCountryName = sanitize(locale.nativeCountryName());
    QString englishLanguageName = currentAppLocale.languageToString(locale.language());
    QString englishCountryName = sanitize(currentAppLocale.countryToString(locale.country()));

    if (nativeName.isEmpty() || nativeCountryName.isEmpty()) {
        return QString();
    }

    // Rename "American English" to "English"
    if (locale.language() == QLocale::English) {
        nativeName = "English";
        englishLanguageName = "English";
    }

    QString displayName = nativeName + " (" + nativeCountryName + ")";
    if (nativeName.compare(englishLanguageName, Qt::CaseInsensitive) != 0 &&
        nativeCountryName.compare(englishCountryName, Qt::CaseInsensitive) != 0) {
        displayName += " - " + englishLanguageName + " (" + englishCountryName + ")";
    }

    return displayName;
}

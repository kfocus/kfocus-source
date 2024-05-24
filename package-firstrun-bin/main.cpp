#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QIcon>
#include <QStandardPaths>
#include <QFile>
#include <QStorageInfo>
#include "startupdata.h"
#include "shellengine.h"

QStringList StartupData::m_cryptDiskList = QStringList();
QString StartupData::m_binDir     = "";
QString StartupData::m_homeDir    = "";
QString StartupData::m_userName   = "";
QString StartupData::m_rollbackCmd = "";
bool StartupData::m_isLiveSession = false;

const qint64 min_disk_int = 1073741824;

int main(int argc, char *argv[])
{
    // Early system info gathering
    StartupData dat;

    // This must be called early to get applicationDirPath
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
    QGuiApplication app(argc, argv);

    // Determine path for kfocus-fixup-set. Prefer dev path if available.
    QString exeDir = app.applicationDirPath();
    QString dirList[2] = { "../../package-main/usr/lib/kfocus/bin", exeDir };
    for ( QString testDir : dirList ) {
      if (QFile::exists(testDir + "/kfocus-firstrun-set")) {
        dat.setBinDir(testDir);
        break;
      }
    }

    if (dat.binDir() == "") {
        qWarning() << "Abort: Cannot find valid bin directory.";
        return 1;
    }

    dat.setHomeDir(QStandardPaths::writableLocation(QStandardPaths::HomeLocation));

    // Check for the presence of a drop file
    if (QFile::exists(dat.homeDir() + "/.config/kfocus-firstrun-wizard")) {
        if (argc == 1 || QString(argv[1]) != QString("-f")) {
            qWarning() << "User has directed to not run again. Use -f to override.";
            return 1;
        }
    }

    // Detect username
    ShellEngine userNameEngine;
    userNameEngine.execSync("whoami");
    QString userName = userNameEngine.stdout();
    userName.remove('\n');
    dat.setUserName(userName);

    // Detect live session (alternate method)
    // TODO 2023-08-24 arraybolt3 notice: Make ShellEngine able to provide exit
    // codes when using execSync, then use the exit code here rather than
    // stdout
    ShellEngine liveSessionDetectEngine;
    liveSessionDetectEngine.execSync("df --output='source,fstype' / |grep -E '^/cow\\s*overlay'");
    QStringList liveDetectStrList = liveSessionDetectEngine.stdout().split('\n');
    if (liveDetectStrList.length() >= 2) {
        dat.setIsLiveSession(true);
    }

    // UI and QML setup
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
    }
    app.setWindowIcon(QIcon("/usr/share/icons/hicolor/scalable/apps/kfocus-bug-wizard.svg"));

    qmlRegisterType<ShellEngine>("shellengine", 1, 1, "ShellEngine");
    qmlRegisterType<StartupData>("startupdata", 1, 0, "StartupData");

    ShellEngine msgbox;

    // Late system info gathering
    ShellEngine encryptedDiskFinder;
    int encryptedDiskFinderExitCode = encryptedDiskFinder.execSync(
        dat.binDir() + "/kfocus-check-crypt -q"
    );
    if (encryptedDiskFinderExitCode != 0) {
        qWarning() << "Abort: Failed to search for encrypted disks.";
        return 1;
    }
    QStringList cryptDisks(encryptedDiskFinder.stdout().split('\n'));
    // The newline following the last entry creates an "extra" blank entry that needs to be removed
    cryptDisks.removeLast();
    dat.setCryptDiskList(cryptDisks);

    // Check for the presence of a second kfocus-firstrun-bin instance
    ShellEngine duplicateFinder;
    // NOTE: We only search for "kfocus-firstrun" and not "kfocus-firstrun-bin"
    // here because for some unknown reason kfocus-firstrun-bin shows up as
    // "kfocus-firstrun-" (yes, with a weird dash at the end) in the output of
    // "ps axo comm". (msm: It gets truncated).
    duplicateFinder.execSync("ps axo comm | grep kfocus-firstrun");
    QStringList outputLines = duplicateFinder.stdout().split('\n');
    if (outputLines.length() > 2) { // there's always one blank line
         // TODO 2023-08-24 arraybolt3 notice: Replace kdialog here?
        msgbox.execSync("kdialog --title \"Kubuntu Focus Welcome Wizard\" \
            --msgbox \"The Welcome Wizard is already running.\""
        );
        return 1;
    }

    // Check disk space - we want at least 1 GiB available
    QStorageInfo driveInfo = QStorageInfo::root();
    if (driveInfo.bytesFree() < min_disk_int) {
        msgbox.execSync("kdialog --title \"Kubuntu Focus Welcome Wizard\" \
            --msgbox \"Your primary drive is low on space. Please free some space before running this wizard.\"");
       return 1;
    }

    // Look for plasma-welcome executable
    ShellEngine rollbackFinder;
    rollbackFinder.execSync("command -v /usr/lib/kfocus/bin/kfocus-rollback || true");
    QString rollbackCmd = rollbackFinder.stdout();
    rollbackCmd.remove('\n');
    dat.setRollbackCmd(rollbackCmd);

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}

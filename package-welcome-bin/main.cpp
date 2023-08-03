#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QIcon>
#include <QStandardPaths>
#include <QFile>
#include <startupdata.h>
#include <shellengine.h>

QStringList StartupData::m_cryptDiskList = QStringList();
QString StartupData::m_binDir = "/home/bill/Github/kfocus-source/package-main/usr/lib/kfocus/bin/";
QString StartupData::m_homeDir = "";

int main(int argc, char *argv[])
{
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
    QGuiApplication app(argc, argv);
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
            QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
        }
    app.setWindowIcon(QIcon("/usr/share/icons/hicolor/scalable/apps/kfocus-bug-wizard.svg"));

    qmlRegisterType<ShellEngine>("shellengine", 1, 1, "ShellEngine");
    qmlRegisterType<StartupData>("startupdata", 1, 0, "StartupData");

    // Gather system info and expose it to QML via StartupData
    StartupData dat;
    ShellEngine encryptedDiskFinder;
    encryptedDiskFinder.execSync(dat.binDir() + "kfocus-check-crypt -q");
    QStringList cryptDisks(encryptedDiskFinder.stdout().split('\n'));
    cryptDisks.removeLast();
    dat.setCryptDiskList(cryptDisks);
    dat.setHomeDir(QStandardPaths::writableLocation(QStandardPaths::HomeLocation));

    // Check for the presence of a drop file
    if (QFile::exists(dat.homeDir() + "/.config/kfocus-firstrun-wizard")) {
        if (argc == 1 || QString(argv[1]) != QString("-f")) {
            qWarning() << "User has directed to not run again. Use -f to override.";
            return 1;
        }
    }

    // Check for the presence of a second kfocus-welcome-bin instance
    ShellEngine duplicateFinder;
    // NOTE! We only search for "kfocus-welcome" and not "kfocus-welcome-bin"
    // here because for some unknown reason kfocus-welcome-bin shows up as
    // "kfocus-welcome-" (yes, with a weird dash at the end) in the output of
    // "ps axo comm". Why this is, I have no clue.
    duplicateFinder.execSync("ps axo comm | grep kfocus-welcome");
    QStringList outputLines = duplicateFinder.stdout().split('\n');
    if (outputLines.length() > 2) { // there's always one blank line
        ShellEngine msgbox;
        msgbox.execSync("kdialog --title \"Kubuntu Focus Welcome Wizard\" --msgbox \"The Welcome Wizard is already running.\"");
        return 1;
    }

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

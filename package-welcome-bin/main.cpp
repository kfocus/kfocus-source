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

    StartupData dat;
    ShellEngine encryptedDiskFinder;
    encryptedDiskFinder.execSync(dat.binDir() + "kfocus-check-crypt -q");
    QStringList cryptDisks(encryptedDiskFinder.stdout().split('\n'));
    cryptDisks.removeLast();
    dat.setCryptDiskList(cryptDisks);
    dat.setHomeDir(QStandardPaths::writableLocation(QStandardPaths::HomeLocation));

    if (QFile::exists(dat.homeDir() + "/.config/kfocus-firstrun-wizard")) {
        if (argc == 1 || QString(argv[1]) != QString("-f")) {
            qWarning() << "User has directed to not run again. Use -f to override.";
            return 1;
        }
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

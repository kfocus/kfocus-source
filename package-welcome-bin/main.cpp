#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QIcon>
#include <startupdata.h>
#include <shellengine.h>

QStringList StartupData::m_cryptDiskList = QStringList();
QString StartupData::m_binDir = "/home/bill/Github/kfocus-source/package-main/usr/lib/kfocus/bin/";

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

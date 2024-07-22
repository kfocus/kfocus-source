#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QIcon>
#include <QMap>
#include <QList>
#include <QDateTime>
#include "shellengine.h"
#include "backendengine.h"

QString BackendEngine::m_rollbackSetExe = "/usr/lib/kfocus/bin/kfocus-rollback-set";
QString BackendEngine::m_pkexecExe = "/usr/bin/pkexec";
bool BackendEngine::m_automaticSnapshotsEnabled = false;
QList<QMap<QString, QString>> *BackendEngine::m_snapshotList = new QList<QMap<QString, QString>>();
QMap<QString, QString> *BackendEngine::m_mainFsInfo = new QMap<QString, QString>();
QMap<QString, QString> *BackendEngine::m_bootFsInfo = new QMap<QString, QString>();

int main(int argc, char *argv[])
{
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
    QGuiApplication app(argc, argv);

    qmlRegisterType<ShellEngine>("shellengine", 1, 1, "ShellEngine");
    qmlRegisterType<BackendEngine>("backendengine", 1, 0, "BackendEngine");

    // Launch the UI
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
    }
    app.setWindowIcon(QIcon("/usr/share/icons/hicolor/scalable/apps/kfocus-bug-rollback.svg"));

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}

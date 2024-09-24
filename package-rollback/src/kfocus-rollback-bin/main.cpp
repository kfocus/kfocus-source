#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QIcon>
#include <QMap>
#include <QList>
#include <QFile>
#include <QDateTime>
#include "shellengine.h"
#include "backendengine.h"
#include "windoweventfilter.h"

QString BackendEngine::m_rollbackBackendExe = "/usr/lib/kfocus/bin/kfocus-rollback-backend";
QString BackendEngine::m_rollbackSetExe = "/usr/lib/kfocus/bin/kfocus-rollback-set";
QString BackendEngine::m_rollbackMainWorkingDir = "/btrfs_main/@kfocus-rollback-working";
QString BackendEngine::m_rollbackBootWorkingDir = "/btrfs_boot/@kfocus-rollback-working-boot";
QString BackendEngine::m_pkexecExe = "/usr/bin/pkexec";
bool BackendEngine::m_automaticSnapshotsEnabled = false;
QList<QMap<QString, QString>> *BackendEngine::m_snapshotList = new QList<QMap<QString, QString>>();
QMap<QString, QString> *BackendEngine::m_mainFsInfo = new QMap<QString, QString>();
QMap<QString, QString> *BackendEngine::m_bootFsInfo = new QMap<QString, QString>();
bool BackendEngine::m_inhibitClose = false;
QStringList BackendEngine::m_snapshotIdList = QStringList();
int BackendEngine::m_snapshotIdIdx = 0;
bool BackendEngine::m_calcSize = false;
bool BackendEngine::m_mainSpaceLow = false;
bool BackendEngine::m_bootSpaceLow = false;
bool BackendEngine::m_updateInProgress = false;
bool BackendEngine::m_isPostRestore = false;
QString BackendEngine::m_postRestoreName = "";
QString BackendEngine::m_postRestoreDate = "";
QString BackendEngine::m_postRestoreReason = "";
bool BackendEngine::m_mainWorkingSubvolExists = false;
bool BackendEngine::m_bootWorkingSubvolExists = false;
bool BackendEngine::m_btrfsStateUnusable = false;
bool BackendEngine::m_postRestoreSubvolsMounted = false;

int main(int argc, char *argv[])
{
    BackendEngine eng;
    ShellEngine shell;

#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
    QCoreApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);
    QGuiApplication app(argc, argv);

    qmlRegisterType<ShellEngine>("shellengine", 1, 1, "ShellEngine");
    qmlRegisterType<BackendEngine>("backendengine", 1, 0, "BackendEngine");

    // Check after-restore state
    if (argc > 1 && QString(argv[1]) == "afterRestore") {
        eng.setIsPostRestore(true);
        QFile restoreReasonFile("/var/lib/kfocus/rollback_restore_complete");
        restoreReasonFile.open(QIODevice::ReadOnly);
        QStringList postRestoreLines = QString(restoreReasonFile.readAll()).split('\n');
        restoreReasonFile.close();
        if (postRestoreLines.count() >= 3) {
            eng.setPostRestoreName(QString(QByteArray::fromBase64(postRestoreLines.at(0).toUtf8())));
            QDateTime postRestoreTs = QDateTime::fromSecsSinceEpoch(postRestoreLines.at(1).toULong());
            QString postRestoreDate = postRestoreTs.toString(Qt::ISODate).split('T').at(0);
            eng.setPostRestoreDate(postRestoreDate);
            eng.setPostRestoreReason(postRestoreLines.at(2));

            if (eng.postRestoreName() == QString()) {
                eng.setPostRestoreName(eng.postRestoreReason());
            }
        }

        // Ensure stale app entries aren't left in the start menu
        if (QFile("/usr/bin/kbuildsycoca5").exists()) {
            shell.execSync("/usr/bin/kbuildsycoca5");
        }
    }

    // Launch the UI
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
    }
    app.setWindowIcon(QIcon("/usr/share/icons/hicolor/scalable/apps/kfocus-bug-rollback.svg"));

    WindowEventFilter *eventFilter = new WindowEventFilter();

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
    // The event filter allows inhibiting window close
    engine.rootObjects().at(0)->installEventFilter(eventFilter);

    return app.exec();
}

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QDir>
#include <QIcon>
#include <QMap>
#include <QList>
#include <QFile>
#include <QDateTime>
#include <QSettings>
#include <unistd.h>
#include "shellengine.h"
#include "backendengine.h"
#include "windoweventfilter.h"

// TODO: Use development binaries instead of system binaries when possible,
// like kfocus-firstrun-bin
QString BackendEngine::m_rollbackBackendExe = "/usr/lib/kfocus/bin/kfocus-rollback-backend";
QString BackendEngine::m_rollbackSetExe = "/usr/lib/kfocus/bin/kfocus-rollback-set";
QString BackendEngine::m_rollbackMainWorkingDir = "/btrfs_main/@kfocus-rollback-working";
QString BackendEngine::m_rollbackBootWorkingDir = "/btrfs_boot/@kfocus-rollback-working-boot";
QString BackendEngine::m_pkexecExe = "/usr/bin/pkexec";
QString BackendEngine::m_systemdInhibitExe = "/usr/bin/systemd-inhibit";

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
bool BackendEngine::m_mainWorkingSubvolExists = false;
bool BackendEngine::m_bootWorkingSubvolExists = false;
bool BackendEngine::m_snapshotSizeInfoPresent = false;
QStringList BackendEngine::m_bulkDataList = QStringList();
bool BackendEngine::m_bulkDataChecked = false;

bool BackendEngine::m_btrfsStateUnusable = false;
bool BackendEngine::m_postRestoreSubvolsMounted = false;
quint64 BackendEngine::m_mainMinUnalloc = 0;
quint64 BackendEngine::m_bootMinUnalloc = 0;
QSettings BackendEngine::m_settings = QSettings(QDir::homePath() + "/.config/kfocus-rollback", QSettings::IniFormat);

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

    // Refuse to be launched by KDE's session restore feature, as it bypasses
    // the frontend locking mechanism (and would mess up the post-restore
    // handler if it didn't bypass the lock). The executable responsible for
    // session restore is "ksmserver".
    pid_t ppid = getppid();
    QFile ppidNameFile(QString("/proc/") + QString::number(ppid) + QString("/comm"));
    ppidNameFile.open(QIODevice::ReadOnly);
    QString ppidName = QString(ppidNameFile.readLine()).trimmed();
    ppidNameFile.close();
    if (ppidName == "ksmserver") {
        return 0;
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

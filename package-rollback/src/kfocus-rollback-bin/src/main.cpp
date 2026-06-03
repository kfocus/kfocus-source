#include <QApplication>
#include <QQmlApplicationEngine>
#include <QtQml>
#include <QUrl>
#include <QQuickStyle>
#include <QFile>
#include <QDir>
#include <QMap>
#include <QList>
#include <QSettings>
#include <KLocalizedContext>
#include <KLocalizedString>
#include <KIconTheme>
#include <unistd.h>
#include "shellengine.h"
#include "backendengine.h"
#include "windoweventfilter.h"

// TODO: Use development binaries instead of system binaries when possible,
// like kfocus-firstrun-bin
QString BackendEngine::m_rollbackBackendExe = QStringLiteral("/usr/lib/kfocus/bin/kfocus-rollback-backend");
QString BackendEngine::m_rollbackSetExe = QStringLiteral("/usr/lib/kfocus/bin/kfocus-rollback-set");
QString BackendEngine::m_rollbackMainWorkingDir = QStringLiteral("/btrfs_main/@kfocus-rollback-working");
QString BackendEngine::m_rollbackBootWorkingDir = QStringLiteral("/btrfs_boot/@kfocus-rollback-working-boot");
QString BackendEngine::m_pkexecExe = QStringLiteral("/usr/bin/pkexec");
QString BackendEngine::m_systemdInhibitExe = QStringLiteral("/usr/bin/systemd-inhibit");

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
QSettings BackendEngine::m_settings = QSettings(QDir::homePath() + QStringLiteral("/.config/kfocus-rollback"), QSettings::IniFormat);

int main(int argc, char *argv[])
{
  KIconTheme::initTheme();
  QApplication app(argc, argv);
  KLocalizedString::setApplicationDomain("rollback");
  QApplication::setOrganizationName(QStringLiteral("KFocus"));
  QApplication::setOrganizationDomain(QStringLiteral("kfocus.org"));
  QApplication::setApplicationName(QStringLiteral("Kubuntu Focus System Rollback"));
  QApplication::setDesktopFileName(QStringLiteral("org.kfocus.rollback"));

  QApplication::setStyle(QStringLiteral("breeze"));
  if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
    QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
  }

  // Refuse to be launched by KDE's session restore feature, as it bypasses
  // the frontend locking mechanism (and would mess up the post-restore
  // handler if it didn't bypass the lock). The executable responsible for
  // session restore is "ksmserver".
  pid_t ppid = getppid();
  QFile ppidNameFile(QStringLiteral("/proc/") + QString::number(ppid) + QStringLiteral("/comm"));
  bool canOpenPpidNameFile = ppidNameFile.open(QIODevice::ReadOnly);
  if (!canOpenPpidNameFile) {
    return -1;
  }
  QString ppidName = QString::fromUtf8(ppidNameFile.readLine()).trimmed();
  ppidNameFile.close();
  if (ppidName == QStringLiteral("ksmserver")) {
    return 0;
  }

  WindowEventFilter *eventFilter = new WindowEventFilter();

  QQmlApplicationEngine engine;

  engine.rootContext()->setContextObject(new KLocalizedContext(&engine));
  engine.loadFromModule("org.kfocus.rollback", "Main");

  if (engine.rootObjects().isEmpty()) {
    return -1;
  }
  engine.rootObjects().at(0)->installEventFilter(eventFilter);

  return app.exec();
}

#include <QApplication>
#include <QQmlApplicationEngine>
#include <QtQml>
#include <QUrl>
#include <QQuickStyle>
#include <QStorageInfo>
#include <QtLogging>
#include <KLocalizedContext>
#include <KLocalizedString>
#include <KIconTheme>
#include "startupdata.h"
#include "shellengine.h"

QStringList StartupData::m_cryptDiskList = QStringList();
QString StartupData::m_binDir      = QStringLiteral("");
QString StartupData::m_homeDir     = QStringLiteral("");
QString StartupData::m_userName    = QStringLiteral("");
QString StartupData::m_rollbackCmd = QStringLiteral("");
bool StartupData::m_isLiveSession  = false;
QString StartupData::m_startPage   = QStringLiteral("introductionItem");

const qint64 min_disk_int = 1073741824;

int main(int argc, char *argv[])
{
  KIconTheme::initTheme();
  QApplication app(argc, argv);
  KLocalizedString::setApplicationDomain("firstrun");
  QApplication::setOrganizationName(QStringLiteral("KFocus"));
  QApplication::setOrganizationDomain(QStringLiteral("kfocus.org"));
  QApplication::setApplicationName(QStringLiteral("Kubuntu Focus Welcome Wizard"));
  QApplication::setDesktopFileName(QStringLiteral("org.kfocus.firstrun"));

  QApplication::setStyle(QStringLiteral("breeze"));
  if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
    QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
  }

  // Early system info gathering
  StartupData dat;
  QStringList args;
  ShellEngine earlyEngine;
  bool forced = false;
  for (int i = 1; i < argc; i++) {
    args.append(QString::fromUtf8(argv[i]));
  }
  if (args.contains(QStringLiteral("-f"))) {
    forced = true;
    args.removeAll(QStringLiteral("-f"));
  }
  if (args.count() != 0) {
    dat.setStartPage(args[0]);
  }

  // Determine path for kfocus-focusrx. Prefer dev path if available.
  QString exeDir = app.applicationDirPath();
  QString dirList[2] = { QStringLiteral("../../package-main/usr/lib/kfocus/bin"), exeDir };
  for (QString testDir : dirList) {
    if (QFile::exists(testDir + QStringLiteral("/kfocus-focusrx"))) {
      dat.setBinDir(testDir);
      break;
    }
  }

  if (dat.binDir() == QStringLiteral("")) {
    qWarning() << "Abort: Cannot find valid bin directory.";
    return 1;
  }

  dat.setHomeDir(QStandardPaths::writableLocation(QStandardPaths::HomeLocation));

  // Check for the presence of a drop file if not forced
  if (!forced && QFile::exists(dat.homeDir() + QStringLiteral("/.config/kfocus-firstrun-wizard"))) {
    qWarning() << "User has directed to not run again. Use -f to override.";
    return 0;
  }

  // Detect username
  earlyEngine.execSync(QStringLiteral("whoami"));
  QString userName = earlyEngine.stdout();
  userName.remove(QStringLiteral("\n"));
  dat.setUserName(userName);

  // Detect live session
  // TODO 2026-05-06 arraybolt3 notice: Use an exit code here rather than
  // stdout
  earlyEngine.execSync(QStringLiteral("df --output='source,fstype' / | grep -E '^/cow\\s*overlay'"));
  QStringList liveDetectStrList = earlyEngine.stdout().split(QStringLiteral("\n"));
  if (liveDetectStrList.length() >= 2) {
    dat.setIsLiveSession(true);
  }

  // Late system info gathering
  int encryptedDiskFinderExitCode = earlyEngine.execSync(
    dat.binDir() + QStringLiteral("/kfocus-check-crypt -q")
  );
  if (encryptedDiskFinderExitCode != 0) {
    qWarning() << "Abort: Failed to search for encrypted disks.";
    return 1;
  }
  QStringList cryptDisks(earlyEngine.stdout().split(QStringLiteral("\n")));
  // The newline following the last entry creates an "extra" blank entry that
  // needs to be removed
  cryptDisks.removeLast();
  dat.setCryptDiskList(cryptDisks);

  if (cryptDisks.count() == 0 && args.contains(QStringLiteral("diskPassphraseItem"))) {
    earlyEngine.execSync(QStringLiteral("kdialog --title \"Kubuntu Focus Welcome Wizard\" --msgbox \"No encrypted disks are present on this system.\""));
    return 1;
  }

  // Check for the presence of a second kfocus-firstrun-bin instance using
  // "ps axo comm"
  // TODO 2026-05-05 arraybolt3 notice: Use a less hacky method for this, like
  // listening on a D-Bus name or something
  earlyEngine.execSync(QStringLiteral("ps axo comm | grep kfocus-firstrun"));
  QStringList outputLines = earlyEngine.stdout().split(QStringLiteral("\n"));
  if (outputLines.length() > 2) { // there's always one blank line
    earlyEngine.execSync(QStringLiteral("kdialog --title \"Kubuntu Focus Welcome Wizard\" --msgbox \"The Welcome Wizard is already running.\""));
    return 1;
  }

  // Check disk space - we want at least 1 GiB available
  QStorageInfo driveInfo = QStorageInfo::root();
  if (driveInfo.bytesFree() < min_disk_int) {
    earlyEngine.execSync(QStringLiteral("kdialog --title \"Kubuntu Focus Welcome Wizard\" --msgbox \"Your primary drive is low on space. Please free some space before running this wizard.\""));
    return 1;
  }

  // Look for kfocus-rollback executable
  earlyEngine.execSync(QStringLiteral("command -v /usr/lib/kfocus/bin/kfocus-rollback || true"));
  QString rollbackCmd = earlyEngine.stdout();
  rollbackCmd.remove(QStringLiteral("\n"));
  dat.setRollbackCmd(rollbackCmd);

  QQmlApplicationEngine engine;

  engine.rootContext()->setContextObject(new KLocalizedContext(&engine));
  engine.loadFromModule("org.kfocus.firstrun", "Main");

  if (engine.rootObjects().isEmpty()) {
    return -1;
  }

  return app.exec();
}

#include <QApplication>
#include <QQmlApplicationEngine>
#include <QtQml>
#include <QUrl>
#include <QQuickStyle>
#include <KLocalizedContext>
#include <KLocalizedString>
#include <KIconTheme>
#include "shellengine.h"

extern "C" {
#include <unistd.h>
#include <signal.h>
}

int main(int argc, char *argv[])
{
  KIconTheme::initTheme();
  QApplication app(argc, argv);
  KLocalizedString::setApplicationDomain("power");
  QApplication::setOrganizationName(QStringLiteral("KFocus"));
  QApplication::setOrganizationDomain(QStringLiteral("kfocus.org"));
  QApplication::setApplicationName(QStringLiteral("Power & Fan"));
  QApplication::setDesktopFileName(QStringLiteral("org.kfocus.power"));

  QApplication::setStyle(QStringLiteral("breeze"));
  if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
    QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
  }

  // Make a best-effort attempt to kill any existing kfocus-power-bin
  // process(es).
  ShellEngine checkEngine;
  int checkExitCode = checkEngine.execSync(
    QStringLiteral("pgrep kfocus-power-bi")
  );
  if (checkExitCode == 0) {
    QStringList outputLines = checkEngine.stdout().split(QStringLiteral("\n"));
    if (outputLines.length() > 2) { // there's always one blank line
      pid_t myPid = getpid();
      for (qsizetype i = 0; i < outputLines.length() - 1; i++) {
        bool convOk = true;
        qlonglong currentPid = outputLines[i].toLongLong(&convOk);
        if (!convOk) {
          continue;
        }
        if (myPid == currentPid) {
          continue;
        }
        kill((pid_t)currentPid, SIGTERM);
      }
    }
  }

  QQmlApplicationEngine engine;

  engine.rootContext()->setContextObject(new KLocalizedContext(&engine));
  engine.loadFromModule("org.kfocus.power", "Main");

  if (engine.rootObjects().isEmpty()) {
    return -1;
  }

  return app.exec();
}

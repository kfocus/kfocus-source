#include <QApplication>
#include <QQmlApplicationEngine>
#include <QtQml>
#include <QUrl>
#include <QQuickStyle>
#include <KLocalizedContext>
#include <KLocalizedString>
#include <KIconTheme>
#include "shellengine.h"

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

  QQmlApplicationEngine engine;

  engine.rootContext()->setContextObject(new KLocalizedContext(&engine));
  engine.loadFromModule("org.kfocus.power", "Main");

  if (engine.rootObjects().isEmpty()) {
    return -1;
  }

  return app.exec();
}

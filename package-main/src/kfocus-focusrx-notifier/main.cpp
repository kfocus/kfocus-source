#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusError>
#include <QDebug>

#include "KDialogLauncher.h"

int main(int argc, char* argv[])
{
    QCoreApplication a(argc, argv);

    QObject obj;
    auto *kdiag = new KDialogLauncher(&obj);
    auto connection = QDBusConnection::sessionBus();
    connection.registerObject("/", &obj);

    if (!connection.registerService("org.kfocus.KDialogLauncher.launcher")) {
        return 1;
    }
    return QCoreApplication::exec();
}

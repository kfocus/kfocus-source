#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusError>
#include <QDebug>

#include "KDialogLauncher.h"

extern "C" {
#include <pwd.h>
#include <unistd.h>
#include <string.h>
}

int main(int argc, char* argv[])
{
    QCoreApplication a(argc, argv);

    QObject obj;
    auto *kdiag = new KDialogLauncher(&obj);
    auto connection = QDBusConnection::sessionBus();
    connection.registerObject("/", &obj);

    if (!connection.registerService("org.kfocus.FocusRxDispatch.launcher")) {
        return 1;
    }

    uid_t uid;
    struct passwd *pw;
    uid = geteuid();
    pw = getpwuid(uid);
    
    if (pw) {
        if (!strcmp(pw->pw_name, "kubuntu")) {
            // username is "kubuntu", we're in a live session, so inhibit
            // screen locking
            QDBusInterface locker("org.freedesktop.ScreenSaver", "/ScreenSaver", "org.freedesktop.ScreenSaver");
            locker.call("Inhibit", "FocusRx", "Live session");
        }
    }

    return QCoreApplication::exec();
}

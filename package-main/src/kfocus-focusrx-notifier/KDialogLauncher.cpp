#include "KDialogLauncher.h"

#include <QProcess>

void KDialogLauncher::info(const QString &msg) {
    launchDialog(Info, msg);
}

void KDialogLauncher::warning(const QString &msg) {
    launchDialog(Warning, msg);
}

void KDialogLauncher::error(const QString &msg) {
    launchDialog(Error, msg);
}

void KDialogLauncher::launchDialog(const KDialogType &type, const QString &msg) {
    auto *proc = new QProcess();
    proc->setProgram("/usr/bin/kdialog");
    switch(type) {
        case Info:
            proc->setArguments(QStringList() << "--msgbox" << msg);
            break;
        case Warning:
            proc->setArguments(QStringList() << "--sorry" << msg);
            break;
        case Error:
            proc->setArguments(QStringList() << "--error" << msg);
            break;
    }
    proc->start();
    connect(proc, SIGNAL(finished(int)), this, SLOT(cleanupDialog()));
}

void KDialogLauncher::cleanupDialog() {
    QObject::sender()->deleteLater();
}
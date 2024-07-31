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
void KDialogLauncher::rollbackLowMainSpace(const QString &msg) {
    launchDialog(RollbackLowMainSpace, msg);
}
void KDialogLauncher::rollbackLowBootSpace(const QString &msg) {
    launchDialog(RollbackLowBootSpace, msg);
}

void KDialogLauncher::launchDialog(const KDialogType &type, const QString &msg) {
    auto *proc = new QProcess();
    proc->setProgram("/usr/bin/kdialog");
    switch (type) {
        case Info:
            proc->setArguments(QStringList() << "--title" << "FocusRx" << "--msgbox" << msg);
            break;
        case Warning:
            proc->setArguments(QStringList() << "--title" << "FocusRx" << "--sorry" << msg);
            break;
        case Error:
            proc->setArguments(QStringList() << "--title" << "FocusRx" << "--error" << msg);
            break;
        case RollbackLowMainSpace:
            proc->setArguments(QStringList() << "--title" << "FocusRx" << "--warningyesnocancel" << msg << "--yes-label" << "Launch System Rollback" << "--no-label" << "Launch Dolphin");
            break;
        case RollbackLowBootSpace:
            proc->setArguments(QStringList() << "--title" << "FocusRx" << "--warningcontinuecancel" << msg << "--continue-label" << "Launch Kernel Cleaner");
            break;
    }
    connect(proc, SIGNAL(finished(int)), this, SLOT(cleanupDialog()));
    connect(proc, &QProcess::started, this, [&, proc, type](){
        m_processList.append(proc);
        m_typeList.append(type);
    });
    proc->start();
}

void KDialogLauncher::cleanupDialog() {
    QProcess *proc = static_cast<QProcess *>(QObject::sender());
    KDialogType type;
    int procIdx;
    for (int i = 0;i < m_processList.count();i++) {
        if (proc == m_processList.at(i)) {
            type = m_typeList.at(i);
            procIdx = i;
            break;
        }
    }

    QProcess *subProc = new QProcess();
    bool runSubProc = true;

    switch (type) {
        case RollbackLowMainSpace:
            switch (proc->exitCode()) {
                case 0:
                    subProc->setProgram("/usr/lib/kfocus/bin/kfocus-rollback-bin");
                    break;
                case 1:
                    subProc->setProgram("/usr/bin/dolphin");
                    break;
                default:
                    delete subProc;
                    runSubProc = false;
                    break;
            }
            break;

        case RollbackLowBootSpace:
            switch (proc->exitCode()) {
                case 0:
                    subProc->setProgram("/usr/lib/kfocus/bin/kfocus-kclean");
                    subProc->setArguments(QStringList() << "-f");
                    break;
                default:
                    delete subProc;
                    runSubProc = false;
                    break;
            }
            break;

        default:
            delete subProc;
            runSubProc = false;
    }

    if (runSubProc) {
        connect(subProc, SIGNAL(finished(int)), this, SLOT(cleanupSubproc()));
        subProc->start();
    }

    m_processList.removeAt(procIdx);
    m_typeList.removeAt(procIdx);
    proc->deleteLater();
}

void KDialogLauncher::cleanupSubproc() {
    QObject::sender()->deleteLater();
}

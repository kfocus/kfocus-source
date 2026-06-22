#include "KDialogLauncher.h"

#include <QProcess>
#include <QSettings>
#include <QDir>

/*
 * TODO 2026-05-20: This file now does more than launching KDialog and should
 * therefore be renamed (along with the class).
 */

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
void KDialogLauncher::rollbackBulkDataWarn(const QString &msg) {
    launchDialog(RollbackBulkDataWarn, msg);
}

void KDialogLauncher::kfocusMime(const QString &uri) {
    auto *kfocusMimeProc = new QProcess();
    kfocusMimeProc->setProgram("/usr/lib/kfocus/bin/kfocus-mime");
    kfocusMimeProc->setArguments(QStringList() << uri);
    /* Redirecting stdout/stderr to /dev/null to prevent kfocus-mime from
     * locking up every time before the UI appears */
    kfocusMimeProc->setStandardOutputFile(QProcess::nullDevice());
    kfocusMimeProc->setStandardErrorFile(QProcess::nullDevice());
    connect(kfocusMimeProc, SIGNAL(finished(int)), this, SLOT(cleanupSubproc()));
    kfocusMimeProc->start();
}

void KDialogLauncher::launchDialog(const KDialogType &type, const QString &msg) {
    if (type == RollbackBulkDataWarn) {
        QSettings rollbackSettings = QSettings(QDir::homePath() + "/.config/kfocus-rollback", QSettings::IniFormat);
        rollbackSettings.beginGroup("kfocus-rollback");
        QString val = rollbackSettings.value("bulkDataWarningEnabled", "true").toString();
        if (val == "false") {
            return;
        }
    }

    auto *kdialogProc = new QProcess();
    kdialogProc->setProgram("/usr/bin/kdialog");
    switch (type) {
        case Info:
            kdialogProc->setArguments(QStringList() << "--title" << "FocusRx" << "--msgbox" << msg);
            break;
        case Warning:
            kdialogProc->setArguments(QStringList() << "--title" << "FocusRx" << "--sorry" << msg);
            break;
        case Error:
            kdialogProc->setArguments(QStringList() << "--title" << "FocusRx" << "--error" << msg);
            break;
        case RollbackLowMainSpace:
            kdialogProc->setArguments(QStringList() << "--title" << "FocusRx" << "--warningyesnocancel" << msg << "--yes-label" << "Open Rollback Dashboard" << "--no-label" << "Open File Manager");
            break;
        case RollbackLowBootSpace:
            kdialogProc->setArguments(QStringList() << "--title" << "FocusRx" << "--warningcontinuecancel" << msg << "--continue-label" << "Open Kernel Cleaner");
            break;
        case RollbackBulkDataWarn:
            kdialogProc->setArguments(QStringList() << "--title" << "FocusRx" << "--warningcontinuecancel" << msg << "--continue-label" << "Open Rollback Dashboard");
            break;
    }
    connect(kdialogProc, SIGNAL(finished(int)), this, SLOT(cleanupDialog()));
    connect(kdialogProc, &QProcess::started, this, [&, kdialogProc, type](){
        m_kdialogProcessList.append(kdialogProc);
        m_kdialogTypeList.append(type);
    });
    kdialogProc->start();
}

void KDialogLauncher::cleanupDialog() {
    QProcess *kdialogProc = static_cast<QProcess *>(QObject::sender());
    KDialogType type;
    int kdialogProcIdx;
    for (int i = 0;i < m_kdialogProcessList.count();i++) {
        if (kdialogProc == m_kdialogProcessList.at(i)) {
            type = m_kdialogTypeList.at(i);
            kdialogProcIdx = i;
            break;
        }
    }

    QProcess *subProc = new QProcess();

    switch (type) {
        case RollbackLowMainSpace:
            switch (kdialogProc->exitCode()) {
                case 0:
                    subProc->setProgram("/usr/lib/kfocus/bin/kfocus-rollback");
                    break;
                case 1:
                    subProc->setProgram("/usr/bin/dolphin");
                    break;
                default:
                    delete subProc;
                    subProc = NULL;
                    break;
            }
            break;

        case RollbackLowBootSpace:
            switch (kdialogProc->exitCode()) {
                case 0:
                    subProc->setProgram("/usr/lib/kfocus/bin/kfocus-kclean");
                    subProc->setArguments(QStringList() << "-f");
                    break;
                default:
                    delete subProc;
                    subProc = NULL;
                    break;
            }
            break;

        case RollbackBulkDataWarn:
            switch (kdialogProc->exitCode()) {
                // 0 = user clicked continue, 2 = user closed window
                case 0:
                case 2:
                    subProc->setProgram("/usr/lib/kfocus/bin/kfocus-rollback");
                    break;
                default:
                    delete subProc;
                    subProc = NULL;
                    break;
            }
            break;

        default:
            delete subProc;
            subProc = NULL;
    }

    if (subProc != NULL) {
        connect(subProc, SIGNAL(finished(int)), this, SLOT(cleanupSubproc()));
        subProc->start();
    }

    m_kdialogProcessList.removeAt(kdialogProcIdx);
    m_kdialogTypeList.removeAt(kdialogProcIdx);
    kdialogProc->deleteLater();
}

void KDialogLauncher::cleanupSubproc() {
    QObject::sender()->deleteLater();
}

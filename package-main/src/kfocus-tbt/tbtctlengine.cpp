#include "tbtctlengine.h"
#include <QProcess>
#include <QDebug>

TbtCtlEngine::TbtCtlEngine(QObject *parent)
    : QObject{parent}
{}

void TbtCtlEngine::tbtSetState(bool enabled, bool persistEnabled) {
    QProcess proc;
    proc.setProgram("/usr/bin/pkexec");
    proc.setArguments(QStringList() << m_tbtSetExe << (enabled ? "start" : "stop"));
    proc.start();
    proc.waitForFinished();
    if (proc.exitCode() != 0) {
        emit stateSetFailure();
        return;
    }
    proc.setProgram("/usr/bin/pkexec");
    proc.setArguments(QStringList() << m_tbtSetExe << (persistEnabled ? "enable" : "disable"));
    proc.start();
    proc.waitForFinished();
    if (proc.exitCode() != 0) {
        emit stateSetFailure();
        return;
    }
    emit stateSetSuccess();
}

QList<bool> TbtCtlEngine::tbtQuery() {
    QList<bool> result;
    QProcess proc;
    proc.setProgram("/usr/bin/pkexec");
    proc.setArguments(QStringList() << m_tbtSetExe << "query");
    proc.start();
    proc.waitForFinished();

    QByteArray outputBytes = proc.readAllStandardOutput();
    QString outputStr = QString::fromUtf8(outputBytes);
    QStringList output = outputStr.split('\n', Qt::SkipEmptyParts);

    if (output.length() != 2) {
        result << false << false;
        return result;
    }

    if (output[0] == "running") {
        result << true;
    } else {
        result << false;
    }

    if (output[1] == "enabled") {
        result << true;
    } else {
        result << false;
    }

    return result;
}

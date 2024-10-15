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

TbtQueryResult *TbtCtlEngine::tbtQuery() {
    TbtQueryResult *result = new TbtQueryResult();

    QProcess proc;
    proc.setProgram("/usr/bin/pkexec");
    proc.setArguments(QStringList() << m_tbtSetExe << "query");
    proc.start();
    proc.waitForFinished();

    QByteArray outputBytes = proc.readAllStandardOutput();
    QString outputStr = QString::fromUtf8(outputBytes);
    QStringList output = outputStr.split('\n', Qt::SkipEmptyParts);

    if (output.length() != 3) {
        return result;
    }

    if (output[0] == "running") {
        result->setIsEnabled(true);
    } else {
        result->setIsEnabled(false);
    }

    if (output[1] == "enabled") {
        result->setIsPersistEnabled(true);
    } else {
        result->setIsPersistEnabled(false);
    }

    result->setDeviceModelCode(output[2]);

    return result;
}

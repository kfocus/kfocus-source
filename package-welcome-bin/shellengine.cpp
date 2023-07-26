#include "shellengine.h"

ShellEngine::ShellEngine()
{
    connect(this, &ShellEngine::commandStrChanged, this, [=]() { this->exec(m_commandStr, QString()); });
}

void ShellEngine::exec(QString args) {
    this->exec(args, "");
}

void ShellEngine::exec(QString args, QString stdinFeed) {
    QProcess *proc = new QProcess();
    QStringList argsList;
    argsList.append("-c");
    argsList.append(args);
    proc->start("bash", argsList);
    lastProcess = proc;
    if (stdinFeed.length() != 0) {
        proc->write(stdinFeed.toUtf8());
    }
    connect(proc, SIGNAL(finished(int)), this, SLOT(triggerExited()));
}

void ShellEngine::triggerExited() {
    QProcess *process = ((QProcess *)sender());
    QByteArray result = process->readAllStandardOutput();
    QString final = QString::fromUtf8(result);
    m_stdout = final;
    sender()->deleteLater();
    emit appExited(process == lastProcess, process->exitCode());
}

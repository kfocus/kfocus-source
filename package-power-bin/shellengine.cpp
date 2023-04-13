#include "shellengine.h"

ShellEngine::ShellEngine()
{
    connect(this, &ShellEngine::commandStrChanged, this, [=]() { this->exec(m_commandStr); });
}

void ShellEngine::exec(QString args) {
    QProcess *proc = new QProcess();
    QStringList argsList;
    argsList.append("-c");
    argsList.append(args);
    proc->start("bash", argsList);
    connect(proc, SIGNAL(finished(int)), this, SLOT(triggerStdout()));
}

void ShellEngine::triggerStdout() {
    QByteArray result = ((QProcess *)sender())->readAllStandardOutput();
    QString final = QString::fromUtf8(result);
    m_stdout = final;
    sender()->deleteLater();
    emit stdoutChanged();
}

#include "shellengine.h"

ShellEngine::ShellEngine()
{
    connect(this, &ShellEngine::commandStrChanged, this, [=]() { this->exec(m_commandStr, QString()); });
}

void ShellEngine::exec(QString args) {
    exec(args, QStringLiteral(""));
}

void ShellEngine::exec(QString args, QString stdinFeed) {
    QProcess *proc = execCore(args, stdinFeed);
    connect(proc, SIGNAL(finished(int)), this, SLOT(triggerExited()));
}

int ShellEngine::execSync(QString args) {
    return execSync(args, QStringLiteral(""));
}

int ShellEngine::execSync(QString args, QString stdinFeed) {
    QProcess *proc = execCore(args, stdinFeed);
    proc->waitForFinished();
    m_stdout = extractStdout(proc);
    proc->deleteLater();
    return proc->exitCode();
}

QProcess *ShellEngine::execCore(QString args, QString stdinFeed) {
    QProcess *proc = new QProcess();
    QStringList argsList;
    argsList.append(QStringLiteral("-c"));
    argsList.append(args);
    proc->start(QStringLiteral("bash"), argsList);
    lastProcess = proc;
    if (stdinFeed.length() != 0) {
        proc->write(stdinFeed.toUtf8());
    }
    proc->closeWriteChannel();
    return proc;
}

void ShellEngine::triggerExited() {
    QProcess *proc = ((QProcess *)sender());
    m_stdout = extractStdout(proc);
    sender()->deleteLater();
    Q_EMIT appExited(proc == lastProcess, proc->exitCode());
}

QString ShellEngine::extractStdout(QProcess *proc) {
    QByteArray result = proc->readAllStandardOutput();
    QString final = QString::fromUtf8(result);
    return final;
}

#include "shellengine.h"

ShellEngine::ShellEngine()
{
    connect(this, &ShellEngine::commandStrChanged, this, [=]() { this->exec(m_commandStr); });
}

void ShellEngine::exec(QString args) {
    QProcess *proc = execCore(args);
    connect(proc, SIGNAL(finished(int)), this, SLOT(triggerStdout()));
}

int ShellEngine::execSync(QString args) {
  QProcess *proc = execCore(args);
  proc->waitForFinished();
  m_stdout = QString::fromUtf8(proc->readAllStandardOutput());
  proc->deleteLater();
  return proc->exitCode();
}

void ShellEngine::ignoreResult() {
  m_ignoreResult = true;
}

void ShellEngine::triggerStdout() {
    if (m_ignoreResult) {
      m_ignoreResult = false;
      sender()->deleteLater();
      return;
    }

    QByteArray result = ((QProcess *)sender())->readAllStandardOutput();
    QString final = QString::fromUtf8(result);
    m_stdout = final;
    sender()->deleteLater();
    Q_EMIT stdoutChanged();
}

QProcess *ShellEngine::execCore(QString args) {
    QProcess *proc = new QProcess();
    QStringList argsList;
    argsList.append(QStringLiteral("-c"));
    argsList.append(args);
    proc->start(QStringLiteral("bash"), argsList);
    return proc;
}

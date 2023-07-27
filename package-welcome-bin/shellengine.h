#ifndef SHELLENGINE_H
#define SHELLENGINE_H

#include <QObject>
#include <QProcess>
#include <QQueue>
#include <QtQml/qqml.h>

class ShellEngine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString commandStr READ commandStr WRITE setCommandStr NOTIFY commandStrChanged)
    Q_PROPERTY(QString stdout READ stdout)
    QML_ELEMENT
public:
    ShellEngine();
    Q_INVOKABLE void exec(QString args);
    Q_INVOKABLE void exec(QString args, QString stdinFeed);
    Q_INVOKABLE int execSync(QString args);
    Q_INVOKABLE int execSync(QString args, QString stdinFeed);
    QString commandStr() {
        return m_commandStr;
    }
    void setCommandStr(QString val) {
        m_commandStr = val;
    }
    QString stdout() {
        return m_stdout;
    }

signals:
    void commandStrChanged();
    void appExited(bool wasLastProcess, int exitCode);

public slots:
    void triggerExited();

private:
    QString m_stdout;
    QString m_commandStr;
    QProcess *lastProcess;
    QProcess *execCore(QString args, QString stdinFeed);
    QString extractStdout(QProcess *proc);
};

#endif // SHELLENGINE_H

#ifndef SHELLENGINE_H
#define SHELLENGINE_H

#include <QObject>
#include <QProcess>
#include <QQueue>
#include <QtQml/qqml.h>

class ShellEngine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString commandStr MEMBER m_commandStr NOTIFY commandStrChanged)
    Q_PROPERTY(QString stdout MEMBER m_stdout)
    QML_ELEMENT
public:
    ShellEngine();
    Q_INVOKABLE void exec(QString args);
    Q_INVOKABLE void exec(QString args, QString stdinFeed);
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
};

#endif // SHELLENGINE_H

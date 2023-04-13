#ifndef SHELLENGINE_H
#define SHELLENGINE_H

#include <QObject>
#include <QProcess>
#include <QQueue>
#include <QtQml/qqml.h>

class ShellEngine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString stdout READ stdout NOTIFY stdoutChanged)
    Q_PROPERTY(QString commandStr MEMBER m_commandStr NOTIFY commandStrChanged)
    QML_ELEMENT
public:
    ShellEngine();
    Q_INVOKABLE void exec(QString args);
    QString stdout() {
        return m_stdout;
    }

signals:
    void stdoutChanged();
    void commandStrChanged();

public slots:
    void triggerStdout();

private:
    QString m_stdout;
    QString m_commandStr;
};

#endif // SHELLENGINE_H

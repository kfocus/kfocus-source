#ifndef STARTUPDATA_H
#define STARTUPDATA_H

#include <QObject>
#include <QtQml/qqml.h>

class StartupData : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList encryptedDisks READ encryptedDisks WRITE setEncryptedDisks)
    Q_PROPERTY(QString binDir READ binDir)
    QML_ELEMENT
public:
    StartupData();
    QStringList encryptedDisks() {
        return m_encryptedDisks;
    }
    void setEncryptedDisks(QStringList val) {
        m_encryptedDisks = val;
    }
    QString binDir() {
        return m_binDir;
    }

private:
    static QStringList m_encryptedDisks;
    static QString m_binDir;
};

#endif // STARTUPDATA_H

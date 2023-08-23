#ifndef STARTUPDATA_H
#define STARTUPDATA_H

#include <QObject>
#include <QtQml/qqml.h>

class StartupData : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList cryptDiskList READ cryptDiskList WRITE setCryptDiskList)
    Q_PROPERTY(QString binDir READ binDir)
    Q_PROPERTY(QString homeDir READ homeDir WRITE setHomeDir)
    Q_PROPERTY(QString userName READ userName WRITE setUserName)
    QML_ELEMENT 
public:
    StartupData();
    QStringList cryptDiskList() {
        return m_cryptDiskList;
    }
    void setCryptDiskList(QStringList val) {
        m_cryptDiskList = val;
    }
    QString binDir() {
        return m_binDir;
    }
    QString homeDir() {
        return m_homeDir;
    }
    QString userName() {
        return m_userName;
    }
    void setHomeDir(QString val) {
        m_homeDir = val;
    }
    void setUserName(QString val) {
        m_userName = val;
    }

private:
    static QStringList m_cryptDiskList;
    static QString m_binDir;
    static QString m_homeDir;
    static QString m_userName;
};

#endif // STARTUPDATA_H

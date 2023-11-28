#ifndef STARTUPDATA_H
#define STARTUPDATA_H

#include <QObject>
#include <QtQml/qqml.h>

class StartupData : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList cryptDiskList READ cryptDiskList WRITE setCryptDiskList)
    Q_PROPERTY(QString binDir READ binDir WRITE setBinDir)
    Q_PROPERTY(QString homeDir READ homeDir WRITE setHomeDir)
    Q_PROPERTY(QString userName READ userName WRITE setUserName)
    Q_PROPERTY(QString welcomeCmd READ welcomeCmd WRITE setWelcomeCmd)
    Q_PROPERTY(bool isLiveSession READ isLiveSession WRITE setIsLiveSession)
    QML_ELEMENT 

public:
    StartupData();
    QStringList cryptDiskList() {
        return m_cryptDiskList;
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
    QString welcomeCmd() {
        return m_welcomeCmd;
    }
    bool isLiveSession() {
        return m_isLiveSession;
    }

    void setCryptDiskList(QStringList val) {
        m_cryptDiskList = val;
    }
    void setBinDir(QString val) {
        m_binDir = val;
    }
    void setHomeDir(QString val) {
        m_homeDir = val;
    }
    void setUserName(QString val) {
        m_userName = val;
    }
    void setWelcomeCmd(QString val) {
        m_welcomeCmd = val;
    }
    void setIsLiveSession(bool val) {
        m_isLiveSession = val;
    }

private:
    static QStringList m_cryptDiskList;
    static QString m_binDir;
    static QString m_homeDir;
    static QString m_userName;
    static QString m_welcomeCmd;
    static bool m_isLiveSession;
};

#endif // STARTUPDATA_H

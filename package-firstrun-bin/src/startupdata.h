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
    Q_PROPERTY(QString rollbackCmd READ rollbackCmd WRITE setRollbackCmd)
    Q_PROPERTY(bool isLiveSession READ isLiveSession WRITE setIsLiveSession)
    Q_PROPERTY(QString startPage READ startPage WRITE setStartPage)
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
    QString rollbackCmd() {
      return m_rollbackCmd;
    }
    bool isLiveSession() {
        return m_isLiveSession;
    }
    QString startPage() {
        return m_startPage;
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
    void setRollbackCmd(QString val) {
      m_rollbackCmd = val;
    }
    void setIsLiveSession(bool val) {
        m_isLiveSession = val;
    }
    void setStartPage(QString val) {
        m_startPage = val;
    }

private:
    static QStringList m_cryptDiskList;
    static QString m_binDir;
    static QString m_homeDir;
    static QString m_userName;
    static QString m_rollbackCmd;
    static bool m_isLiveSession;
    static QString m_startPage;
};

#endif // STARTUPDATA_H

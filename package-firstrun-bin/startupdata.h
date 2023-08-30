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
    bool isLiveSession() {
        return m_isLiveSession;
    }
    void setCryptDiskList(QStringList val) {
        m_cryptDiskList = val;
    }
    void setHomeDir(QString val) {
        m_homeDir = val;
    }
    void setUserName(QString val) {
        m_userName = val;
    }
    void setIsLiveSession(bool val) {
        m_isLiveSession = val;
    }

private:
    static QStringList m_cryptDiskList;
    static QString m_binDir;
    static QString m_homeDir;
    static QString m_userName;
    static bool m_isLiveSession;
};

#endif // STARTUPDATA_H

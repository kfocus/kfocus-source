#ifndef STARTUPDATA_H
#define STARTUPDATA_H

#include <QObject>
#include <QtQml/qqml.h>

class StartupData : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList cryptDiskList READ cryptDiskList WRITE setCryptDiskList)
    Q_PROPERTY(QString binDir READ binDir)
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

private:
    static QStringList m_cryptDiskList;
    static QString m_binDir;
};

#endif // STARTUPDATA_H

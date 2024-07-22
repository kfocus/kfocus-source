#ifndef BACKENDENGINE_H
#define BACKENDENGINE_H

#include <QObject>
#include <QtQml/qqml.h>

class BackendEngine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString rollbackSetExe READ rollbackSetExe NOTIFY rollbackSetExeChanged)
    Q_PROPERTY(QString pkexecExe READ pkexecExe NOTIFY pkexecExeChanged)
    Q_PROPERTY(bool automaticSnapshotsEnabled READ automaticSnapshotsEnabled NOTIFY automaticSnapshotsEnabledChanged)
    QML_ELEMENT 

public:
    BackendEngine();
    QString rollbackSetExe();
    void setRollbackSetExe(QString val);
    QString pkexecExe();
    void setPkexecExe(QString val);
    bool automaticSnapshotsEnabled();
    void setAutomaticSnapshotsEnabled(bool val);
    QList<QMap<QString, QString>> *snapshotList();
    void setSnapshotList(QList<QMap<QString, QString>> *val);
    QMap<QString, QString> *mainFsInfo();
    void setMainFsInfo(QMap<QString, QString> *val);
    QMap<QString, QString> *bootFsInfo();
    void setBootFsInfo(QMap<QString, QString> *val);
    Q_INVOKABLE int getSnapshotCount();
    Q_INVOKABLE QString getSnapshotInfo(int index, QString key);
    Q_INVOKABLE QString getFsData(QString fs, QString key);
    Q_INVOKABLE QString toBase64(QString val);
    Q_INVOKABLE void refreshSystemData();

signals:
    void rollbackSetExeChanged();
    void pkexecExeChanged();
    void automaticSnapshotsEnabledChanged();

private:
    QString fieldSeek(QStringList lines, QString searchStr, int field);

    static QString m_rollbackSetExe;
    static QString m_pkexecExe;
    static bool m_automaticSnapshotsEnabled;
    static QList<QMap<QString, QString>> *m_snapshotList;
    static QMap<QString, QString> *m_mainFsInfo;
    static QMap<QString, QString> *m_bootFsInfo;
};

#endif // BACKENDENGINE_H

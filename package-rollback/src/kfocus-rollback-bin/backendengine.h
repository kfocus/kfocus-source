#ifndef BACKENDENGINE_H
#define BACKENDENGINE_H

#include <QObject>
#include <QtQml/qqml.h>

class BackendEngine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString rollbackBackendExe READ rollbackBackendExe CONSTANT)
    Q_PROPERTY(QString rollbackSetExe READ rollbackSetExe CONSTANT)
    Q_PROPERTY(QString pkexecExe READ pkexecExe NOTIFY pkexecExeChanged)
    Q_PROPERTY(bool automaticSnapshotsEnabled READ automaticSnapshotsEnabled NOTIFY automaticSnapshotsEnabledChanged)
    Q_PROPERTY(bool inhibitClose READ inhibitClose WRITE setInhibitClose NOTIFY inhibitCloseChanged)
    Q_PROPERTY(bool mainSpaceLow READ mainSpaceLow WRITE setMainSpaceLow NOTIFY mainSpaceLowChanged)
    QML_ELEMENT 

public:
    BackendEngine();
    QString rollbackBackendExe();
    QString rollbackSetExe();
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
    bool inhibitClose();
    void setInhibitClose(bool val);
    bool mainSpaceLow();
    void setMainSpaceLow(bool val);
    Q_INVOKABLE int getSnapshotCount();
    Q_INVOKABLE QString getSnapshotInfo(int index, QString key);
    Q_INVOKABLE QString getFsData(QString fs, QString key);
    Q_INVOKABLE QString toBase64(QString val);
    Q_INVOKABLE bool isBackgroundRollbackRunning();
    Q_INVOKABLE void refreshSystemData(bool calcSize);

signals:
    void pkexecExeChanged();
    void inhibitCloseChanged();
    void automaticSnapshotsEnabledChanged();
    void systemDataLoaded();
    void mainSpaceLowChanged();

private slots:
    void onSystemDataReady();

private:
    QString fieldSeek(QStringList lines, QString searchStr, int field);
    QString bytesToGib(quint64 val);

    void loadGlobalInfo();

    static QString m_rollbackBackendExe;
    static QString m_rollbackSetExe;
    static QString m_pkexecExe;
    static bool m_automaticSnapshotsEnabled;
    static QList<QMap<QString, QString>> *m_snapshotList;
    static QMap<QString, QString> *m_mainFsInfo;
    static QMap<QString, QString> *m_bootFsInfo;
    static bool m_inhibitClose;
    static bool m_mainSpaceLow;

    static QStringList m_snapshotIdList;
    static int m_snapshotIdIdx;
    static bool m_calcSize;
};

#endif // BACKENDENGINE_H

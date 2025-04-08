#ifndef BACKENDENGINE_H
#define BACKENDENGINE_H

#include <QObject>
#include <QtQml/qqml.h>

class BackendEngine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString rollbackBackendExe READ rollbackBackendExe CONSTANT)
    Q_PROPERTY(QString rollbackSetExe READ rollbackSetExe CONSTANT)
    Q_PROPERTY(QString rollbackMainWorkingDir READ rollbackMainWorkingDir CONSTANT)
    Q_PROPERTY(QString rollbackBootWorkingDir READ rollbackBootWorkingDir CONSTANT)
    Q_PROPERTY(QString pkexecExe READ pkexecExe CONSTANT)
    Q_PROPERTY(QString systemdInhibitExe READ systemdInhibitExe CONSTANT)
    Q_PROPERTY(bool automaticSnapshotsEnabled READ automaticSnapshotsEnabled NOTIFY automaticSnapshotsEnabledChanged)
    Q_PROPERTY(bool inhibitClose READ inhibitClose WRITE setInhibitClose NOTIFY inhibitCloseChanged)
    Q_PROPERTY(bool mainSpaceLow READ mainSpaceLow NOTIFY mainSpaceLowChanged)
    Q_PROPERTY(bool bootSpaceLow READ bootSpaceLow NOTIFY bootSpaceLowChanged)
    Q_PROPERTY(bool btrfsStateUnusable READ btrfsStateUnusable NOTIFY btrfsStateUnusableChanged)
    Q_PROPERTY(bool postRestoreSubvolsMounted READ postRestoreSubvolsMounted NOTIFY postRestoreSubvolsMountedChanged)
    Q_PROPERTY(bool mainWorkingSubvolExists READ mainWorkingSubvolExists NOTIFY mainWorkingSubvolExistsChanged)
    Q_PROPERTY(bool bootWorkingSubvolExists READ bootWorkingSubvolExists NOTIFY bootWorkingSubvolExistsChanged)
    Q_PROPERTY(bool snapshotSizeInfoPresent READ snapshotSizeInfoPresent NOTIFY snapshotSizeInfoPresentChanged)
    QML_ELEMENT

public:
    BackendEngine();
    QString rollbackBackendExe();
    QString rollbackSetExe();
    QString rollbackMainWorkingDir();
    QString rollbackBootWorkingDir();
    QString pkexecExe();
    QString systemdInhibitExe();
    bool automaticSnapshotsEnabled();
    QList<QMap<QString, QString>> *snapshotList();
    void setSnapshotList(QList<QMap<QString, QString>> *val);
    QMap<QString, QString> *mainFsInfo();
    void setMainFsInfo(QMap<QString, QString> *val);
    QMap<QString, QString> *bootFsInfo();
    void setBootFsInfo(QMap<QString, QString> *val);
    bool inhibitClose();
    void setInhibitClose(bool val);
    bool mainSpaceLow();
    bool bootSpaceLow();
    bool btrfsStateUnusable();
    bool postRestoreSubvolsMounted();
    bool mainWorkingSubvolExists();
    bool bootWorkingSubvolExists();
    bool snapshotSizeInfoPresent();
    Q_INVOKABLE int getSnapshotCount();
    Q_INVOKABLE QString getSnapshotInfo(int index, QString key);
    Q_INVOKABLE QString getFsData(QString fs, QString key);
    Q_INVOKABLE QString toBase64(QString val);
    Q_INVOKABLE bool isBackgroundRollbackRunning();
    Q_INVOKABLE void refreshSystemData(bool calcSize);

signals:
    void inhibitCloseChanged();
    void automaticSnapshotsEnabledChanged();
    void mainSpaceLowChanged();
    void bootSpaceLowChanged();
    void systemDataLoaded();
    void btrfsStateUnusableChanged();
    void postRestoreSubvolsMountedChanged();
    void mainWorkingSubvolExistsChanged();
    void bootWorkingSubvolExistsChanged();
    void snapshotSizeInfoPresentChanged();

private slots:
    void onSystemDataReady();

private:
    QString fieldSeek(QStringList lines, QString searchStr, int field);
    QString bytesToGib(quint64 val, bool keepShort);

    void loadGlobalInfo();

    static QString m_rollbackBackendExe;
    static QString m_rollbackSetExe;
    static QString m_rollbackMainWorkingDir;
    static QString m_rollbackBootWorkingDir;
    static QString m_pkexecExe;
    static QString m_systemdInhibitExe;
    static bool m_automaticSnapshotsEnabled;
    static QList<QMap<QString, QString>> *m_snapshotList;
    static QMap<QString, QString> *m_mainFsInfo;
    static QMap<QString, QString> *m_bootFsInfo;
    static bool m_inhibitClose;
    static bool m_mainSpaceLow;
    static bool m_bootSpaceLow;
    static bool m_btrfsStateUnusable;
    static bool m_postRestoreSubvolsMounted;
    static bool m_mainWorkingSubvolExists;
    static bool m_bootWorkingSubvolExists;
    static bool m_snapshotSizeInfoPresent;

    static QStringList m_snapshotIdList;
    static int m_snapshotIdIdx;
    static bool m_calcSize;
    static quint64 m_mainMinUnalloc;
    static quint64 m_bootMinUnalloc;
    static bool m_updateInProgress;
};

#endif // BACKENDENGINE_H

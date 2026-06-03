#include <QDateTime>
#include <QDir>
#include <QtLogging>

#include "backendengine.h"
#include "shellengine.h"

BackendEngine::BackendEngine() { }

QString BackendEngine::rollbackBackendExe() {
    return m_rollbackBackendExe;
}

QString BackendEngine::rollbackSetExe() {
    return m_rollbackSetExe;
}

QString BackendEngine::rollbackMainWorkingDir() {
    return m_rollbackMainWorkingDir;
}

QString BackendEngine::rollbackBootWorkingDir() {
    return m_rollbackBootWorkingDir;
}

QString BackendEngine::pkexecExe() {
    return m_pkexecExe;
}

QString BackendEngine::systemdInhibitExe() {
    return m_systemdInhibitExe;
}

bool BackendEngine::automaticSnapshotsEnabled()
{
    return m_automaticSnapshotsEnabled;
}

QList<QMap<QString, QString>> *BackendEngine::snapshotList() {
    return m_snapshotList;
}

void BackendEngine::setSnapshotList(QList<QMap<QString, QString>> *val) {
    m_snapshotList = val;
}

QMap<QString, QString> *BackendEngine::mainFsInfo() {
    return m_mainFsInfo;
}

void BackendEngine::setMainFsInfo(QMap<QString, QString> *val) {
    m_mainFsInfo = val;
}

QMap<QString, QString> *BackendEngine::bootFsInfo() {
    return m_bootFsInfo;
}

void BackendEngine::setBootFsInfo(QMap<QString, QString> *val) {
    m_mainFsInfo = val;
}

bool BackendEngine::inhibitClose() {
    return m_inhibitClose;
}

void BackendEngine::setInhibitClose(bool val) {
    m_inhibitClose = val;
    Q_EMIT inhibitCloseChanged();
}

bool BackendEngine::mainSpaceLow() {
    return m_mainSpaceLow;
}

bool BackendEngine::bootSpaceLow() {
    return m_bootSpaceLow;
}

bool BackendEngine::btrfsStateUnusable() {
    return m_btrfsStateUnusable;
}

bool BackendEngine::postRestoreSubvolsMounted() {
    return m_postRestoreSubvolsMounted;
}

bool BackendEngine::mainWorkingSubvolExists() {
    return m_mainWorkingSubvolExists;
}

bool BackendEngine::bootWorkingSubvolExists() {
    return m_bootWorkingSubvolExists;
}

bool BackendEngine::snapshotSizeInfoPresent() {
    return m_snapshotSizeInfoPresent;
}

QStringList BackendEngine::bulkDataList() {
    return m_bulkDataList;
}

bool BackendEngine::bulkDataWarningEnabled() {
    m_settings.beginGroup(QStringLiteral("kfocus-rollback"));
    QString val = m_settings.value(QStringLiteral("bulkDataWarningEnabled"), QStringLiteral("true")).toString();
    m_settings.endGroup();
    if (val == QStringLiteral("true")) {
        return true;
    }
    return false;
}

int BackendEngine::getSnapshotCount() {
    return m_snapshotList->length();
}

QString BackendEngine::getSnapshotInfo(int index, QString key) {
    return m_snapshotList->at(index).value(key);
}
QString BackendEngine::getFsData(QString fs, QString key) {
    if (fs == QStringLiteral("main")) {
        return m_mainFsInfo->value(key);
    } else if (fs == QStringLiteral("boot")) {
        return m_bootFsInfo->value(key);
    } else {
        return QStringLiteral("");
    }
}

QString BackendEngine::toBase64(QString val) {
    return QString::fromUtf8(val.toUtf8().toBase64());
}

bool BackendEngine::isBackgroundRollbackRunning() {
    ShellEngine execEngine;
    execEngine.execSync(QStringLiteral("ps axo cmd | grep kfocus-rollback-backend | grep -v getSnapshotList | grep -v grep"));
    if (execEngine.stdout().trimmed() == QStringLiteral("")) {
        return false;
    } else {
        return true;
    }
}

QString BackendEngine::fieldSeek(QStringList lines, QString searchStr, int field) {
    for (int i = 0; i < lines.count(); i++) {
        if (lines[i].contains(searchStr)) {
            QStringList splitLine = lines[i].trimmed().split(QStringLiteral(" "), Qt::SkipEmptyParts);
            if (field < splitLine.count()) {
                return splitLine[field];
            }
        }
    }
    return QStringLiteral("");
}

QString BackendEngine::bytesToGib(quint64 val, bool keepShort) {
    double gibSize = (((static_cast<double>(val) / 1024) / 1024) / 1024);
    gibSize = qRound(gibSize * 100.0) / 100.0;
    QString gibSizeStr;
    if (gibSize >= 100 && keepShort) {
        gibSizeStr = QString::number(gibSize, 'f', 0);
    } else {
        gibSizeStr = QString::number(gibSize, 'f', 1);
    }
    return gibSizeStr;
}

void BackendEngine::refreshSystemData(bool calcSize) {
    /*
     * This is the "kickoff" method. It starts a refresh process using an
     * asynchronous "loop" implemented with ShellEngine connections. It's
     * ugly, but this was the only way I could think of to leverage the
     * kfocus-rollback-backend API in an asynchronous fashion.
     *
     * WARNING: It is mandatory that this function is NOT executed while a
     * refresh process is actively running! This is not re-entrant, it is not
     * thread-safe, and if you call it multiple times in quick succession,
     * behavior is undefined.
     */
    if (m_updateInProgress) {
      return;
    }

    m_calcSize = calcSize;
    ShellEngine *execEngine = new ShellEngine();

    m_snapshotList->clear();

    // NOTE: Callback is connected before execution, this is confusing but it's the only safe way to do this
    connect(execEngine, &ShellEngine::appExited, this, [&, execEngine]() {
        execEngine->disconnect(this);

        // Get automatic snapshot state
        QString btrfsStatus = execEngine->stdout().trimmed();
        if (btrfsStatus == QStringLiteral("SUPPORTED, MANUAL")) {
            m_automaticSnapshotsEnabled = false;
            Q_EMIT automaticSnapshotsEnabledChanged();
        } else if (btrfsStatus == QStringLiteral("SUPPORTED, AUTO")) {
            m_automaticSnapshotsEnabled = true;
            Q_EMIT automaticSnapshotsEnabledChanged();
        } else {
            m_btrfsStateUnusable = true;
            Q_EMIT btrfsStateUnusableChanged();
        }

        // Determine if post-restore subvols are mounted or not
        execEngine->execSync(QStringLiteral("mount | grep 'btrfs' | grep -q '@kfocus-rollback-working'; echo $?"));
        QString prMountCheckStr = execEngine->stdout().trimmed();
        if (prMountCheckStr == QStringLiteral("0")) {
            m_postRestoreSubvolsMounted = true;
            Q_EMIT postRestoreSubvolsMountedChanged();
        }
        execEngine->execSync(QStringLiteral("mount | grep 'btrfs' | grep -q '@kfocus-rollback-working-boot'; echo $?"));
        prMountCheckStr = execEngine->stdout().trimmed();
        if (prMountCheckStr == QStringLiteral("0")) {
            m_postRestoreSubvolsMounted = true;
            Q_EMIT postRestoreSubvolsMountedChanged();
        }

        // Check post-restore subvol locations
        if (!m_postRestoreSubvolsMounted) {
            if (QDir(m_rollbackMainWorkingDir).exists()) {
                m_mainWorkingSubvolExists = true;
                Q_EMIT mainWorkingSubvolExistsChanged();
            } else if (QDir(m_rollbackBootWorkingDir).exists()) {
                m_bootWorkingSubvolExists = true;
                Q_EMIT bootWorkingSubvolExistsChanged();
            }
        }

        if (!m_btrfsStateUnusable) {
            // NOTE: Callback is connected before execution, this is confusing but it's the only safe way to do this
            connect(execEngine, &ShellEngine::appExited, this, [&, execEngine](){
                execEngine->disconnect(this);

                m_snapshotIdList = execEngine->stdout().split(QStringLiteral("\n"), Qt::SkipEmptyParts);
                if (m_snapshotIdList.count() == 0) {
                    loadGlobalInfo();
                } else {
                    m_snapshotIdIdx = 0;
                    connect(execEngine, &ShellEngine::appExited, this, &BackendEngine::onSystemDataReady);
                    if (m_calcSize) {
                        execEngine->exec(m_pkexecExe + QStringLiteral(" ") + m_rollbackSetExe + QStringLiteral(" getFullSnapshotMetadata ") + m_snapshotIdList.at(0));
                    } else {
                        execEngine->exec(m_pkexecExe + QStringLiteral(" ") + m_rollbackSetExe + QStringLiteral(" getBaseSnapshotMetadata ") + m_snapshotIdList.at(0));
                    }
                }
            });
            execEngine->exec(m_pkexecExe + QStringLiteral(" ") + m_rollbackSetExe + QStringLiteral(" getSnapshotList"));
        } else {
            execEngine->deleteLater();
            Q_EMIT systemDataLoaded();
            m_updateInProgress = false;
        }
    });
    execEngine->exec(m_pkexecExe + QStringLiteral(" ") + m_rollbackSetExe + QStringLiteral(" getBtrfsStatus"));
    m_updateInProgress = true;
}

void BackendEngine::onSystemDataReady() {
    /*
     * This function essentially calls itself via a signal handler in order to
     * loop asynchronously (i.e., while the work being done is handled in a
     * worker process, the UI remains responsive rather than hanging).
     */

    ShellEngine *execEngine = ((ShellEngine *)sender());
    execEngine->disconnect(this);

    // Get raw data from the ShellEngine
    QString snapshotItem = m_snapshotIdList.at(m_snapshotIdIdx);
    QStringList snapshotMetadataList = execEngine->stdout().split(QStringLiteral("\n"));
    if (snapshotMetadataList.count() < 6 || snapshotMetadataList.at(0) == QStringLiteral("Invalid mode specified.")) {
        qWarning() << QStringLiteral("Snapshot metadata unsupported - incompatible BTRFS status hit?");
        return;
    }

    QString metaSnapshotName = snapshotMetadataList.at(0);
    QString metaSnapshotDesc = snapshotMetadataList.at(1);
    QString metaSnapshotPinned = snapshotMetadataList.at(2);
    QString metaSnapshotReason = snapshotMetadataList.at(3);
    QString metaMainSnapshotSize = snapshotMetadataList.at(4);
    QString metaBootSnapshotSize = snapshotMetadataList.at(5);

    // Parse trivial snapshot info
    QString snapshotReason = metaSnapshotReason.trimmed();
    QString snapshotName = QString::fromUtf8(QByteArray::fromBase64(metaSnapshotName.toUtf8()));
    if (snapshotName.isEmpty()) {
        snapshotName = snapshotReason;
    }
    QString snapshotDesc = QString::fromUtf8(QByteArray::fromBase64(metaSnapshotDesc.toUtf8()));
    QString snapshotPinned = metaSnapshotPinned == QStringLiteral("y") ? QStringLiteral("true") : QStringLiteral("false");
    QString snapshotStateDir = QStringLiteral("/btrfs_main/@kfocus-rollback-snapshots/") + snapshotItem;
    QString snapshotId = snapshotItem;

    // Parse snapshot size
    quint64 mainSnapshotIntSize = metaMainSnapshotSize.toULongLong();
    quint64 bootSnapshotIntSize = metaBootSnapshotSize.toULongLong();
    QString mainSnapshotSize;
    QString bootSnapshotSize;
    if (metaMainSnapshotSize == QStringLiteral("")) {
        mainSnapshotSize = QStringLiteral("");
    } else {
        mainSnapshotSize = bytesToGib(mainSnapshotIntSize, true);
    }
    if (metaBootSnapshotSize == QStringLiteral("")) {
        bootSnapshotSize = QStringLiteral("");
    } else {
        bootSnapshotSize = bytesToGib(bootSnapshotIntSize, true);
    }

    // Parse snapshot date (this mangles the snapshotItem string so we have to do it last)
    QDateTime snapshotTs = QDateTime::fromSecsSinceEpoch(snapshotItem.remove(0, 1).toULong());
    QString snapshotDate = snapshotTs.toString(Qt::ISODate).split(QStringLiteral("T")).at(0);
    snapshotDate += QStringLiteral(" ") + snapshotTs.toString(Qt::ISODate).split(QStringLiteral("T")).at(1).split(QStringLiteral("-")).at(0).left(5);
    QString snapshotDayOfWeek = snapshotTs.toString(QStringLiteral("dddd"));

    // Load parsed data into the snapshot list
    m_snapshotList->append(QMap<QString, QString>({
        { QStringLiteral("reason"), snapshotReason },
        { QStringLiteral("name"), snapshotName },
        { QStringLiteral("description"), snapshotDesc },
        { QStringLiteral("pinned"), snapshotPinned },
        { QStringLiteral("stateDir"), snapshotStateDir },
        { QStringLiteral("id"), snapshotId },
        { QStringLiteral("mainSize"), mainSnapshotSize },
        { QStringLiteral("bootSize"), bootSnapshotSize},
        { QStringLiteral("date"), snapshotDate },
        { QStringLiteral("dayofweek"), snapshotDayOfWeek }
    }));

    // Loop if necessary, otherwise get global disk info
    m_snapshotIdIdx++;
    if (m_snapshotIdIdx < m_snapshotIdList.count()) {
        connect(execEngine, &ShellEngine::appExited, this, &BackendEngine::onSystemDataReady);
        if (m_calcSize) {
            execEngine->exec(m_pkexecExe + QStringLiteral(" ") + m_rollbackSetExe + QStringLiteral(" getFullSnapshotMetadata ") + m_snapshotIdList.at(m_snapshotIdIdx));
        } else {
            execEngine->exec(m_pkexecExe + QStringLiteral(" ") + m_rollbackSetExe + QStringLiteral(" getBaseSnapshotMetadata ") + m_snapshotIdList.at(m_snapshotIdIdx));
        }
    } else {
        loadGlobalInfo();
        execEngine->deleteLater();
    }
}

void BackendEngine::loadGlobalInfo() {
    ShellEngine *execEngine = new ShellEngine();

    // NOTE: Callback is connected before execution, this is confusing but it's the only safe way to do this
    connect(execEngine, &ShellEngine::appExited, this, [&, execEngine](){
        execEngine->disconnect(this);
        m_mainMinUnalloc = execEngine->stdout().toULongLong();

        // NOTE: Callback is connected before execution, this is confusing but it's the only safe way to do this
        connect(execEngine, &ShellEngine::appExited, this, [&, execEngine](){
            execEngine->disconnect(this);
            m_bootMinUnalloc = execEngine->stdout().toULongLong();

            // Get disk usage info
            execEngine->execSync(QStringLiteral("LC_ALL=C /usr/bin/btrfs filesystem usage -b '/btrfs_main'"));
            QStringList btrfsMainRawReport = execEngine->stdout().split(QStringLiteral("\n"));
            execEngine->execSync(QStringLiteral("LC_ALL=C /usr/bin/btrfs filesystem usage -b '/btrfs_boot'"));
            QStringList btrfsBootRawReport = execEngine->stdout().split(QStringLiteral("\n"));

            btrfsMainRawReport = btrfsMainRawReport.replaceInStrings(QStringLiteral("\t"), QStringLiteral(" "));
            btrfsBootRawReport = btrfsBootRawReport.replaceInStrings(QStringLiteral("\t"), QStringLiteral(" "));

            // Get main FS space consumption info
            quint64 btrfsMainRawSize = fieldSeek(btrfsMainRawReport, QStringLiteral("Device size:"), 2).toULongLong();
            quint64 btrfsMainRawRemain = fieldSeek(btrfsMainRawReport, QStringLiteral("Free (estimated):"), 2).toULongLong();
            quint64 btrfsMainRawUnalloc = fieldSeek(btrfsMainRawReport, QStringLiteral("Device unallocated:"), 2).toULongLong();
            double btrfsMainUnalloc = qRound((static_cast<double>(btrfsMainRawUnalloc) / static_cast<double>(btrfsMainRawSize)) * 10000.0) / 100.0;
            QString btrfsMainStatus;
            // NOTE: 15% is hardcoded in the backend.
            if (btrfsMainRawUnalloc > m_mainMinUnalloc) {
                btrfsMainStatus = QStringLiteral("Good >15%");
                m_mainSpaceLow = false;
                Q_EMIT mainSpaceLowChanged();
            } else {
                btrfsMainStatus = QStringLiteral("ALERT <15%");
                m_mainSpaceLow = true;
                Q_EMIT mainSpaceLowChanged();
            }
            QString btrfsMainSize = bytesToGib(btrfsMainRawSize, false);
            QString btrfsMainRemain = bytesToGib(btrfsMainRawRemain, false);

            // Get boot FS space consumption info
            quint64 btrfsBootRawSize = fieldSeek(btrfsBootRawReport, QStringLiteral("Device size:"), 2).toULongLong();
            quint64 btrfsBootRawRemain = fieldSeek(btrfsBootRawReport, QStringLiteral("Free (estimated):"), 2).toULongLong();
            quint64 btrfsBootRawUnalloc = fieldSeek(btrfsBootRawReport, QStringLiteral("Device unallocated:"), 2).toULongLong();
            double btrfsBootUnalloc = qRound((static_cast<double>(btrfsBootRawUnalloc) / static_cast<double>(btrfsBootRawSize)) * 10000.0) / 100.0;
            QString btrfsBootStatus;
            // NOTE: 25% is hardcoded in the backend.
            if (btrfsBootRawUnalloc > m_bootMinUnalloc) {
                btrfsBootStatus = QStringLiteral("Good >25%");
                m_bootSpaceLow = false;
                Q_EMIT bootSpaceLowChanged();
            } else {
                btrfsBootStatus = QStringLiteral("ALERT <25%");
                m_bootSpaceLow = true;
                Q_EMIT bootSpaceLowChanged();
            }
            QString btrfsBootSize = bytesToGib(btrfsBootRawSize, false);
            QString btrfsBootRemain = bytesToGib(btrfsBootRawRemain, false);

            // Load all the info into the fs info objects
            m_mainFsInfo->clear();
            m_mainFsInfo->insert(QMap<QString, QString>({
                { QStringLiteral("status"), btrfsMainStatus },
                { QStringLiteral("size"), QString(btrfsMainSize) },
                { QStringLiteral("remain"), QString(btrfsMainRemain) },
                // This value includes rounding because percentage calculated above
                { QStringLiteral("unalloc"), QString::number(btrfsMainUnalloc, 'f', 1) + QStringLiteral("%") }
            }));
            m_bootFsInfo->clear();
            m_bootFsInfo->insert(QMap<QString, QString>({
                { QStringLiteral("status"), btrfsBootStatus },
                { QStringLiteral("size"), QString(btrfsBootSize) },
                { QStringLiteral("remain"), QString(btrfsBootRemain) },
                // This value includes rounding because percentage calculated above
                { QStringLiteral("unalloc"), QString::number(btrfsBootUnalloc, 'f', 1) + QStringLiteral("%") }
            }));

            execEngine->deleteLater();
            m_snapshotSizeInfoPresent = m_calcSize;
            Q_EMIT snapshotSizeInfoPresentChanged();

            if (!m_bulkDataChecked) {
                m_bulkDataList.clear();
                execEngine->execSync(QStringLiteral("pkexec ") + m_rollbackSetExe + QStringLiteral(" getBulkDirList"));
                m_bulkDataList.append(execEngine->stdout().split(QStringLiteral("\n"), Qt::SkipEmptyParts));
                Q_EMIT bulkDataListChanged();
                m_bulkDataChecked = true;
            }

            Q_EMIT systemDataLoaded();
            m_updateInProgress = false;
        });
        execEngine->exec(m_pkexecExe + QStringLiteral(" ") + m_rollbackSetExe + QStringLiteral(" getBootMinUnalloc"));
    });
    execEngine->exec(m_pkexecExe + QStringLiteral(" ") + m_rollbackSetExe + QStringLiteral(" getMainMinUnalloc"));
}

void BackendEngine::enableBulkDataWarning() {
    m_settings.beginGroup(QStringLiteral("kfocus-rollback"));
    m_settings.setValue(QStringLiteral("bulkDataWarningEnabled"), QStringLiteral("true"));
    m_settings.endGroup();
    Q_EMIT bulkDataWarningEnabledChanged();
}

void BackendEngine::disableBulkDataWarning() {
    m_settings.beginGroup(QStringLiteral("kfocus-rollback"));
    m_settings.setValue(QStringLiteral("bulkDataWarningEnabled"), QStringLiteral("false"));
    m_settings.endGroup();
    Q_EMIT bulkDataWarningEnabledChanged();
}

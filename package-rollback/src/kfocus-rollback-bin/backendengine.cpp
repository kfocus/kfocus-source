#include <QDateTime>
#include <QDir>

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
    inhibitCloseChanged();
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
    m_settings.beginGroup("kfocus-rollback");
    QString val = m_settings.value("bulkDataWarningDisabled", "false").toString();
    m_settings.endGroup();
    if (val == "true") {
        return false;
    }
    return true;
}

int BackendEngine::getSnapshotCount() {
    return m_snapshotList->length();
}

QString BackendEngine::getSnapshotInfo(int index, QString key) {
    return m_snapshotList->at(index).value(key);
}
QString BackendEngine::getFsData(QString fs, QString key) {
    if (fs == "main") {
        return m_mainFsInfo->value(key);
    } else if (fs == "boot") {
        return m_bootFsInfo->value(key);
    } else {
        return "";
    }
}

QString BackendEngine::toBase64(QString val) {
    return QString(val.toUtf8().toBase64());
}

bool BackendEngine::isBackgroundRollbackRunning() {
    ShellEngine execEngine;
    execEngine.execSync("ps axo cmd | grep kfocus-rollback-backend | grep -v getSnapshotList | grep -v grep");
    if (execEngine.stdout().trimmed() == "") {
        return false;
    } else {
        return true;
    }
}

QString BackendEngine::fieldSeek(QStringList lines, QString searchStr, int field) {
    for (int i = 0; i < lines.count(); i++) {
        if (lines[i].contains(searchStr)) {
            QStringList splitLine = lines[i].trimmed().split(' ', Qt::SkipEmptyParts);
            if (field < splitLine.count()) {
                return splitLine[field];
            }
        }
    }
    return "";
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
        if (btrfsStatus == "SUPPORTED, MANUAL") {
            m_automaticSnapshotsEnabled = false;
            automaticSnapshotsEnabledChanged();
        } else if (btrfsStatus == "SUPPORTED, AUTO") {
            m_automaticSnapshotsEnabled = true;
            automaticSnapshotsEnabledChanged();
        } else {
            m_btrfsStateUnusable = true;
            btrfsStateUnusableChanged();
        }

        // Determine if post-restore subvols are mounted or not
        execEngine->execSync("mount | grep 'btrfs' | grep -q '@kfocus-rollback-working'; echo $?");
        QString prMountCheckStr = execEngine->stdout().trimmed();
        if (prMountCheckStr == "0") {
            m_postRestoreSubvolsMounted = true;
            postRestoreSubvolsMountedChanged();
        }
        execEngine->execSync("mount | grep 'btrfs' | grep -q '@kfocus-rollback-working-boot'; echo $?");
        prMountCheckStr = execEngine->stdout().trimmed();
        if (prMountCheckStr == "0") {
            m_postRestoreSubvolsMounted = true;
            postRestoreSubvolsMountedChanged();
        }

        // Check post-restore subvol locations
        if (!m_postRestoreSubvolsMounted) {
            if (QDir(m_rollbackMainWorkingDir).exists()) {
                m_mainWorkingSubvolExists = true;
                mainWorkingSubvolExistsChanged();
            } else if (QDir(m_rollbackBootWorkingDir).exists()) {
                m_bootWorkingSubvolExists = true;
                bootWorkingSubvolExistsChanged();
            }
        }

        if (!m_btrfsStateUnusable) {
            // NOTE: Callback is connected before execution, this is confusing but it's the only safe way to do this
            connect(execEngine, &ShellEngine::appExited, this, [&, execEngine](){
                execEngine->disconnect(this);

                m_snapshotIdList = execEngine->stdout().split('\n', Qt::SkipEmptyParts);
                if (m_snapshotIdList.count() == 0) {
                    loadGlobalInfo();
                } else {
                    m_snapshotIdIdx = 0;
                    connect(execEngine, &ShellEngine::appExited, this, &BackendEngine::onSystemDataReady);
                    if (m_calcSize) {
                        execEngine->exec(m_pkexecExe + ' ' + m_rollbackSetExe + " getFullSnapshotMetadata " + m_snapshotIdList.at(0));
                    } else {
                        execEngine->exec(m_pkexecExe + ' ' + m_rollbackSetExe + " getBaseSnapshotMetadata " + m_snapshotIdList.at(0));
                    }
                }
            });
            execEngine->exec(m_pkexecExe + ' ' + m_rollbackSetExe + " getSnapshotList");
        } else {
            execEngine->deleteLater();
            systemDataLoaded();
            m_updateInProgress = false;
        }
    });
    execEngine->exec(m_pkexecExe + ' ' + m_rollbackSetExe + " getBtrfsStatus");
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
    QStringList snapshotMetadataList = execEngine->stdout().split('\n');
    if (snapshotMetadataList.count() < 6 || snapshotMetadataList.at(0) == "Invalid mode specified.") {
        qWarning() << "Snapshot metadata unsupported - incompatible BTRFS status hit?";
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
    QString snapshotName = QString(QByteArray::fromBase64(metaSnapshotName.toUtf8()));
    if (snapshotName.isEmpty()) {
        snapshotName = snapshotReason;
    }
    QString snapshotDesc = QString(QByteArray::fromBase64(metaSnapshotDesc.toUtf8()));
    QString snapshotPinned = metaSnapshotPinned == "y" ? "true" : "false";
    QString snapshotStateDir = QString("/btrfs_main/@kfocus-rollback-snapshots/" + snapshotItem);
    QString snapshotId = snapshotItem;

    // Parse snapshot size
    quint64 mainSnapshotIntSize = metaMainSnapshotSize.toULongLong();
    quint64 bootSnapshotIntSize = metaBootSnapshotSize.toULongLong();
    QString mainSnapshotSize;
    QString bootSnapshotSize;
    if (metaMainSnapshotSize == "") {
        mainSnapshotSize = "";
    } else {
        mainSnapshotSize = bytesToGib(mainSnapshotIntSize, true);
    }
    if (metaBootSnapshotSize == "") {
        bootSnapshotSize = "";
    } else {
        bootSnapshotSize = bytesToGib(bootSnapshotIntSize, true);
    }

    // Parse snapshot date (this mangles the snapshotItem string so we have to do it last)
    QDateTime snapshotTs = QDateTime::fromSecsSinceEpoch(snapshotItem.remove(0, 1).toULong());
    QString snapshotDate = snapshotTs.toString(Qt::ISODate).split('T').at(0);
    snapshotDate += QString(' ') + snapshotTs.toString(Qt::ISODate).split('T').at(1).split('-').at(0).left(5);
    QString snapshotDayOfWeek = snapshotTs.toString("dddd");

    // Load parsed data into the snapshot list
    m_snapshotList->append(QMap<QString, QString>({
        { "reason", snapshotReason },
        { "name", snapshotName },
        { "description", snapshotDesc },
        { "pinned", snapshotPinned },
        { "stateDir", snapshotStateDir },
        { "id", snapshotId },
        { "mainSize", mainSnapshotSize },
        { "bootSize", bootSnapshotSize},
        { "date", snapshotDate },
        { "dayofweek", snapshotDayOfWeek }
    }));

    // Loop if necessary, otherwise get global disk info
    m_snapshotIdIdx++;
    if (m_snapshotIdIdx < m_snapshotIdList.count()) {
        connect(execEngine, &ShellEngine::appExited, this, &BackendEngine::onSystemDataReady);
        if (m_calcSize) {
            execEngine->exec(m_pkexecExe + ' ' + m_rollbackSetExe + " getFullSnapshotMetadata " + m_snapshotIdList.at(m_snapshotIdIdx));
        } else {
            execEngine->exec(m_pkexecExe + ' ' + m_rollbackSetExe + " getBaseSnapshotMetadata " + m_snapshotIdList.at(m_snapshotIdIdx));
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
            execEngine->execSync("LC_ALL=C /usr/bin/btrfs filesystem usage -b '/btrfs_main'");
            QStringList btrfsMainRawReport = execEngine->stdout().split('\n');
            execEngine->execSync("LC_ALL=C /usr/bin/btrfs filesystem usage -b '/btrfs_boot'");
            QStringList btrfsBootRawReport = execEngine->stdout().split('\n');

            btrfsMainRawReport = btrfsMainRawReport.replaceInStrings("\t", " ");
            btrfsBootRawReport = btrfsBootRawReport.replaceInStrings("\t", " ");

            // Get main FS space consumption info
            quint64 btrfsMainRawSize = fieldSeek(btrfsMainRawReport, "Device size:", 2).toULongLong();
            quint64 btrfsMainRawRemain = fieldSeek(btrfsMainRawReport, "Free (estimated):", 2).toULongLong();
            quint64 btrfsMainRawUnalloc = fieldSeek(btrfsMainRawReport, "Device unallocated:", 2).toULongLong();
            double btrfsMainUnalloc = qRound((static_cast<double>(btrfsMainRawUnalloc) / static_cast<double>(btrfsMainRawSize)) * 10000.0) / 100.0;
            QString btrfsMainStatus;
            // NOTE: 15% is hardcoded in the backend.
            if (btrfsMainRawUnalloc > m_mainMinUnalloc) {
                btrfsMainStatus = "Good >15%";
                m_mainSpaceLow = false;
                mainSpaceLowChanged();
            } else {
                btrfsMainStatus = "ALERT <15%";
                m_mainSpaceLow = true;
                mainSpaceLowChanged();
            }
            QString btrfsMainSize = bytesToGib(btrfsMainRawSize, false);
            QString btrfsMainRemain = bytesToGib(btrfsMainRawRemain, false);

            // Get boot FS space consumption info
            quint64 btrfsBootRawSize = fieldSeek(btrfsBootRawReport, "Device size:", 2).toULongLong();
            quint64 btrfsBootRawRemain = fieldSeek(btrfsBootRawReport, "Free (estimated):", 2).toULongLong();
            quint64 btrfsBootRawUnalloc = fieldSeek(btrfsBootRawReport, "Device unallocated:", 2).toULongLong();
            double btrfsBootUnalloc = qRound((static_cast<double>(btrfsBootRawUnalloc) / static_cast<double>(btrfsBootRawSize)) * 10000.0) / 100.0;
            QString btrfsBootStatus;
            // NOTE: 25% is hardcoded in the backend.
            if (btrfsBootRawUnalloc > m_bootMinUnalloc) {
                btrfsBootStatus = "Good >25%";
                m_bootSpaceLow = false;
                bootSpaceLowChanged();
            } else {
                btrfsBootStatus = "ALERT <25%";
                m_bootSpaceLow = true;
                bootSpaceLowChanged();
            }
            QString btrfsBootSize = bytesToGib(btrfsBootRawSize, false);
            QString btrfsBootRemain = bytesToGib(btrfsBootRawRemain, false);

            // Load all the info into the fs info objects
            m_mainFsInfo->clear();
            m_mainFsInfo->insert(QMap<QString, QString>({
                { "status", btrfsMainStatus },
                { "size", QString(btrfsMainSize) },
                { "remain", QString(btrfsMainRemain) },
                // This value includes rounding because percentage calculated above
                { "unalloc", QString::number(btrfsMainUnalloc, 'f', 1) + "%" }
            }));
            m_bootFsInfo->clear();
            m_bootFsInfo->insert(QMap<QString, QString>({
                { "status", btrfsBootStatus },
                { "size", QString(btrfsBootSize) },
                { "remain", QString(btrfsBootRemain) },
                // This value includes rounding because percentage calculated above
                { "unalloc", QString::number(btrfsBootUnalloc, 'f', 1) + "%" }
            }));

            execEngine->deleteLater();
            m_snapshotSizeInfoPresent = m_calcSize;
            snapshotSizeInfoPresentChanged();

            if (!m_bulkDataChecked) {
                m_bulkDataList.clear();
                for (int i = 0; i < m_bulkLocationMap.count(); i++) {
                    execEngine->execSync("pkexec " + m_rollbackSetExe + " getDirSpace \"" + m_bulkLocationMap.keys()[i] + "\"");
                    qDebug() << execEngine->stdout();
                    QString bulkSizeStr = execEngine->stdout().split('\n')[0];
                    quint64 bulkSizeInt = bulkSizeStr.toULongLong();
                    if (bulkSizeInt > m_bulkSizeThreshold) {
                        m_bulkDataList.append(m_bulkLocationMap.keys()[i] + " (" + m_bulkLocationMap.values()[i] + ")");
                    }
                }
                bulkDataListChanged();
                m_bulkDataChecked = true;
            }

            systemDataLoaded();
            m_updateInProgress = false;
        });
        execEngine->exec(m_pkexecExe + ' ' + m_rollbackSetExe + " getBootMinUnalloc");
    });
    execEngine->exec(m_pkexecExe + ' ' + m_rollbackSetExe + " getMainMinUnalloc");
}

void BackendEngine::enableBulkDataWarning() {
    m_settings.beginGroup("kfocus-rollback");
    m_settings.setValue("bulkDataWarningDisabled", "false");
    m_settings.endGroup();
    bulkDataWarningEnabledChanged();
}

void BackendEngine::disableBulkDataWarning() {
    m_settings.beginGroup("kfocus-rollback");
    m_settings.setValue("bulkDataWarningDisabled", "true");
    m_settings.endGroup();
    bulkDataWarningEnabledChanged();
}

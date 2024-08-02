#include <QDateTime>

#include "backendengine.h"
#include "shellengine.h"

BackendEngine::BackendEngine()
{

}

QString BackendEngine::rollbackBackendExe() {
    return m_rollbackBackendExe;
}

QString BackendEngine::rollbackSetExe() {
    return m_rollbackSetExe;
}

QString BackendEngine::pkexecExe() {
    return m_pkexecExe;
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

bool BackendEngine::isPostRestore() {
    return m_isPostRestore;
}

void BackendEngine::setIsPostRestore(bool val) {
    m_isPostRestore = val;
}

QString BackendEngine::postRestoreName() {
    return m_postRestoreName;
}

void BackendEngine::setPostRestoreName(QString val) {
    m_postRestoreName = val;
}

QString BackendEngine::postRestoreDate() {
    return m_postRestoreDate;
}

void BackendEngine::setPostRestoreDate(QString val) {
    m_postRestoreDate = val;
}

QString BackendEngine::postRestoreReason() {
    return m_postRestoreReason;
}

void BackendEngine::setPostRestoreReason(QString val) {
    m_postRestoreReason = val;
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

QString BackendEngine::bytesToGib(quint64 val) {
    double gibSize = (((static_cast<double>(val) / 1024) / 1024) / 1024);
    gibSize = qRound(gibSize * 100.0) / 100.0;
    QString gibSizeStr = QString::number(gibSize, 'f', 2) + " GiB";
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
    QString metaSnapshotName = snapshotMetadataList.at(0);
    QString metaSnapshotDesc = snapshotMetadataList.at(1);
    QString metaSnapshotPinned = snapshotMetadataList.at(2);
    QString metaSnapshotReason = snapshotMetadataList.at(3);
    QString metaSnapshotSize = snapshotMetadataList.at(4);
    if (snapshotMetadataList.count() < 4 || snapshotMetadataList.at(0) == "Invalid mode specified.") {
        qWarning() << "Snapshot metadata unsupported - kfocus-rollback-backend too old?";
        return;
    }

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
    quint64 snapshotIntSize = metaSnapshotSize.toULongLong();
    QString snapshotSize;
    if (metaSnapshotSize == "") {
        snapshotSize = "";
    } else {
        snapshotSize = bytesToGib(snapshotIntSize);
        for (int i = 0;i < 11 - snapshotSize.count(); i++) {
            snapshotSize.insert(0, ' ');
        }
    }

    // Parse snapshot date (this mangles the snapshotItem string so we have to do it last)
    QDateTime snapshotTs = QDateTime::fromSecsSinceEpoch(snapshotItem.remove(0, 1).toULong());
    QString snapshotDate = snapshotTs.toString(Qt::ISODate).split('T').at(0);

    // Load parsed data into the snapshot list
    m_snapshotList->append(QMap<QString, QString>({
        { "reason", snapshotReason },
        { "name", snapshotName },
        { "description", snapshotDesc },
        { "pinned", snapshotPinned },
        { "stateDir", snapshotStateDir },
        { "id", snapshotId },
        { "size", snapshotSize },
        { "date", snapshotDate }
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
    // Get disk usage info
    ShellEngine *execEngine = new ShellEngine();
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
    if (btrfsMainUnalloc >= 15) {
        btrfsMainStatus = "Good";
        m_mainSpaceLow = false;
        mainSpaceLowChanged();
    } else {
        btrfsMainStatus = "ALERT";
        m_mainSpaceLow = true;
        mainSpaceLowChanged();
    }
    QString btrfsMainSize = bytesToGib(btrfsMainRawSize);
    QString btrfsMainRemain = bytesToGib(btrfsMainRawRemain);

    // Get boot FS space consumption info
    quint64 btrfsBootRawSize = fieldSeek(btrfsBootRawReport, "Device size:", 2).toULongLong();
    quint64 btrfsBootRawRemain = fieldSeek(btrfsBootRawReport, "Free (estimated):", 2).toULongLong();
    quint64 btrfsBootRawUnalloc = fieldSeek(btrfsBootRawReport, "Device unallocated:", 2).toULongLong();
    double btrfsBootUnalloc = qRound((static_cast<double>(btrfsBootRawUnalloc) / static_cast<double>(btrfsBootRawSize)) * 10000.0) / 100.0;
    QString btrfsBootStatus;
    if (btrfsBootUnalloc >= 15) {
        btrfsBootStatus = "Good";
    } else {
        btrfsBootStatus = "ALERT";
    }
    QString btrfsBootSize = bytesToGib(btrfsBootRawSize);
    QString btrfsBootRemain = bytesToGib(btrfsBootRawRemain);

    // Load all the info into the fs info objects
    m_mainFsInfo->clear();
    m_mainFsInfo->insert(QMap<QString, QString>({
        { "status", btrfsMainStatus },
        { "size", QString(btrfsMainSize) },
        { "remain", QString(btrfsMainRemain) },
        { "unalloc", QString::number(btrfsMainUnalloc) + "%" }
    }));
    m_bootFsInfo->clear();
    m_bootFsInfo->insert(QMap<QString, QString>({
        { "status", btrfsBootStatus },
        { "size", QString(btrfsBootSize) },
        { "remain", QString(btrfsBootRemain) },
        { "unalloc", QString::number(btrfsBootUnalloc) + "%" }
    }));

    // NOTE: Callback is connected before execution, this is confusing but it's the only safe way to do this
    connect(execEngine, &ShellEngine::appExited, this, [&, execEngine](){
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
            qCritical() << "BTRFS status neither manual nor auto!";
        }
        execEngine->deleteLater();

        automaticSnapshotsEnabledChanged();
        systemDataLoaded();
        m_updateInProgress = false;
    });
    execEngine->exec(m_pkexecExe + ' ' + m_rollbackSetExe + " getBtrfsStatus");
}

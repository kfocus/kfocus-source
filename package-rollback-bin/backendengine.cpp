#include <QDateTime>

#include "backendengine.h"
#include "shellengine.h"

BackendEngine::BackendEngine()
{

}

QString BackendEngine::rollbackSetExe() {
    return m_rollbackSetExe;
}

void BackendEngine::setRollbackSetExe(QString val) {
    m_rollbackSetExe = val;
    emit rollbackSetExeChanged();
}

QString BackendEngine::pkexecExe() {
    return m_pkexecExe;
    emit pkexecExeChanged();
}

void BackendEngine::setPkexecExe(QString val) {
    m_pkexecExe = val;
}

bool BackendEngine::automaticSnapshotsEnabled()
{
    return m_automaticSnapshotsEnabled;
}

void BackendEngine::setAutomaticSnapshotsEnabled(bool val)
{
    m_automaticSnapshotsEnabled = val;
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

void BackendEngine::refreshSystemData(bool calcSize) {
    /*
     * This is the "kickoff" method. It starts an asynchronous processing loop
     * that does most of the real work.
     */
    m_calcSize = calcSize;
    m_snapshotList->clear();
    ShellEngine *execEngine = new ShellEngine();
    execEngine->execSync(m_rollbackSetExe + " getSnapshotList");
    m_snapshotIdList = execEngine->stdout().split('\n', Qt::SkipEmptyParts);
    if (m_snapshotIdList.count() == 0) {
        loadGlobalInfo();
        return;
    }
    m_snapshotIdIdx = 0;
    connect(execEngine, &ShellEngine::appExited, this, &BackendEngine::onSystemDataReady);
    if (m_calcSize) {
        execEngine->exec(m_rollbackSetExe + " getFullSnapshotMetadata " + m_snapshotIdList.at(0));
    } else {
        execEngine->exec(m_rollbackSetExe + " getBaseSnapshotMetadata " + m_snapshotIdList.at(0));
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

void BackendEngine::onSystemDataReady() {
    /*
     * This function essentially calls itself via a signal handler in order to
     * loop asynchronously (i.e., while the work being done is handled in a
     * worker process, the UI remains responsive rather than hanging.
     */
    ShellEngine *execEngine = ((ShellEngine *)sender());
    execEngine->disconnect(this);
    QString snapshotItem = m_snapshotIdList.at(m_snapshotIdIdx);
    QStringList snapshotMetadataList = execEngine->stdout().split('\n');
    QString metaSnapshotName = snapshotMetadataList.at(0);
    QString metaSnapshotDesc = snapshotMetadataList.at(1);
    QString metaSnapshotPinned = snapshotMetadataList.at(2);
    QString metaSnapshotSize = snapshotMetadataList.at(3);
    if (snapshotMetadataList.count() < 4 || snapshotMetadataList.at(0) == "Invalid mode specified.") {
        qWarning() << "Snapshot metadata unsupported - kfocus-rollback-set too old?";
        return;
    }

    execEngine->execSync(m_rollbackSetExe + " getSnapshotReason " + snapshotItem);
    QString snapshotReason = execEngine->stdout().trimmed();
    QString snapshotStateDir = QString("/btrfs_main/@kfocus-rollback-snapshots/" + snapshotItem);
    QString snapshotName = QString(QByteArray::fromBase64(metaSnapshotName.toUtf8()));
    if (snapshotName.isEmpty()) {
        snapshotName = snapshotReason;
    }
    QString snapshotDesc = QString(QByteArray::fromBase64(metaSnapshotDesc.toUtf8()));
    QString snapshotPinned = metaSnapshotPinned == "y" ? "true" : "false";
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
    QString snapshotId = snapshotItem;
    QDateTime snapshotTs = QDateTime::fromSecsSinceEpoch(snapshotItem.remove(0, 1).toULong());
    QString snapshotDate = snapshotTs.toString(Qt::ISODate).split('T').at(0);
    m_snapshotList->append(QMap<QString, QString>({
        { "date", snapshotDate },
        { "name", snapshotName },
        { "reason", snapshotReason },
        { "description", snapshotDesc },
        { "pinned", snapshotPinned },
        { "size", snapshotSize },
        { "stateDir", snapshotStateDir },
        { "id", snapshotId }
    }));

    m_snapshotIdIdx++;
    if (m_snapshotIdIdx < m_snapshotIdList.count()) {
        connect(execEngine, &ShellEngine::appExited, this, &BackendEngine::onSystemDataReady);
        if (m_calcSize) {
            execEngine->exec(m_rollbackSetExe + " getFullSnapshotMetadata " + m_snapshotIdList.at(m_snapshotIdIdx));
        } else {
            execEngine->exec(m_rollbackSetExe + " getBaseSnapshotMetadata " + m_snapshotIdList.at(m_snapshotIdIdx));
        }
    } else {
        loadGlobalInfo();
        execEngine->deleteLater();
    }
}

void BackendEngine::loadGlobalInfo() {
    // Get disk usage info
    ShellEngine execEngine;
    execEngine.execSync("LC_ALL=C /usr/bin/btrfs filesystem usage '/btrfs_main'");
    QStringList btrfsMainReport = execEngine.stdout().split('\n');
    execEngine.execSync("LC_ALL=C /usr/bin/btrfs filesystem usage '/btrfs_boot'");
    QStringList btrfsBootReport = execEngine.stdout().split('\n');
    execEngine.execSync("LC_ALL=C /usr/bin/btrfs filesystem usage -b '/btrfs_main'");
    QStringList btrfsMainRawReport = execEngine.stdout().split('\n');
    execEngine.execSync("LC_ALL=C /usr/bin/btrfs filesystem usage -b '/btrfs_boot'");
    QStringList btrfsBootRawReport = execEngine.stdout().split('\n');

    btrfsMainReport = btrfsMainReport.replaceInStrings("\t", " ");
    btrfsBootReport = btrfsBootReport.replaceInStrings("\t", " ");
    btrfsMainRawReport = btrfsMainRawReport.replaceInStrings("\t", " ");
    btrfsBootRawReport = btrfsBootRawReport.replaceInStrings("\t", " ");

    quint64 btrfsMainRawSize = fieldSeek(btrfsMainRawReport, "Device size:", 2).toULongLong();
    quint64 btrfsMainRawRemain = fieldSeek(btrfsMainRawReport, "Free (estimated):", 2).toULongLong();
    quint64 btrfsMainRawUnalloc = fieldSeek(btrfsMainRawReport, "Device unallocated:", 2).toULongLong();
    double btrfsMainUnalloc = qRound((static_cast<double>(btrfsMainRawUnalloc) / static_cast<double>(btrfsMainRawSize)) * 10000.0) / 100.0;
    QString btrfsMainStatus = btrfsMainUnalloc >= 15 ? "Good" : "ALERT";
    QString btrfsMainSize = bytesToGib(btrfsMainRawSize);
    QString btrfsMainRemain = bytesToGib(btrfsMainRawRemain);

    quint64 btrfsBootRawSize = fieldSeek(btrfsBootRawReport, "Device size:", 2).toULongLong();
    quint64 btrfsBootRawRemain = fieldSeek(btrfsBootRawReport, "Free (estimated):", 2).toULongLong();
    quint64 btrfsBootRawUnalloc = fieldSeek(btrfsBootRawReport, "Device unallocated:", 2).toULongLong();
    double btrfsBootUnalloc = qRound((static_cast<double>(btrfsBootRawUnalloc) / static_cast<double>(btrfsBootRawSize)) * 10000.0) / 100.0;
    QString btrfsBootStatus = btrfsBootUnalloc >= 15 ? "Good" : "ALERT";
    QString btrfsBootSize = bytesToGib(btrfsBootRawSize);
    QString btrfsBootRemain = bytesToGib(btrfsBootRawRemain);

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

    // Get automatic snapshot state
    execEngine.execSync(m_rollbackSetExe + " getBtrfsStatus");
    QString btrfsStatus = execEngine.stdout().trimmed();
    if (btrfsStatus == "SUPPORTED, MANUAL") {
        m_automaticSnapshotsEnabled = false;
    } else if (btrfsStatus == "SUPPORTED, AUTO") {
        m_automaticSnapshotsEnabled = true;
    } else {
        qCritical() << "BTRFS status neither manual nor auto!";
    }

    emit automaticSnapshotsEnabledChanged();
    emit systemDataLoaded();
}

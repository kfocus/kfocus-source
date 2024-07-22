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

void BackendEngine::refreshSystemData() {
    ShellEngine execEngine;

    // Get snapshot list
    execEngine.execSync(m_rollbackSetExe + " getSnapshotList");
    QStringList snapshotList = execEngine.stdout().split('\n', Qt::SkipEmptyParts);
    m_snapshotList->clear();
    for (QString snapshotItem : snapshotList) {
        execEngine.execSync(m_rollbackSetExe + " getSnapshotMetadata " + snapshotItem);
        QStringList snapshotMetadataList = execEngine.stdout().split('\n');
        if (snapshotMetadataList.count() < 3 || snapshotMetadataList.at(0) == "Invalid mode specified.") {
          qWarning() << "Snapshot metadata unsupported - kfocus-rollback-set too old?";
          return;
        }
        execEngine.execSync(m_rollbackSetExe + " getSnapshotReason " + snapshotItem);
        QString snapshotReason = execEngine.stdout().trimmed();
        QString snapshotStateDir = QString("/btrfs_main/@kfocus-rollback-snapshots/" + snapshotItem);
        QString snapshotName = QString(QByteArray::fromBase64(snapshotMetadataList.at(0).toUtf8()));
        if (snapshotName.isEmpty()) {
            snapshotName = snapshotReason;
        }
        QString snapshotDesc = QString(QByteArray::fromBase64(snapshotMetadataList.at(1).toUtf8()));
        QString snapshotPinned = snapshotMetadataList.at(2) == "y" ? "true" : "false";
        QString snapshotId = snapshotItem;
        QDateTime snapshotTs = QDateTime::fromSecsSinceEpoch(snapshotItem.remove(0, 1).toULong());
        QString snapshotDate = snapshotTs.toString(Qt::ISODate).split('T').at(0);
        m_snapshotList->append(QMap<QString, QString>({
            { "date", snapshotDate },
            { "name", snapshotName },
            { "reason", snapshotReason },
            { "description", snapshotDesc },
            { "pinned", snapshotPinned },
            { "stateDir", snapshotStateDir },
            { "id", snapshotId }
        }));
    }

    // Get disk usage info
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

    QString btrfsMainSize = fieldSeek(btrfsMainReport, "Device size:", 2);
    QString btrfsMainRemain = fieldSeek(btrfsMainReport, "Free (estimated):", 2);
    quint64 btrfsMainRawSize = fieldSeek(btrfsMainRawReport, "Device size:", 2).toULongLong();
    quint64 btrfsMainRawUnalloc = fieldSeek(btrfsMainRawReport, "Device unallocated:", 2).toULongLong();
    int btrfsMainUnalloc = qRound((static_cast<double>(btrfsMainRawUnalloc) / static_cast<double>(btrfsMainRawSize)) * 100);
    QString btrfsMainStatus = btrfsMainUnalloc >= 15 ? "Good" : "ALERT";

    QString btrfsBootSize = fieldSeek(btrfsBootReport, "Device size:", 2);
    QString btrfsBootRemain = fieldSeek(btrfsBootReport, "Free (estimated):", 2);
    quint64 btrfsBootRawSize = fieldSeek(btrfsBootRawReport, "Device size:", 2).toULongLong();
    quint64 btrfsBootRawUnalloc = fieldSeek(btrfsBootRawReport, "Device unallocated:", 2).toULongLong();
    int btrfsBootUnalloc = qRound((static_cast<double>(btrfsBootRawUnalloc) / static_cast<double>(btrfsBootRawSize)) * 100);
    QString btrfsBootStatus = btrfsBootUnalloc >= 15 ? "Good" : "ALERT";

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

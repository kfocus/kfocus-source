#ifndef KDIALOGLAUNCHER_H
#define KDIALOGLAUNCHER_H

#include <QObject>
#include <QDBusAbstractAdaptor>
#include <QDBusVariant>
#include <QMap>

//#include "ProcessContainer.h"

class QProcess;

class KDialogLauncher : public QDBusAbstractAdaptor {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.kfocus.FocusRxDispatch.launcher")

    enum KDialogType {
        // Generic
        Info,
        Warning,
        Error,
        // Rollback-specific
        RollbackLowMainSpace,
        RollbackLowBootSpace
    };

public:
    explicit KDialogLauncher(QObject *obj) : QDBusAbstractAdaptor(obj) {}

public slots:
    void info(const QString &msg);
    void warning(const QString &msg);
    void error(const QString &msg);
    void rollbackLowMainSpace(const QString &msg);
    void rollbackLowBootSpace(const QString &msg);

private slots:
    void cleanupDialog();
    void cleanupSubproc();

private:
    QList<QProcess *> m_processList;
    QList<KDialogType> m_typeList;
    void launchDialog(const KDialogType &type, const QString &msg);
};
#endif //KDIALOGLAUNCHER_H

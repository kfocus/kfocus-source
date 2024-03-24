#ifndef KDIALOGLAUNCHER_H
#define KDIALOGLAUNCHER_H

#include <QObject>
#include <QDBusAbstractAdaptor>
#include <QDBusVariant>

class KDialogLauncher : public QDBusAbstractAdaptor {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.kfocus.KDialogLauncher.launcher")

    enum KDialogType {
        Info,
        Warning,
        Error
    };

public:
    explicit KDialogLauncher(QObject *obj) : QDBusAbstractAdaptor(obj) {}

public slots:
    void info(const QString &msg);
    void warning(const QString &msg);
    void error(const QString &msg);

private slots:
    void cleanupDialog();

private:
    void launchDialog(const KDialogType &type, const QString &msg);
};
#endif //KDIALOGLAUNCHER_H

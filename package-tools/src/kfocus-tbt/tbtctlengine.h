#ifndef TBTCTLENGINE_H
#define TBTCTLENGINE_H

#include "tbtqueryresult.h"

#include <QObject>
#include <QString>
#include <QList>

class TbtCtlEngine : public QObject
{
    Q_OBJECT
public:
    explicit TbtCtlEngine(QObject *parent = nullptr);
    void tbtSetState(bool enabled, bool persistEnabled);
    TbtQueryResult *tbtQuery();

signals:
    void stateSetSuccess();
    void stateSetFailure();

private:
    static QString m_tbtSetExe;
};

#endif // TBTCTLENGINE_H

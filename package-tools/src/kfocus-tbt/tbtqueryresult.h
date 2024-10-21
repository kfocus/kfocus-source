#ifndef TBTQUERYRESULT_H
#define TBTQUERYRESULT_H

#include <QObject>

class TbtQueryResult : public QObject
{
    Q_OBJECT
public:
    explicit TbtQueryResult(QObject *parent = nullptr);

    bool isEnabled();
    void setIsEnabled(bool val);
    bool isPersistEnabled();
    void setIsPersistEnabled(bool val);
    QString deviceModelCode();
    void setDeviceModelCode(QString val);

private:
    bool m_isEnabled;
    bool m_isPersistEnabled;
    QString m_deviceModelCode;
};

#endif // TBTQUERYRESULT_H

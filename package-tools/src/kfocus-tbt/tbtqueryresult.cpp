#include "tbtqueryresult.h"

TbtQueryResult::TbtQueryResult(QObject *parent)
    : QObject{parent}
{}

bool TbtQueryResult::isEnabled() { return m_isEnabled; }
void TbtQueryResult::setIsEnabled(bool val) { m_isEnabled = val; }
bool TbtQueryResult::isPersistEnabled() { return m_isPersistEnabled; }
void TbtQueryResult::setIsPersistEnabled(bool val) { m_isPersistEnabled = val; }
QString TbtQueryResult::deviceModelCode() { return m_deviceModelCode; }
void TbtQueryResult::setDeviceModelCode(QString val) { m_deviceModelCode = val; }

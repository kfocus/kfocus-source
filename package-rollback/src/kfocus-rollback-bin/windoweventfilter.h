#ifndef WINDOWEVENTFILTER_H
#define WINDOWEVENTFILTER_H

#include "backendengine.h"

#include <QObject>

class WindowEventFilter : public QObject
{
    Q_OBJECT
public:
    explicit WindowEventFilter(QObject *parent = nullptr);
    virtual ~WindowEventFilter();

protected:
    bool eventFilter(QObject *obj, QEvent *event) override;

private:
    BackendEngine m_backendEngine;
};

#endif // WINDOWEVENTFILTER_H

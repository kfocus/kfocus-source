#include <QCloseEvent>
#include <QDebug>

#include "windoweventfilter.h"

WindowEventFilter::WindowEventFilter(QObject *parent)
    : QObject{parent}
{}

WindowEventFilter::~WindowEventFilter() {}

bool WindowEventFilter::eventFilter(__attribute__((unused)) QObject *obj, QEvent *event) {
    if (event->type() == QEvent::Close) {
        if (m_backendEngine.inhibitClose()) {
            return true;
        }
    }
    return false;
}

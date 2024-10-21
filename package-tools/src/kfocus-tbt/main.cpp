#include "tbtctldialog.h"
#include "tbtctlengine.h"

#include <QApplication>

QString TbtCtlEngine::m_tbtSetExe = "/usr/lib/kfocus/bin/kfocus-tbt-set";

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    TbtCtlDialog w;
    w.show();
    return a.exec();
}

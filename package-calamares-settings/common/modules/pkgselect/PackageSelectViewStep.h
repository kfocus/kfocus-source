#ifndef PACKAGESELECTVIEWSTEP_H
#define PACKAGESELECTVIEWSTEP_H

#include <QFile>
#include <QTextStream>

#include "DllMacro.h"
#include "utils/PluginFactory.h"
#include "viewpages/ViewStep.h"

#include "ui_pkgselect.h"

namespace Ui {
    class pkgselect;
}

class PLUGINDLLEXPORT PackageSelectViewStep : public Calamares::ViewStep
{
    Q_OBJECT

public:
    explicit PackageSelectViewStep( QObject* parent = nullptr );
    ~PackageSelectViewStep() override;

    QString prettyName() const override;
    QWidget* widget() override;
    Calamares::JobList jobs() const override;

    bool isNextEnabled() const override;
    bool isBackEnabled() const override;
    bool isAtBeginning() const override;
    bool isAtEnd() const override;

    void onActivate() override;
    void onLeave() override;

    QVariantMap packageSelections() const { return m_packageSelections; }
    void updatePackageSelections(bool checked);

signals:
    void packageSelectionsChanged();

private:
    QVariantMap m_packageSelections;
    Ui::pkgselect *ui;
    QWidget* m_widget;
    bool exists_and_true(const QString& key) const;
};

CALAMARES_PLUGIN_FACTORY_DECLARATION( PackageSelectViewStepFactory )

#endif

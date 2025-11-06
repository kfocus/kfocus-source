#ifndef INTEGRITYVIEWSTEP_H
#define INTEGRITYVIEWSTEP_H

#include "DllMacro.h"
#include "utils/PluginFactory.h"
#include "viewpages/ViewStep.h"

#include "ui_integrity.h"

namespace Ui {
  class integrity;
}

class QTimer;

class PLUGINDLLEXPORT IntegrityViewStep : public Calamares::ViewStep
{
  Q_OBJECT

public:
  enum IntegrityStatus {
    GoodIntegrity,
    BadIntegrity,
    CheckingIntegrity,
    IntegrityCheckError,
  };

  explicit IntegrityViewStep(QObject* parent = nullptr);
  ~IntegrityViewStep() override;
  QString prettyName() const override;
  QWidget* widget() override;
  Calamares::JobList jobs() const override;

  bool isNextEnabled() const override;
  bool isBackEnabled() const override;
  bool isAtBeginning() const override;
  bool isAtEnd() const override;

  void onActivate() override;
  void onLeave() override;

private:
  Ui::integrity *ui;
  QWidget* m_widget;
  bool m_checkDone;
  QTimer *m_checkTimer;
  void pollIntegrity();
  IntegrityStatus checkIntegrityFile() const;
};

CALAMARES_PLUGIN_FACTORY_DECLARATION(IntegrityViewStepFactory)

#endif

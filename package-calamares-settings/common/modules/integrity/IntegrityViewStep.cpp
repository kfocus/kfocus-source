#include "IntegrityViewStep.h"

#include <QFile>
#include <QIODevice>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <QJsonValue>
#include <QTimer>

IntegrityViewStep::IntegrityViewStep(QObject* parent)
  : Calamares::ViewStep(parent),
  m_checkDone(false),
  m_checkTimer(NULL),
  ui(new Ui::integrity)
{
  m_widget = new QWidget();
  ui->setupUi(m_widget);
}

IntegrityViewStep::~IntegrityViewStep()
{
  delete ui;
  delete m_widget;
}

QString
IntegrityViewStep::prettyName() const
{
  return tr("Integrity");
}

QWidget*
IntegrityViewStep::widget()
{
  return m_widget;
}

Calamares::JobList
IntegrityViewStep::jobs() const
{
  return Calamares::JobList();
}

bool
IntegrityViewStep::isNextEnabled() const
{
  return m_checkDone;
}

bool
IntegrityViewStep::isBackEnabled() const
{
  return true;
}

bool
IntegrityViewStep::isAtBeginning() const
{
  return true;
}

bool
IntegrityViewStep::isAtEnd() const
{
  return true;
}

void
IntegrityViewStep::onActivate()
{
  pollIntegrity();

  if (m_checkTimer == NULL) {
    m_checkTimer = new QTimer();
    connect(m_checkTimer, &QTimer::timeout, this, &IntegrityViewStep::pollIntegrity);
  }
  m_checkTimer->start(1000);
}

void
IntegrityViewStep::onLeave()
{
  if (m_checkTimer != NULL) {
    m_checkTimer->stop();
  }
}

void
IntegrityViewStep::pollIntegrity()
{
  IntegrityStatus status = checkIntegrityFile();
  switch(status) {
  case GoodIntegrity:
    ui->titleLabel->setText("Integrity check passed.");
    ui->descLabel->setText("The integrity check passed. You may proceed with the installation.");
    ui->notifProgressBar->setMaximum(1);
    ui->notifProgressBar->setValue(1);
    ui->statusLabel->setText("✅");
    m_checkDone = true;
    emit nextStatusChanged(this->isNextEnabled());
    break;
  case BadIntegrity:
    ui->titleLabel->setText("Integrity check failed!");
    ui->descLabel->setText("The integrity check failed! The installation media is most likely corrupt. Please see <a href=\"https://kfocus.org/wf/iso-verify.html\">https://kfocus.org/wf/iso-verify.html</a> for instructions on verifying your download.");
    ui->notifProgressBar->setMaximum(1);
    ui->notifProgressBar->setValue(1);
    ui->statusLabel->setText("⚠️");
    break;
  case CheckingIntegrity:
    ui->titleLabel->setText("Checking installer integrity...");
    ui->descLabel->setText("This process ensures that the installation media is not corrupt. This usually only takes a few minutes.");
    ui->notifProgressBar->setMaximum(0);
    ui->notifProgressBar->setValue(0);
    ui->statusLabel->setText("⚙️");
    break;
  case IntegrityCheckError:
    ui->titleLabel->setText("Error!");
    ui->descLabel->setText("Something went wrong while checking integrity! The installation media is most likely corrupt. Please see <a href=\"https://kfocus.org/wf/iso-verify.html\">https://kfocus.org/wf/iso-verify.html</a> for instructions on verifying your download.");
    ui->notifProgressBar->setMaximum(1);
    ui->notifProgressBar->setValue(1);
    ui->statusLabel->setText("💥");
    break;
  }
}

IntegrityViewStep::IntegrityStatus
IntegrityViewStep::checkIntegrityFile() const
{
  QFile casperFile(QStringLiteral("/run/casper-md5check.json"));

  if (!casperFile.exists()) {
    return CheckingIntegrity;
  }
  if (!casperFile.open(QIODevice::ReadOnly)) {
    return IntegrityCheckError;
  }

  QByteArray fileContents = casperFile.readAll();
  if (fileContents.size() == 0) {
    // Maybe casper is just still writing the file?
    return CheckingIntegrity;
  }
  casperFile.close();

  QJsonParseError jsonErr;
  jsonErr.error = QJsonParseError::NoError;
  QJsonDocument jsonDoc = QJsonDocument::fromJson(fileContents, &jsonErr);
  if (jsonErr.error != QJsonParseError::NoError) {
    // Maybe casper is just still writing the file?
    return CheckingIntegrity;
  }
  if (!jsonDoc.isObject()) {
    return IntegrityCheckError;
  }
  QJsonObject jsonObj = jsonDoc.object();
  if (!jsonObj.contains(QStringLiteral("result"))) {
    return IntegrityCheckError;
  }
  QJsonValue jsonVal = jsonObj.value(QStringLiteral("result"));

  if (!jsonVal.isString()) {
    return IntegrityCheckError;
  }
  if (jsonVal.toString() != QStringLiteral("pass")) {
    return BadIntegrity;
  }

  return GoodIntegrity;
}

CALAMARES_PLUGIN_FACTORY_DEFINITION(IntegrityViewStepFactory, registerPlugin<IntegrityViewStep>();)

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
    ui->titleLabel->setText("Integrity check succeeded");
    ui->descLabel->setText("The integrity check succeeded. Press Next to proceed.");
    ui->notifProgressBar->setMaximum(1);
    ui->notifProgressBar->setValue(1);
    ui->statusLabel->setText("✅");
    m_checkDone = true;
    emit nextStatusChanged(this->isNextEnabled());
    break;
  case BadIntegrity:
    ui->titleLabel->setText("Integrity check failed!");
    ui->descLabel->setText("The integrity check failed! Please cancel this install, verify your download (<a href=\"https://kfocus.org/wf/iso-verify.html\">https://kfocus.org/wf/iso-verify.html</a>), and recreate the installation media.");
    ui->notifProgressBar->setMaximum(1);
    ui->notifProgressBar->setValue(1);
    ui->statusLabel->setText("⚠️");
    break;
  case CheckingIntegrity:
    ui->titleLabel->setText("Checking installation media integrity");
    ui->descLabel->setText("This process is currently scanning the installation media. This can take up to 2 minutes for a USB 3.0 drive, 3-5 minutes for a USB 2.0 drive, and up to 20 minutes for a DVD. If the process takes longer than expected, you may want to power down and try again. If this step continues to stall, cancel this install, verify your download (<a href=\"https://kfocus.org/wf/iso-verify.html\">https://kfocus.org/wf/iso-verify.html</a>), and recreate the installation media.");
    ui->notifProgressBar->setMaximum(0);
    ui->notifProgressBar->setValue(0);
    ui->statusLabel->setText("⚙️");
    break;
  case IntegrityCheckError:
    ui->titleLabel->setText("Error!");
    ui->descLabel->setText("An unhandled error occurred while checking integrity! Please cancel this install, verify your download (<a href=\"https://kfocus.org/wf/iso-verify.html\">https://kfocus.org/wf/iso-verify.html</a>), and recreate the installation media.");
    ui->notifProgressBar->setMaximum(1);
    ui->notifProgressBar->setValue(1);
    // Could also use 💥 to indicate that the integrity check "crashed"
    ui->statusLabel->setText("⚠️");
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
  casperFile.close();

  // casper-md5check creates the file immediately and partially writes it.
  // In practice, the contents don't appear until the file is closed and
  // buffering is flushed. However, some system event could cause a
  // partial write.
  if (fileContents.size() == 0) {
    return CheckingIntegrity;
  }

  QJsonParseError jsonErr;
  jsonErr.error = QJsonParseError::NoError;
  QJsonDocument jsonDoc = QJsonDocument::fromJson(fileContents, &jsonErr);
  if (jsonErr.error != QJsonParseError::NoError) {
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

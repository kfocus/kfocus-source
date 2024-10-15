#include "tbtctldialog.h"
#include "tbtctlengine.h"
#include "./ui_tbtctldialog.h"

#include <QPalette>
#include <QMessageBox>
#include <QCursor>

TbtCtlDialog::TbtCtlDialog(QWidget *parent)
    : QDialog(parent)
    , ui(new Ui::TbtCtlDialog)
{
    ui->setupUi(this);
    m_engine = new TbtCtlEngine();
    m_tbtQueryResult = m_engine->tbtQuery();
    ui->tbtEnabledCheckBox->setChecked(m_tbtQueryResult->isEnabled());
    ui->tbtPersistEnabledCheckBox->setChecked (m_tbtQueryResult->isPersistEnabled());
    if (m_tbtQueryResult->deviceModelCode() == "m2g5p1") {
        ui->instructionsLabel->setText(
            QStringLiteral("<p>This model uses the Barlow Ridge Thunderbolt 5 chip. As of ")
            + QStringLiteral("late 2024, support for this chip is still evolving, and ")
            + QStringLiteral("displays attached via USB-C can time-out and go ")
            + QStringLiteral("blank after 15 seconds. Disabling Thunderbolt can fix ")
            + QStringLiteral("this while retaining almost all other capabilities.<br></p>"));
    } else {
        ui->instructionsLabel->setText(
            QStringLiteral("<p>For most systems and situations, you want Thunderbolt ")
            + QStringLiteral("running and enabled. However, there are some situations where ")
            + QStringLiteral("it is useful to disable Thunderbolt, either temporarily or ")
            + QStringLiteral("permanently.<br></p>"));
    }

    m_checkboxNormalPalette = ui->tbtEnabledCheckBox->palette();
    m_checkboxChangedPalette = m_checkboxNormalPalette;
    m_checkboxChangedPalette.setColor(QPalette::WindowText, QColor(0xf7, 0x94, 0x1d)); // Orange color used by KFocus

    ui->tbtLogoLabel->setText("");
    ui->tbtLogoLabel->setPixmap(QIcon::fromTheme("kfocus-tbt-symbolic").pixmap(QSize(64,64)));

    setOkButtonState();

    connect(ui->tbtEnabledCheckBox, &QCheckBox::stateChanged, this, &TbtCtlDialog::onTbtEnabledCheckboxChanged);
    connect(ui->tbtPersistEnabledCheckBox, &QCheckBox::stateChanged, this, &TbtCtlDialog::onTbtPersistEnabledCheckboxChanged);
    connect(ui->enableInfoButton, &QPushButton::clicked, this, &TbtCtlDialog::onEnableInfoButtonClicked);
    connect(ui->enablePersistInfoButton, &QPushButton::clicked, this, &TbtCtlDialog::onEnablePersistInfoButtonClicked);
    connect(ui->okButton, &QPushButton::clicked, this, &TbtCtlDialog::onOkClicked);
    connect(ui->cancelButton, &QPushButton::clicked, this, &TbtCtlDialog::onCancelClicked);
    connect(m_engine, &TbtCtlEngine::stateSetSuccess, this, &TbtCtlDialog::onStateSetSuccess);
    connect(m_engine, &TbtCtlEngine::stateSetFailure, this, &TbtCtlDialog::onStateSetFailure);
}

TbtCtlDialog::~TbtCtlDialog()
{
    delete ui;
}

void TbtCtlDialog::setOkButtonState() {
    if (ui->tbtEnabledCheckBox->isChecked() == m_tbtQueryResult->isEnabled()
        && ui->tbtPersistEnabledCheckBox->isChecked() == m_tbtQueryResult->isPersistEnabled()) {
        ui->okButton->setEnabled(false);
    } else {
        ui->okButton->setEnabled(true);
    }
}

void TbtCtlDialog::onTbtEnabledCheckboxChanged() {
    if (ui->tbtEnabledCheckBox->isChecked() != m_tbtQueryResult->isEnabled()) {
        ui->tbtEnabledCheckBox->setPalette(m_checkboxChangedPalette);
    } else {
        ui->tbtEnabledCheckBox->setPalette(m_checkboxNormalPalette);
    }
    setOkButtonState();
}

void TbtCtlDialog::onTbtPersistEnabledCheckboxChanged() {
    if (ui->tbtPersistEnabledCheckBox->isChecked() != m_tbtQueryResult->isPersistEnabled()) {
        ui->tbtPersistEnabledCheckBox->setPalette(m_checkboxChangedPalette);
    } else {
        ui->tbtPersistEnabledCheckBox->setPalette(m_checkboxNormalPalette);
    }
    setOkButtonState();
}

void TbtCtlDialog::onEnableInfoButtonClicked() {
    QMessageBox msgBox;
    msgBox.setIcon(QMessageBox::Information);
    msgBox.setText("Check this to load the Thunderbolt driver now.<br>Uncheck to unload the driver now.");
    msgBox.setWindowTitle("KFocus Thunderbolt Control");
    msgBox.exec();
}

void TbtCtlDialog::onEnablePersistInfoButtonClicked() {
    QMessageBox msgBox;
    msgBox.setIcon(QMessageBox::Information);
    msgBox.setText("Check this to load the Thunderbolt driver at boot.<br>Uncheck to prevent the driver from loading at boot.");
    msgBox.setWindowTitle("KFocus Thunderbolt Control");
    msgBox.exec();
}

void TbtCtlDialog::onOkClicked() {
    QCursor busyCursor;
    busyCursor.setShape(Qt::WaitCursor);
    QApplication::setOverrideCursor(busyCursor);
    ui->tbtEnabledCheckBox->setEnabled(false);
    ui->tbtPersistEnabledCheckBox->setEnabled(false);
    ui->okButton->setEnabled(false);
    ui->cancelButton->setEnabled(false);
    ui->enableInfoButton->setEnabled(false);
    ui->enablePersistInfoButton->setEnabled(false);
    m_engine->tbtSetState(ui->tbtEnabledCheckBox->isChecked(), ui->tbtPersistEnabledCheckBox->isChecked());
}

void TbtCtlDialog::onCancelClicked() {
    QApplication::quit();
}

void TbtCtlDialog::onStateSetSuccess() {
    QCursor normalCursor;
    normalCursor.setShape(Qt::ArrowCursor);
    QApplication::setOverrideCursor(normalCursor);
    QMessageBox msgBox;
    msgBox.setIcon(QMessageBox::Information);
    msgBox.setText("The settings have been successfully applied.");
    msgBox.setWindowTitle("KFocus Thunderbolt Control");
    msgBox.exec();
    QApplication::exit();
}

void TbtCtlDialog::onStateSetFailure() {
    QCursor normalCursor;
    normalCursor.setShape(Qt::ArrowCursor);
    QApplication::setOverrideCursor(normalCursor);
    QMessageBox msgBox;
    msgBox.setIcon(QMessageBox::Information);
    msgBox.setText("Something went wrong while trying to apply the settings! Please contact technical support.");
    msgBox.setWindowTitle("KFocus Thunderbolt Control");
    msgBox.exec();
    QApplication::exit();
}

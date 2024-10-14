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
    QList<bool> tbtQueryResult = m_engine->tbtQuery();
    m_tbtEnabled = tbtQueryResult[0];
    m_tbtPersistEnabled = tbtQueryResult[1];
    ui->tbtEnabledCheckBox->setChecked(m_tbtEnabled);
    ui->tbtPersistEnabledCheckBox->setChecked (m_tbtPersistEnabled);
    m_checkboxNormalPalette = ui->tbtEnabledCheckBox->palette();
    m_checkboxChangedPalette = m_checkboxNormalPalette;
    m_checkboxChangedPalette.setColor(QPalette::WindowText, QColor(0xf7, 0x94, 0x1d)); // Orange color used by KFocus

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
    if (ui->tbtEnabledCheckBox->isChecked() == m_tbtEnabled
        && ui->tbtPersistEnabledCheckBox->isChecked() == m_tbtPersistEnabled) {
        ui->okButton->setEnabled(false);
    } else {
        ui->okButton->setEnabled(true);
    }
}

void TbtCtlDialog::onTbtEnabledCheckboxChanged() {
    if (ui->tbtEnabledCheckBox->isChecked() != m_tbtEnabled) {
        ui->tbtEnabledCheckBox->setPalette(m_checkboxChangedPalette);
    } else {
        ui->tbtEnabledCheckBox->setPalette(m_checkboxNormalPalette);
    }
    setOkButtonState();
}

void TbtCtlDialog::onTbtPersistEnabledCheckboxChanged() {
    if (ui->tbtPersistEnabledCheckBox->isChecked() != m_tbtPersistEnabled) {
        ui->tbtPersistEnabledCheckBox->setPalette(m_checkboxChangedPalette);
    } else {
        ui->tbtPersistEnabledCheckBox->setPalette(m_checkboxNormalPalette);
    }
    setOkButtonState();
}

void TbtCtlDialog::onEnableInfoButtonClicked() {
    QMessageBox msgBox;
    msgBox.setIcon(QMessageBox::Information);
    msgBox.setText("Enables or disables Thunderbolt in this session.");
    msgBox.setWindowTitle("KFocus Thunderbolt Control");
    msgBox.exec();
}

void TbtCtlDialog::onEnablePersistInfoButtonClicked() {
    QMessageBox msgBox;
    msgBox.setIcon(QMessageBox::Information);
    msgBox.setText("Enables or disables Thunderbolt for the next time the system is booted.");
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

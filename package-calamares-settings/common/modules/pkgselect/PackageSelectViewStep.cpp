#include "PackageSelectViewStep.h"
#include "JobQueue.h"
#include "GlobalStorage.h"
#include "network/Manager.h"

#include <QVariantMap>

PackageSelectViewStep::PackageSelectViewStep( QObject* parent )
    : Calamares::ViewStep( parent ),
      m_packageSelections(QVariantMap()),
      ui(new Ui::pkgselect)
{
    m_widget = new QWidget();
    ui->setupUi(m_widget);
}

PackageSelectViewStep::~PackageSelectViewStep()
{
    delete ui;
    delete m_widget;
}

QString
PackageSelectViewStep::prettyName() const
{
    return tr( "Customize" );
}

bool PackageSelectViewStep::exists_and_true(const QString& key) const
{
    return m_packageSelections.contains(key) && m_packageSelections[key].toBool() == true;
}

QWidget* PackageSelectViewStep::widget()
{   
    return m_widget;
}

Calamares::JobList PackageSelectViewStep::jobs() const
{
    return Calamares::JobList();
}

bool PackageSelectViewStep::isNextEnabled() const
{
    return true;
}

bool PackageSelectViewStep::isBackEnabled() const
{
    return true;
}

bool PackageSelectViewStep::isAtBeginning() const
{
    return true;
}

bool PackageSelectViewStep::isAtEnd() const
{
    return true;
}

void PackageSelectViewStep::onActivate()
{
    // Connect the Minimal Installation radio button
    connect(ui->minimal_button, &QRadioButton::toggled, this, [this](bool checked) {
        Calamares::Network::Manager network;
        if (checked && network.hasInternet()) {
            ui->extraparty_scroll->setVisible(false);
            ui->extraparty_text->setVisible(false);
            ui->mandatory_warning_label->setVisible(false);

            ui->element_button->setChecked(false);
            ui->thunderbird_button->setChecked(false);
            ui->virtmanager_button->setChecked(false);
            ui->krita_button->setChecked(false);

            ui->element_button->setEnabled(false);
            ui->thunderbird_button->setEnabled(false);
            ui->virtmanager_button->setEnabled(false);
            ui->krita_button->setEnabled(false);
        }
    });

    // Connect the Normal Installation radio button
    connect(ui->normal_button, &QRadioButton::toggled, this, [this](bool checked) {
        Calamares::Network::Manager network;
        if (checked && network.hasInternet()) {
            ui->extraparty_scroll->setVisible(true);
            ui->extraparty_text->setVisible(true);
            ui->mandatory_warning_label->setVisible(true);

            ui->element_button->setChecked(false);
            ui->thunderbird_button->setChecked(false);
            ui->virtmanager_button->setChecked(false);
            ui->krita_button->setChecked(false);

            ui->element_button->setEnabled(true);
            ui->thunderbird_button->setEnabled(true);
            ui->virtmanager_button->setEnabled(true);
            ui->krita_button->setEnabled(true);
        }
    });

    // Connect the Full Installation radio button
    connect(ui->full_button, &QRadioButton::toggled, this, [this](bool checked) {
        Calamares::Network::Manager network;
        if (checked && network.hasInternet()) {
            ui->extraparty_scroll->setVisible(true);
            ui->extraparty_text->setVisible(true);
            ui->mandatory_warning_label->setVisible(true);

            ui->element_button->setChecked(true);
            ui->thunderbird_button->setChecked(true);
            ui->virtmanager_button->setChecked(true);
            ui->krita_button->setChecked(true);

            ui->element_button->setEnabled(false);
            ui->thunderbird_button->setEnabled(false);
            ui->virtmanager_button->setEnabled(false);
            ui->krita_button->setEnabled(false);
        }
    });

    // Disable many bits of functionality if network is not enabled
    Calamares::Network::Manager network;
    if (!network.hasInternet()) {
        ui->full_button->setVisible(false);
        ui->full_text->setVisible(false);

        ui->left_spacer->changeSize(20, 20, QSizePolicy::Fixed, QSizePolicy::Fixed);
        ui->right_spacer->changeSize(0, 0, QSizePolicy::Fixed, QSizePolicy::Fixed);

        ui->additional_label->setVisible(false);
        ui->updates_button->setVisible(false);
        ui->updates_text->setVisible(false);
        ui->party_button->setVisible(false);
        ui->party_text->setVisible(false);

        ui->extraparty_scroll->setVisible(false);
        ui->extraparty_text->setVisible(false);
        ui->mandatory_warning_label->setVisible(false);

        ui->element_button->setChecked(false);
        ui->thunderbird_button->setChecked(false);
        ui->virtmanager_button->setChecked(false);
        ui->krita_button->setChecked(false);

        ui->element_button->setEnabled(false);
        ui->thunderbird_button->setEnabled(false);
        ui->virtmanager_button->setEnabled(false);
        ui->krita_button->setEnabled(false);
    }

    // Connect the storage items
    /// Full/Normal/Minimal
    connect(ui->minimal_button, &QRadioButton::toggled, this, &PackageSelectViewStep::updatePackageSelections);
    connect(ui->normal_button, &QRadioButton::toggled, this, &PackageSelectViewStep::updatePackageSelections);
    connect(ui->full_button, &QRadioButton::toggled, this, &PackageSelectViewStep::updatePackageSelections);
    /// Additional Options
    connect(ui->updates_button, &QRadioButton::toggled, this, &PackageSelectViewStep::updatePackageSelections);
    connect(ui->party_button, &QRadioButton::toggled, this, &PackageSelectViewStep::updatePackageSelections);
    /// Third-Party Apps
    connect(ui->element_button, &QCheckBox::toggled, this, &PackageSelectViewStep::updatePackageSelections);
    connect(ui->thunderbird_button, &QCheckBox::toggled, this, &PackageSelectViewStep::updatePackageSelections);
    connect(ui->virtmanager_button, &QCheckBox::toggled, this, &PackageSelectViewStep::updatePackageSelections);
    connect(ui->krita_button, &QCheckBox::toggled, this, &PackageSelectViewStep::updatePackageSelections);
}

void
PackageSelectViewStep::onLeave()
{
    Calamares::GlobalStorage* gs = Calamares::JobQueue::instance()->globalStorage();
    QVariantMap config;
    for (auto i = m_packageSelections.begin(); i != m_packageSelections.end(); ++i) {
        if (exists_and_true(i.key())) {
            config.insert(i.key(), i.value());
	    }
    }
    gs->insert("packages", config);
}

void PackageSelectViewStep::updatePackageSelections(bool checked) {
    QObject* sender_obj = sender();
    if (!sender_obj) return;

    QString key = sender_obj->objectName();

    // snake_case -> camelCase
    QStringList parts = key.split("_", Qt::SkipEmptyParts);
    for (int i = 1; i < parts.size(); ++i) {
        parts[i][0] = parts[i][0].toUpper();
    }
    QString camelCaseKey = parts.join("");

    m_packageSelections[camelCaseKey] = checked;
}

CALAMARES_PLUGIN_FACTORY_DEFINITION( PackageSelectViewStepFactory, registerPlugin< PackageSelectViewStep >(); )

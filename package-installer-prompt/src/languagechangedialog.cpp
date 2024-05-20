#include "languagechangedialog.h"
#include "ui_languagechangedialog.h"

#include <QCloseEvent>

LanguageChangeDialog::LanguageChangeDialog(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::LanguageChangeDialog)
{
    ui->setupUi(this);
}

LanguageChangeDialog::~LanguageChangeDialog()
{
    delete ui;
}

void LanguageChangeDialog::closeEvent(QCloseEvent *event)
{
    event->ignore();
}

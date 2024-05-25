/*
 * Copyright (C) 2022-2023 Lubuntu Developers <lubuntu-devel@lists.ubuntu.com>
 * Authored by: Simon Quigley <tsimonq2@lubuntu.me>
 *              Aaron Rainbolt <arraybolt3@lubuntu.me>
 *
 * This is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * This is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 */

#include "installerprompt.h"
#include "backgroundscreen.h"
#include <QApplication>
#include <QScreen>
#include <QTranslator>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    QTranslator translator;
    const QStringList uiLanguages = QLocale::system().uiLanguages();
    for (const QString &locale : uiLanguages) {
        const QString baseName = QLocale(locale).name();
        if (translator.load(":/i18n/" + baseName)) {
            app.installTranslator(&translator);
            break;
        }
    }

    InstallerPrompt* w;
    QList<BackgroundScreen *> bss;

    // Iterate through all available screens
    for (QScreen *screen : QApplication::screens()) {
        if (screen == QApplication::primaryScreen()) {
            w = new InstallerPrompt();
            w->setGeometry(screen->geometry());
            w->activateBackground();
            w->showFullScreen();
            continue;
        }
        BackgroundScreen *backscreen = new BackgroundScreen();
        backscreen->setGeometry(screen->geometry());
        backscreen->activateBackground();
        backscreen->showFullScreen();
        bss.append(backscreen);
    }

    return app.exec();
}

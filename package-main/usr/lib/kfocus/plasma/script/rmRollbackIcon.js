// Copyright: 2024 MindShare Inc., 2024 KDE Contributors
// License: GPLv3
// Copied and adapted for the Kubuntu Focus from the example shown at
// https://develop.kde.org/docs/plasma/scripting/

panelIds.forEach((panel) => {
    panel = panelById(panel);
    if (!panel) {
        return;
    }
    panel.widgetIds.forEach((appletWidget) => {
        appletWidget = panel.widgetById(appletWidget);
        if (appletWidget.type === "org.kde.plasma.icon") {
            var lpath = appletWidget.readConfig('localPath', 'none')
            if (lpath.includes('kfocus-rollback')) {
                appletWidget.remove()
            }
        }
    });
});

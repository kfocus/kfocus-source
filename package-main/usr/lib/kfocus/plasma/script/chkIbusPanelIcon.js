// Copyright: 2024 MindShare Inc., 2024 KDE Contributors
// License: GPLv3
// Copied and adapted for the Kubuntu Focus from the example shown at
// https://develop.kde.org/docs/plasma/scripting/

isIbusIconFound=false;

panelIds.forEach((panel) => {
    panel = panelById(panel);
    if (!panel) {
        return;
    }
    panel.widgetIds.forEach((myWidget) => {
        myWidget = panel.widgetById(myWidget);
        if (myWidget.type === "org.kde.plasma.systemtray") {
            systrayId = myWidget.readConfig("SystrayContainmentId");
            if (systrayId) {
                const systray = desktopById(systrayId);
                systray.currentConfigGroup = ["General"];
                const hiddenItems = systray.readConfig("hiddenItems")
                  .split(",");
                if (hiddenItems.indexOf("ibus-ui-gtk3") === -1) {
                    isIbusIconFound=true;
                }
            }
        }
    });
});

if (isIbusIconFound) {
    print('true');
} else {
    print ('false');
}

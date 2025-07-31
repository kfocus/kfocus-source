// Copyright: 2025 MindShare Inc.
// License: GPLv2

desktops().forEach((desktop) => {
  desktop.widgetIds.forEach((widgetId) => {
    widget = desktop.widgetById(widgetId);
    if (widget.type === 'org.kde.plasma.mediaframe') {
      widget.currentConfigGroup = 'Paths';
      config_data = widget.readConfig('pathList');
      if (config_data.includes('kfocus-hints')) {
        widget.remove();
      }
    } else if (widget.type === 'org.kde.plasma.icon') {
      widget.currentConfigGroup = 'General';
      config_data = widget.readConfig('localPath');
      switch (config_data) {
        case '/usr/share/applications/kfocus-support-app.desktop':
        case '/usr/share/applications/kfocus-support-wf.desktop':
        case '/usr/share/applications/kfocus-support-welcome.desktop':
        case '/usr/share/applications/kfocus-help.desktop':
          widget.remove();
          break;
      }
    }
  });
});

/*global Panel gridUnit languageId panelIds panelById screenGeometry*/
/* Refactored 2023-03-29 to pass eslint */

// Use this in plasma-interactive console to inspect properties and values.
// See layout-vert and /usr/share/plasma/layout-templates for 
// desktop layout and panel layout respectively.
function introspectFn () {
  // Begin Favor Bottom Then Top Edge
  for ( var idx = 0; idx < panelIds.length; idx++ ) {
    var panel_obj = panelById( panelIds[ idx ] );
    // print( Object.keys( panel_obj ).sort().join('\n') + '\n\n' );
    // print( 'Panel ' + idx + ' edge is ' + panel_obj.location + '\n' );
    for ( var jdx = 0; jdx < panel_obj.widgetIds.length; jdx++ ) {
      var widget_obj = panel_obj.widgetById( panel_obj.widgetIds[ jdx ] );
      // if ( widget_obj.type === 'org.kde.plasma.kickoff' ) {
      // if ( widget_obj.type === 'org.kde.plasma.pager' ) {
      if ( true ) {
        print( 'Widget Type is ' + widget_obj.type + '\n' );
        print( Object.keys( widget_obj ).sort().join('\n  ') + '\n\n' );
        // print( ' Interface ' + widget_obj.showConfigurationInterface + '\n');
        // print( 'configKeys  : ' + widget_obj.configKeys + '\n\n');

        var group_list = widget_obj.configGroups.slice();
        print( 'configGroups: ' + group_list.join(',') + '\n\n');

        for ( var kdx = 0; kdx < group_list.length; kdx++ ) {
          var group_key = group_list[ kdx ];
          print( 'Group key ' + kdx + ' is |' + group_key + '|\n' );
          widget_obj.currentConfigGroup = group_key;
          var key_list = widget_obj.configKeys.slice();
          for ( var pdx = 0; pdx < key_list.length; pdx++ ) {
            config_key = key_list[ pdx ];
            print( 'Config key ' + pdx + ' is |' + config_key + '|\n' );
            print( '  Value is |' + widget_obj.readConfig( config_key ) + '|\n\n' );
          }
        }
      }
    }
  }
}

/*global Panel gridUnit languageId panelIds panelById screenGeometry*/
/* Refactored 2023-03-29 to pass eslint */

// Use this in plasma-interactive console to inspect properties and values.
// See layout-vert and /usr/share/plasma/layout-templates for
// desktop layout and panel layout respectively.
function introspectPanel01Fn () {
  // Begin Favor Bottom Then Top Edge
  for ( var idx = 0; idx < panelIds.length; idx++ ) {
    var panel_obj = panelById( panelIds[ idx ] );
    // print( Object.keys( panel_obj ).sort().join('\n') + '\n\n' );
    // print( 'Panel ' + idx + ' edge is ' + panel_obj.location + '\n' );
    for ( var jdx = 0; jdx < panel_obj.widgetIds.length; jdx++ ) {
      var widget_obj = panel_obj.widgetById( panel_obj.widgetIds[ jdx ] );
      // if ( widget_obj.type === 'org.kde.plasma.kickoff' ) {
      // if ( widget_obj.type === 'org.kde.plasma.pager' ) {
      if ( true ) {
        print( 'Widget Type is ' + widget_obj.type + '\n' );
        print( Object.keys( widget_obj ).sort().join('\n  ') + '\n\n' );
        // print( ' Interface ' + widget_obj.showConfigurationInterface + '\n');
        // print( 'configKeys  : ' + widget_obj.configKeys + '\n\n');

        var group_list = widget_obj.configGroups.slice();
        print( 'configGroups: ' + group_list.join(',') + '\n\n');

        for ( var kdx = 0; kdx < group_list.length; kdx++ ) {
          var group_key = group_list[ kdx ];
          print( 'Group key ' + kdx + ' is |' + group_key + '|\n' );
          widget_obj.currentConfigGroup = group_key;
          var key_list = widget_obj.configKeys.slice();
          for ( var pdx = 0; pdx < key_list.length; pdx++ ) {
            config_key = key_list[ pdx ];
            print( 'Config key ' + pdx + ' is |' + config_key + '|\n' );
            print( '  Value is |' + widget_obj.readConfig( config_key ) + '|\n\n' );
          }
        }
      }
    }
  }
}

// This is from KDE found here:
// https://develop.kde.org/docs/plasma/scripting/examples/
function introspectDesktopsFn () {
  print( 'Desktop Instrospection:\n' );
  var allDesktops = desktops();
  for (var desktopIndex = 0; desktopIndex < allDesktops.length; desktopIndex++) {
    var d = allDesktops[desktopIndex];
    print(d);

    var widgets = d.widgets();
    for (var widgetIndex = 0; widgetIndex < widgets.length; widgetIndex++) {
      var w = widgets[widgetIndex];
      print("\t" + w.type + ": ");

      var configGroups = w.configGroups.concat([]); // concat is used to clone the array
      for (var groupIndex = 0; groupIndex < configGroups.length; groupIndex++) {
        var g = configGroups[groupIndex];
        print("\t\t" + g + ": ");
        w.currentConfigGroup = [g];

        for (var keyIndex = 0; keyIndex < w.configKeys.length; keyIndex++) {
          var configKey = w.configKeys[keyIndex];
          print("\t\t\t" + configKey + ": " + w.readConfig(configKey));
        }
      }
    }
  }
  print( '========================\n\n');
}

function introspectPanels02Fn () {
  print( 'Panels Instrospection:\n' );
  var allPanels = panels();
  for (var panelIndex = 0; panelIndex < allPanels.length; panelIndex++) {
    var p = allPanels[panelIndex];
    print(p);

    var widgets = p.widgets();
    for (var widgetIndex = 0; widgetIndex < widgets.length; widgetIndex++) {
      var w = widgets[widgetIndex];
      print("\t" + w.type + ": ");

      var configGroups = w.configGroups.concat([]); // concat is used to clone the array
      for (var groupIndex = 0; groupIndex < configGroups.length; groupIndex++) {
        var g = configGroups[groupIndex];
        print("\t\t" + g + ": ");
        w.currentConfigGroup = [g];

        for (var keyIndex = 0; keyIndex < w.configKeys.length; keyIndex++) {
          var configKey = w.configKeys[keyIndex];
          print("\t\t\t" + configKey + ": " + w.readConfig(configKey));
        }
      }
    }
  }
  print( '========================\n\n');
}


// introspectDesktopsFn();
// introspectPanels02Fn();

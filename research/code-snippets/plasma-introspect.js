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

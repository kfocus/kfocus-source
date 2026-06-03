/*global Panel, gridUnit, languageId, panelIds, panelById, screenGeometry,
 applicationExists
*/
/* eslint-disable one-var */
/* Refactored 2026-03-31, Verified with EsLint */

//== BEGIN setPanelEdgeFn {
// panelIds, panelById are Plasma globals
//
function setPanelEdgeFn ( arg_panel_obj ) {
  const edge_map = {
    'bottom': true, 'top': true, 'left': true, 'right': true
  };
  const prefer_list = [ 'left', 'right', 'top', 'bottom' ];
  const screen_obj = arg_panel_obj.screen;

  // Mark open panels in map
  for ( let idx = 0; idx < panelIds.length; idx++ ) {
    const loop_panel_obj = panelById( panelIds[ idx ] );
    if ( loop_panel_obj.screen === screen_obj ) {
      // Ignore the new panel
      if ( loop_panel_obj.id !== arg_panel_obj.id ) {
        edge_map[ loop_panel_obj.location ] = false;
      }
    }
  }

  // Use first available edge from prefer_list
  let edge_key;
  for ( let idx = 0; idx < prefer_list.length; idx++ ) {
    const loop_key = prefer_list[ idx ];
    if ( edge_map[ loop_key ] ) {
      edge_key = loop_key;
      break;
    }
  }

  // Use default value if no free edge found
  if ( ! edge_key ) {
    edge_key = prefer_list[ 0 ];
  }

  arg_panel_obj.location = edge_key;
}
//== . END setPanelEdgeFn }

//== BEGIN setPanelSizeFn {
function setPanelSizeFn ( arg_panel_obj, arg_is_horiz ) {
  const screen_obj = arg_panel_obj.screen;
  // Set horizontal layout if specified
  if ( arg_is_horiz ) {
    arg_panel_obj.height = Math.round( 3 * gridUnit );
    const geom_obj = screenGeometry( screen_obj );
    // Restrict horizontal panel to 2x screen height
    const max_w_int = Math.round( geom_obj.height * 2 );
    if ( geom_obj.width > max_w_int ) {
      arg_panel_obj.minimumLength = max_w_int;
      arg_panel_obj.maximumLength = max_w_int;
      arg_panel_obj.alignment = 'center';
    }
  }

  // otherwise, set vertical layout
  else {
    arg_panel_obj.height = Math.round( gridUnit * 3.5 );
    arg_panel_obj.length = gridUnit * 999;
  }
}
//== . End setPanelSizeFn }

//== BEGIN addStartFn {
function addStartFn ( arg_panel_obj, arg_is_horiz ) {
  // Set up kickoff
  const kickoff_obj = arg_panel_obj.addWidget( 'org.kde.plasma.kickoff' );
  kickoff_obj.currentConfigGroup = [ 'Shortcuts' ];
  kickoff_obj.writeConfig( 'global', 'Alt+F1' );
  kickoff_obj.currentConfigGroup = [ 'General' ];
  kickoff_obj.writeConfig( 'showAppsByName', 'true' );
  kickoff_obj.writeConfig(     'icon','start-here-kubuntu' );

  // If vertical, place clock at top
  if ( ! arg_is_horiz ) {
    const clock_obj = arg_panel_obj.addWidget( 'org.kde.plasma.digitalclock' );
    clock_obj.currentConfigGroup = [ 'Appearance' ];
    clock_obj.writeConfig( 'showDate', 'true' );
    clock_obj.writeConfig( 'dateFormat', 'isoDate' );
    clock_obj.writeConfig( 'showSeconds', 'false' );
    clock_obj.writeConfig( 'use24hFormat', '0' );
  }
}
//== . END addKickoffFn }

//== BEGIN addPagerFn {
function addPagerFn ( arg_panel_obj, arg_is_horiz ) {
  // We do not currently add an activity manager
  // arg_panel_obj.addWidget('org.kde.plasma.showActivityManager');
  const pager_obj = arg_panel_obj.addWidget( 'org.kde.plasma.pager' );
  pager_obj.currentConfigGroup = [ 'General' ];
  pager_obj.writeConfig( 'wrapPage', 'true' );

  // Show screen Names if pager is shown in vertical panel
  if ( ! arg_is_horiz ) {
    pager_obj.currentConfigGroup = [ 'General' ];
    pager_obj.writeConfig( 'displayedText', 'Name' );
  }
}
//== . END addPagerFn }

//== BEGIN addIconTasksFn {
function addIconTasksFn( arg_panel_obj ) {
  const icontasks_obj = arg_panel_obj.addWidget( 'org.kde.plasma.icontasks' );
  const app_software_str = applicationExists( 'kubuntu-manage-software' )
      ? 'applications:org.kubuntu.manage-software.desktop'
      : 'applications:org.kde.discover.desktop'
  ;

  // Available preferred:// options include browser, email, filemanger, terminal.
  // Email doesn't seem to work though, although it doesn't show either.
  // We show the KDE defaults though to incentivize their use, and because using
  // preferred:// seems to have the panel set its own order while using explicit
  // app names first preserves order.
  //
  const launcher_list = [
    'applications:systemsettings.desktop',
    app_software_str,
    'applications:org.kde.dolphin.desktop',
    'applications:org.kde.konsole.desktop',
    'preferred://browser'
    // 'preferred://email' // does not work
  ];
  icontasks_obj.writeConfig( 'launchers', launcher_list );
  // This provides padding to systemtray or other adjacent items
  arg_panel_obj.addWidget( 'org.kde.plasma.marginsseparator' );
}
//== . END addIconTasksFn }

//== BEGIN addInputPanelFn {
// Determine whether to add the Input Method Panel widget.
// This is only done if the system locale language ID is a member
// of the embedded whitelist. These IDs are known to pull in one of
// KDEs supported IME backends when choosen during installation
// of common distributions.
//
function addInputPanelFn ( arg_panel_obj ) {
  const lang_id_list = [
    'as',    // Assamese
    'bn',    // Bengali
    'bo',    // Tibetan
    'brx',   // Bodo
    'doi',   // Dogri
    'gu',    // Gujarati
    'hi',    // Hindi
    'ja',    // Japanese
    'kn',    // Kannada
    'ko',    // Korean
    'kok',   // Konkani
    'ks',    // Kashmiri
    'lep',   // Lepcha
    'mai',   // Maithili
    'ml',    // Malayalam
    'mni',   // Manipuri
    'mr',    // Marathi
    'ne',    // Nepali
    'or',    // Odia
    'pa',    // Punjabi
    'sa',    // Sanskrit
    'sat',   // Santali
    'sd',    // Sindhi
    'si',    // Sinhala
    'ta',    // Tamil
    'te',    // Telugu
    'th',    // Thai
    'ur',    // Urdu
    'vi',    // Vietnamese
    'zh_CN', // Simplified Chinese
    'zh_TW'  // Traditional Chinese
  ];

  if ( lang_id_list.indexOf( languageId ) !== -1 ) {
    arg_panel_obj.addWidget( 'org.kde.plasma.kimpanel' );
  }
}
//== . END addInputPanelFn }

//== BEGIN addExtraIconsFn {
function addExtraIconsFn ( arg_panel_obj ) {
  // Add only if installed
  if (applicationExists( 'kfocus-rollback' ) ) {
    const rollback_obj = arg_panel_obj.addWidget( 'org.kde.plasma.icon' );
    rollback_obj.writeConfig( 'localPath', '/usr/share/applications/org.kfocus.rollback.desktop' );
    rollback_obj.currentConfigGroup = [ 'General' ];
    rollback_obj.writeConfig( 'url', 'file:///usr/share/applications/org.kfocus.rollback.desktop' );
  }
  // Add only if installed
  if (applicationExists( 'backintime-qt' ) ) {
    const backup_obj = arg_panel_obj.addWidget( 'org.kde.plasma.icon' );
    // Write this config with out setting a group to match
    //   qdbus6 org.kde.plasmashell /PlasmaShell \
    //     org.kde.PlasmaShell.dumpCurrentLayoutJS;
    backup_obj.writeConfig( 'localPath', '/usr/share/applications/backintime-qt.desktop' );
    backup_obj.currentConfigGroup = [ 'General' ];
    backup_obj.writeConfig( 'url', 'file:///usr/share/applications/backintime-qt.desktop' );
  }
  // TODO if we add kup
  // backup_obj.writeConfig( 'localPath', '/usr/share/kservices5/kcm_kup.desktop' );
  // backup_obj.writeConfig( 'url', 'file:///usr/share/kservices5/kcm_kup.desktop' );
}
//== . END addExtraIconsFn }

//== BEGIN addEndFn {
function addEndFn( arg_panel_obj, arg_is_horiz ) {
  const systray_obj = arg_panel_obj.addWidget( 'org.kde.plasma.systemtray' );
  systray_obj.currentConfigGroup = [ 'General' ];

  const shown_items = systray_obj.readConfig('shownItems').split(',');
  if (shown_items.indexOf('org.kde.plasma.battery') === -1) {
    shown_items.push('org.kde.plasma.battery');
  }

  // TODO if we add kup
  // if (shown_items.indexOf('org.kde.kupapplet') === -1) {
  //   shown_items.push('org.kde.kupapplet');
  // }

  systray_obj.writeConfig('shownItems', shown_items);

  // If horizontal, place clock at far right
  if ( arg_is_horiz ) {
    // Add showDesktop for horizontal layouts
    const clock_obj = arg_panel_obj.addWidget( 'org.kde.plasma.digitalclock' );
    clock_obj.currentConfigGroup = [ 'Appearance' ];
    clock_obj.writeConfig( 'showDate', 'true' );
    clock_obj.writeConfig( 'dateFormat', 'isoDate' );
    clock_obj.writeConfig( 'showSeconds', 'false' );
    clock_obj.writeConfig( 'use24hFormat', '0' );

    arg_panel_obj.addWidget( 'org.kde.plasma.showdesktop' );
  }
}
//== . END addEndFn }

//== BEGIN mainFn {
// Panel is a Plasma global
function mainFn () {
  const panel_obj = new Panel;
  panel_obj.floating = 0;
  panel_obj.hiding   = 'normal';
  panel_obj.screen   = 0;

  setPanelEdgeFn(  panel_obj );
  const is_horiz = panel_obj.formFactor === 'horizontal';
  setPanelSizeFn(  panel_obj, is_horiz );
  addStartFn(      panel_obj, is_horiz );
  addPagerFn(      panel_obj, is_horiz );
  addIconTasksFn(  panel_obj );
  addInputPanelFn( panel_obj );

  addExtraIconsFn( panel_obj );
  addEndFn( panel_obj, is_horiz );
}
//== . END mainFn }

mainFn();

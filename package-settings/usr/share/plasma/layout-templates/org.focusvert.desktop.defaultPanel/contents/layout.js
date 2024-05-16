/*global Panel gridUnit languageId panelIds panelById screenGeometry*/
/* Refactored 2023-10-18, passes eslint */
var
  panel_obj,     screen_obj,    edge_map,      prefer_list,
  idx,           loop_obj,      loop_key,      edge_key,
  is_horizontal, geom_obj,      max_w_int,     kickoff_obj,
  pager_obj,     icontasks_obj, launcher_list, lang_id_list,
  backup_obj,    rollback_obj,  systray_obj,   clock_obj
  ;

panel_obj = new Panel;
screen_obj = panel_obj.screen;
edge_map = {
  'bottom': true, 'top': true, 'left': true, 'right': true
};
// prefer_list = [ 'bottom', 'top', 'left', 'right' ];
prefer_list = [ 'left', 'right', 'top', 'bottom' ];

// Begin Mark open panels in map
for ( idx = 0; idx < panelIds.length; idx++ ) {
  loop_obj = panelById( panelIds[ idx ] );
  if ( loop_obj.screen === screen_obj ) {
    // Ignore the new panel
    if ( loop_obj.id !== panel_obj.id ) {
      edge_map[ loop_obj.location ] = false;
    }
  }
}
// . End Mark open panels in map

// Begin Use first available edge from prefer_list
for ( idx = 0; idx < prefer_list.length; idx++ ) {
  loop_key = prefer_list[ idx ];
  if ( edge_map[ loop_key ] ) {
    edge_key = loop_key;
    break;
  }
}
// Use default value if no free edge found
if ( ! edge_key ) {
  edge_key = prefer_list[ 0 ];
}

panel_obj.location = edge_key;
// . End Use first available edge from prefer_list

// Begin Size by orientation
is_horizontal = panel_obj.formFactor === 'horizontal';
if ( is_horizontal ) {
  panel_obj.height = Math.round( gridUnit * 2.5 );
  geom_obj = screenGeometry( screen_obj );
  // Restrict horizontal panel to 2x screen height
  max_w_int = Math.round( geom_obj.height * 2 );
  if ( geom_obj.width > max_w_int ) {
    panel_obj.minimumLength = max_w_int;
    panel_obj.maximumLength = max_w_int;
    panel_obj.alignment = 'center';
  }
}
// . End Horizontal Layout from org.kde.plasma

// Begin Vertical Layout
else {
  panel_obj.height = Math.round( gridUnit * 3 );
  panel_obj.length = gridUnit * 999;
}
// . End Vertical Layout

kickoff_obj = panel_obj.addWidget( 'org.kde.plasma.kickoff' );
kickoff_obj.currentConfigGroup = [ 'Shortcuts' ];
kickoff_obj.writeConfig( 'global', 'Alt+F1' );
kickoff_obj.currentConfigGroup = [ 'General' ];
kickoff_obj.writeConfig( 'alphaSort', 'true' );
kickoff_obj.writeConfig( 'systemFavorites', 'suspend,reboot,shudown');

// If vertical, place clock at top
if ( ! is_horizontal ) {
  clock_obj = panel_obj.addWidget( 'org.kde.plasma.digitalclock' );
  clock_obj.currentConfigGroup = [ 'Appearance' ];
  clock_obj.writeConfig( 'showDate', 'true' );
  clock_obj.writeConfig( 'dateFormat', 'isoDate' );
  clock_obj.writeConfig( 'showSeconds', 'false' );
}

// 2023-03-27 This is probably no longer desirable
// kickoff.currentConfigGroup = ["Configuration/ConfigDialog"];
// kickoff.writeConfig("DialogHeight", 720);
// kickoff.writeConfig("DialogHeight", 960);

// This needs to be set as not 'flexible'. Disabled for now.
// var spacer = panel.addWidget("org.kde.plasma.panelspacer")
// spacer.writeConfig("length", "2")
// spacer.writeConfig("immutability", "1")

// We do not currently add an activity manager
// panel_obj.addWidget('org.kde.plasma.showActivityManager');

pager_obj = panel_obj.addWidget( 'org.kde.plasma.pager' );
pager_obj.currentConfigGroup = [ 'General' ];

// Show screen Names if pager is shown in vertical panel
pager_obj.writeConfig( 'wrapPage', 'true' );
if ( ! is_horizontal ) {
  pager_obj.currentConfigGroup = [ 'General' ];
  pager_obj.writeConfig( 'displayedText', 'Name' );
}

icontasks_obj = panel_obj.addWidget( 'org.kde.plasma.icontasks' );
launcher_list = [
  'applications:systemsettings.desktop',
  'applications:org.kde.discover.desktop',
  'applications:org.kde.konsole.desktop',
  'applications:org.kde.dolphin.desktop'
];

if (applicationExists( 'firefox' ) ) {
  launcher_list.push( 'applications:firefox.desktop' );
}
if (applicationExists( 'google-chrome' ) ) {
  launcher_list.push( 'applications:google-chrome.desktop' );
}

icontasks_obj.writeConfig( 'launchers', launcher_list );

/* Determine whether to add the Input Method Panel
 * widget to the panel or not. This is done based on whether
 * the system locale's language id is a member of the following
 * white list of languages which are known to pull in one of
 * our supported IME backends when chosen during installation
 * of common distributions. */

lang_id_list = [
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
  panel_obj.addWidget( 'org.kde.plasma.kimpanel' );
}

// Add only if installed
if (applicationExists( 'backintime-qt' ) ) {
  backup_obj = panel_obj.addWidget( 'org.kde.plasma.icon' );
  backup_obj.currentConfigGroup = [ 'General' ];
  backup_obj.writeConfig( 'localPath', '/usr/share/applications/backintime-qt.desktop' );
  backup_obj.writeConfig( 'url', 'file:///usr/share/applications/backintime-qt.desktop' );
}

// Add only if installed
if (applicationExists( 'kfocus-rollback' ) ) {
  rollback_obj = panel_obj.addWidget( 'org.kde.plasma.icon' );
  rollback_obj.currentConfigGroup = [ 'General' ];
  rollback_obj.writeConfig( 'localPath', '/usr/share/applications/kfocus-rollback.desktop' );
  rollback_obj.writeConfig( 'url', 'file:///usr/share/applications/kfocus-rollback.desktop' );
}

// TODO if we add kup
// backup_obj.writeConfig( 'localPath', '/usr/share/kservices5/kcm_kup.desktop' );
// backup_obj.writeConfig( 'url', 'file:///usr/share/kservices5/kcm_kup.desktop' );

systray_obj = panel_obj.addWidget( 'org.kde.plasma.systemtray' );
systray_obj.currentConfigGroup = [ 'General' ];

// TODO if we add kup
// systray_obj.writeConfig( 'shownItems', 'org.kde.kupapplet' );

// If horizontal, place clock at far right
if ( is_horizontal ) {
  // Add showDesktop for horizontal layouts
  panel_obj.addWidget( 'org.kde.plasma.showdesktop' );

  clock_obj = panel_obj.addWidget( 'org.kde.plasma.digitalclock' );
  clock_obj.currentConfigGroup = [ 'Configuration/General' ];
  clock_obj.writeConfig( 'showDate', 'true' );
  clock_obj.writeConfig( 'dateFormat', 'isoDate' );
}
// End

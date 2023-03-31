/*global Panel gridUnit languageId panelIds panelById screenGeometry*/
/* Refactored 2023-03-29 to pass eslint */
var 
  panel_obj,      screen_obj,     edge_map,       idx,
  tmppanel_obj,   max_ratio,      geom_obj,       max_w_int,
  kickoff_obj,    pager_obj,      tmanager_obj,   launcher_list,
  lang_id_list,   backup_obj,     systray_obj,    clock_obj
  ;

panel_obj = new Panel;
screen_obj = panel_obj.screen;
edge_map = {
  'bottom': true, 'top': true, 'left': true, 'right': true
};

// Begin Favor Left Then Right Edge
for ( idx = 0; idx < panelIds.length; ++idx ) {
  tmppanel_obj = panelById( panelIds[ idx ] );
  if ( tmppanel_obj.screen == screen_obj ) {
    // Ignore the new panel
    if ( tmppanel_obj.id != panel_obj.id ) {
      edge_map[ tmppanel_obj.location ] = false;
    }
  }
}

if ( edge_map[ 'left' ] == true ) {
  panel_obj.location = 'left';
} else if ( edge_map[ 'right' ] == true ) {
  panel_obj.location = 'right';
} else if ( edge_map[ 'bottom' ] == true ) {
  panel_obj.location = 'bottom';
} else if ( edge_map[ 'top' ] == true ) {
  panel_obj.location = 'top';
} else {
  // Use default value if no free edge found
  panel_obj.location = 'left';
}
// . End Favor Left then Right Edge

// Begin Horizontal Layout from org.kde.plasma
// Restrict horizontal panel to a maximum ratio of a 21:9 monitor
max_ratio = 20/9;
if ( panel_obj.formFactor === 'horizontal' ) {
  // For an Icons-Only Task Manager on the bottom, *3 is too much, *2 is too
  // little Round down to next highest even number since the panel_obj size
  // widget only displays// even numbers
  panel_obj.height = 2 * Math.floor( gridUnit * 2.5 / 2 );
  geom_obj = screenGeometry( screen_obj );
  max_w_int = Math.ceil( geom_obj.height * max_ratio );
  if ( geom_obj.width > max_w_int ) {
    panel_obj.alignment = 'center';
    panel_obj.minimumLength = max_w_int;
    panel_obj.maximumLength = max_w_int;
  }
}
// . End Horizontal Layout from org.kde.plasma

// Begin Vertical Layout
else {
  panel_obj.height = gridUnit * 3;
  panel_obj.length = gridUnit * 999;
}
// . End Vertical Layout

kickoff_obj = panel_obj.addWidget( 'org.kde.plasma.kickoff' );
kickoff_obj.currentConfigGroup = [ 'Shortcuts' ];
kickoff_obj.writeConfig( 'global', 'Alt+F1' );
kickoff_obj.currentConfigGroup = [ 'General' ];
kickoff_obj.writeConfig( 'showAppsByName', 'true' );

// 2023-03-27 This is probably no longer desirable
// kickoff.currentConfigGroup = [ 'ConfigDialog' ];
// kickoff.writeConfig("DialogHeight", 720);
// kickoff.writeConfig("DialogHeight", 960);

// This needs to be set as not 'flexible'. Disabled for now.
// var spacer = panel.addWidget("org.kde.plasma.panelspacer")
// spacer.writeConfig("length", "2")
// spacer.writeConfig("immutability", "1")

// We do not currently add an activity manager
// panel_obj.addWidget( 'org.kde.plasma.showActivityManager' );

pager_obj = panel_obj.addWidget( 'org.kde.plasma.pager' );
// Vertical gets text in the pager mini-screens
pager_obj.currentConfigGroup = [ 'General' ];
if ( panel_obj.formFactor !== 'horizontal' ) {
  pager_obj.writeConfig( 'displayedText', 'Name' );
}

tmanager_obj = panel_obj.addWidget( 'org.kde.plasma.icontasks' );
launcher_list = [
  'applications:systemsettings.desktop',
  'applications:org.kde.discover.desktop',
  'applications:org.kde.konsole.desktop',
  'applications:org.kde.dolphin.desktop',
  'applications:google-chrome.desktop',
  'applications:firefox_firefox.desktop'
];
tmanager_obj.writeConfig( 'launchers', launcher_list );

/* Next up is determining whether to add the Input Method Panel
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

if ( lang_id_list.indexOf( languageId ) != -1 ) {
  panel_obj.addWidget( 'org.kde.plasma.kimpanel' );
}

backup_obj = panel_obj.addWidget( 'org.kde.plasma.icon' );
backup_obj.currentConfigGroup = [ 'General' ];
backup_obj.writeConfig( 'localPath', '/usr/share/applications/backintime-qt.desktop' );
backup_obj.writeConfig( 'url', 'file:///usr/share/applications/backintime-qt.desktop' );
// TODO if we add kup
// backup_obj.writeConfig( 'localPath', '/usr/share/kservices5/kcm_kup.desktop' );
// backup_obj.writeConfig( 'url', 'file:///usr/share/kservices5/kcm_kup.desktop' );

systray_obj = panel_obj.addWidget( 'org.kde.plasma.systemtray' );
systray_obj.currentConfigGroup = [ 'General' ];
// TODO if we add kup
// systray_obj.writeConfig( 'shownItems', 'org.kde.kupapplet' );

// Place clock on bottom panel, far-right as is the convention.
clock_obj = panel_obj.addWidget( 'org.kde.plasma.digitalclock' );
clock_obj.currentConfigGroup = [ 'General' ];
clock_obj.writeConfig( 'showDate', 'true' );
clock_obj.writeConfig( 'dateFormat', 'isoDate' );

panel_obj.addWidget( 'org.kde.plasma.showdesktop' );

// End

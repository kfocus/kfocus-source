/*globals gridUnit, screenGeometry, panelIds, panelById, desktops,
 loadTemplate, desktopsForActivity, currentActivity */

/* Plasma scripting API: https://develop.kde.org/docs/plasma/scripting/api/
 *
 * Copyright: 2025 MindShare Inc.
 * Written for Kubuntu Focus by Michael Mikowski and Aaron Rainbolt
 * License: GPLv2
 *
 * Passed ESLint 2025-08-04
*/

loadTemplate("org.kfocus.desktop.defaultPanel");

// Given two points on a curve, return y at x (rounded)
function getScaleNumFn ( map ) {
  let
    s = (map.y2 - map.y1 ) / (map.x2 - map.x1 ),
    k = map.y2 - (s * map.x2),
    solve_num = k + map.x * s,
    // Round to the nearest integer
    round_num = Math.round( solve_num );

  if (      round_num < map.min ) { round_num = map.min; }
  else if ( round_num > map.max ) { round_num = map.max; }

  return round_num;
}

const
  scaleMatrix = {
    large : {
      // Inverse scale with DPI: Icon height
      // Adjusted scale for 136 DPI 4K screen
      icon_ht_px    : getScaleNumFn({x1:22,y1:7,x2:32,y2:6,min:6,max:8,x:gridUnit}) * gridUnit,
      // Inverse scale with DPI: Icon padding from widget edge
      icon_padx_px  : getScaleNumFn({x1:22,y1:2,x2:32,y2:1,min:1,max:4,x:gridUnit}) * gridUnit,
      // Inverse icon top from screen edge
      icon_top_px   : getScaleNumFn({x1:22,y1:4,x2:32,y2:2,min:0,max:2,x:gridUnit}) * (gridUnit * 1.25),
      // Inverse scale with DPI: Icon spacing
      icon_space_px : getScaleNumFn({x1:22,y1:9,x2:32,y2:7,min:6,max:14,x:gridUnit}) * gridUnit,
      // Inverse scale with DPI: Icon width
      icon_w_px     : 4 * gridUnit,
      // Offset widget from right edge
      widget_padx_px: 0.5 * gridUnit,
      // Offset widget from edge
      widget_pady_px: 1 * gridUnit,
      // Hack to make sure the widget fits on 176 DPI
      widget_h_px   : 994 + gridUnit / 4,
      widget_w_px   : 640
    },
    medium : {
      // Inverse scale with DPI: Icon height
      icon_ht_px    : getScaleNumFn({x1:22,y1:7,x2:32,y2:6,min:6,max:8,x:gridUnit}) * gridUnit,
      // Inverse scale with DPI: Icon padding from widget edge
      icon_padx_px  : getScaleNumFn({x1:22,y1:2,x2:32,y2:1,min:1,max:4,x:gridUnit}) * gridUnit,
      // Inverse icon top from screen edge
      icon_top_px   : getScaleNumFn({x1:22,y1:2,x2:32,y2:1,min:0,max:2,x:gridUnit}) * (gridUnit * 1.25),
      // Inverse scale with DPI: Icon spacing
      icon_space_px : getScaleNumFn({x1:22,y1:7,x2:32,y2:6,min:6,max:14,x:gridUnit}) * gridUnit,
      // Inverse scale with DPI: Icon width
      icon_w_px     : 4 * gridUnit,
      // Offset widget from right edge
      widget_padx_px: 0.5 * gridUnit,
      // Offset widget from edge
      widget_pady_px: 1 * gridUnit,
      widget_h_px   : 796 + gridUnit / 4,
      widget_w_px   : 512
    },
    small : {
      // Inverse scale with DPI: Icon height
      icon_ht_px    : getScaleNumFn({x1:14,y1:8,x2:22,y2:6,min:6,max:8,x:gridUnit}) * gridUnit,
      // Inverse scale with DPI: Icon padding from widget edge
      icon_padx_px  : getScaleNumFn({x1:14,y1:3,x2:22,y2:1,min:1,max:3,x:gridUnit}) * gridUnit,
      // Inverse icon top from screen edge
      icon_top_px   : getScaleNumFn({x1:14,y1:3,x2:22,y2:2,min:1,max:3,x:gridUnit}) * (gridUnit * 1.25),
      // Inverse scale with DPI: Icon spacing
      icon_space_px : getScaleNumFn({x1:14,y1:10,x2:22,y2:7,min:6,max:14,x:gridUnit}) * gridUnit,
      // Inverse scale with DPI: Icon width
      icon_w_px     : 4 * gridUnit,
      // Offset widget from right edge
      widget_padx_px: 0.5 * gridUnit,
      // Offset widget from edge
      widget_pady_px: 1 * gridUnit,
      widget_h_px   : 664 + gridUnit / 4,
      widget_w_px   : 428
    }
  },
  // kfocus hints widget images are 1280 x 1988
  widgetPathList = [
    '{"path":"file:///usr/share/kfocus-hints/00_badge.png","type":"file"}',
    '{"path":"file:///usr/share/kfocus-hints/01_desktop.png","type":"file"}',
    '{"path":"file:///usr/share/kfocus-hints/02_system.png","type":"file"}',
    '{"path":"file:///usr/share/kfocus-hints/03_konsole.png","type":"file"}',
    '{"path":"file:///usr/share/kfocus-hints/04_filesys.png","type":"file"}',
    '{"path":"file:///usr/share/kfocus-hints/05_env.png","type":"file"}',
    '{"path":"file:///usr/share/kfocus-hints/06_search.png","type":"file"}',
    '{"path":"file:///usr/share/kfocus-hints/07_perms.png","type":"file"}',
    '{"path":"file:///usr/share/kfocus-hints/08_network.png","type":"file"}',
    '{"path":"file:///usr/share/kfocus-hints/09_vim_01.png","type":"file"}',
    '{"path":"file:///usr/share/kfocus-hints/10_vim_02.png","type":"file"}',
    '{"path":"file:///usr/share/kfocus-hints/11_vim_03.png","type":"file"}'
  ];

function quantizeToGridFn(px) {
  return Math.floor( px / gridUnit ) * gridUnit;
}

// BEGIN tweakWallpapersFn {
// Purpose: Enables rmb > Configure Desktop > Wallpaper type = Image,
//   scaled-and-cropped.
//
function tweakWallpapersFn () {
  let desktop_list, j, desktop_obj;
  desktop_list = desktopsForActivity(currentActivity());
  for ( j = 0; j < desktop_list.length; j++) {
    desktop_obj = desktop_list[j];
    desktop_obj.wallpaperPlugin = 'org.kde.image';
    desktop_obj.wallpaperMode   = '2';
  }
}
// . END tweakWallpapersFn }

// BEGIN setLayoutFn {
// Purpose: Defines and loads serialized layout
//
function setLayoutFn () {
  let rect_obj, screen_w_px, screen_h_px, scale_key, scale_map,
    icon_h_px, icon_padx_px, icon_space_px, icon_top_px, icon_w_px,
    widget_padx_px, widget_pady_px, widget_w_px, widget_h_px,
    widget_x_px, widget_y_px, icon_x_px, panel_obj,

    main_desktop_obj, mediaframe_widget_obj, curated_icon_widget_obj,
    guided_icon_widget_obj, feature_icon_widget_obj,
    reference_icon_widget_obj;

  rect_obj     = screenGeometry(0); // (1)

  screen_w_px  = rect_obj.right  - rect_obj.left;
  screen_h_px  = rect_obj.bottom - rect_obj.top;

  scale_key    = ( screen_w_px >= 3200 && screen_h_px >= 1800 ) ? 'large'
    : (screen_w_px >= 2560 && screen_h_px >= 1440 ) ? 'medium' : 'small';
  scale_map    = scaleMatrix[ scale_key ];

  icon_h_px     = scale_map.icon_ht_px;
  icon_padx_px  = scale_map.icon_padx_px;
  icon_space_px = scale_map.icon_space_px;
  icon_top_px   = scale_map.icon_top_px;
  icon_w_px     = scale_map.icon_w_px;

  widget_h_px    = scale_map.widget_h_px;
  widget_padx_px = scale_map.widget_padx_px;
  widget_pady_px = scale_map.widget_pady_px;
  widget_w_px    = scale_map.widget_w_px;

  panelIds.forEach((panel_id) => {
    panel_obj = panelById(panel_id);
    if (panel_obj.location !== 'left' && panel_obj.location !== 'right') {
      return;
    }
    widget_padx_px += panel_obj.height;
  });

  widget_x_px = screen_w_px - widget_w_px - widget_padx_px;
  widget_y_px = widget_pady_px;
  icon_x_px   = widget_x_px - icon_w_px - icon_padx_px;

  main_desktop_obj = desktops()[0];

  mediaframe_widget_obj = main_desktop_obj.addWidget(
    "org.kde.plasma.mediaframe",
    quantizeToGridFn(widget_x_px), quantizeToGridFn(widget_y_px),
    quantizeToGridFn(widget_w_px), quantizeToGridFn(widget_h_px)
  );
  mediaframe_widget_obj.currentConfigGroup = [];
  mediaframe_widget_obj.writeConfig("PreloadWeight", "0");
  mediaframe_widget_obj.writeConfig("UserBackgroundHints", "NoBackground");
  mediaframe_widget_obj.currentConfigGroup = [ "ConfigDialog" ];
  mediaframe_widget_obj.writeConfig("DialogHeight", 20 * gridUnit);
  mediaframe_widget_obj.writeConfig("DialogWidth", 25 * gridUnit);
  mediaframe_widget_obj.currentConfigGroup = [ "General" ];
  mediaframe_widget_obj.writeConfig("fillMode", "1");
  mediaframe_widget_obj.writeConfig("interval", "3600");
  mediaframe_widget_obj.writeConfig("leftClickOpenImage", "false");
  mediaframe_widget_obj.writeConfig("randomize", "false");
  mediaframe_widget_obj.writeConfig("useBackground", "false");
  mediaframe_widget_obj.currentConfigGroup = [ "Paths" ];
  mediaframe_widget_obj.writeConfig("pathList", widgetPathList);

  curated_icon_widget_obj = main_desktop_obj.addWidget(
    "org.kde.plasma.icon",
    quantizeToGridFn(icon_x_px), quantizeToGridFn(icon_top_px),
    quantizeToGridFn(icon_w_px), quantizeToGridFn(icon_h_px)
  );
  curated_icon_widget_obj.currentConfigGroup = [];
  curated_icon_widget_obj.writeConfig("localPath",
    "/usr/share/applications/kfocus-support-app.desktop");
  curated_icon_widget_obj.writeConfig("url",
    "file:///usr/share/applications/kfocus-support-app.desktop");

  guided_icon_widget_obj = main_desktop_obj.addWidget(
    "org.kde.plasma.icon",
    quantizeToGridFn(icon_x_px),
    quantizeToGridFn(icon_top_px + icon_space_px * 1),
    quantizeToGridFn(icon_w_px), quantizeToGridFn(icon_h_px)
  );
  guided_icon_widget_obj.currentConfigGroup = [];
  guided_icon_widget_obj.writeConfig("localPath",
    "/usr/share/applications/kfocus-support-wf.desktop");
  guided_icon_widget_obj.writeConfig("url",
    "file:///usr/share/applications/kfocus-support-wf.desktop");

  feature_icon_widget_obj = main_desktop_obj.addWidget(
    "org.kde.plasma.icon",
    quantizeToGridFn(icon_x_px),
    quantizeToGridFn(icon_top_px + icon_space_px * 2),
    quantizeToGridFn(icon_w_px), quantizeToGridFn(icon_h_px)
  );
  feature_icon_widget_obj.currentConfigGroup = [];
  feature_icon_widget_obj.writeConfig("localPath",
    "/usr/share/applications/kfocus-support-welcome.desktop");
  feature_icon_widget_obj.writeConfig("url",
    "file:///usr/share/applications/kfocus-support-welcome.desktop");

  reference_icon_widget_obj = main_desktop_obj.addWidget(
    "org.kde.plasma.icon",
    quantizeToGridFn(icon_x_px),
    quantizeToGridFn(icon_top_px + icon_space_px * 3),
    quantizeToGridFn(icon_w_px), quantizeToGridFn(icon_h_px)
  );
  reference_icon_widget_obj.currentConfigGroup = [];
  reference_icon_widget_obj.writeConfig("localPath",
    "/usr/share/applications/kfocus-help.desktop");
  reference_icon_widget_obj.writeConfig("url",
    "file:///usr/share/applications/kfocus-help.desktop");

  tweakWallpapersFn();
}
// . END setLayoutFn }

setLayoutFn();

// (1) See QRectF https://develop.kde.org/docs/extend/plasma/scripting/api/#screen-geometry
// (2) Scale ratio is 1.5 for HDPI 4k screens. This should reduce to 1 for a
//     1080p screen at 96dpi.

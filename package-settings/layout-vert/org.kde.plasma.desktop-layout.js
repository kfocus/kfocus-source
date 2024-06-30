/*globals gridUnit, desktopsForActivity, currentActivity,
  getApiVersion, screenGeometry, loadTemplate */
/* Passes eslint 2024-05-03 */

loadTemplate("org.focusvert.desktop.defaultPanel");

// Given two points on a curve, return y at x (rounded)
function getScaleNumFn ( map ) {
  var
    s = (map.y2 - map.y1 ) / (map.x2 - map.x1 ),
    k = map.y2 - (s * map.x2),
    solve_num = k + map.x * s,
    // Round to interger
    round_num = Math.round( solve_num );

  if (      round_num < map.min ) { round_num = map.min; }
  else if ( round_num > map.max ) { round_num = map.max; }

  return round_num;
}

var
  scaleMatrix = {
    large : {
      // Inverse scale with DPI: Icon height
      // icon_ht_int : getScaleNumFn({x1:22,y1:8,x2:32,y2:7,min:6,max:8,x:gridUnit}),
      // Adjusted scale for 136 DPI 4K screen
      icon_ht_int    : getScaleNumFn({x1:22,y1:7,x2:32,y2:6,min:6,max:8,x:gridUnit}),
      // Inverse scale with DPI: Icon padding from widget edge
      icon_padx_int  : getScaleNumFn({x1:22,y1:2,x2:32,y2:1,min:1,max:4,x:gridUnit}),
      // Inverse icon top from screen edge
      icon_top_int   : getScaleNumFn({x1:22,y1:4,x2:32,y2:2,min:0,max:2,x:gridUnit}),
      // Inverse scale with DPI: Icon spacing
      icon_space_int : getScaleNumFn({x1:22,y1:9,x2:32,y2:7,min:6,max:14,x:gridUnit}),
      // Inverse scale with DPI: Icon width
      icon_w_int     : 4,
      // Offset widget from right edge, add 3 to allow for vertical panel
      widget_padx_num: 3.5,
      // Offset widget from edge
      widget_pady_num: 1,
      // Hack to make sure widget fits on 176 DPI
      widget_h_px  : 994 + gridUnit / 4, 
      widget_w_px  : 640  
    },
    medium : {
      // Inverse scale with DPI: Icon height
      icon_ht_int    : getScaleNumFn({x1:22,y1:7,x2:32,y2:6,min:6,max:8,x:gridUnit}),
      // Inverse scale with DPI: Icon padding from widget edge
      icon_padx_int  : getScaleNumFn({x1:22,y1:2,x2:32,y2:1,min:1,max:4,x:gridUnit}),
      // Inverse icon top from screen edge
      icon_top_int   : getScaleNumFn({x1:22,y1:2,x2:32,y2:1,min:0,max:2,x:gridUnit}),
      // Inverse scale with DPI: Icon spacing
      icon_space_int : getScaleNumFn({x1:22,y1:7,x2:32,y2:6,min:6,max:14,x:gridUnit}),
      // Inverse scale with DPI: Icon width
      icon_w_int     : 4,
      // Offset widget from right edge, add 3 to allow for vertical panel
      widget_padx_num: 3.5,
      // Offset widget from edge
      widget_pady_num: 1,
      widget_h_px  : 796 + gridUnit / 4,
      widget_w_px  : 512
    },
    small : {
      // Inverse scale with DPI: Icon height
      icon_ht_int    : getScaleNumFn({x1:14,y1:8,x2:22,y2:6,min:6,max:8,x:gridUnit}),
      // Inverse scale with DPI: Icon padding from widget edge
      icon_padx_int  : getScaleNumFn({x1:14,y1:3,x2:22,y2:1,min:1,max:3,x:gridUnit}),
      // Inverse icon top from screen edge
      icon_top_int   : getScaleNumFn({x1:14,y1:3,x2:22,y2:2,min:1,max:3,x:gridUnit}),
      // Inverse scale with DPI: Icon spacing
      icon_space_int : getScaleNumFn({x1:14,y1:10,x2:22,y2:7,min:6,max:14,x:gridUnit}),
      // Inverse scale with DPI: Icon width
      icon_w_int     : 4,
      // Offset widget from right edge, add 3 to allow for vertical panel
      widget_padx_num: 3.5,
      // Offset widget from edge
      widget_pady_num: 1,
      widget_h_px    : 664 + gridUnit / 4,
      widget_w_px    : 428
    }
  },

  // kfocus hints widget images are 1280 x 1988
  widgetPathList = [
    '{"path":"file:///usr/share/kfocus-hints//00_badge.png","type":"file"}',
    '{"path":"file:///usr/share/kfocus-hints//01_desktop.png","type":"file"}',
    '{"path":"file:///usr/share/kfocus-hints//02_system.png","type":"file"}',
    '{"path":"file:///usr/share/kfocus-hints//03_konsole.png","type":"file"}',
    '{"path":"file:///usr/share/kfocus-hints//04_filesys.png","type":"file"}',
    '{"path":"file:///usr/share/kfocus-hints//05_env.png","type":"file"}',
    '{"path":"file:///usr/share/kfocus-hints//06_search.png","type":"file"}',
    '{"path":"file:///usr/share/kfocus-hints//07_perms.png","type":"file"}',
    '{"path":"file:///usr/share/kfocus-hints//08_network.png","type":"file"}',
    '{"path":"file:///usr/share/kfocus-hints//09_vim_01.png","type":"file"}',
    '{"path":"file:///usr/share/kfocus-hints//10_vim_02.png","type":"file"}',
    '{"path":"file:///usr/share/kfocus-hints//11_vim_03.png","type":"file"}'
  ];

// BEGIN tweakWallpapersFn {
// Purpose: Enables rmb > Configure Desktop > Wallpaper type = Image,
//   scaled-and-cropped.
//
function tweakWallpapersFn () {
  var desktop_list, j, desktop_obj;
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
  var plasma_obj, rect_obj, screen_w_px, screen_h_px, screen_w_num,
    screen_h_num, scale_key, scale_map, icon_ht_int, icon_padx_int,
    icon_space_int, icon_top_int, icon_w_int,
    icon_x_num,

    widget_w_px, widget_w_num,
    widget_h_px, widget_padx_num, widget_pady_num,
    widget_h_num, widget_x_num, widget_y_num, 
    layout_matrix;

  plasma_obj  = getApiVersion(1);
  rect_obj    = screenGeometry(0); // (1)

  screen_w_px  = rect_obj.right  - rect_obj.left;
  screen_h_px  = rect_obj.bottom - rect_obj.top;
  screen_w_num = screen_w_px / gridUnit;
  screen_h_num = screen_h_px / gridUnit;

  scale_key = ( screen_w_px >= 3200 && screen_h_px >= 1800 ) ? 'large'
    : (screen_w_px >= 2560 && screen_h_px >= 1440 ) ? 'medium' : 'small';
  scale_map    = scaleMatrix[ scale_key ];

  icon_ht_int    = scale_map.icon_ht_int;
  icon_padx_int  = scale_map.icon_padx_int;
  icon_space_int = scale_map.icon_space_int;
  icon_top_int   = scale_map.icon_top_int;
  icon_w_int     = scale_map.icon_w_int;

  widget_h_px     = scale_map.widget_h_px;
  widget_padx_num = scale_map.widget_padx_num;
  widget_pady_num = scale_map.widget_pady_num;
  widget_w_px     = scale_map.widget_w_px;

  widget_w_num = widget_w_px / gridUnit;
  widget_h_num = widget_h_px / gridUnit;
  widget_x_num = screen_w_num - widget_w_num - widget_padx_num;
  widget_y_num = widget_pady_num;
  icon_x_num   = widget_x_num - icon_w_int - icon_padx_int;

  layout_matrix = {
    "desktops": [
      {
        "applets": [
          {
            "config": {
              "/": {
                "PreloadWeight": "0",
                "UserBackgroundHints": "NoBackground" // (A)
              },
              "/ConfigDialog": {
                "DialogHeight": 20 * gridUnit,
                "DialogWidth" : 25 * gridUnit
              },
              "/General": {
                "fillMode": "1",
                "interval": "3600",
                "leftClickOpenImage": "false",
                "randomize": "false",
                "useBackground": "false"
              },
              "/Paths": { "pathList": widgetPathList }
            },
            "geometry.height": widget_h_num,
            "geometry.width": widget_w_num,
            "geometry.x": widget_x_num,
            "geometry.y": widget_y_num,
            "plugin": "org.kde.plasma.mediaframe",
            "title": "Media Frame"
          },
          {
            "config": {
              "/": {
                "localPath": "/usr/share/applications/kfocus-support-app.desktop",
                "url": "file:///usr/share/applications/kfocus-support-app.desktop"
              }
            },
            "geometry.height": icon_ht_int,
            "geometry.width": icon_w_int,
            "geometry.y": icon_top_int + icon_space_int * 0,
            "geometry.x": icon_x_num,
            "plugin": "org.kde.plasma.icon",
            "title": "Curated Apps"
          },
          {
            "config": {
              "/": {
                "localPath": "/usr/share/applications/kfocus-support-wf.desktop",
                "url": "file:///usr/share/applications/kfocus-support-wf.desktop"
              }
            },
            "geometry.height": icon_ht_int,
            "geometry.width": icon_w_int,
            "geometry.y": icon_top_int + icon_space_int * 1,
            "geometry.x": icon_x_num,
            "plugin": "org.kde.plasma.icon",
            "title": "Guided Solutions"
          },
          {
            "config": {
              "/": {
                "localPath": "/usr/share/applications/kfocus-support-welcome.desktop",
                "url": "file:///usr/share/applications/kfocus-support-welcome.desktop"
              }
            },
            "geometry.height": icon_ht_int,
            "geometry.width": icon_w_int,
            "geometry.y": icon_top_int + icon_space_int * 2,
            "geometry.x": icon_x_num,
            "plugin": "org.kde.plasma.icon",
            "title": "Feature Guide"
          },
          {
            "config": {
              "/": {
                "localPath": "/usr/share/applications/kfocus-help.desktop",
                "url": "file:///usr/share/applications/kfocus-help.desktop"
              }
            },
            "geometry.height": icon_ht_int,
            "geometry.width": icon_w_int,
            "geometry.y": icon_top_int + icon_space_int * 3,
            "geometry.x": icon_x_num,
            "plugin": "org.kde.plasma.icon",
            "title": "Help Documents"
          }
        ],
        // Keeping this config appears to enhance stability
        "config": {
          "/": {
            "formfactor": "0",
            "immutability": "1",
            "lastScreen": "0"
          },
          "/ConfigDialog": {
            "DialogHeight": "600",
            "DialogWidth": "800"
          },
          "/Configuration": {
            "PreloadWeight": "0"
          },
          "/General": {
            "pressToMoveHelp": "false",
            "showToolbox": "false",
            "sortMode": "-1"
          }
        }
      }
    ],
    "serializationFormatVersion": "1"
  };

  // Debug:
  // debug_str = ''
  //   + 'scale_key        : ' + scale_key       + '\n'
  //   + 'gridUnit         : ' + gridUnit        + '\n'
  //   + 'screen_w_px      : ' + screen_w_px     + '\n'
  //   + 'screen_h_px      : ' + screen_h_px     + '\n'
  //   + '===============\n'
  //   + 'screen_w_num     : ' + screen_w_num    + '\n'
  //   + 'screen_h_num     : ' + screen_h_num    + '\n'
  //   + '===============\n'
  //   + 'icon_padx_int    : ' + icon_padx_int   + '\n'
  //   + 'icon_top_int     : ' + icon_top_int    + '\n'
  //   + 'icon_space_int   : ' + icon_space_int  + '\n'
  //   + 'icon_w_int       : ' + icon_w_int      + '\n'
  //   + 'icon_ht_int      : ' + icon_ht_int     + '\n'
  //   + 'widget_padx_num  : ' + widget_padx_num + '\n'
  //   + 'widget_pady_num  : ' + widget_pady_num + '\n'
  //   + 'widget_w_px      : ' + widget_w_px     + '\n'
  //   + 'widget_h_px      : ' + widget_h_px     + '\n'
  //   + '===============\n'
  //   + 'widget_w_num     : ' + widget_w_num    + '\n'
  //   + 'widget_h_num     : ' + widget_h_num    + '\n'
  //   + 'widget_x_num     : ' + widget_x_num    + '\n'
  //   + 'widget_y_num     : ' + widget_y_num    + '\n'
  //   + 'icon_x_num       : ' + icon_x_num      + '\n'
  //   + '===============\n'
  //   + 'layout matrix    : \n'
  //   + JSON.stringify( layout_matrix, null, 2 ) + '\n\n'
  //   ;
  //
  // (A) https://api.kde.org/frameworks/plasma-framework/html/
  //       classPlasma_1_1Types.html#ab2b1c1767f3f432a0928dc7ca6b3f29e

  plasma_obj.loadSerializedLayout(layout_matrix);
  tweakWallpapersFn();
}
// . END setLayoutFn }

setLayoutFn();

// (1) See QRectF https://develop.kde.org/docs/extend/plasma/scripting/api/#screen-geometry
// (2) Scale ratio is 1.5 for HDPI 4k screens. This should reduce to 1 for a
//     1080p screen at 96dpi.


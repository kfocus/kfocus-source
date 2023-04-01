/*globals gridUnit, desktopsForActivity, currentActivity,
  getApiVersion, screenGeometry, loadTemplate */

loadTemplate("org.focusvert.desktop.defaultPanel");

var scaleMatrix = {
  large : {
    icon_table  : [
      { "h": 4, "w": 3, "y":  2 },
      { "h": 4, "w": 3, "y":  8 },
      { "h": 3, "w": 3, "y": 14 },
      { "h": 4, "w": 3, "y": 19 }
    ],
    icon_pad_int : 5,
    pad_h_int    : 1,
    pad_w_int    : 4, // Add width of 3 for vertical panel
    widget_h_px  : 994,
    widget_w_px  : 640
  },
  medium : {
    icon_table  : [
      { "h": 4, "w": 3, "y":  2 },
      { "h": 4, "w": 3, "y":  8 },
      { "h": 3, "w": 3, "y": 14 },
      { "h": 4, "w": 3, "y": 19 }
    ],
    icon_pad_int : 5,
    pad_h_int    : 1,
    pad_w_int    : 4,
    widget_h_px  : 796,
    widget_w_px  : 512
  },
  small : {
    icon_table  : [
      { "h": 4, "w": 3, "y":  2 },
      { "h": 4, "w": 3, "y":  8 },
      { "h": 3, "w": 3, "y": 14 },
      { "h": 4, "w": 3, "y": 19 }
    ],
    icon_pad_int : 5,
    pad_h_int    : 1,
    pad_w_int    : 4,
    widget_h_px  : 664,
    widget_w_px  : 428
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

function tweakWallpapersFn () {
  var desktop_list, j, desktop_obj;

  desktop_list = desktopsForActivity(currentActivity());
  for ( j = 0; j < desktop_list.length; j++) {
    desktop_obj = desktop_list[j];
    desktop_obj.wallpaperPlugin = 'org.kde.image';
    // plasma5 docs says this does nothing, yet it forces the
    // presentation of wallpapers in the rmb > Configure Desktop... dialog
    desktop_obj.wallpaperMode   = '2';
  }
}

function setLayoutFn () {
  var plasma_obj, rect_obj, screen_w_px, screen_h_px, screen_w_num,
    screen_h_num, scale_key, scale_map, icon_pad_int, pad_h_int, pad_w_int,
    widget_h_px, widget_w_px, widget_w_num, widget_h_num, widget_x_num,
    widget_y_num, icon_x_num, icon_table, layout_matrix;

  plasma_obj  = getApiVersion(1);
  rect_obj    = screenGeometry(0); // (1)

  screen_w_px  = rect_obj.right  - rect_obj.left;
  screen_h_px  = rect_obj.bottom - rect_obj.top;
  screen_w_num = screen_w_px / gridUnit;
  screen_h_num = screen_h_px / gridUnit;

  scale_key = ( screen_w_px >= 3200 && screen_h_px >= 1800 ) ? 'large'
    : (screen_w_px >= 2560 && screen_h_px >= 1440 ) ? 'medium' : 'small';
  scale_map = scaleMatrix[ scale_key ];

  icon_pad_int  = scale_map.icon_pad_int;
  pad_h_int     = scale_map.pad_h_int;
  pad_w_int     = scale_map.pad_w_int;
  widget_h_px   = scale_map.widget_h_px;
  widget_w_px   = scale_map.widget_w_px;

  widget_w_num = Math.round( widget_w_px / gridUnit );
  widget_h_num = Math.round( widget_h_px / gridUnit );
  widget_x_num = screen_w_num - widget_w_num - pad_w_int;
  widget_y_num = pad_h_int;
  icon_x_num   = widget_x_num - icon_pad_int;

  icon_table = scale_map.icon_table;

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
            "geometry.height": icon_table[0].h,
            "geometry.width": icon_table[0].w,
            "geometry.x": icon_x_num,
            "geometry.y": icon_table[0].y,
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
            "geometry.height": icon_table[1].h,
            "geometry.width": icon_table[1].w,
            "geometry.x": icon_x_num,
            "geometry.y": icon_table[1].y,
            "plugin": "org.kde.plasma.icon",
            "title": "Guided Solutions"
          },
          {
            "config": {
              "/": {
                "localPath": "/usr/share/applications/kfocus-help.desktop",
                "url": "file:///usr/share/applications/kfocus-help.desktop"
              }
            },
            "geometry.height": icon_table[2].h,
            "geometry.width": icon_table[2].w,
            "geometry.x": icon_x_num,
            "geometry.y": icon_table[2].y,
            "plugin": "org.kde.plasma.icon",
            "title": "Welcome Guide"
          },
          {
            "config": {
              "/": {
                "localPath": "/usr/share/applications/kfocus-support-welcome.desktop",
                "url": "file:///usr/share/applications/kfocus-support-welcome.desktop"
              }
            },
            "geometry.height": icon_table[3].h,
            "geometry.width": icon_table[3].w,
            "geometry.x": icon_x_num,
            "geometry.y": icon_table[3].y,
            "plugin": "org.kde.plasma.icon",
            "title": "Help"
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
  //   + 'scale_key        : ' + scale_key    + '\n'
  //   + 'gridUnit         : ' + gridUnit     + '\n'
  //   + 'screen_w_px      : ' + screen_w_px  + '\n'
  //   + 'screen_h_px      : ' + screen_h_px  + '\n'
  //   + '===============\n'
  //   + 'screen_w_num     : ' + screen_w_num + '\n'
  //   + 'screen_h_num     : ' + screen_h_num + '\n'
  //   + '===============\n'
  //   + 'widget_w_px      : ' + widget_w_px  + '\n'
  //   + 'widget_h_px      : ' + widget_h_px  + '\n'
  //   + '===============\n'
  //   + 'pad_h_int        : ' + pad_h_int    + '\n'
  //   + 'pad_w_int        : ' + pad_w_int    + '\n'
  //   + 'widget_w_num     : ' + widget_w_num + '\n'
  //   + 'widget_h_num     : ' + widget_h_num + '\n'
  //   + 'widget_x_num     : ' + widget_x_num + '\n'
  //   + 'widget_y_num     : ' + widget_y_num + '\n'
  //   + 'icon_x_num       : ' + icon_x_num   + '\n'
  //   + '===============\n'
  //   + 'icon_table       : \n'
  //   + JSON.stringify( icon_table, null, 2 ) + '\n\n'
  //   + 'layout matrix    : \n'
  //   + JSON.stringify( layout_matrix, null, 2 ) + '\n\n'
  //   ;
  //
  // (A) https://api.kde.org/frameworks/plasma-framework/html/
  //       classPlasma_1_1Types.html#ab2b1c1767f3f432a0928dc7ca6b3f29e

  plasma_obj.loadSerializedLayout(layout_matrix);
  tweakWallpapersFn();
}
setLayoutFn();

// (1) See QRectF https://develop.kde.org/docs/extend/plasma/scripting/api/#screen-geometry
// (2) Scale ratio is 1.5 for HDPI 4k screens. This should reduce to 1 for a
//     1080p screen at 96dpi.


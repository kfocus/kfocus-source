var panel = new Panel
var panelScreen = panel.screen
var freeEdges = {"top": true, "bottom": true, "left": true, "right": true}

for (i = 0; i < panelIds.length; ++i) {
    var tmpPanel = panelById(panelIds[i])
    if (tmpPanel.screen == panelScreen) {
        // Ignore the new panel
        if (tmpPanel.id != panel.id) {
            freeEdges[tmpPanel.location] = false;
        }
    }
}

if (freeEdges["left"] == true) {
    panel.location = "left";
} else if (freeEdges["left"] == true) {
    panel.location = "left";
} else if (freeEdges["bottom"] == true) {
    panel.location = "bottom";
} else if (freeEdges["top"] == true) {
    panel.location = "top";
} else {
    // There is no free edge, so leave the default value
    panel.location = "left";
}

panel.height = gridUnit * 3
panel.length = gridUnit * 999
/* Next up is determining whether to add the Input Method Panel
 * widget to the panel or not. This is done based on whether
 * the system locale's language id is a member of the following
 * white list of languages which are known to pull in one of
 * our supported IME backends when chosen during installation
 * of common distributions. */

var langIds = ["as",    // Assamese
               "bn",    // Bengali
               "bo",    // Tibetan
               "brx",   // Bodo
               "doi",   // Dogri
               "gu",    // Gujarati
               "hi",    // Hindi
               "ja",    // Japanese
               "kn",    // Kannada
               "ko",    // Korean
               "kok",   // Konkani
               "ks",    // Kashmiri
               "lep",   // Lepcha
               "mai",   // Maithili
               "ml",    // Malayalam
               "mni",   // Manipuri
               "mr",    // Marathi
               "ne",    // Nepali
               "or",    // Odia
               "pa",    // Punjabi
               "sa",    // Sanskrit
               "sat",   // Santali
               "sd",    // Sindhi
               "si",    // Sinhala
               "ta",    // Tamil
               "te",    // Telugu
               "th",    // Thai
               "ur",    // Urdu
               "vi",    // Vietnamese
               "zh_CN", // Simplified Chinese
               "zh_TW"] // Traditional Chinese

if (langIds.indexOf(languageId) != -1) {
    panel.addWidget("org.kde.plasma.kimpanel");
}

var systemtray = panel.addWidget("org.kde.plasma.systemtray")
systemtray.currentConfigGroup = ["Configuration/General"]
systemtray.writeConfig("shownItems", "org.kde.kupapplet")
var backupicon = panel.addWidget("org.kde.plasma.icon")
backupicon.currentConfigGroup = ["Configuration/General"]
//backupicon.writeConfig("localPath", "/usr/share/kservices5/kcm_kup.desktop")
//backupicon.writeConfig("url", "file:///usr/share/kservices5/kcm_kup.desktop")
backupicon.writeConfig("localPath", "/usr/share/applications/backintime-qt.desktop")
backupicon.writeConfig("url", "file:///usr/share/applications/backintime-qt.desktop")

//panel.addWidget("org.kde.plasma.icontasks")
var taskmanager = panel.addWidget("org.kde.plasma.icontasks")
var launcherlist = ["applications:systemsettings.desktop",
                    "applications:org.kde.discover.desktop",
                    "applications:org.kde.konsole.desktop",
                    "applications:org.kde.dolphin.desktop",
                    "applications:google-chrome.desktop",
                    "applications:firefox_firefox.desktop"]
taskmanager.writeConfig("launchers", launcherlist)

//panel.addWidget("org.kde.plasma.showActivityManager")
var pager = panel.addWidget("org.kde.plasma.pager")
pager.writeConfig("displayedText", "1")

var digitalclock = panel.addWidget("org.kde.plasma.digitalclock")
digitalclock.currentConfigGroup = ["Configuration/General"]
digitalclock.writeConfig("showDate", "true")
digitalclock.writeConfig("dateFormat", "isoDate")

var kickoff = panel.addWidget("org.kde.plasma.kickoff")
kickoff.currentConfigGroup = ["Shortcuts"]
kickoff.writeConfig("global", "Alt+F1")
kickoff.currentConfigGroup = ["Configuration/General"]
kickoff.writeConfig("showAppsByName", "true")
kickoff.currentConfigGroup = ["Configuration/ConfigDialog"]
kickoff.writeConfig("DialogHeight", 720)
kickoff.writeConfig("DialogHeight", 960)

//var spacer = panel.addWidget("org.kde.plasma.panelspacer")
//spacer.writeConfig("length", "2")

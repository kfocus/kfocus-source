#!/usr/bin/env python3

import argparse, subprocess, sys
#import subprocess
#import argparse
from PyQt6.QtCore import Qt, QTimer
# Later from PyQt6.QtGui:  QPalette, QColor, QCursor,
from PyQt6.QtGui import QIcon, QGuiApplication
from PyQt6.QtWidgets import (
    QApplication,
    QCheckBox,
    QDialog,
    QHBoxLayout,
    QLabel,
    QPushButton,
    QVBoxLayout,
)

class UltraStrictDialog(QDialog):
    def __init__(self,
                 cancel_label,
                 checkbox_label,
                 message_html,
                 ok_label,
                 wait_sec,
                 window_title,
                 ):
        super().__init__()
        # Store variables passed via arguments
        self.timer = QTimer(self)
        self.btn_cancel = None
        self.btn_ok     = None
        self.checkbox   = None
        self.msg_label  = None
        self.original_checkbox_label = None

        # Strip leading and ending quotes passed by the shell
        self.cancel_label   = cancel_label.strip("'\"")
        self.countdown_left = int(wait_sec)
        self.checkbox_label = checkbox_label.strip("'\"")
        self.message_html   = message_html.strip("'\"")
        self.ok_label       = ok_label.strip("'\"")
        self.window_title   = window_title.strip("'\"")

        self.init_ui()

    def init_ui(self):
        self.setWindowTitle(self.window_title)

        # Apply an elegant dark theme stylesheet with custom padding around
        # the whole dialog content
        # self.setStyleSheet("""
        #     QDialog {
        #         /* background-color: #1e1e24; */
        #     }
        #     QLabel {
        #         font-family: 'Nimbus Sans', sans-serif;
        #         font-size: 14px;
        #     }
        #     QCheckBox {
        #         color: #dde4e9;
        #         font-size: 13px;
        #         padding: 10px;
        #     }
        #     QPushButton {
        #         background-color: #2b2b36;
        #         color: #ffffff;
        #         border: 1px solid #3f3f50;
        #         border-radius: 4px;
        #         padding: 6px 20px;
        #         min-width: 80px;
        #         font-size: 13px;
        #     }
        #     QPushButton:hover {
        #         background-color: #3a3a4a;
        #     }
        #     QPushButton:disabled {
        #         background-color: #18181c;
        #         color: #55555c;
        #         border: 1px solid #25252b;
        #     }
        # """)

        # Window Flags: Strip window controls and force Stay On Top
        self.setWindowFlags(
            Qt.WindowType.Window
            | Qt.WindowType.CustomizeWindowHint
            | Qt.WindowType.WindowTitleHint
            | Qt.WindowType.WindowStaysOnTopHint
        )

        # Content Layout
        layout = QVBoxLayout()
        layout.setContentsMargins(25, 10, 25, 10)
        layout.setSpacing(15) # Spacing between vertical elements

        # Message Body Text configured as an HTML Label
        # Replacing literal "\n" strings with HTML line breaks if present
        #   content = self.message_html.replace('\\n', '<br>')
        self.msg_label = QLabel()
        self.msg_label.setTextFormat(Qt.TextFormat.RichText)
        self.msg_label.setText(self.message_html)
        self.msg_label.setWordWrap(True) # Allows word-wrapping for dynamic text expansion
        self.msg_label.setAlignment(Qt.AlignmentFlag.AlignLeft)
        layout.addWidget(self.msg_label)

        # Required Checkbox
        self.checkbox = QCheckBox(self.checkbox_label)
        self.checkbox.setFocusPolicy(Qt.FocusPolicy.NoFocus)
        self.checkbox.stateChanged.connect(self.toggle_buttons)
        layout.addWidget(self.checkbox, alignment=Qt.AlignmentFlag.AlignCenter)

        # Create Action Buttons
        btn_layout = QHBoxLayout()
        btn_layout.addStretch()
        # btn_layout.setSpacing(10)
        self.btn_ok = QPushButton(self.ok_label)
        self.btn_ok.setIcon(QIcon.fromTheme("dialog-ok-symbolic"))

        self.btn_cancel = QPushButton(self.cancel_label)
        self.btn_cancel.setIcon(QIcon.fromTheme("dialog-cancel-symbolic"))

        # Disable all default keyboard and focus behavior
        for btn in (self.btn_ok, self.btn_cancel):
            btn.setAutoDefault(False)
            btn.setDefault(False)
            btn.setFocusPolicy(Qt.FocusPolicy.NoFocus)

        # Buttons and Checkbox start DISABLED until the timer completes
        self.btn_ok.setEnabled(False)
        self.btn_cancel.setEnabled(False)

        btn_layout.addWidget(self.btn_ok)
        btn_layout.addWidget(self.btn_cancel)
        layout.addLayout(btn_layout)
        self.setLayout(layout)

        # Connect click events
        self.btn_ok.clicked.connect(self.accept)
        self.btn_cancel.clicked.connect(self.reject)

        # Configure Countdown Timer if requested
        if self.countdown_left > 0:
            self.checkbox.setEnabled(False)
            self.original_checkbox_label = self.checkbox_label
            self.checkbox.setText(f"{self.original_checkbox_label} (Wait {self.countdown_left}s)")

            self.timer.timeout.connect(self.update_countdown)
            self.timer.start(1000) # Trigger every 1 second
        else:
            self.checkbox.setEnabled(True)

        # Enforce dynamic window sizing based on internal layout constraints
        self.adjustSize()
        # Keep layout strict and prevent manual user stretching/shrinking resizing
        self.setFixedSize(self.size())

        # Center the window on the active monitor screen
        self.center_window()

        # Alert the user with a system sound upon creation
        self.sound_alert()

    def center_window(self):
        # Grab the primary screen geometry safely
        screen = QGuiApplication.primaryScreen()
        if not screen:
            return

        screen_geometry = screen.geometry()

        # Calculate top-left point to center the fixed-size dialog
        x = screen_geometry.x() + (screen_geometry.width() - self.width()) // 2
        y = screen_geometry.y() + (screen_geometry.height() - self.height()) // 2

        self.move(x, y)

    @staticmethod
    def sound_alert():
        try:
            # Try PulseAudio player first using a standard system alert path
            subprocess.Popen(
                ["paplay", "/usr/share/sounds/freedesktop/stereo/dialog-warning.oga"],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
            )
        except FileNotFoundError:
            # noinspection PyBroadException
            try:
                # Fallback for newer PipeWire-native platforms
                subprocess.Popen(
                    ["pw-play", "/usr/share/sounds/freedesktop/stereo/dialog-warning.oga"],
                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
                )
            except Exception:
                pass # Completely silent fallback if sound engines are not running

    def update_countdown(self):
        self.countdown_left -= 1
        if self.countdown_left > 0:
            self.checkbox.setText(f"{self.original_checkbox_label} (Wait {self.countdown_left}s)")
        else:
            self.timer.stop()
            self.checkbox.setText(self.original_checkbox_label)
            self.checkbox.setEnabled(True) # Unlock the checkbox completely

    def toggle_buttons(self, state):
        is_checked = (state == 2)
        self.btn_ok.setEnabled(is_checked)
        self.btn_cancel.setEnabled(is_checked)

    # Intercept window state changes and overrides requests to minimize
    def changeEvent(self, event, **kwargs):
        if event.type() == event.Type.WindowStateChange:
            if self.windowState() & Qt.WindowState.WindowMinimized:
                self.setWindowState(self.windowState() & ~Qt.WindowState.WindowMinimized | Qt.WindowState.WindowActive)
                self.raise_()
                self.activateWindow()
        super().changeEvent(event)

    @staticmethod
    def closeEvent(event, **kwargs):
        event.ignore()

    def keyPressEvent(self, event, **kwargs):
        if event.key() in (Qt.Key.Key_Return, Qt.Key.Key_Enter, Qt.Key.Key_Escape):
            event.ignore()
        else:
            super().keyPressEvent(event)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Strict PyQt6 HTML Dialog")
    parser.add_argument(
        '--cancel-label', type=str, default="Cancel",
        help="Label for the cancel button"
    )
    parser.add_argument(
        '--checkbox-label', type=str, default="Read and agreed",
        help="Label for required checkbox"
    )
    parser.add_argument(
        '--message-html', type=str, required=True,
        help="Main HTML formatted message body"
    )
    parser.add_argument(
        '--ok-label', type=str, default="OK",
        help="Label for the confirm button"
    )
    parser.add_argument(
        '--wait_sec', type=int, default=5,
        help="Seconds to freeze checkbox interaction"
    )
    parser.add_argument(
        '--window-title', type=str, default="Notice",
        help="The title bar text"
    )
    args = parser.parse_args()

    app = QApplication(sys.argv)
    dialog = UltraStrictDialog(
        cancel_label   = args.cancel_label,
        checkbox_label = args.checkbox_label,
        message_html   = args.message_html,
        ok_label       = args.ok_label,
        wait_sec       = args.wait_sec,
        window_title   = args.window_title,
    )
    result = dialog.exec()

    if result == QDialog.DialogCode.Accepted:
        sys.exit(0)
    else:
        sys.exit(1)


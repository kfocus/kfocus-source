#!/usr/bin/python3
#
# Copyright 2016-2026 MindShare Inc.
# Written for Kubuntu Focus by A. Rainbolt and M. Mikowski.
#
# Name    : kfocus_strict_dialog.py
# Purpose : Present dialogs to the user that are hard to dismiss without
#         : reading.
# License : GPL v2
# Run By  : Users
# Spec    : 6805
#
# no-member has to be disabled because pylint cannot see a lot of the members
# defined by PyQt5. Remove this override for PyQt6.
# pylint: disable=no-member

"""
A partial KDialog reimplementation that is harder to ignore.
"""

import argparse
import functools
import signal
import sys
from pathlib import Path
from types import FrameType
from typing import NoReturn

from PyQt5.QtCore import (
    pyqtSignal,
    Qt,
    QTimer,
    QUrl,
)
from PyQt5.QtGui import (
    QCloseEvent,
    QIcon,
)
from PyQt5.QtWidgets import (
    QApplication,
    QCheckBox,
    QDialog,
    QFrame,
    QHBoxLayout,
    QLabel,
    QPushButton,
    QSpacerItem,
    QVBoxLayout,
    QWidget,
)
from PyQt5.QtMultimedia import (
    QMediaContent,
    QMediaPlayer,
)


# pylint: disable=too-many-instance-attributes
class StrictBaseDialog(QDialog):
    """
    Core UI components shared by all child dialogs.
    """

    confirm_timeout_expired: pyqtSignal = pyqtSignal()

    # pylint: disable=too-many-arguments, too-many-positional-arguments, too-many-statements
    def __init__(
        self,
        win_icon_name: str | None,
        win_title: str,
        body_icon_name: str | None,
        body_text: str,
        confirm_checkbox_text: str,
        confirm_timeout: int,
        notification_sound_name: str,
        parent: QWidget | None = None,
    ) -> None:
        super().__init__(parent)

        self.setWindowFlags(
            Qt.WindowType.Window  # type: ignore
            | Qt.WindowType.CustomizeWindowHint
            | Qt.WindowType.WindowTitleHint
            | Qt.WindowType.WindowStaysOnTopHint
        )

        if win_icon_name is not None:
            self.setWindowIcon(QIcon.fromTheme(win_icon_name))
        self.setWindowTitle(win_title)

        self.core_layout: QVBoxLayout = QVBoxLayout()

        self.body_icon_label: QLabel = QLabel()
        if body_icon_name is not None:
            self.body_icon_label.setPixmap(
                QIcon.fromTheme(body_icon_name).pixmap(64, 64)
            )
        self.body_text_label: QLabel = QLabel(body_text)
        self.body_text_label.setWordWrap(True)
        self.body_text_label.setOpenExternalLinks(True)

        self.text_area_layout: QHBoxLayout = QHBoxLayout()
        self.text_area_layout.setContentsMargins(20, 5, 20, 0)
        self.text_area_layout.addStretch()
        # Can't use Qt.AlignmentFlag.AlignTop due to a Qt bug.
        self.body_icon_label_layout: QVBoxLayout = QVBoxLayout()
        self.body_icon_label_layout.addWidget(self.body_icon_label)
        self.body_icon_label_layout.addStretch()
        self.text_area_layout.addLayout(self.body_icon_label_layout)

        self.icon_spacer: QSpacerItem = QSpacerItem(5, 0)
        self.text_area_layout.addItem(self.icon_spacer)

        self.body_text_label_layout: QVBoxLayout = QVBoxLayout()
        self.body_text_label_layout.addWidget(self.body_text_label)
        self.body_text_label_layout.addStretch()
        self.text_area_layout.addLayout(self.body_text_label_layout)
        self.text_area_layout.addStretch()
        self.core_layout.addLayout(self.text_area_layout)

        self.confirm_timeout: int = confirm_timeout
        self.confirm_checkbox: QCheckBox | None = None
        if confirm_checkbox_text != "":
            self.confirm_checkbox_layout: QHBoxLayout = QHBoxLayout()
            self.confirm_checkbox_layout.addStretch()
            self.confirm_checkbox = QCheckBox(confirm_checkbox_text)
            if self.confirm_timeout > 0:
                self.confirm_checkbox.setEnabled(False)
                self.confirm_timeout_expired.connect(
                    functools.partial(self.confirm_checkbox.setEnabled, True)
                )
            self.confirm_checkbox_layout.addWidget(self.confirm_checkbox)
            self.confirm_checkbox_layout.addStretch()
            self.core_layout.addLayout(self.confirm_checkbox_layout)

        self.confirm_timer: QTimer = QTimer()
        self.confirm_timer.setInterval(1000)
        self.confirm_timer.timeout.connect(self.decrement_confirm_timeout)
        self.confirm_timer.start()

        self.checkbox_spacer: QSpacerItem = QSpacerItem(0, 8)
        self.core_layout.addItem(self.checkbox_spacer)

        self.separator_line: QFrame = QFrame()
        self.separator_line.setFrameStyle(
            QFrame.Shape.HLine | QFrame.Shadow.Plain
        )
        self.core_layout.addWidget(self.separator_line)

        self.setLayout(self.core_layout)

        self.media_player: QMediaPlayer | None = None
        self.notification_sound_path_str: str | None = (
            self.get_notification_sound_path(notification_sound_name)
        )
        if self.notification_sound_path_str is not None:
            self.media_player = QMediaPlayer()
            self.media_player.setMedia(
                QMediaContent(
                    QUrl.fromLocalFile(self.notification_sound_path_str)
                )
            )
            self.media_player.setVolume(100)

        # Buttons are defined by child classes.

    def get_notification_sound_path(self, sound_name: str) -> str | None:
        """
        Gets the path to a sound file for the given sound name. Implementation
        is non-ideal but a better method is not yet known.
        """

        ocean_sound_path: Path = Path(
            "/usr/share/sounds/ocean/stereo/" + sound_name + ".oga"
        )
        if ocean_sound_path.is_file():
            return str(ocean_sound_path)

        oxygen_sound_path: Path | None = None
        match sound_name:
            case "dialog-information":
                oxygen_sound_path = Path(
                    "/usr/share/sounds/Oxygen-Sys-App-Message.ogg"
                )
            case "dialog-warning":
                oxygen_sound_path = Path(
                    "/usr/share/sounds/Oxygen-Sys-Warning.ogg"
                )
            case "dialog-error":
                oxygen_sound_path = Path(
                    "/usr/share/sounds/Oxygen-Sys-App-Error-Critical.ogg"
                )
            case "dialog-question":
                oxygen_sound_path = Path(
                    "/usr/share/sounds/Oxygen-Sys-Question.ogg"
                )
        if oxygen_sound_path is not None and oxygen_sound_path.is_file():
            return str(oxygen_sound_path)

        freedesktop_sound_path: Path
        match sound_name:
            case "dialog-question":
                freedesktop_sound_path = Path(
                    "/usr/share/sounds/freedesktop/stereo/window-question.oga"
                )
            case _:
                freedesktop_sound_path = Path(
                    "/usr/share/sounds/freedesktop/stereo/"
                    + sound_name
                    + ".oga"
                )
        if freedesktop_sound_path.is_file():
            return str(freedesktop_sound_path)

        return None

    def get_confirm_timeout_str(self) -> str:
        """
        Gets a string displaying the confirm timeout seconds remaining.
        """

        if self.confirm_timeout > 0:
            return f"{self.confirm_timeout}s"
        return ""

    def decrement_confirm_timeout(self) -> None:
        """
        Decrements the checkbox timeout and recalculates text for the confirm
        checkbox. Also stops the timer and enables the confirm checkbox if the
        timeout hits 0.
        """

        self.confirm_timeout -= 1
        if self.confirm_timeout == 0:
            self.confirm_timer.stop()
            # self.confirm_checkbox.setEnabled(True)
            self.confirm_timeout_expired.emit()

    def play_notification_sound(self) -> None:
        """
        Plays the notification sound.
        """

        if self.media_player is not None:
            self.media_player.play()

    # pylint: disable=invalid-name
    def closeEvent(self, event: QCloseEvent | None) -> None:
        """
        Ignores close events.
        """

        if event is None:
            return
        event.ignore()


class StrictOkDialog(StrictBaseDialog):
    """
    A strict dialog with a single OK button.
    """

    # pylint: disable=too-many-arguments, too-many-positional-arguments
    def __init__(
        self,
        win_icon_name: str | None,
        win_title: str,
        body_icon_name: str | None,
        body_text: str,
        confirm_checkbox_text: str,
        confirm_timeout: int,
        notification_sound_name: str,
        ok_button_text: str,
        parent: QWidget | None = None,
    ) -> None:
        super().__init__(
            win_icon_name,
            win_title,
            body_icon_name,
            body_text,
            confirm_checkbox_text,
            confirm_timeout,
            notification_sound_name,
            parent,
        )

        self.button_layout: QHBoxLayout = QHBoxLayout()

        self.confirm_timeout_label: QLabel = QLabel(
            self.get_confirm_timeout_str()
        )
        # "Disabling" this label doesn't do anything but change the color.
        self.confirm_timeout_label.setEnabled(False)
        self.button_layout.addWidget(self.confirm_timeout_label)
        self.confirm_timer.timeout.connect(self.refresh_confirm_timeout_label)

        self.button_layout.addStretch()

        self.ok_button: QPushButton = QPushButton(
            QIcon.fromTheme("dialog-ok"), ok_button_text
        )
        self.ok_button.clicked.connect(functools.partial(self.done, 0))
        if self.confirm_timeout > 0 or self.confirm_checkbox is not None:
            self.ok_button.setEnabled(False)
        self.button_layout.addWidget(self.ok_button)

        self.core_layout.addLayout(self.button_layout)
        self.adjustSize()

        if self.confirm_checkbox is None:
            self.confirm_timeout_expired.connect(
                functools.partial(self.ok_button.setEnabled, True)
            )
        else:
            self.confirm_checkbox.stateChanged.connect(
                self.confirm_checkbox_state_changed
            )

    # pylint: disable=unused-argument
    def confirm_checkbox_state_changed(self, state_int: int) -> None:
        """
        Toggles usability of the OK button based on the confirm checkbox state.
        """

        assert self.confirm_checkbox is not None
        if self.confirm_checkbox.isChecked():
            self.ok_button.setEnabled(True)
        else:
            self.ok_button.setEnabled(False)

    def refresh_confirm_timeout_label(self) -> None:
        """
        Sets the confirm timeout label's text to the current timeout string.
        """

        self.confirm_timeout_label.setText(self.get_confirm_timeout_str())


class StrictYesNoDialog(StrictBaseDialog):
    """
    A strict dialog with yes and no buttons.
    """

    # pylint: disable=too-many-arguments, too-many-positional-arguments
    def __init__(
        self,
        win_icon_name: str | None,
        win_title: str,
        body_icon_name: str | None,
        body_text: str,
        confirm_checkbox_text: str,
        confirm_timeout: int,
        notification_sound_name: str,
        yes_button_text: str,
        no_button_text: str,
        parent: QWidget | None = None,
    ):
        super().__init__(
            win_icon_name,
            win_title,
            body_icon_name,
            body_text,
            confirm_checkbox_text,
            confirm_timeout,
            notification_sound_name,
            parent,
        )

        self.button_layout: QHBoxLayout = QHBoxLayout()

        self.confirm_timeout_label: QLabel = QLabel(
            self.get_confirm_timeout_str()
        )
        # "Disabling" this label doesn't do anything but change the color.
        self.confirm_timeout_label.setEnabled(False)
        self.button_layout.addWidget(self.confirm_timeout_label)
        self.confirm_timer.timeout.connect(self.refresh_confirm_timeout_label)

        self.button_layout.addStretch()

        self.yes_button: QPushButton = QPushButton(
            QIcon.fromTheme("dialog-ok"), yes_button_text
        )
        self.no_button: QPushButton = QPushButton(
            QIcon.fromTheme("dialog-cancel"), no_button_text
        )
        self.yes_button.clicked.connect(functools.partial(self.done, 0))
        self.no_button.clicked.connect(functools.partial(self.done, 1))
        if self.confirm_timeout > 0 or self.confirm_checkbox is not None:
            self.yes_button.setEnabled(False)
            self.no_button.setEnabled(False)
        self.button_layout.addWidget(self.yes_button)
        self.button_layout.addWidget(self.no_button)

        self.core_layout.addLayout(self.button_layout)
        self.adjustSize()

        if self.confirm_checkbox is None:
            self.confirm_timeout_expired.connect(
                functools.partial(self.yes_button.setEnabled, True)
            )
            self.confirm_timeout_expired.connect(
                functools.partial(self.no_button.setEnabled, True)
            )
        else:
            self.confirm_checkbox.stateChanged.connect(
                self.confirm_checkbox_state_changed
            )

    # pylint: disable=unused-argument
    def confirm_checkbox_state_changed(self, state_int: int) -> None:
        """
        Toggles usability of the Yes and No buttons based on the confirm
        checkbox state.
        """

        assert self.confirm_checkbox is not None
        if self.confirm_checkbox.isChecked():
            self.yes_button.setEnabled(True)
            self.no_button.setEnabled(True)
        else:
            self.yes_button.setEnabled(False)
            self.no_button.setEnabled(False)

    def refresh_confirm_timeout_label(self) -> None:
        """
        Sets the confirm timeout label's text to the current timeout string.
        """

        self.confirm_timeout_label.setText(self.get_confirm_timeout_str())


# pylint: disable=unused-argument
def signal_handler(sig: int, frame: FrameType | None) -> None:
    """
    Handles SIGINT and SIGTERM.
    """

    sys.exit(128 + sig)


# pylint: disable=too-many-statements, too-many-locals
def main() -> NoReturn:
    """
    Entry point.
    """

    # pylint: disable=unused-variable
    app: QApplication = QApplication(sys.argv)

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    signal_timer: QTimer = QTimer()
    signal_timer.start(500)
    signal_timer.timeout.connect(lambda: None)

    win_icon_name: str | None = None
    win_title: str | None = None
    body_icon_name: str | None = None
    body_text: str | None = None
    confirm_checkbox_text: str | None = None
    confirm_timeout: int | None = None
    notification_sound_name: str | None = None
    ok_button_text: str | None = None
    yes_button_text: str | None = None
    no_button_text: str | None = None

    arg_parser: argparse.ArgumentParser = argparse.ArgumentParser(
        prog="kfocus-strict-dialog",
        description=(
            "A partial KDialog reimplementation that is harder to ignore."
        ),
    )
    arg_parser.add_argument(
        "--icon",
        type=str,
        metavar="ICON_NAME",
        help="The name of the icon to display on the window.",
        default="kfocus-bug-rx",
    )
    arg_parser.add_argument(
        "--title",
        type=str,
        metavar="WIN_TITLE",
        help="The string to display in the window titlebar.",
        default="FocusRx",
    )
    arg_parser.add_argument(
        "--confirm-check-label",
        type=str,
        metavar="LABEL_STR",
        help=(
            "The string to display on the confirmation checkbox. If omitted "
            + "or blank, no confirm checkbox is shown."
        ),
        default="",
    )
    arg_parser.add_argument(
        "--confirm-timeout",
        type=int,
        metavar="TIMEOUT_INT",
        help=(
            "How many seconds to make the user wait before they may proceed "
            + "through the window. If omitted, zero, or less than zero, no "
            + "timeout is enforced."
        ),
        default=0,
    )
    arg_parser.add_argument(
        "--msgbox",
        type=str,
        metavar="BODY_TEXT",
        help=(
            "Display an informational single-button dialog with the specified "
            + "body text."
        ),
    )
    arg_parser.add_argument(
        "--sorry",
        type=str,
        metavar="BODY_TEXT",
        help=(
            "Display an warning single-button dialog with the specified body "
            + "text."
        ),
    )
    arg_parser.add_argument(
        "--error",
        type=str,
        metavar="BODY_TEXT",
        help=(
            "Display an error single-button dialog with the specified body "
            + "text."
        ),
    )
    arg_parser.add_argument(
        "--yesno",
        type=str,
        metavar="BODY_TEXT",
        help=(
            "Display an inquisitive yes/no dialog with the specified body "
            + "text."
        ),
    )
    arg_parser.add_argument(
        "--warningyesno",
        type=str,
        metavar="BODY_TEXT",
        help="Display a warning yes/no dialog with the specified body text.",
    )
    arg_parser.add_argument(
        "--ok-label",
        type=str,
        metavar="LABEL_STR",
        help=(
            "The text to display on the 'OK' button of a single-button dialog."
        ),
        default="OK",
    )
    arg_parser.add_argument(
        "--yes-label",
        type=str,
        metavar="LABEL_STR",
        help="The text to display on the 'Yes' button of a yes/no dialog.",
        default="Yes",
    )
    arg_parser.add_argument(
        "--no-label",
        type=str,
        metavar="LABEL_STR",
        help="The text to display on the 'No' button of a yes/no dialog.",
        default="No",
    )
    args: argparse.Namespace = arg_parser.parse_args()

    win_icon_name = args.icon
    win_title = args.title
    confirm_checkbox_text = args.confirm_check_label
    confirm_timeout = args.confirm_timeout
    ok_button_text = args.ok_label
    yes_button_text = args.yes_label
    no_button_text = args.no_label

    if args.msgbox is not None:
        body_text = args.msgbox
        body_icon_name = "dialog-information"
        notification_sound_name = "dialog-information"
    elif args.sorry is not None:
        body_text = args.sorry
        body_icon_name = "dialog-warning"
        notification_sound_name = "dialog-warning"
    elif args.error is not None:
        body_text = args.error
        body_icon_name = "dialog-error"
        notification_sound_name = "dialog-error"
    elif args.yesno is not None:
        body_text = args.yesno
        body_icon_name = "dialog-question"
        notification_sound_name = "dialog-question"
    elif args.warningyesno is not None:
        body_text = args.warningyesno
        body_icon_name = "dialog-warning"
        notification_sound_name = "dialog-warning"

    if any(x is not None for x in [args.msgbox, args.sorry, args.error]):
        assert body_text is not None
        assert body_icon_name is not None
        assert notification_sound_name is not None
        ok_dialog: StrictOkDialog = StrictOkDialog(
            win_icon_name,
            win_title,
            body_icon_name,
            body_text,
            confirm_checkbox_text,
            confirm_timeout,
            notification_sound_name,
            ok_button_text,
        )
        ok_dialog.play_notification_sound()
        ok_dialog.exec()
        sys.exit(0)
    elif any(x is not None for x in [args.yesno, args.warningyesno]):
        assert body_text is not None
        assert body_icon_name is not None
        assert notification_sound_name is not None
        yes_no_dialog: StrictYesNoDialog = StrictYesNoDialog(
            win_icon_name,
            win_title,
            body_icon_name,
            body_text,
            confirm_checkbox_text,
            confirm_timeout,
            notification_sound_name,
            yes_button_text,
            no_button_text,
        )
        yes_no_dialog.play_notification_sound()
        yes_no_dialog.exec()
        sys.exit(yes_no_dialog.result())
    else:
        print("ERROR: No body text argument provided.", file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()

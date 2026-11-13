#!/usr/bin/python3

# SPDX-FileCopyrightText: 2026 - 2026 Kubuntu Contributors <kubuntu-devel@lists.ubuntu.com>
# SPDX-License-Identifier: GPL-3.0

"""
kubuntu_contribute.py: Shows a dialog informing the user how to donate
or otherwise contribute to Kubuntu.
"""

import sys
import signal
import argparse
from enum import Enum
from typing import NoReturn
from types import FrameType

from PyQt6.QtCore import (
    Qt,
    QTimer,
    QUrl,
)
from PyQt6.QtGui import (
    QIcon,
    QDesktopServices,
    QPalette,
)
from PyQt6.QtWidgets import (
    QApplication,
    QDialog,
    QGridLayout,
    QHBoxLayout,
    QLabel,
    QPushButton,
    QSizePolicy,
    QVBoxLayout,
    QWidget,
)


class ThemedColor(Enum):
    """
    Supported colors for the themed color getter.
    """

    BLUE = 1
    #GREEN = 2
    #RED = 3


def get_themed_color(color: ThemedColor) -> str:
    """
    Gets a color value corresponding to the requested ThemedColor that matches
    the system's color scheme somewhat.
    """

    light_theme: bool = QApplication.palette().color(
        QPalette.ColorGroup.Normal, QPalette.ColorRole.Text
    ).value() < 128

    if light_theme:
        match color:
            case ThemedColor.BLUE:
                return "#ecf6fc"
            #case ThemedColor.GREEN:
            #    return "#ddfbe8"
            #case ThemedColor.RED:
            #    return "#faeced"
    else:
        match color:
            case ThemedColor.BLUE:
                return "#122b38"
            #case ThemedColor.GREEN:
            #    return "#0d2c1b"
            #case ThemedColor.RED:
            #    return "#3c161a"


# pylint: disable=too-many-instance-attributes
class ContributeDialog(QDialog):
    """
    Points the user at any of three ways of contributing.
    """

    # pylint: disable=too-many-statements
    def __init__(self, parent: QWidget | None = None):
        super().__init__(parent)

        self.resize(524, 425)
        self.setMinimumWidth(524)
        self.setMinimumHeight(425)
        self.setWindowTitle("Contribute to Kubuntu")

        self.core_layout: QVBoxLayout = QVBoxLayout()
        self.contribute_header: QLabel = QLabel(
            "<h1>Contribute to Kubuntu</h1>"
        )
        self.contribute_header.setAlignment(Qt.AlignmentFlag.AlignHCenter)
        self.contribute_header.setContentsMargins(0, 0, 0, 10)
        self.core_layout.addWidget(self.contribute_header)

        self.content_grid: QGridLayout = QGridLayout()
        self.kubuntu_logo: QLabel = QLabel()
        self.kubuntu_logo.setPixmap(
            QIcon.fromTheme("vcs-added").pixmap(96, 96)
        )
        self.kubuntu_logo.setContentsMargins(16, 0, 16, 16)
        self.kubuntu_logo.setAlignment(
            Qt.AlignmentFlag.AlignHCenter | Qt.AlignmentFlag.AlignTop
        )
        self.content_grid.addWidget(self.kubuntu_logo, 0, 0, 1, 1)

        self.desc_label: QLabel = QLabel("""\
<p>Kubuntu exists today thanks to the support of numerous donors and
contributors around the world. You can support us in several ways:</p>""")
        self.desc_label.setWordWrap(True)
        self.desc_label.setContentsMargins(8, 0, 0, 16)
        self.content_grid.addWidget(self.desc_label, 0, 1, 1, 1)

        self.donate_button: QPushButton = QPushButton(
            QIcon.fromTheme("donate-symbolic"), "Donate"
        )
        self.donate_button.setContentsMargins(0, 0, 0, 8)
        self.donate_button.setStyleSheet(
            f"background-color: {get_themed_color(ThemedColor.BLUE)}"
        )
        self.donate_button.clicked.connect(self.donate_clicked)
        self.content_grid.addWidget(
            self.donate_button, 1, 0, 1, 1, Qt.AlignmentFlag.AlignTop
        )

        self.donate_label: QLabel = QLabel("""\
<p>Your donation helps sustain Kubuntu and make it even better for users around
the world.</p>""")
        self.donate_label.setWordWrap(True)
        self.donate_label.setContentsMargins(8, 0, 0, 8)
        self.content_grid.addWidget(
            self.donate_label, 1, 1, 1, 1, Qt.AlignmentFlag.AlignTop
        )

        self.buy_button: QPushButton = QPushButton(
            QIcon.fromTheme("help-donate-usd"), "Buy"
        )
        self.buy_button.setContentsMargins(0, 0, 0, 8)
        self.buy_button.setStyleSheet(
            f"background-color: {get_themed_color(ThemedColor.BLUE)}"
        )
        self.buy_button.clicked.connect(self.buy_clicked)
        self.content_grid.addWidget(
            self.buy_button, 2, 0, 1, 1, Qt.AlignmentFlag.AlignTop
        )

        self.buy_label: QLabel = QLabel("""\
<p>Purchase hardware and software from companies that support Kubuntu.</p>""")
        self.buy_label.setWordWrap(True)
        self.buy_label.setContentsMargins(8, 0, 0, 8)
        self.content_grid.addWidget(
            self.buy_label, 2, 1, 1, 1, Qt.AlignmentFlag.AlignTop
        )

        self.volunteer_button: QPushButton = QPushButton(
            QIcon.fromTheme("applications-development-symbolic"), "Volunteer"
        )
        self.volunteer_button.setContentsMargins(0, 0, 0, 8)
        self.volunteer_button.setStyleSheet(
            f"background-color: {get_themed_color(ThemedColor.BLUE)}"
        )
        self.volunteer_button.clicked.connect(self.volunteer_clicked)
        self.content_grid.addWidget(
            self.volunteer_button, 3, 0, 1, 1, Qt.AlignmentFlag.AlignTop
        )

        self.volunteer_label: QLabel = QLabel("""\
<p>You can help with development, packaging, testing, documentation, and
more!</p>""")
        self.volunteer_label.setWordWrap(True)
        self.volunteer_label.setContentsMargins(8, 0, 0, 8)
        self.content_grid.addWidget(
            self.volunteer_label, 3, 1, 1, 1, Qt.AlignmentFlag.AlignTop
        )
        self.content_grid.setColumnStretch(1, 1)
        self.core_layout.addLayout(self.content_grid)
        self.core_layout.addStretch()

        self.bottom_button_layout: QHBoxLayout = QHBoxLayout()
        self.bottom_button_layout.addStretch()
        self.close_button: QPushButton = QPushButton(
            QIcon.fromTheme("dialog-close"), "Close"
        )
        self.close_button.clicked.connect(self.accept)
        self.bottom_button_layout.addWidget(self.close_button)
        self.core_layout.addLayout(self.bottom_button_layout)

        self.setLayout(self.core_layout)

    def donate_clicked(self) -> None:
        """
        Opens the donation portal.
        """

        QDesktopServices.openUrl(
            QUrl("https://kubuntu.org/app/contribute/donate/")
        )

    def buy_clicked(self) -> None:
        """
        Opens the buy page.
        """

        QDesktopServices.openUrl(
            QUrl("https://kubuntu.org/app/contribute/buy")
        )

    def volunteer_clicked(self) -> None:
        """
        Opens the contribution webpage.
        """

        QDesktopServices.openUrl(
            QUrl("https://kubuntu.org/app/contribute/contribute")
        )


# pylint: disable=too-many-instance-attributes
class DonateDialog(QDialog):
    """
    Directs the user to the donation portal.
    """

    def __init__(self, parent: QWidget | None = None) -> None:
        super().__init__(parent)

        self.resize(552, 235)
        self.setMinimumWidth(552)
        self.setMinimumHeight(235)
        self.setWindowTitle("Donate to Kubuntu")

        self.core_layout: QVBoxLayout = QVBoxLayout()
        self.donate_header: QLabel = QLabel("<h1>Donate to Kubuntu</h1>")
        self.donate_header.setAlignment(Qt.AlignmentFlag.AlignHCenter)
        self.donate_header.setContentsMargins(0, 0, 0, 16)
        self.core_layout.addWidget(self.donate_header)

        self.content_layout: QHBoxLayout = QHBoxLayout()
        self.kubuntu_logo: QLabel = QLabel()
        self.kubuntu_logo.setPixmap(
            QIcon.fromTheme("donate-symbolic").pixmap(96, 96)
        )
        self.kubuntu_logo.setContentsMargins(8, 0, 16, 8)
        self.kubuntu_logo.setSizePolicy(
            QSizePolicy.Policy.Fixed, QSizePolicy.Policy.Fixed
        )
        self.content_layout.addWidget(
            self.kubuntu_logo, Qt.AlignmentFlag.AlignTop
        )

        self.desc_label: QLabel = QLabel("""\
<p>Kubuntu exists today thanks to the support of numerous donors and
contributors around the world. Your donation helps sustain Kubuntu and make it
even better for users around the world.</p>""")
        self.desc_label.setWordWrap(True)
        self.desc_label.setSizePolicy(
            QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Preferred
        )
        self.desc_label.setAlignment(Qt.AlignmentFlag.AlignTop)
        self.desc_label.setContentsMargins(0, 0, 0, 8)
        self.content_layout.addWidget(
            self.desc_label, Qt.AlignmentFlag.AlignTop
        )
        self.core_layout.addLayout(self.content_layout)
        self.core_layout.addStretch()

        self.bottom_button_layout: QHBoxLayout = QHBoxLayout()
        self.bottom_button_layout.addStretch()
        self.donate_button: QPushButton = QPushButton(
            QIcon.fromTheme("donate-symbolic"), "Donate Now"
        )
        self.donate_button.setStyleSheet(
            f"background-color: {get_themed_color(ThemedColor.BLUE)}"
        )
        self.donate_button.clicked.connect(self.donate_clicked)
        self.bottom_button_layout.addWidget(self.donate_button)

        self.close_button: QPushButton = QPushButton(
            QIcon.fromTheme("dialog-close"), "Close"
        )
        self.close_button.clicked.connect(self.accept)
        self.bottom_button_layout.addWidget(self.close_button)
        self.core_layout.addLayout(self.bottom_button_layout)

        self.accept_timer: QTimer = QTimer()
        self.accept_timer.setInterval(500)
        self.accept_timer.timeout.connect(self.accept)

        self.setLayout(self.core_layout)

    def donate_clicked(self) -> None:
        """
        Opens the donation portal and exits.
        """

        QDesktopServices.openUrl(QUrl("https://kubuntu.org/app/donate/donate"))
        self.accept_timer.start()


# pylint: disable=unused-argument
def signal_handler(sig: int, frame: FrameType | None) -> NoReturn:
    """
    Handles Ctrl+C keypresses.
    """

    sys.exit(128 + sig)


def main() -> NoReturn:
    """
    Main function.
    """

    app: QApplication = QApplication(sys.argv)
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    keepalive_timer: QTimer = QTimer()
    keepalive_timer.setInterval(500)
    keepalive_timer.timeout.connect(lambda: None)

    arg_parser: argparse.ArgumentParser = argparse.ArgumentParser(
        prog="kfocus-contribute",
        description="Provides guidance to contribute to Kubuntu.",
    )
    arg_parser.add_argument(
        "--mode",
        type=str,
        help=(
            'One of "contribute" or "donate". Determines whether to show a '
            + "detailed or donation-focused dialog."
        ),
        default="contribute",
    )
    arg_obj: argparse.Namespace = arg_parser.parse_args()
    dialog_mode: str | None = arg_obj.mode
    app_dialog: ContributeDialog | DonateDialog | None = None

    if dialog_mode is None:
        print("ERROR: No mode provided!", file=sys.stderr)
        sys.exit(1)
    elif dialog_mode == "contribute":
        app.setDesktopFileName("kubuntu-contribute")
        app_dialog = ContributeDialog()
    elif dialog_mode == "donate":
        app.setDesktopFileName("kubuntu-donate")
        app_dialog = DonateDialog()
    else:
        print(
            f"ERROR: Unrecognized mode '{dialog_mode}' provided!",
            file=sys.stderr,
        )
    assert app_dialog is not None

    keepalive_timer.start()
    app_dialog.show()
    sys.exit(app.exec())

if __name__ == "__main__":
    main()

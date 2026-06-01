#!/usr/bin/python3

# pylint: disable=broad-exception-caught

"""
A simple utility for enabling and disabling Thunderbolt on Linux.
"""

import subprocess
import sys
import signal
from types import FrameType
from typing import NoReturn

from PyQt6.QtCore import Qt, QTimer
from PyQt6.QtGui import QIcon, QPalette, QColor, QCursor
from PyQt6.QtWidgets import (
    QApplication,
    QDialog,
    QWidget,
    QVBoxLayout,
    QGridLayout,
    QPushButton,
    QLabel,
    QMessageBox,
    QCheckBox,
    QHBoxLayout,
)

TBT_SET_EXE: str = "/usr/lib/kfocus/bin/kfocus-tbt-set"
WINDOW_TITLE: str = "KFocus Thunderbolt Control"


# pylint: disable=too-few-public-methods
class TbtQueryRslt:
    """
    Parsed data from a kfocus-tbt-set query.
    """

    run_state: bool
    persist_state: bool
    model_code: str


def _query_tbt() -> TbtQueryRslt:
    """
    Runs kfocus-tbt-set to query the current state of Thunderbolt on the
    system. Returns a TbtQueryRslt object.
    """

    out_tuple: TbtQueryRslt = TbtQueryRslt()
    query_rslt: list[str] = (
        subprocess.run(
            ["/usr/bin/pkexec", TBT_SET_EXE, "query"],
            capture_output=True,
            encoding="utf-8",
            check=True,
        )
        .stdout.strip()
        .split("\n")
    )
    if len(query_rslt) != 3:
        raise RuntimeError("Not enough data from 'kfocus-tbt-set query'!")

    match query_rslt[0]:
        case "running":
            out_tuple.run_state = True
        case "stopped":
            out_tuple.run_state = False
        case _:
            raise RuntimeError(
                f"Unexpected Thunderbolt running state '{query_rslt[0]}' "
                + "from 'kfocus-tbt-set query'!"
            )

    match query_rslt[1]:
        case "enabled":
            out_tuple.persist_state = True
        case "disabled":
            out_tuple.persist_state = False
        case _:
            raise RuntimeError(
                f"Unexpected Thunderbolt enabled state '{query_rslt[1]}' "
                + "from 'kfocus-tbt-set query'!"
            )

    out_tuple.model_code = query_rslt[2]
    return out_tuple


# pylint: disable=too-many-instance-attributes, too-many-statements
class TbtCtlDialog(QDialog):
    """
    UI and business logic.
    """

    def __init__(self, parent: QWidget | None = None) -> None:
        """
        Initialize the UI.
        """

        super().__init__(parent)

        try:
            self.tbt_query_rslt: TbtQueryRslt = _query_tbt()
        except Exception:
            QMessageBox.critical(
                self,
                WINDOW_TITLE,
                "Could not determine the machine's Thunderbolt state! Please "
                + "report this to technical support.",
            )
            sys.exit(1)

        self.resize(440, 440)
        self.setWindowTitle(WINDOW_TITLE)

        self.core_layout: QVBoxLayout = QVBoxLayout()
        self.top_grid_layout: QGridLayout = QGridLayout()

        self.top_grid_layout.setColumnStretch(0, 1)

        self.header_label: QLabel = QLabel(
            '<h3 style="text-align: center; color: #f7941d">'
            + "KFocus Thunderbolt Control</h3>"
        )
        self.top_grid_layout.addWidget(self.header_label, 0, 1, 1, 5)

        self.desc_label: QLabel
        if self.tbt_query_rslt.model_code == "m2g5p1":
            self.desc_label = QLabel(
                "<p>This model uses the Barlow Ridge Thunderbolt 5 chip. As of "
                + "late 2024, support for this chip is still evolving, and "
                + "displays attached via USB-C can time-out and go "
                + "blank after 15 seconds. Disabling Thunderbolt can fix "
                + "this while retaining almost all other capabilities.<br></p>"
            )
        else:
            self.desc_label = QLabel(
                "<p>For most systems and situations, you want Thunderbolt "
                + "running and enabled. However, there are some situations "
                + "where it is useful to disable Thunderbolt, either "
                + "temporarily or permanently.<br></p>"
            )
        self.desc_label.setWordWrap(True)
        self.top_grid_layout.addWidget(self.desc_label, 1, 1, 1, 5)

        self.use_tbt_checkbox: QCheckBox = QCheckBox("Use Thunderbolt")
        self.use_tbt_checkbox.setChecked(self.tbt_query_rslt.run_state)
        self.top_grid_layout.addWidget(self.use_tbt_checkbox, 2, 1, 1, 1)

        self.enable_on_boot_checkbox: QCheckBox = QCheckBox("Enable on boot")
        self.enable_on_boot_checkbox.setChecked(
            self.tbt_query_rslt.persist_state
        )
        self.top_grid_layout.addWidget(self.enable_on_boot_checkbox, 3, 1, 1, 1)

        self.use_tbt_info_button: QPushButton = QPushButton(
            QIcon.fromTheme("info-symbolic"), ""
        )
        self.top_grid_layout.addWidget(self.use_tbt_info_button, 2, 2, 1, 1)

        self.checkbox_normal_palette = self.use_tbt_checkbox.palette()
        self.checkbox_changed_palette = self.use_tbt_checkbox.palette()
        self.checkbox_changed_palette.setColor(
            QPalette.ColorRole.WindowText, QColor(0xF7, 0x94, 0x1D)
        )

        self.enable_on_boot_info_button: QPushButton = QPushButton(
            QIcon.fromTheme("info-symbolic"), ""
        )
        self.top_grid_layout.addWidget(
            self.enable_on_boot_info_button, 3, 2, 1, 1
        )

        self.top_grid_layout.setColumnStretch(3, 1)

        self.tbt_logo_label: QLabel = QLabel()
        self.tbt_logo_label.setPixmap(
            QIcon.fromTheme("kfocus-tbt-symbolic").pixmap(78, 78)
        )
        self.top_grid_layout.addWidget(self.tbt_logo_label, 2, 4, 2, 1)

        ## TODO: Does a column stretch of 2 work here?
        self.top_grid_layout.setColumnStretch(5, 1)
        self.top_grid_layout.setColumnStretch(6, 1)

        self.core_layout.addLayout(self.top_grid_layout)
        self.core_layout.addStretch()

        self.button_layout: QHBoxLayout = QHBoxLayout()
        self.button_layout.addStretch()

        self.ok_button: QPushButton = QPushButton("OK")
        self.ok_button.setIcon(QIcon.fromTheme("dialog-ok-symbolic"))
        self.button_layout.addWidget(self.ok_button)

        self.cancel_button: QPushButton = QPushButton("Cancel")
        self.cancel_button.setIcon(QIcon.fromTheme("dialog-cancel-symbolic"))
        self.button_layout.addWidget(self.cancel_button)

        self.core_layout.addLayout(self.button_layout)

        self.setLayout(self.core_layout)

        self.set_ok_button_state()
        self.use_tbt_info_button.clicked.connect(
            self.use_tbt_info_button_clicked
        )
        self.enable_on_boot_info_button.clicked.connect(
            self.enable_on_boot_info_button_clicked
        )
        self.use_tbt_checkbox.clicked.connect(self.use_tbt_checkbox_clicked)
        self.enable_on_boot_checkbox.clicked.connect(
            self.enable_on_boot_checkbox_clicked
        )
        self.ok_button.clicked.connect(self.ok_button_clicked)
        self.cancel_button.clicked.connect(self.cancel_button_clicked)

        self.show()

    def set_ok_button_state(self) -> None:
        """
        Enables the OK button if a checkbox has changed state, disables it
        otherwise.
        """

        if (
            self.use_tbt_checkbox.isChecked() == self.tbt_query_rslt.run_state
            and self.enable_on_boot_checkbox.isChecked()
            == self.tbt_query_rslt.persist_state
        ):
            self.ok_button.setEnabled(False)
        else:
            self.ok_button.setEnabled(True)

    def use_tbt_info_button_clicked(self) -> None:
        """
        Displays some help about the "Use Thunderbolt" checkbox.
        """

        QMessageBox.information(
            self,
            WINDOW_TITLE,
            "Check this to load the Thunderbolt driver now.<br>"
            + "Uncheck to unload the driver now.",
        )

    def enable_on_boot_info_button_clicked(self) -> None:
        """
        Displays some help about the "Enable on boot" checkbox.
        """

        QMessageBox.information(
            self,
            WINDOW_TITLE,
            "Check this to load the Thunderbolt driver at boot.<br>"
            + "Uncheck to prevent the driver from loading at boot.",
        )

    def use_tbt_checkbox_clicked(self) -> None:
        """
        Changes the color of the "Use Thunderbolt" checkbox if its state has
        changed.
        """

        if self.use_tbt_checkbox.isChecked() != self.tbt_query_rslt.run_state:
            self.use_tbt_checkbox.setPalette(self.checkbox_changed_palette)
        else:
            self.use_tbt_checkbox.setPalette(self.checkbox_normal_palette)
        self.set_ok_button_state()

    def enable_on_boot_checkbox_clicked(self) -> None:
        """
        Changes the color of the "Enable on boot" checkbox if its state has
        changed.
        """

        if (
            self.enable_on_boot_checkbox.isChecked()
            != self.tbt_query_rslt.persist_state
        ):
            self.enable_on_boot_checkbox.setPalette(
                self.checkbox_changed_palette
            )
        else:
            self.enable_on_boot_checkbox.setPalette(
                self.checkbox_normal_palette
            )
        self.set_ok_button_state()

    def ok_button_clicked(self) -> None:
        """
        Uses kfocus-tbt-set to enable or disable Thunderbolt, both for this
        boot and subsequent boots.
        """

        busy_cursor: QCursor = QCursor()
        busy_cursor.setShape(Qt.CursorShape.WaitCursor)
        QApplication.setOverrideCursor(busy_cursor)

        self.use_tbt_checkbox.setEnabled(False)
        self.enable_on_boot_checkbox.setEnabled(False)
        self.ok_button.setEnabled(False)
        self.cancel_button.setEnabled(False)
        self.use_tbt_info_button.setEnabled(False)
        self.enable_on_boot_info_button.setEnabled(False)

        ret_code: int = subprocess.run(
            [
                "/usr/bin/pkexec",
                TBT_SET_EXE,
                "start" if self.use_tbt_checkbox.isChecked() else "stop",
            ],
            capture_output=False,
            check=False,
        ).returncode
        if ret_code != 0:
            self.fail_and_exit()

        ret_code = subprocess.run(
            [
                "/usr/bin/pkexec",
                TBT_SET_EXE,
                (
                    "enable"
                    if self.enable_on_boot_checkbox.isChecked()
                    else "disable"
                ),
            ],
            capture_output=False,
            check=False,
        ).returncode
        if ret_code != 0:
            self.fail_and_exit()

        self.succeed_and_exit()

    def succeed_and_exit(self) -> None:
        """
        Fixes the mouse cursor, displays a success message, and exits.
        """

        normal_cursor: QCursor = QCursor()
        normal_cursor.setShape(Qt.CursorShape.ArrowCursor)
        QApplication.setOverrideCursor(normal_cursor)

        QMessageBox.information(
            self,
            WINDOW_TITLE,
            "The settings have been successfully applied.",
        )
        QApplication.quit()

    def fail_and_exit(self) -> None:
        """
        Fixes the mouse cursor, displays a failure message, and exits.
        """

        normal_cursor: QCursor = QCursor()
        normal_cursor.setShape(Qt.CursorShape.ArrowCursor)
        QApplication.setOverrideCursor(normal_cursor)

        QMessageBox.information(
            self,
            WINDOW_TITLE,
            "Something went wrong while trying to apply the settings! "
            + "Please contact technical support.",
        )
        QApplication.quit()

    def cancel_button_clicked(self) -> None:
        """
        Exits the app.
        """

        QApplication.quit()


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
    app.setDesktopFileName("kfocus-tbt")

    keepalive_timer: QTimer = QTimer()
    keepalive_timer.setInterval(500)
    keepalive_timer.timeout.connect(lambda: None)
    keepalive_timer.start()

    # pylint: disable=unused-variable
    dialog = TbtCtlDialog()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()

#!/usr/bin/python3

# pylint: disable=broad-exception-caught

"""
A simple utility for controlling the GPU Boost feature on Ar GEN 1 systems.
"""

import subprocess
import sys
import signal
from types import FrameType
from typing import Any, NoReturn

from PyQt6.QtCore import (
    pyqtClassInfo,
    pyqtSlot,
    Qt,
    QTimer,
)
from PyQt6.QtGui import (
    QIcon,
    QWindow,
)
from PyQt6.QtWidgets import (
    QApplication,
    QDialog,
    QMessageBox,
    QVBoxLayout,
    QHBoxLayout,
    QGridLayout,
    QLabel,
    QRadioButton,
    QPushButton,
    QWidget,
    QSpacerItem,
)
from PyQt6.QtDBus import (
    QDBusConnection,
    QDBusAbstractAdaptor,
    QDBusInterface,
)

GPUBOOST_SET_EXE: str = "/usr/lib/kfocus/bin/kfocus-pl-gpuboost-set"
WINDOW_TITLE: str = "KFocus Panther Lake GPU Boost Tool"

ENABLED_RADIO_TEXT: str = (
    'GPU Boost ENABLED <br><font color="#f7941d">(AC Required)</font>'
)
DISABLED_RADIO_TEXT: str = "GPU Boost DISABLED"


# pylint: disable=unused-argument
def signal_handler(sig: int, frame: FrameType | None) -> NoReturn:
    """
    Handles Ctrl+C keypresses.
    """

    sys.exit(128 + sig)


# pylint: disable=too-many-instance-attributes
class GpuBoostDialog(QDialog):
    """
    Main user interface.
    """

    def __init__(self, parent: QWidget | None = None) -> None:
        """
        Initialize the UI.
        """

        super().__init__(parent)

        # self.resize(440, 380)
        self.setWindowTitle(WINDOW_TITLE)

        self.core_layout: QVBoxLayout = QVBoxLayout()
        self.top_grid_layout: QGridLayout = QGridLayout()

        self.top_grid_layout.setColumnStretch(0, 1)

        self.header_label: QLabel = QLabel(
            '<h3 style="text-align: center; color: #f7941d">GPU Boost</h3>'
        )
        self.top_grid_layout.addWidget(self.header_label, 0, 1, 1, 4)

        self.boost_info_layout: QHBoxLayout = QHBoxLayout()
        self.boost_info_button: QPushButton = QPushButton(
            QIcon.fromTheme("info-symbolic"), ""
        )
        self.boost_info_label: QLabel = QLabel(
            "<p>Boost Panther Lake GPU speed up to 50%.</p>"
        )
        #self.boost_info_label.setSizePolicy(
        #    QSizePolicy.Policy.Expanding,
        #    QSizePolicy.Policy.Preferred,
        #)
        self.boost_info_layout.addWidget(self.boost_info_button)
        self.boost_info_layout.addWidget(self.boost_info_label)
        self.boost_info_layout.addStretch()
        self.boost_info_button.clicked.connect(self.msg_boost_info)
        self.top_grid_layout.addLayout(self.boost_info_layout, 1, 1, 1, 4)

        self.ac_needed_layout: QHBoxLayout = QHBoxLayout()
        self.ac_needed_button: QPushButton = QPushButton(
            QIcon.fromTheme("info-symbolic"), ""
        )
        self.ac_needed_label: QLabel = QLabel(
            "<p>Boost is not available on battery.</p>"
        )
        self.ac_needed_layout.addWidget(self.ac_needed_button)
        self.ac_needed_layout.addWidget(self.ac_needed_label)
        self.ac_needed_layout.addStretch()
        self.ac_needed_button.clicked.connect(self.msg_ac_needed)
        self.top_grid_layout.addLayout(self.ac_needed_layout, 2, 1, 1, 4)

        self.more_perf_layout: QHBoxLayout = QHBoxLayout()
        self.more_perf_button: QPushButton = QPushButton(
            QIcon.fromTheme("info-symbolic"), ""
        )
        self.more_perf_label: QLabel = QLabel(
            "<p>Additional tweaks can increase performance.</p>"
        )
        self.more_perf_layout.addWidget(self.more_perf_button)
        self.more_perf_layout.addWidget(self.more_perf_label)
        self.more_perf_layout.addStretch()
        self.more_perf_button.clicked.connect(self.msg_more_perf)
        self.top_grid_layout.addLayout(self.more_perf_layout, 3, 1, 1, 4)

        self.sect_spacer: QSpacerItem = QSpacerItem(0, 32)
        self.top_grid_layout.addItem(self.sect_spacer, 4, 0, 1, 1)

        self.enabled_radio_button: QRadioButton = QRadioButton()
        self.top_grid_layout.addWidget(self.enabled_radio_button, 5, 1, 1, 1)
        self.top_grid_layout.setAlignment(
            self.enabled_radio_button,
            Qt.AlignmentFlag.AlignTop,
        )
        # We can't use the text field of QRadioButton because it does not support rich text.
        self.enabled_radio_button_label: QLabel = QLabel(ENABLED_RADIO_TEXT)
        self.enabled_radio_button.toggled.connect(self.enabled_button_toggled)
        self.top_grid_layout.addWidget(self.enabled_radio_button_label, 5, 2, 1, 1)
        self.top_grid_layout.setAlignment(
            self.enabled_radio_button_label,
            Qt.AlignmentFlag.AlignTop,
        )

        self.disabled_radio_button: QRadioButton = QRadioButton()
        self.top_grid_layout.addWidget(self.disabled_radio_button, 6, 1, 1, 1)
        self.disabled_radio_button_label: QLabel = QLabel(DISABLED_RADIO_TEXT)
        self.disabled_radio_button.toggled.connect(self.disabled_button_toggled)
        self.top_grid_layout.addWidget(self.disabled_radio_button_label, 6, 2, 1, 1)

        self.top_grid_layout.setColumnStretch(3, 1)

        self.gpuboost_logo_label: QLabel = QLabel()
        self.gpuboost_logo_label.setPixmap(
            QIcon.fromTheme("kfocus-bug-gpuboost").pixmap(78, 78)
        )
        self.top_grid_layout.addWidget(self.gpuboost_logo_label, 5, 4, 2, 1)

        self.top_grid_layout.setColumnStretch(5, 1)

        self.core_layout.addLayout(self.top_grid_layout)
        self.core_layout.addStretch()

        self.lower_spacer: QSpacerItem = QSpacerItem(0, 32)
        self.core_layout.addItem(self.lower_spacer)

        self.button_layout: QHBoxLayout = QHBoxLayout()
        self.button_layout.addStretch()
        self.close_button: QPushButton = QPushButton("Close")
        self.close_button.clicked.connect(self.accept)
        self.button_layout.addWidget(self.close_button)
        self.button_layout.setContentsMargins(0, 0, 0, 0)
        self.close_button.setContentsMargins(0, 0, 0, 0)
        self.core_layout.addLayout(self.button_layout)
        self.core_layout.setContentsMargins(24, 24, 24, 24)
        self.setLayout(self.core_layout)

        self.ignore_next_toggle: bool = False

        self.check_state_timer: QTimer = QTimer()
        self.check_state_timer.setInterval(3000)
        self.check_state_timer.setSingleShot(True)
        self.check_state_timer.timeout.connect(self.poll_service_state)

        self.poll_service_state()

        self.show()

    def msg_boost_info(self) -> None:
        """
        Shows a hint to the user about how GPU boost works.
        """

        QMessageBox.information(
            self,
            WINDOW_TITLE,
            "<br>GPU performance is throttled by default to improve battery "
            + "life and allow faster CPU performance. Raising GPU power "
            + "limits will likely improve sustained performance for games, "
            + "AI tools, and other GPU-intensive workloads, but may shorten "
            + "battery life and slow down CPU-intensive applications."
        )

    def msg_ac_needed(self) -> None:
        """
        Shows a hint to the user about why GPU boost is unavailable on
        battery.
        """

        QMessageBox.information(
            self,
            WINDOW_TITLE,
            "<br>The GPU can only make use of increased power limits if the "
            + "system is plugged into AC power. Unplugging the system while "
            + "GPU Boost is enabled will automatically disable it."
        )

    def msg_more_perf(self) -> None:
        """
        Shows a hint to the user about how to get better GPU performance.
        """

        QMessageBox.information(
            self,
            WINDOW_TITLE,
            '<br>In the "Power and Fan Tool," you can set the CPU '
            + '"Power Profile" to "Powersave," or set "Frequency Profile"'
            + 'to "Low." Both allow more power to be allocated to the '
            + 'GPU and further increase its performance.'
        )

    def enabled_button_toggled(self, is_checked: bool) -> None:
        """
        Starts the GPU Boost service when the user clicks the "Enable" button.
        """

        if not is_checked:
            return
        if self.ignore_next_toggle:
            self.ignore_next_toggle = False
            return

        if (
            subprocess.run(
                [
                    "pkexec",
                    "/usr/lib/kfocus/bin/kfocus-pl-gpuboost-set",
                    "on",
                ],
                capture_output=False,
                check=False,
            ).returncode
            != 0
        ):
            self.ignore_next_toggle = True
            self.disabled_radio_button.setChecked(True)
        else:
            self.check_state_timer.start()

    def disabled_button_toggled(self, is_checked: bool) -> None:
        """
        Stops the GPU Boost service when the user clicks the "Disable" button.
        """

        if not is_checked:
            return
        if self.ignore_next_toggle:
            self.ignore_next_toggle = False
            return

        if (
            subprocess.run(
                [
                    "pkexec",
                    "/usr/lib/kfocus/bin/kfocus-pl-gpuboost-set",
                    "off",
                ],
                capture_output=False,
                check=False,
            ).returncode
            != 0
        ):
            self.ignore_next_toggle = True
            self.enabled_radio_button.setChecked(True)
        else:
            self.check_state_timer.start()

    def daemon_state_change_notify(self, is_running: bool) -> None:
        """
        Updates the UI if the GPU Boost service starts or terminates without
        the frontend's intervention.
        """

        if is_running:
            if not self.enabled_radio_button.isChecked():
                self.ignore_next_toggle = True
                self.enabled_radio_button.setChecked(True)
        else:
            if not self.disabled_radio_button.isChecked():
                self.ignore_next_toggle = True
                self.disabled_radio_button.setChecked(True)

    def poll_service_state(self) -> None:
        """
        Uses systemctl to check if the service is running and updates the UI
        accordingly.
        """

        current_backend_state: str = subprocess.run(
            [
                "systemctl",
                "is-active",
                "kfocus-pl-gpuboost.service",
            ],
            capture_output=True,
            encoding="utf-8",
            check=False,
        ).stdout.strip()
        self.daemon_state_change_notify(current_backend_state == "active")


@pyqtClassInfo("D-Bus Interface", "org.kfocus.gpuboost")  # type: ignore
class GpuBoostDBusAdaptor(QDBusAbstractAdaptor):
    """
    Provides D-Bus methods for the frontend.
    """

    # pylint: disable=invalid-name
    @pyqtSlot()
    def RequestActivate(self) -> None:
        """
        Makes the parent window request activation.
        """

        parent_obj: Any = self.parent()
        assert isinstance(parent_obj, GpuBoostDialog)
        gbd: GpuBoostDialog = parent_obj
        window_handle: QWindow | None = gbd.windowHandle()
        assert window_handle is not None
        window_handle.requestActivate()

    # pylint: disable=invalid-name
    @pyqtSlot()
    def DaemonExitNotify(self) -> None:
        """
        Informs the frontend that the backend has shut down.
        """

        parent_obj: Any = self.parent()
        assert isinstance(parent_obj, GpuBoostDialog)
        gbd: GpuBoostDialog = parent_obj
        gbd.daemon_state_change_notify(is_running=False)

    # pylint: disable=invalid-name
    @pyqtSlot()
    def DaemonStartNotify(self) -> None:
        """
        Informs the frontend that the backend has started.
        """

        parent_obj: Any = self.parent()
        assert isinstance(parent_obj, GpuBoostDialog)
        gbd: GpuBoostDialog = parent_obj
        gbd.daemon_state_change_notify(is_running=True)


def main() -> NoReturn:
    """
    Main function.
    """

    app: QApplication = QApplication(sys.argv)
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    app.setDesktopFileName("kfocus-pl-gpuboost")

    # Check the model code
    model_code: str = subprocess.run(
        [
            "bash",
            "-c",
            "source /usr/lib/kfocus/lib/common.2.source; "
            + "_cm2EchoModelStrFn 'code';",
        ],
        capture_output=True,
        encoding="utf-8",
        check=False,
    ).stdout.strip()
    model_code = "arg1"
    if model_code != "arg1":
        QMessageBox.critical(
            None,
            WINDOW_TITLE,
            "This tool is only useful on a Kubuntu Focus Ar GEN 1 system. "
            + "Please uninstall the kfocus-pl-gpuboost package.",
        )
        sys.exit(1)

    # Try to register a D-Bus interface
    dbus_conn: QDBusConnection = QDBusConnection.sessionBus()
    if dbus_conn.isConnected():
        if not dbus_conn.registerService("org.kfocus.gpuboost"):
            # Registration failed, a client must already be running. Message
            # that client and exit.
            dbus_iface: QDBusInterface = QDBusInterface(
                "org.kfocus.gpuboost",
                "/org/kfocus/gpuboost",
                "org.kfocus.gpuboost",
                dbus_conn,
            )
            if not dbus_iface.isValid():
                print("No GPU Boost D-Bus service?", file=sys.stderr)
                sys.exit(1)
            dbus_iface.call("RequestActivate")
            sys.exit(0)
    else:
        print("D-Bus connection failed!", file=sys.stderr)
        sys.exit(1)

    # Service is registered at this point
    gbd: GpuBoostDialog = GpuBoostDialog()
    # pylint: disable=unused-variable
    dbus_adaptor: GpuBoostDBusAdaptor = GpuBoostDBusAdaptor(gbd)
    dbus_conn.registerObject("/org/kfocus/gpuboost", gbd)

    keepalive_timer: QTimer = QTimer()
    keepalive_timer.setInterval(500)
    keepalive_timer.timeout.connect(lambda: None)
    keepalive_timer.start()

    app.exec()
    sys.exit(0)


if __name__ == "__main__":
    main()

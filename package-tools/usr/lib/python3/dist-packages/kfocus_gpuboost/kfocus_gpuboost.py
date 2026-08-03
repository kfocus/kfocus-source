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
)
from PyQt6.QtDBus import (
    QDBusConnection,
    QDBusAbstractAdaptor,
    QDBusInterface,
)

GPUBOOST_SET_EXE: str = "/usr/lib/kfocus/bin/kfocus-pl-gpuboost-set"
WINDOW_TITLE: str = "KFocus Panther Lake GPU Boost Tool"

ENABLED_RADIO_TEXT: str = "GPU Boost ENABLED"
ENABLED_NOAC_RADIO_TEXT: str = (
    'GPU Boost ENABLED <font color="#f7941d">(Plug in AC)</font>'
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

        self.resize(440, 440)
        self.setWindowTitle(WINDOW_TITLE)

        self.core_layout: QVBoxLayout = QVBoxLayout()
        self.top_grid_layout: QGridLayout = QGridLayout()

        self.top_grid_layout.setColumnStretch(0, 1)

        self.header_label: QLabel = QLabel(
            '<h3 style="text-align: center; color: #f7941d">GPU Boost</h3>'
        )
        self.top_grid_layout.addWidget(self.header_label, 0, 1, 1, 4)

        self.desc_label: QLabel = QLabel(
            "<p>This tool will boost frame rates up to 50% on Kubuntu Focus "
            + "Panther Lake systems when plugged in. This is done by raising "
            + "power limits. CPU-intensive applications may slow down.</p>"
            + "<p>GPU boost is always disabled and cannot be used on battery. "
            + "Changing frequency profile settings in the Power and Fan tool "
            + "will also disable GPU boost.</p>"
        )
        self.desc_label.setWordWrap(True)
        self.top_grid_layout.addWidget(self.desc_label, 1, 1, 1, 4)

        self.enabled_radio_button: QRadioButton = QRadioButton(
            ENABLED_RADIO_TEXT
        )
        self.top_grid_layout.addWidget(self.enabled_radio_button, 2, 1, 1, 1)

        self.disabled_radio_button: QRadioButton = QRadioButton(
            DISABLED_RADIO_TEXT
        )
        self.top_grid_layout.addWidget(self.disabled_radio_button, 3, 1, 1, 1)

        self.top_grid_layout.setColumnStretch(2, 1)

        self.gpuboost_logo_label: QLabel = QLabel()
        self.gpuboost_logo_label.setPixmap(
            QIcon.fromTheme("kfocus-bug-gpuboost").pixmap(78, 78)
        )
        self.top_grid_layout.addWidget(self.gpuboost_logo_label, 2, 3, 2, 1)

        self.top_grid_layout.setColumnStretch(4, 1)
        self.top_grid_layout.setColumnStretch(5, 1)

        self.core_layout.addLayout(self.top_grid_layout)
        self.core_layout.addStretch()

        self.button_layout: QHBoxLayout = QHBoxLayout()
        self.button_layout.addStretch()

        self.exit_button: QPushButton = QPushButton("Exit")
        self.exit_button.setIcon(QIcon.fromTheme("application-exit"))
        self.exit_button.clicked.connect(self.accept)
        self.button_layout.addWidget(self.exit_button)
        self.core_layout.addLayout(self.button_layout)
        self.setLayout(self.core_layout)

        current_backend_state: str = subprocess.run(
            [
                "systemctl",
                "status",
                "kfocus-pl-gpuboost.service",
            ],
            capture_output=True,
            encoding="utf-8",
            check=False,
        ).stdout.strip()
        if current_backend_state == "active":
            self.enabled_radio_button.setChecked(True)
        else:
            self.disabled_radio_button.setChecked(True)
            self.check_ac_state()

        self.ignore_next_toggle: bool = False

        self.enabled_radio_button.toggled.connect(self.enabled_button_toggled)
        self.disabled_radio_button.toggled.connect(self.disabled_button_toggled)

        self.show()

    def check_ac_state(self) -> None:
        """
        Checks if AC power is available and updates the UI accordingly.
        """

        is_ac_available: bool = (
            subprocess.run(
                ["/usr/lib/kfocus/bin/kfocus-pl-gpuboost-set", "checkAc"],
                capture_output=False,
                check=False,
            ).returncode
            == 0
        )
        if is_ac_available:
            self.enabled_radio_button.setText(ENABLED_RADIO_TEXT)
        else:
            self.enabled_radio_button.setText(ENABLED_NOAC_RADIO_TEXT)

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

        self.check_ac_state()

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

        self.check_ac_state()

    def daemon_exit_notify(self) -> None:
        """
        Updates the UI if the GPU Boost service voluntarily terminates.
        """

        self.ignore_next_toggle = True
        self.disabled_radio_button.setChecked(True)
        self.check_ac_state()


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
        gbd.daemon_exit_notify()


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

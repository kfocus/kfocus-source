#!/usr/bin/env python3
import sys
import time
from PyQt6.QtWidgets import QApplication, QProgressDialog
from PyQt6.QtCore import Qt

def slow_operation():
    app = QApplication(sys.argv)

    num_steps = 100
    # Create the dialog [Source: Qt Forum]
    # progress = QProgressDialog("Processing data...", "Cancel", 0, num_steps)
    progress = QProgressDialog("Configuring for Hardware after installation.<br>This process should only be required once,<br>and can take a few minutes.", "Cancel", 0, num_steps)
    progress.setCancelButton(None)
    progress.setWindowTitle("Configuring for Hardware")
    progress.setWindowModality(Qt.WindowModality.WindowModal)
    progress.setMinimumDuration(0)  # Show immediately [Source: Qt for Python Docs]

    for i in range(num_steps + 1):
        progress.setValue(i)

        # Check if user canceled [Source: Stack Overflow]
        if progress.wasCanceled():
            print("Operation aborted by user.")
            break

        # Simulate work
        time.sleep(0.05)

    progress.setValue(num_steps)
    sys.exit(app.exec())

if __name__ == "__main__":
    slow_operation()

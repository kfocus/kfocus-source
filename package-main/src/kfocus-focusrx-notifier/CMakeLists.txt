cmake_minimum_required(VERSION 3.0)
project(kfocus-focusrx-notifier)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt5 COMPONENTS
        Core
        DBus
        REQUIRED)

add_executable(kfocus-focusrx-notifier main.cpp
        KDialogLauncher.cpp
        KDialogLauncher.h)
target_link_libraries(kfocus-focusrx-notifier
        Qt5::Core
        Qt5::DBus
)

install(TARGETS kfocus-focusrx-notifier
	BUNDLE DESTINATION .
	LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
	RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

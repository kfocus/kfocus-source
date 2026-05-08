cmake_minimum_required(VERSION 4.2)
project(kfocus-focusrx-dbus-dispatch)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS
        Core
        DBus)

add_executable(kfocus-focusrx-dbus-dispatch main.cpp
        KDialogLauncher.cpp
        KDialogLauncher.h)
target_link_libraries(kfocus-focusrx-dbus-dispatch
        Qt6::Core
        Qt6::DBus
)

install(TARGETS kfocus-focusrx-dbus-dispatch
	BUNDLE DESTINATION .
	LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
	RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

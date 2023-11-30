# ADDED TO SUPPORT CLION C++ DEBUGGING 2023-11-29
# This improves debugging, but cmake will not build.
#   There appears to be an issue finding the headers.
# See https://blog.creekorful.org/2019/08/setup-qt-with-clion-easily/
# Also https://stackoverflow.com/questions/38433375

cmake_minimum_required(VERSION 3.14)

project(kfocus-firstrun-bin)

set(CMAKE_CXX_STANDARD 17)

# Tell cmake where Qt is located
set(Qt5_DIR "/usr/include/x86_64-linux-gnu/cmake/Qt5")

# Quick QuickControls2
# Tell cmake to find the modules
# These may NOT be needed: Core Widgets Quick
find_package(Qt5 COMPONENTS Core Widgets Quick QuickControls2 REQUIRED)

# Define headers
include_directories(.)

# Define sources
set(SOURCES shellengine.cpp main.cpp startupdata.cpp )

add_executable(kfocus-firstrun-bin ${SOURCES})
qt_add_resources(RCC_SOURCES qml.qrc )

# Qt5:Quick Qt5:QuickControls2
# Link the library to the executable
# These may NOT be needed: Qt5::Core Qt5::Widgets Qt5::Quick
target_link_libraries(kfocus-firstrun-bin
    Qt5::Core Qt5::Widgets Qt5::Quick Qt5::QuickControls2
)

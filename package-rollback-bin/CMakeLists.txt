cmake_minimum_required(VERSION 3.14)

project(kfocus-rollback-bin VERSION 0.1 LANGUAGES CXX)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(QT NAMES Qt5 REQUIRED COMPONENTS Core Quick QuickControls2)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Quick QuickControls2)

set(PROJECT_SOURCES
        main.cpp
        qml.qrc
        shellengine.cpp
        backendengine.cpp
        shellengine.h
        backendengine.h
)

add_executable(kfocus-rollback-bin
    ${PROJECT_SOURCES}
)

target_link_libraries(kfocus-rollback-bin
  PRIVATE Qt${QT_VERSION_MAJOR}::Core Qt${QT_VERSION_MAJOR}::Quick Qt${QT_VERSION_MAJOR}::QuickControls2)

include(GNUInstallDirs)
install(TARGETS kfocus-rollback-bin DESTINATION "/usr/lib/kfocus/bin")

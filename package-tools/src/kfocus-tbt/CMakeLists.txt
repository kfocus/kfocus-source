cmake_minimum_required(VERSION 3.5)

project(kfocus-tbt VERSION 0.1 LANGUAGES CXX)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt5 REQUIRED COMPONENTS Widgets)

set(PROJECT_SOURCES
        main.cpp
        tbtctldialog.cpp
        tbtctldialog.h
        tbtctldialog.ui
        tbtctlengine.h
        tbtctlengine.cpp
        tbtqueryresult.h
        tbtqueryresult.cpp
)

add_executable(kfocus-tbt
    ${PROJECT_SOURCES}
)

target_link_libraries(kfocus-tbt PRIVATE Qt5::Widgets)

include(GNUInstallDirs)
install(TARGETS kfocus-tbt
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

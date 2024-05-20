cmake_minimum_required(VERSION 3.16)

project(kubuntu-installer-prompt VERSION 1.1.2 LANGUAGES CXX)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_INSTALL_PREFIX "/usr")

find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})
find_package(QT NAMES Qt5 REQUIRED COMPONENTS Core Widgets Network LinguistTools)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Widgets Network LinguistTools)
find_package(KF5 REQUIRED COMPONENTS NetworkManagerQt WidgetsAddons)

file(GLOB TS_FILES "src/translations/kubuntu-installer-prompt_*.ts")

set(PROJECT_SOURCES
    src/main.cpp
    src/installerprompt.cpp
    src/installerprompt.h
    src/installerprompt.ui
    src/backgroundscreen.h
    src/backgroundscreen.cpp
    src/resource.qrc
    src/wifipassworddialog.h
    src/wifipassworddialog.cpp
    src/wifipassworddialog.ui
    src/languagechangedialog.h
    src/languagechangedialog.cpp
    src/languagechangedialog.ui
    src/warningdialog.h
    src/warningdialog.cpp
    src/warningdialog.ui
    src/connectionprogressdialog.h
    src/connectionprogressdialog.cpp
    src/connectionprogressdialog.ui
)

set(TRANSLATION_RESOURCES "src/translations.qrc")

configure_file(${TRANSLATION_RESOURCES} translations.qrc COPYONLY)
qt5_add_translation(QM_FILES ${TS_FILES})
qt5_add_resources(QM_RESOURCES ${CMAKE_CURRENT_BINARY_DIR}/translations.qrc)

add_custom_target(translations ALL DEPENDS ${QM_FILES})

add_executable(kubuntu-installer-prompt
    ${PROJECT_SOURCES}
    ${QM_RESOURCES}
)

add_dependencies(kubuntu-installer-prompt translations)

target_link_libraries(kubuntu-installer-prompt PRIVATE Qt${QT_VERSION_MAJOR}::Widgets Qt5::Network KF5::NetworkManagerQt KF5::WidgetsAddons)

install(TARGETS kubuntu-installer-prompt
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
install(PROGRAMS "scripts/change-system-language" DESTINATION libexec)
install(PROGRAMS "scripts/start-kubuntu-live-env" DESTINATION libexec)
install(FILES "kubuntu-live-environment.desktop" DESTINATION share/xsessions)

if(QT_VERSION_MAJOR EQUAL 6)
    qt_finalize_executable(kubuntu-installer-prompt)
endif()

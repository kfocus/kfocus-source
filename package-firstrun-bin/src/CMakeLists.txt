add_executable(kfocus-firstrun-bin)

ecm_add_qml_module(kfocus-firstrun-bin
    URI
    org.kfocus.firstrun
)

target_sources(kfocus-firstrun-bin
    PRIVATE
    main.cpp
    shellengine.cpp
    startupdata.cpp
    shellengine.h
    startupdata.h
    qml.qrc
)

ecm_target_qml_sources(kfocus-firstrun-bin
    SOURCES
    Main.qml
)

target_link_libraries(kfocus-firstrun-bin
    PRIVATE
    Qt6::Core
    Qt6::Widgets
    Qt6::Quick
    Qt6::Qml
    Qt6::Gui
    Qt6::QuickControls2
    KF6::I18n
    KF6::CoreAddons
    KF6::IconThemes
)

install(TARGETS kfocus-firstrun-bin ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})

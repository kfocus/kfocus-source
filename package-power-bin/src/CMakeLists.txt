add_executable(kfocus-power-bin)

ecm_add_qml_module(kfocus-power-bin
    URI
    org.kfocus.power
)

target_sources(kfocus-power-bin
    PRIVATE
    main.cpp
    shellengine.cpp
    shellengine.h
    qml.qrc
)

ecm_target_qml_sources(kfocus-power-bin
    SOURCES
    Main.qml
)


target_link_libraries(kfocus-power-bin
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

install(TARGETS kfocus-power-bin DESTINATION "/usr/lib/kfocus/bin")

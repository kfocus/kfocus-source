add_executable(kfocus-rollback-bin)

ecm_add_qml_module(kfocus-rollback-bin
    URI
    org.kfocus.rollback
)

target_sources(kfocus-rollback-bin
    PRIVATE
    main.cpp
    shellengine.cpp
    backendengine.cpp
    windoweventfilter.cpp
    shellengine.h
    backendengine.h
    windoweventfilter.h
    #qml.qrc
)

ecm_target_qml_sources(kfocus-rollback-bin
    SOURCES
    BlockItem.qml
    ConfirmScreenItem.qml
    ConfirmSnapshotActionItem.qml
    ErrorScreenItem.qml
    ErrorSnapshotActionItem.qml
    HelpWindow.qml
    OverlayAlertItem.qml
    SnapshotCompareItem.qml
    SnapshotCompareWindow.qml
    SnapshotInfoItem.qml
    WaitScreenItem.qml
    Main.qml
)

target_link_libraries(kfocus-rollback-bin
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

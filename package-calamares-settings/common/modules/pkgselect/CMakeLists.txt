cmake_minimum_required(VERSION 3.16 FATAL_ERROR)

include(FeatureSummary)

set( CMAKE_CXX_STANDARD 17 )
set( CMAKE_CXX_STANDARD_REQUIRED ON )

set( CALAMARES_VERSION_REQUIRED 3.3.0 )

find_package(ECM ${ECM_VERSION} NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${CMAKE_MODULE_PATH})
include(KDEInstallDirs)
find_package(KF5 REQUIRED COMPONENTS CoreAddons)
find_package(Calamares ${CALAMARES_VERSION_REQUIRED} NO_CMAKE_PACKAGE_REGISTRY)
if (NOT TARGET Calamares::calamares OR NOT TARGET Calamares::calamaresui)
    find_package(Calamares ${CALAMARES_VERSION_REQUIRED} REQUIRED)
endif()

message(STATUS "Found Calamares version ${Calamares_VERSION}")
message(STATUS "              libraries ${Calamares_LIB_DIRS}")
message(STATUS "")

calamares_add_plugin( pkgselect
    TYPE viewmodule
    EXPORT_MACRO PLUGINDLLEXPORT_PRO
    SOURCES
    	PackageSelectViewStep.cpp
    UI
        pkgselect.ui
    SHARED_LIB
)

# FindBSD - Lookup native libbsd installation.
#
# This module provides the following imported library targets:
#
# - BSD::libbsd
#
#   Target encapsulating the libbsd usage requirements, if found.

include(FindPackageHandleStandardArgs)

find_package(PkgConfig QUIET)

if(PKG_CONFIG_FOUND)
	pkg_check_modules(PC_BSD QUIET libbsd)
endif()

find_path(BSD_INCLUDE_DIR NAMES bsd.h HINTS ${PC_BSD_INCLUDE_DIRS} PATH_SUFFIXES bsd)
find_library(BSD_LIBRARY NAMES libbsd.so HINTS ${PC_BSD_LIBRARY_DIRS})

set(BSD_VERSION ${PC_BSD_VERSION})

find_package_handle_standard_args(
	BSD
	REQUIRED_VARS
		BSD_LIBRARY
		BSD_INCLUDE_DIR
	VERSION_VAR
		BSD_VERSION
)

if(BSD_FOUND AND NOT TARGET BSD::libbsd)
	add_library(BSD::libbsd UNKNOWN IMPORTED)
	set_target_properties(BSD::libbsd PROPERTIES
		IMPORTED_LOCATION "${BSD_LIBRARY}"
		INTERFACE_COMPILE_OPTIONS "${PC_BSD_CFLAGS_OTHER}"
		INTERFACE_INCLUDE_DIRECTORIES "${BSD_INCLUDE_DIR}"
	)
endif()

mark_as_advanced(BSD_INCLUDE_DIR BSD_LIBRARY)

# FindZSTD - Lookup native libzstd installation.
#
# This module provides the following imported library targets:
#
# - ZSTD::libzstd
#
#   Target encapsulating the libzstd usage requirements, if found.

include(FindPackageHandleStandardArgs)

find_package(PkgConfig QUIET)

if(PKG_CONFIG_FOUND)
	pkg_check_modules(PC_ZSTD QUIET libzstd)
endif()

find_path(ZSTD_INCLUDE_DIR NAMES zstd.h HINTS ${PC_ZSTD_INCLUDE_DIRS})
find_library(ZSTD_LIBRARY NAMES libzstd.so HINTS ${PC_ZSTD_LIBRARY_DIRS})

set(ZSTD_VERSION ${PC_ZSTD_VERSION})

find_package_handle_standard_args(
	ZSTD
	REQUIRED_VARS
		ZSTD_LIBRARY
		ZSTD_INCLUDE_DIR
	VERSION_VAR
		ZSTD_VERSION
)

if(ZSTD_FOUND AND NOT TARGET ZSTD::libzstd)
	add_library(ZSTD::libzstd UNKNOWN IMPORTED)
	set_target_properties(ZSTD::libzstd PROPERTIES
		IMPORTED_LOCATION "${ZSTD_LIBRARY}"
		INTERFACE_COMPILE_OPTIONS "${PC_ZSTD_CFLAGS_OTHER}"
		INTERFACE_INCLUDE_DIRECTORIES "${ZSTD_INCLUDE_DIR}"
	)
endif()

mark_as_advanced(ZSTD_INCLUDE_DIR ZSTD_LIBRARY)

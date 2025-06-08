# FindLibowfat - Lookup native libowfat installation.
#
# This module provides the following imported library targets:
#
# - Libowfat::libowfat
#
#   Target encapsulating the libowfat usage requirements, if found.
#
# If WANT_STATIC_LIBOWFAT is true, provide static library target instead.
# Note that shared libs aren't available in all platforms, so you may need
# to build from source if unavailable.

include(FindPackageHandleStandardArgs)

if(WANT_STATIC_LIBOWFAT)
	set(Libowfat_LIBS "libowfat.a")
else()
	set(Libowfat_LIBS "libowfat.so")
endif()

# Try to find the include dir for headers. In some environments (notably,
# Debian), header files are dumped into /usr/include, while in others (Fedora)
# they are in /usr/include/libowfat.
#
# CAS.h and windoze.h are chosen for their unique names, but they aren't
# present in old versions of the library, so also look for a few others.
find_path(Libowfat_INCLUDE_DIR NAMES CAS.h windoze.h openreadclose.h safemult.h PATH_SUFFIXES libowfat)

find_library(Libowfat_LIBRARY NAMES ${Libowfat_LIBS})

# Try to lookup the version string for libowfat.
#
# libowfat doesn't expose version information in a convenient way, so we need
# to resort to parsing the changelog. Not ideal, ugly as hell. This is best
# effort, and Libowfat_VERSION may be unset in some environments.
if(EXISTS "${Libowfat_INCLUDE_DIR}/CHANGES")
	# libowfat changelog of a local installation (when built from source)
	file(STRINGS "${Libowfat_INCLUDE_DIR}/CHANGES" _libowfat_changelog)
else()
	# libowfat changelog of a global installation
	find_file(_libowfat_changelog_path
		NAMES "changelog.gz" "changelog.Debian.gz"
		PATHS "/usr/share/doc/libowfat-dev"
		NO_CACHE
		NO_DEFAULT_PATH
	)

	if(NOT _libowfat_changelog_path MATCHES "NOTFOUND")
		execute_process(
			COMMAND gunzip -c ${_libowfat_changelog_path}
			OUTPUT_VARIABLE _libowfat_changelog
			OUTPUT_STRIP_TRAILING_WHITESPACE
			RESULT_VARIABLE _exit_status
		)

		if(NOT _exit_status EQUAL "0")
			message(AUTHOR_WARNING "Failed to inflate libowfat changelog: ${_libowfat_changelog_path}")
		endif()
	else()
		message(AUTHOR_WARNING "Failed to detect libowfat version: cannot find changelog")
	endif()
endif()

# Pick out the first line matching a version string. Conventionally, the
# current version appears near the top of the changelog.
if(_libowfat_changelog)
	string(REGEX MATCH "([0-9]+\\.[0-9]+)(\\.[0-9]+)?" LIBOWFAT_VERSION_STRING "${_libowfat_changelog}")
	set(Libowfat_VERSION "${LIBOWFAT_VERSION_STRING}")
endif()

find_package_handle_standard_args(
	Libowfat
	REQUIRED_VARS
		Libowfat_LIBRARY Libowfat_INCLUDE_DIR
	VERSION_VAR
		Libowfat_VERSION
)

if(Libowfat_FOUND AND NOT TARGET Libowfat::libowfat)
	if(WANT_STATIC_LIBOWFAT)
		add_library(Libowfat::libowfat STATIC IMPORTED)
	else()
		add_library(Libowfat::libowfat UNKNOWN IMPORTED)
	endif()

	set_target_properties(Libowfat::libowfat PROPERTIES
		IMPORTED_LOCATION "${Libowfat_LIBRARY}"
		INTERFACE_INCLUDE_DIRECTORIES "${Libowfat_INCLUDE_DIR}"
	)
endif()

mark_as_advanced(Libowfat_INCLUDE_DIR Libowfat_LIBRARY)

# Initialize Build Environment
cmake_minimum_required(VERSION 3.18.4)

project(opentracker
	DESCRIPTION "This is opentracker. An open bittorrent tracker."
	HOMEPAGE_URL "https://erdgeist.org/arts/software/opentracker"
	LANGUAGES C
)

include(GNUInstallDirs)

set(THREADS_PREFER_PTHREAD_FLAG ON)
set(CMAKE_C_FLAGS "-Wall -pipe -Wextra")
set(CMAKE_C_FLAGS_DEBUG "-g -ggdb")

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Configure Build Options
option(WANT_V4_ONLY "Compile opentracker with IPv4 only (without IPv6)." OFF)
option(WANT_ACCESSLIST_BLACK "Enable support for configuring a torrent blacklist file." OFF)
option(WANT_ACCESSLIST_WHITE "Enable support for configuring a torrent whitelist file." OFF)
option(WANT_DYNAMIC_ACCESSLIST "Enable support for dynamic access lists, with fifo allowing to add or delete torrents." OFF)
option(WANT_COMPRESSION_ZSTD "Compile opentracker with support for zstd compression. Requires libzstd." OFF)
option(WANT_COMPRESSION_ZSTD_ALWAYS "Configure opentracker to always offer zstd compression when serving requests." OFF)
option(WANT_COMPRESSION_GZIP "Compile opentracker with support for gzip compression. Requires zlib." ON)
option(WANT_COMPRESSION_GZIP_ALWAYS "Configure opentracker to always offer gzip compression when serving requests." OFF)
option(WANT_SYNC_LIVE "Build opentracker to run in a cluster." OFF)
option(WANT_IP_FROM_QUERY_STRING "Configure opentracker to use peer addresses from the appropriate query string in announce requests. Recommended only for debugging purposes." OFF)
option(WANT_IP_FROM_PROXY "(Experimental) Use peer address from proxy variables." OFF)
option(WANT_LOG_NETWORKS "(Experimental) Log networks." OFF)
option(WANT_RESTRICT_STATS "Restrict access to sensitive stats endpoint, blessing source addresses through configuration." OFF)
option(WANT_FULLLOG_NETWORKS "Undocumented." OFF)
option(WANT_LOG_NUMWANT "Undocumented." OFF)
option(WANT_MODEST_FULLSCRAPES "Undocumented." OFF)
option(WANT_SPOT_WOODPECKER "Undocumented." OFF)
option(WANT_SYSLOGS "Enable logging to syslog." OFF)
option(WANT_DEV_RANDOM "Use srandomdev (BSD). On Linux, requires libbsd." OFF)
option(WANT_ARC4RANDOM "Use arc4random (BSD). On Linux, requires libbsd." OFF)
option(WANT_FULLSCRAPE "Enable fullscrapes to allow clients to query for all tracked torrents." ON)
option(WANT_NO_AUTO_FREE "Configure opentracker to disable automatic release of chunks during full scrape transfer (default for libowfat <0.34)." OFF)
option(WANT_STATIC_LIBOWFAT "Link against static libowfat library." ON)
option(_DEBUG_HTTPERROR "(Debug) Log HTTP errors." OFF)
option(_DEBUG_RANDOMTORRENTS "(Debug) Generate random peers and torrents at startup for testing." OFF)

# Read Version Information
execute_process(
		COMMAND git rev-parse HEAD
		WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
		OUTPUT_VARIABLE GIT_VERSION
		OUTPUT_STRIP_TRAILING_WHITESPACE
		RESULT_VARIABLE _exit_status
)

if(NOT _exit_status EQUAL "0")
	set(GIT_VERSION "_git_or_commit_not_found_")
endif()

# Load Project Dependencies
find_package(Threads REQUIRED)
find_package(Libowfat REQUIRED)
find_package(ZLIB)
find_package(ZSTD)
find_package(BSD)

if(Libowfat_VERSION AND Libowfat_VERSION VERSION_LESS "0.34")
	message(STATUS "Forcing WANT_NO_AUTO_FREE for compatibility with older libowfat version (${Libowfat_VERSION})")
	set(WANT_NO_AUTO_FREE ON CACHE BOOL "Required for libowfat <0.34." FORCE)
endif()

# Configure Build Targets
set(OPENTRACKER_BUILD_DEFINITIONS
	$<$<BOOL:${WANT_NO_AUTO_FREE}>:WANT_NO_AUTO_FREE>
	$<$<BOOL:${WANT_V4_ONLY}>:WANT_V4_ONLY>
	$<$<BOOL:${WANT_ACCESSLIST_BLACK}>:WANT_ACCESSLIST_BLACK>
	$<$<BOOL:${WANT_ACCESSLIST_WHITE}>:WANT_ACCESSLIST_WHITE>
	$<$<BOOL:${WANT_DYNAMIC_ACCESSLIST}>:WANT_DYNAMIC_ACCESSLIST>
	$<$<BOOL:${WANT_COMPRESSION_ZSTD}>:WANT_COMPRESSION_ZSTD>
	$<$<BOOL:${WANT_COMPRESSION_ZSTD_ALWAYS}>:WANT_COMPRESSION_ZSTD_ALWAYS>
	$<$<BOOL:${WANT_COMPRESSION_GZIP}>:WANT_COMPRESSION_GZIP>
	$<$<BOOL:${WANT_COMPRESSION_GZIP_ALWAYS}>:WANT_COMPRESSION_GZIP_ALWAYS>
	$<$<BOOL:${WANT_SYNC_LIVE}>:WANT_SYNC_LIVE>
	$<$<BOOL:${WANT_IP_FROM_QUERY_STRING}>:WANT_IP_FROM_QUERY_STRING>
	$<$<BOOL:${WANT_IP_FROM_PROXY}>:WANT_IP_FROM_PROXY>
	$<$<BOOL:${WANT_LOG_NETWORKS}>:WANT_LOG_NETWORKS>
	$<$<BOOL:${WANT_RESTRICT_STATS}>:WANT_RESTRICT_STATS>
	$<$<BOOL:${WANT_FULLLOG_NETWORKS}>:WANT_FULLLOG_NETWORKS>
	$<$<BOOL:${WANT_LOG_NUMWANT}>:WANT_LOG_NUMWANT>
	$<$<BOOL:${WANT_MODEST_FULLSCRAPES}>:WANT_MODEST_FULLSCRAPES>
	$<$<BOOL:${WANT_SPOT_WOODPECKER}>:WANT_SPOT_WOODPECKER>
	$<$<BOOL:${WANT_SYSLOGS}>:WANT_SYSLOGS>
	$<$<BOOL:${WANT_DEV_RANDOM}>:WANT_DEV_RANDOM>
	$<$<BOOL:${WANT_ARC4RANDOM}>:WANT_ARC4RANDOM>
	$<$<BOOL:${WANT_FULLSCRAPE}>:WANT_FULLSCRAPE>
	$<$<BOOL:${WANT_NO_AUTO_FREE}>:WANT_NO_AUTO_FREE>

	$<$<CONFIG:Debug>:_DEBUG>
	$<$<BOOL:${_DEBUG_HTTPERROR}>:_DEBUG_HTTPERROR>
	$<$<BOOL:${_DEBUG_RANDOMTORRENTS}>:_DEBUG_RANDOMTORRENTS>

	-DGIT_VERSION=${GIT_VERSION}
)

set(OPENTRACKER_SOURCE_FILES
	opentracker.c trackerlogic.c scan_urlencoded_query.c ot_mutex.c ot_stats.c ot_vector.c ot_clean.c
	ot_udp.c ot_iovec.c ot_fullscrape.c ot_accesslist.c ot_http.c ot_livesync.c ot_rijndael.c
)
add_executable(opentracker ${OPENTRACKER_SOURCE_FILES})
set_target_properties(opentracker PROPERTIES DEBUG_POSTFIX ".debug")
target_compile_definitions(opentracker PUBLIC ${OPENTRACKER_BUILD_DEFINITIONS})

# Link Dependencies
target_link_libraries(opentracker Threads::Threads Libowfat::libowfat)

if(WANT_COMPRESSION_ZSTD)
	target_link_libraries(opentracker ZSTD::libzstd)
endif()
if(WANT_COMPRESSION_GZIP)
	target_link_libraries(opentracker ZLIB::ZLIB)
endif()
if((WANT_DEV_RANDOM OR WANT_ARC4RANDOM) AND CMAKE_SYSTEM_NAME EQUAL "Linux")
	target_link_libraries(opentracker BSD::libbsd)
endif()

# Configure Install Targets
install(TARGETS opentracker RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

#[[
	# opentracker-proxy currently broken by 9000f5d (minor cleanups. Breaks proxy.c, 2024-04-05)
	# uncommand when fixed

set(PROXY_SOURCE_FILES proxy.c ot_vector.c ot_mutex.c)
add_executable(opentracker-proxy ${PROXY_SOURCE_FILES})
set_target_properties(opentracker-proxy PROPERTIES DEBUG_POSTFIX ".debug")
target_compile_definitions(opentracker-proxy PUBLIC ${OPENTRACKER_BUILD_DEFINITIONS})

target_link_libraries(opentracker-proxy Threads::Threads Libowfat::libowfat)
if(WANT_COMPRESSION_ZSTD)
	target_link_libraries(opentracker-proxy ZSTD::libzstd)
endif()
if(WANT_COMPRESSION_GZIP)
	target_link_libraries(opentracker-proxy ZLIB::ZLIB)
endif()
if((WANT_DEV_RANDOM OR WANT_ARC4RANDOM) AND CMAKE_SYSTEM_NAME EQUAL "Linux")
	target_link_libraries(opentracker-proxy BSD::libbsd)
endif()

# Configure Install Targets
install(TARGETS opentracker-proxy RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
]]

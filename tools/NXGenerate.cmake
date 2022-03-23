# -------------------------------
# SPDX-License-Identifier: ISC
#
# Copyright © 2021 Daniel Wolf <<nephatrine@gmail.com>>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.
# -------------------------------

include(_NXInternals)

nx_guard_file()

nx_set(NXGENERATE_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}")

# ===================================================================

if(NOT NX_TARGET_PLATFORM_MSDOS)
	if(NOT DEFINED CMAKE_C_VISIBILITY_PRESET)
		set(CMAKE_C_VISIBILITY_PRESET "hidden")
	endif()
	if(NOT DEFINED CMAKE_CXX_VISIBILITY_PRESET)
		set(CMAKE_CXX_VISIBILITY_PRESET "hidden")
	endif()
	if(NOT DEFINED CMAKE_VISIBILITY_INLINES_HIDDEN)
		set(CMAKE_VISIBILITY_INLINES_HIDDEN ON)
	endif()
endif()

# ===================================================================

function(nx_generate_export_header sBaseName)
	nx_function_begin()

	string(TOUPPER "${sBaseName}" sBaseName)
	string(MAKE_C_IDENTIFIER "${sBaseName}" sBaseName)

	# Defaults

	set(NX_GEH_BASE_NAME ${sBaseName})
	set(NX_GEH_DEFINE_NO_DEPRECATED 0)

	unset(NX_GEH_CUSTOM_CONTENT_FROM_VARIABLE)
	unset(NX_GEH_DEFINE_SYMBOL)
	unset(NX_GEH_DEPRECATED_MACRO_NAME)
	unset(NX_GEH_EXPORT_FILE_NAME)
	unset(NX_GEH_EXPORT_MACRO_CNAME)
	unset(NX_GEH_EXPORT_MACRO_NAME)
	unset(NX_GEH_INCLUDE_GUARD_NAME)
	unset(NX_GEH_NO_DEPRECATED_MACRO_NAME)
	unset(NX_GEH_NO_EXPORT_MACRO_NAME)
	unset(NX_GEH_PREFIX_NAME)
	unset(NX_GEH_STATIC_DEFINE)

	# Parse Args

	set(lsParseModes
		BASE_NAME
		CUSTOM_CONTENT_FROM_VARIABLE
		DEFINE_SYMBOL
		DEPRECATED_MACRO_NAME
		EXPORT_FILE_NAME
		EXPORT_MACRO_CNAME
		EXPORT_MACRO_NAME
		INCLUDE_GUARD_NAME
		NO_DEPRECATED_MACRO_NAME
		NO_EXPORT_MACRO_NAME
		PREFIX_NAME
		STATIC_DEFINE)
	set(lsParseToggles DEFINE_NO_DEPRECATED)
	set(sParseMode "EXPORT_FILE_NAME")

	foreach(sArgument ${ARGN})
		if("${sArgument}" IN_LIST lsParseModes)
			set(sParseMode "${sArgument}")
		elseif("${sArgument}" IN_LIST lsParseToggles)
			set(NX_GEH_${sArgument} 1)
		else()
			set(NX_GEH_${sParseMode} "${sArgument}")
		endif()
	endforeach()

	# Set Variables

	unset(NX_GEH_CUSTOM_CONTENT)

	if(DEFINED NX_GEH_CUSTOM_CONTENT_FROM_VARIABLE)
		if(DEFINED ${NX_GEH_CUSTOM_CONTENT_FROM_VARIABLE})
			set(NX_GEH_CUSTOM_CONTENT "${${NX_GEH_CUSTOM_CONTENT_FROM_VARIABLE}}")
		endif()
	endif()

	if(NOT DEFINED NX_GEH_EXPORT_FILE_NAME)
		string(TOLOWER "${sBaseName}_export.h" NX_GEH_EXPORT_FILE_NAME)
	endif()

	if(NOT DEFINED NX_GEH_DEFINE_SYMBOL)
		if(DEFINED ${sBaseName}_DEFINE_SYMBOL)
			set(NX_GEH_DEFINE_SYMBOL "${${sBaseName}_DEFINE_SYMBOL}")
		else()
			set(NX_GEH_DEFINE_SYMBOL "${NX_GEH_PREFIX_NAME}${NX_GEH_BASE_NAME}_EXPORTS")
		endif()
	endif()

	if(NOT DEFINED NX_GEH_DEPRECATED_MACRO_NAME)
		set(NX_GEH_DEPRECATED_MACRO_NAME "${NX_GEH_PREFIX_NAME}${NX_GEH_BASE_NAME}_DEPRECATED")
	endif()

	if(NOT DEFINED NX_GEH_EXPORT_MACRO_CNAME)
		set(NX_GEH_EXPORT_MACRO_CNAME "${NX_GEH_PREFIX_NAME}${NX_GEH_BASE_NAME}_CEXPORT")
	endif()

	if(NOT DEFINED NX_GEH_EXPORT_MACRO_NAME)
		set(NX_GEH_EXPORT_MACRO_NAME "${NX_GEH_PREFIX_NAME}${NX_GEH_BASE_NAME}_EXPORT")
	endif()

	if(NOT DEFINED NX_GEH_INCLUDE_GUARD_NAME)
		get_filename_component(NX_GEH_INCLUDE_GUARD_NAME "${NX_GEH_EXPORT_FILE_NAME}" NAME)
		string(TOUPPER "${PROJECT_NAME}" NX_GEH_INCLUDE_GUARD_PREFIX)
		string(TOUPPER "${NX_GEH_INCLUDE_GUARD_NAME}" NX_GEH_INCLUDE_GUARD_NAME)
		if(NOT NX_GEH_INCLUDE_GUARD_NAME MATCHES "^${NX_GEH_INCLUDE_GUARD_PREFIX}")
			set(NX_GEH_INCLUDE_GUARD_NAME "${NX_GEH_INCLUDE_GUARD_PREFIX}_${NX_GEH_INCLUDE_GUARD_NAME}")
		endif()
		string(MAKE_C_IDENTIFIER "${NX_GEH_INCLUDE_GUARD_NAME}" NX_GEH_INCLUDE_GUARD_NAME)
		set(NX_GEH_INCLUDE_GUARD_NAME "${NX_GEH_PREFIX_NAME}${NX_GEH_INCLUDE_GUARD_NAME}")
	endif()

	if(NOT DEFINED NX_GEH_NO_DEPRECATED_MACRO_NAME)
		set(NX_GEH_NO_DEPRECATED_MACRO_NAME "${NX_GEH_PREFIX_NAME}${NX_GEH_BASE_NAME}_NO_DEPRECATED")
	endif()

	if(NOT DEFINED NX_GEH_NO_EXPORT_MACRO_NAME)
		set(NX_GEH_NO_EXPORT_MACRO_NAME "${NX_GEH_PREFIX_NAME}${NX_GEH_BASE_NAME}_NO_EXPORT")
	endif()

	if(NOT DEFINED NX_GEH_STATIC_DEFINE)
		if(DEFINED ${sBaseName}_STATIC_DEFINE)
			set(NX_GEH_STATIC_DEFINE "${${sBaseName}_STATIC_DEFINE}")
		else()
			set(NX_GEH_STATIC_DEFINE "${NX_GEH_PREFIX_NAME}${NX_GEH_BASE_NAME}_STATIC_DEFINE")
		endif()
	endif()

	nx_set(${sBaseName}_DEFINE_SYMBOL "${NX_GEH_DEFINE_SYMBOL}")
	nx_set(${sBaseName}_STATIC_DEFINE "${NX_GEH_STATIC_DEFINE}")

	if(NOT DEFINED _CURRENT_YEAR)
		string(TIMESTAMP _CURRENT_YEAR "%Y")
	endif()
	if(NOT DEFINED _CURRENT_DATE)
		string(TIMESTAMP _CURRENT_DATE "%Y%m%d")
	endif()

	# Configuration

	nx_mkpath("${CMAKE_CURRENT_BINARY_DIR}/${NX_GEH_EXPORT_FILE_NAME}")
	configure_file("${NXGENERATE_DIRECTORY}/NXGenerateExportHeader.h.in" "${CMAKE_CURRENT_BINARY_DIR}/${NX_GEH_EXPORT_FILE_NAME}")

	nx_function_end()
endfunction()

# ===================================================================

function(nx_generate_version_header sBaseName)
	nx_function_begin()

	string(TOUPPER "${sBaseName}" sBaseName)
	string(MAKE_C_IDENTIFIER "${sBaseName}" sBaseName)

	# Defaults

	set(NX_GVH_BASE_NAME ${sBaseName})
	set(NX_GVH_QUERY_GIT 0)

	if(DEFINED PROJECT_VERSION)
		set(NX_GVH_VERSION ${PROJECT_VERSION})
	else()
		set(NX_GVH_VERSION "0.0.0")
	endif()

	unset(NX_GVH_CUSTOM_CONTENT_FROM_VARIABLE)
	unset(NX_GVH_GIT_MACRO_NAME)
	unset(NX_GVH_INCLUDE_GUARD_NAME)
	unset(NX_GVH_PREFIX_NAME)
	unset(NX_GVH_VERSION_FILE_NAME)
	unset(NX_GVH_VERSION_MACRO_NAME)

	# Parse Args

	set(lsParseModes
		BASE_NAME
		CUSTOM_CONTENT_FROM_VARIABLE
		GIT_MACRO_NAME
		INCLUDE_GUARD_NAME
		PREFIX_NAME
		VERSION
		VERSION_FILE_NAME
		VERSION_MACRO_NAME)
	set(lsParseToggles QUERY_GIT)
	set(sParseMode "VERSION_FILE_NAME")

	foreach(sArgument ${ARGN})
		if("${sArgument}" IN_LIST lsParseModes)
			set(sParseMode "${sArgument}")
		elseif("${sArgument}" IN_LIST lsParseToggles)
			set(NX_GVH_${sArgument} 1)
		else()
			set(NX_GVH_${sParseMode} "${sArgument}")
		endif()
	endforeach()

	# Set Variables

	unset(NX_GVH_CUSTOM_CONTENT)

	if(DEFINED NX_GVH_CUSTOM_CONTENT_FROM_VARIABLE)
		if(DEFINED ${NX_GVH_CUSTOM_CONTENT_FROM_VARIABLE})
			set(NX_GVH_CUSTOM_CONTENT "${${NX_GVH_CUSTOM_CONTENT_FROM_VARIABLE}}")
		endif()
	endif()

	if(NOT DEFINED NX_GVH_VERSION_FILE_NAME)
		string(TOLOWER "${sBaseName}_version.h" NX_GVH_VERSION_FILE_NAME)
	endif()

	if(NOT DEFINED NX_GVH_GIT_MACRO_NAME)
		set(NX_GVH_GIT_MACRO_NAME "${NX_GVH_PREFIX_NAME}${NX_GVH_BASE_NAME}_GIT")
	endif()

	if(NOT DEFINED NX_GVH_INCLUDE_GUARD_NAME)
		get_filename_component(NX_GVH_INCLUDE_GUARD_NAME "${NX_GVH_VERSION_FILE_NAME}" NAME)
		string(TOUPPER "${PROJECT_NAME}" NX_GVH_INCLUDE_GUARD_PREFIX)
		string(TOUPPER "${NX_GVH_INCLUDE_GUARD_NAME}" NX_GVH_INCLUDE_GUARD_NAME)
		if(NOT NX_GVH_INCLUDE_GUARD_NAME MATCHES "^${NX_GVH_INCLUDE_GUARD_PREFIX}")
			set(NX_GVH_INCLUDE_GUARD_NAME "${NX_GVH_INCLUDE_GUARD_PREFIX}_${NX_GVH_INCLUDE_GUARD_NAME}")
		endif()
		string(MAKE_C_IDENTIFIER "${NX_GVH_INCLUDE_GUARD_NAME}" NX_GVH_INCLUDE_GUARD_NAME)
		set(NX_GVH_INCLUDE_GUARD_NAME "${NX_GVH_PREFIX_NAME}${NX_GVH_INCLUDE_GUARD_NAME}")
	endif()

	if(NOT DEFINED NX_GVH_VERSION_MACRO_NAME)
		set(NX_GVH_VERSION_MACRO_NAME "${NX_GVH_PREFIX_NAME}${NX_GVH_BASE_NAME}_VERSION")
	endif()

	if(NOT DEFINED _CURRENT_YEAR)
		string(TIMESTAMP _CURRENT_YEAR "%Y")
	endif()
	if(NOT DEFINED _CURRENT_DATE)
		string(TIMESTAMP _CURRENT_DATE "%Y%m%d")
	endif()

	string(REPLACE "." ";" lsVersionComponents "${NX_GVH_VERSION}")
	list(LENGTH lsVersionComponents nVersionComponents)

	if(nVersionComponents GREATER 0)
		list(GET lsVersionComponents 0 NX_GVH_VERSION_MAJOR)
	else()
		set(NX_GVH_VERSION_MAJOR 0)
	endif()
	if(nVersionComponents GREATER 1)
		list(GET lsVersionComponents 1 NX_GVH_VERSION_MINOR)
	else()
		set(NX_GVH_VERSION_MINOR 0)
	endif()
	if(nVersionComponents GREATER 2)
		list(GET lsVersionComponents 2 NX_GVH_VERSION_PATCH)
	else()
		set(NX_GVH_VERSION_PATCH 0)
	endif()

	set(NX_GVH_VERSION_HEX "${NX_GVH_VERSION_MAJOR}*65536 + ${NX_GVH_VERSION_MINOR}*256 + ${NX_GVH_VERSION_PATCH}")
	math(EXPR NX_GVH_VERSION_HEX "${NX_GVH_VERSION_HEX}" OUTPUT_FORMAT HEXADECIMAL)

	# Configuration

	nx_mkpath("${CMAKE_CURRENT_BINARY_DIR}/${NX_GVH_VERSION_FILE_NAME}")
	if(NX_GVH_QUERY_GIT)
		if(NOT DEFINED NX_GIT_WATCH_VARS)
			include(GitWatch)
		endif()
		get_filename_component(NX_GVH_VERSION_FILE_TEMP "${NX_GVH_VERSION_FILE_NAME}" NAME)
		configure_file("${NXGENERATE_DIRECTORY}/NXGenerateVersionHeaderGit.h.in"
						"${CMAKE_CURRENT_BINARY_DIR}/${NX_GVH_VERSION_FILE_TEMP}.in" @ONLY)
		nx_git_configure("${CMAKE_CURRENT_BINARY_DIR}/${NX_GVH_VERSION_FILE_TEMP}.in"
							"${CMAKE_CURRENT_BINARY_DIR}/${NX_GVH_VERSION_FILE_NAME}")
	else()
		configure_file("${NXGENERATE_DIRECTORY}/NXGenerateVersionHeader.h.in" "${CMAKE_CURRENT_BINARY_DIR}/${NX_GVH_VERSION_FILE_NAME}")
	endif()

	nx_function_end()
endfunction()

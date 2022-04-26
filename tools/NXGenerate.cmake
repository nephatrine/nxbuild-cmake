# -------------------------------
# SPDX-License-Identifier: ISC
#
# Copyright © 2022 Daniel Wolf <<nephatrine@gmail.com>>
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

# cmake-lint: disable=C0111,R0912,R0915

include(_NXInternals)

if(NOT NX_TARGET_PLATFORM_MSDOS)
	if(NX_HOST_LANGUAGE_C)
		set(CMAKE_C_VISIBILITY_PRESET "hidden")
	endif()
	if(NX_HOST_LANGUAGE_CXX)
		set(CMAKE_CXX_VISIBILITY_PRESET "hidden")
		set(CMAKE_VISIBILITY_INLINES_HIDDEN ON)
	endif()
endif()

_nx_guard_file()

nx_set(NXGENERATE_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}")

# ===================================================================

function(nx_generate_export_header sBaseName)
	_nx_function_begin()

	string(TOUPPER "${sBaseName}" sBaseName)
	string(MAKE_C_IDENTIFIER "${sBaseName}" sBaseName)

	# PARSER START ====

	_nx_parser_initialize()

	set(lsKeywordToggle "DEFINE_NO_DEPRECATED")
	set(lsKeywordSingle
		"BASE_NAME"
		"CEXPORT_MACRO_NAME"
		"CIMPORT_MACRO_NAME"
		"CUSTOM_CONTENT"
		"CUSTOM_CONTENT_FROM_VARIABLE"
		"DEFINE_SYMBOL"
		"DEPRECATED_MACRO_NAME"
		"EXPORT_FILE_NAME"
		"EXPORT_MACRO_NAME"
		"IMPORT_MACRO_NAME"
		"INCLUDE_GUARD_NAME"
		"NO_DEPRECATED_MACRO_NAME"
		"NO_EXPORT_MACRO_NAME"
		"PREFIX_NAME"
		"STATIC_DEFINE")

	set(sParseMode "EXPORT_FILE_NAME")

	_nx_parser_clear()

	set(sNextEXPORT_FILE_NAME "BASE_NAME")
	set(sNextEXPORT_MACRO_NAME "CEXPORT_MACRO_NAME")
	set(sNextIMPORT_MACRO_NAME "CIMPORT_MACRO_NAME")

	_nx_parser_run(${ARGN})

	# ==== PARSER END

	if(NOT DEFINED bArgDEFINE_NO_DEPRECATED)
		set(bArgDEFINE_NO_DEPRECATED 0)
	endif()

	if(NOT DEFINED sArgBASE_NAME)
		set(sArgBASE_NAME ${sBaseName})
	endif()

	if(DEFINED sArgCUSTOM_CONTENT_FROM_VARIABLE)
		if(DEFINED ${sArgCUSTOM_CONTENT_FROM_VARIABLE})
			set(sArgCUSTOM_CONTENT "${${sArgCUSTOM_CONTENT_FROM_VARIABLE}}")
		endif()
	endif()

	if(NOT DEFINED sArgDEFINE_SYMBOL)
		if(DEFINED ${sBaseName}_DEFINE_SYMBOL)
			set(sArgDEFINE_SYMBOL "${${sBaseName}_DEFINE_SYMBOL}")
		else()
			set(sArgDEFINE_SYMBOL "${sArgPREFIX_NAME}${sArgBASE_NAME}_EXPORTS")
		endif()
	endif()

	if(NOT DEFINED sArgDEPRECATED_MACRO_NAME)
		set(sArgDEPRECATED_MACRO_NAME "${sArgPREFIX_NAME}${sArgBASE_NAME}_DEPRECATED")
	endif()

	if(NOT DEFINED sArgEXPORT_FILE_NAME)
		string(TOLOWER "${sBaseName}_export.h" sArgEXPORT_FILE_NAME)
	endif()

	if(NOT DEFINED sArgEXPORT_MACRO_NAME)
		set(sArgEXPORT_MACRO_NAME "${sArgPREFIX_NAME}${sArgBASE_NAME}_EXPORT")
	endif()
	if(NOT DEFINED sArgCEXPORT_MACRO_NAME)
		set(sArgCEXPORT_MACRO_NAME "${sArgPREFIX_NAME}${sArgBASE_NAME}_CEXPORT")
	endif()

	if(NOT DEFINED sArgIMPORT_MACRO_NAME)
		set(sArgIMPORT_MACRO_NAME "${sArgPREFIX_NAME}${sArgBASE_NAME}_API")
	endif()
	if(NOT DEFINED sArgCIMPORT_MACRO_NAME)
		set(sArgCIMPORT_MACRO_NAME "${sArgPREFIX_NAME}${sArgBASE_NAME}_CAPI")
	endif()

	if(NOT DEFINED sArgNO_DEPRECATED_MACRO_NAME)
		set(sArgNO_DEPRECATED_MACRO_NAME "${sArgPREFIX_NAME}${sArgBASE_NAME}_NO_DEPRECATED")
	endif()

	if(NOT DEFINED sArgNO_EXPORT_MACRO_NAME)
		set(sArgNO_EXPORT_MACRO_NAME "${sArgPREFIX_NAME}${sArgBASE_NAME}_PRIVATE")
	endif()

	if(NOT DEFINED sArgSTATIC_DEFINE)
		if(DEFINED ${sBaseName}_STATIC_DEFINE)
			set(sArgSTATIC_DEFINE "${${sBaseName}_STATIC_DEFINE}")
		else()
			set(sArgSTATIC_DEFINE "${sArgPREFIX_NAME}${sArgBASE_NAME}_STATIC")
		endif()
	endif()

	if(NOT DEFINED sArgINCLUDE_GUARD_NAME)
		get_filename_component(sArgINCLUDE_GUARD_NAME "${sArgEXPORT_FILE_NAME}" NAME)
		string(TOUPPER "${sArgINCLUDE_GUARD_NAME}" sArgINCLUDE_GUARD_NAME)
		string(MAKE_C_IDENTIFIER "${sArgINCLUDE_GUARD_NAME}" sArgINCLUDE_GUARD_NAME)
		if(NOT sArgINCLUDE_GUARD_NAME MATCHES "^${sArgBASE_NAME}")
			set(sArgINCLUDE_GUARD_NAME "${sArgBASE_NAME}_${sArgINCLUDE_GUARD_NAME}")
		endif()
		set(sArgINCLUDE_GUARD_NAME "${sArgPREFIX_NAME}${sArgINCLUDE_GUARD_NAME}")
	endif()

	nx_set(${sBaseName}_DEFINE_SYMBOL "${sArgDEFINE_SYMBOL}")
	nx_set(${sBaseName}_STATIC_DEFINE "${sArgSTATIC_DEFINE}")

	if(NOT DEFINED _CURRENT_YEAR)
		string(TIMESTAMP _CURRENT_YEAR "%Y")
	endif()
	if(NOT DEFINED _CURRENT_DATE)
		string(TIMESTAMP _CURRENT_DATE "%Y%m%d")
	endif()

	nx_mkpath("${CMAKE_CURRENT_BINARY_DIR}/${sArgEXPORT_FILE_NAME}")
	configure_file("${NXGENERATE_DIRECTORY}/NXGenerateExportHeader.h.in" "${CMAKE_CURRENT_BINARY_DIR}/${sArgEXPORT_FILE_NAME}")

	_nx_function_end()
endfunction()

# ===================================================================

function(nx_generate_version_header sBaseName)
	_nx_function_begin()

	string(TOUPPER "${sBaseName}" sBaseName)
	string(MAKE_C_IDENTIFIER "${sBaseName}" sBaseName)

	# PARSER START ====

	_nx_parser_initialize()

	set(lsKeywordToggle "QUERY_GIT")
	set(lsKeywordSingle
		"BASE_NAME"
		"CUSTOM_CONTENT"
		"CUSTOM_CONTENT_FROM_VARIABLE"
		"GIT_MACRO_NAME"
		"INCLUDE_GUARD_NAME"
		"PREFIX_NAME"
		"VERSION"
		"VERSION_FILE_NAME"
		"VERSION_MACRO_NAME")

	set(sParseMode "VERSION_FILE_NAME")

	_nx_parser_clear()

	set(sNextVERSION_FILE_NAME "BASE_NAME")

	_nx_parser_run(${ARGN})

	# ==== PARSER END

	if(NOT DEFINED bArgQUERY_GIT)
		set(bArgQUERY_GIT OFF)
	endif()

	if(NOT DEFINED sArgBASE_NAME)
		set(sArgBASE_NAME ${sBaseName})
	endif()

	if(DEFINED sArgCUSTOM_CONTENT_FROM_VARIABLE)
		if(DEFINED ${sArgCUSTOM_CONTENT_FROM_VARIABLE})
			set(sArgCUSTOM_CONTENT "${${sArgCUSTOM_CONTENT_FROM_VARIABLE}}")
		endif()
	endif()

	if(NOT DEFINED sArgGIT_MACRO_NAME)
		set(sArgGIT_MACRO_NAME "${sArgPREFIX_NAME}${sArgBASE_NAME}_GIT")
	endif()

	if(NOT DEFINED sArgVERSION)
		if(DEFINED PROJECT_VERSION)
			set(sArgVERSION ${PROJECT_VERSION})
		elseif(DEFINED "${NX_PROJECT_NAME}_PROJECT_VERSION")
			set(sArgVERSION "${NX_PROJECT_NAME}_PROJECT_VERSION")
		else()
			set(sArgVERSION "0.0.0")
		endif()
	endif()

	if(NOT DEFINED sArgVERSION_FILE_NAME)
		string(TOLOWER "${sArgBASE_NAME}_version.h" sArgVERSION_FILE_NAME)
	endif()

	if(NOT DEFINED sArgVERSION_MACRO_NAME)
		set(sArgVERSION_MACRO_NAME "${sArgPREFIX_NAME}${sArgBASE_NAME}_VERSION")
	endif()

	if(NOT DEFINED sArgINCLUDE_GUARD_NAME)
		get_filename_component(sArgINCLUDE_GUARD_NAME "${sArgVERSION_FILE_NAME}" NAME)
		string(TOUPPER "${sArgINCLUDE_GUARD_NAME}" sArgINCLUDE_GUARD_NAME)
		string(MAKE_C_IDENTIFIER "${sArgINCLUDE_GUARD_NAME}" sArgINCLUDE_GUARD_NAME)
		if(NOT sArgINCLUDE_GUARD_NAME MATCHES "^${sArgBASE_NAME}")
			set(sArgINCLUDE_GUARD_NAME "${sArgBASE_NAME}_${sArgINCLUDE_GUARD_NAME}")
		endif()
		set(sArgINCLUDE_GUARD_NAME "${sArgPREFIX_NAME}${sArgINCLUDE_GUARD_NAME}")
	endif()

	if(NOT DEFINED _CURRENT_YEAR)
		string(TIMESTAMP _CURRENT_YEAR "%Y")
	endif()
	if(NOT DEFINED _CURRENT_DATE)
		string(TIMESTAMP _CURRENT_DATE "%Y%m%d")
	endif()

	string(REPLACE "." ";" lsVersionComponents "${sArgVERSION}")
	list(LENGTH lsVersionComponents nVersionComponents)

	if(nVersionComponents GREATER 0)
		list(GET lsVersionComponents 0 sArgVERSION_MAJOR)
	else()
		set(sArgVERSION_MAJOR 0)
	endif()
	if(nVersionComponents GREATER 1)
		list(GET lsVersionComponents 1 sArgVERSION_MINOR)
	else()
		set(sArgVERSION_MINOR 0)
	endif()
	if(nVersionComponents GREATER 2)
		list(GET lsVersionComponents 2 sArgVERSION_PATCH)
	else()
		set(sArgVERSION_PATCH 0)
	endif()

	set(sArgVERSION_HEX "${sArgVERSION_MAJOR}*65536 + ${sArgVERSION_MINOR}*256 + ${sArgVERSION_PATCH}")
	math(EXPR sArgVERSION_HEX "${sArgVERSION_HEX}" OUTPUT_FORMAT HEXADECIMAL)

	nx_mkpath("${CMAKE_CURRENT_BINARY_DIR}/${sArgVERSION_FILE_NAME}")
	if(bArgQUERY_GIT)
		if(NOT DEFINED NX_GITWATCH_VARS)
			include(GitWatch)
		endif()
		get_filename_component(sIntermediateFile "${sArgVERSION_FILE_NAME}" NAME)
		configure_file("${NXGENERATE_DIRECTORY}/NXGenerateVersionHeaderGit.h.in" "${CMAKE_CURRENT_BINARY_DIR}/${sIntermediateFile}.in"
						@ONLY)
		nx_git_configure("${CMAKE_CURRENT_BINARY_DIR}/${sIntermediateFile}.in" "${CMAKE_CURRENT_BINARY_DIR}/${sArgVERSION_FILE_NAME}")
	else()
		configure_file("${NXGENERATE_DIRECTORY}/NXGenerateVersionHeader.h.in" "${CMAKE_CURRENT_BINARY_DIR}/${sArgVERSION_FILE_NAME}")
	endif()

	_nx_function_end()
endfunction()

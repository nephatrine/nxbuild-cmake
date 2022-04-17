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

if(CMAKE_VERSION VERSION_LESS "3.14")
	message(FATAL_ERROR "_NXInternals: Requires CMake 3.14+")
endif()

if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.22")
	cmake_policy(SET CMP0127 NEW)
endif()

if("x${NX_INTERNAL_PROJECT}" STREQUAL "x${PROJECT_NAME}")
	return()
else()
	set(NX_INTERNAL_PROJECT "${PROJECT_NAME}")
endif()

string(TOUPPER "${NX_INTERNAL_PROJECT}" NX_PROJECT_NAME)
string(MAKE_C_IDENTIFIER "_${NX_PROJECT_NAME}" NX_PROJECT_NAME)

string(TOUPPER "${NX_INTERNAL_PROJECT}" NX_PROJECT_UPPER)
string(TOLOWER "${NX_INTERNAL_PROJECT}" NX_PROJECT_LOWER)

foreach(_NX_TEMP ${NX_VARLISTS_RESET})
	if(DEFINED ${_NX_TEMP})
		unset(${_NX_TEMP})
	endif()
endforeach()

include(CMakeDependentOption)

# ===================================================================

macro(_nx_function_begin)
	if(NOT DEFINED NX_SCOPE_FUNCTION_ENABLED)
		set(NX_SCOPE_FUNCTION_ENABLED ON)
	else()
		set(NX_SCOPE_FUNCTION_CHILD ON)
	endif()
endmacro()

macro(_nx_function_end)
	if(NX_SCOPE_FUNCTION_ENABLED)
		if(DEFINED NX_VARLISTS_SORTED AND NX_VARLISTS_SORTED)
			list(REMOVE_DUPLICATES NX_VARLISTS_SORTED)
		endif()

		foreach(vSortedList "NX_VARLISTS_RESET" "NX_VARLISTS_GLOBAL" "NX_VARLISTS_SET" ${NX_VARLISTS_SORTED})
			if(DEFINED ${vSortedList} AND ${vSortedList})
				list(SORT ${vSortedList})
				list(REMOVE_DUPLICATES ${vSortedList})
			endif()
		endforeach()

		foreach(vPropagate "NX_VARLISTS_RESET" "NX_VARLISTS_GLOBAL" "NX_VARLISTS_SORTED" ${NX_VARLISTS_GLOBAL} ${NX_VARLISTS_SET})
			if(DEFINED ${vPropagate})
				set(${vPropagate}
					"${${vPropagate}}"
					PARENT_SCOPE)
			else()
				unset(${vPropagate} PARENT_SCOPE)
			endif()
		endforeach()

		if(DEFINED NX_SCOPE_FUNCTION_CHILD)
			if(DEFINED NX_VARLISTS_SET)
				set(NX_VARLISTS_SET
					"${NX_VARLISTS_SET}"
					PARENT_SCOPE)
			else()
				unset(NX_VARLISTS_SET PARENT_SCOPE)
			endif()
		endif()
	endif()
endmacro()

# ===================================================================

function(nx_set vName)
	_nx_function_begin()

	unset(${vName})

	set(bCacheVar OFF)
	if(DEFINED CACHE{${vName}})
		set(bCacheVar ON)
		get_property(
			sCacheType
			CACHE ${vName}
			PROPERTY TYPE)
		unset(${vName} CACHE)
	endif()

	if(ARGC GREATER 1)
		list(APPEND ${vName} ${ARGN})
	endif()

	if(bCacheVar)
		set(${vName}
			"${${vName}}"
			CACHE ${sCacheType} "Oops All Berries")
	endif()

	if(vName MATCHES "^${NX_PROJECT_NAME}|_${NX_PROJECT_NAME}_")
		list(APPEND NX_VARLISTS_GLOBAL "${vName}")
	elseif(vName MATCHES "^NX_|^CPACK_|^CMAKE_")
		list(APPEND NX_VARLISTS_RESET "${vName}")
		list(APPEND NX_VARLISTS_SET "${vName}")
	else()
		list(APPEND NX_VARLISTS_SET "${vName}")
	endif()

	_nx_function_end()
endfunction()

function(nx_set_global vName)
	_nx_function_begin()
	unset(${vName})

	set(bCacheVar OFF)
	if(DEFINED CACHE{${vName}})
		set(bCacheVar ON)
		get_property(
			sCacheType
			CACHE ${vName}
			PROPERTY TYPE)
		unset(${vName} CACHE)
	endif()

	if(ARGC GREATER 1)
		list(APPEND ${vName} ${ARGN})
	endif()

	if(bCacheVar)
		set(${vName}
			"${${vName}}"
			CACHE ${sCacheType} "Oops All Berries")
	endif()

	list(APPEND NX_VARLISTS_GLOBAL "${vName}")

	_nx_function_end()
endfunction()

function(nx_set_cache vName sValue sType sDesc)
	_nx_function_begin()

	set(${vName} "${sValue}")
	set(${vName}
		"${sValue}"
		CACHE ${sType} "${sDesc}" FORCE)

	list(APPEND NX_VARLISTS_GLOBAL "${vName}")

	_nx_function_end()
endfunction()

function(nx_append vName)
	_nx_function_begin()

	set(bIsCacheVar OFF)
	if(DEFINED CACHE{${vName}})
		set(bIsCacheVar ON)
		get_property(
			sCacheType
			CACHE ${vName}
			PROPERTY TYPE)
		message(FATAL_ERROR "nx_append: DO NOT APPEND TO CACHE VARIABLE")
	endif()

	if(ARGC GREATER 1)
		list(APPEND ${vName} ${ARGN})
	endif()
	if(vName MATCHES "^${NX_PROJECT_NAME}|_${NX_PROJECT_NAME}_")
		list(APPEND NX_VARLISTS_GLOBAL "${vName}")
	elseif(vName MATCHES "^NX_|^CPACK_|^CMAKE_")
		list(APPEND NX_VARLISTS_RESET "${vName}")
		list(APPEND NX_VARLISTS_SET "${vName}")
	else()
		list(APPEND NX_VARLISTS_SET "${vName}")
	endif()
	list(APPEND NX_VARLISTS_SORTED "${vName}")
	_nx_function_end()
endfunction()

function(nx_append_global vName)
	_nx_function_begin()

	set(bIsCacheVar OFF)
	if(DEFINED CACHE{${vName}})
		set(bIsCacheVar ON)
		get_property(
			sCacheType
			CACHE ${vName}
			PROPERTY TYPE)
		message(FATAL_ERROR "nx_append_global: DO NOT APPEND TO CACHE VARIABLE")
	endif()

	if(ARGC GREATER 1)
		list(APPEND ${vName} ${ARGN})
	endif()
	list(APPEND NX_VARLISTS_GLOBAL "${vName}")
	list(APPEND NX_VARLISTS_SORTED "${vName}")
	_nx_function_end()
endfunction()

# ===================================================================

macro(_nx_guard_file)
	get_filename_component(vIncludeGuard "${CMAKE_CURRENT_LIST_FILE}" NAME_WE)
	string(TOUPPER "${vIncludeGuard}_FILE_GUARD" vIncludeGuard)
	string(MAKE_C_IDENTIFIER "${vIncludeGuard}" vIncludeGuard)

	if(DEFINED ${vIncludeGuard})
		return()
	endif()

	nx_set(${vIncludeGuard} ON)
endmacro()

macro(_nx_guard_function sFunctionName)
	string(TOUPPER "${NX_PROJECT_NAME}_${sFunctionName}_GUARD" vFunctionGuard)
	string(MAKE_C_IDENTIFIER "${vFunctionGuard}" vFunctionGuard)

	if(DEFINED ${vFunctionGuard})
		return()
	endif()

	nx_set(${vFunctionGuard} ON)
endmacro()

# ===================================================================

function(nx_mkpath)
	_nx_function_begin()

	unset(lsDirNames)

	foreach(sArgument ${ARGN})
		file(RELATIVE_PATH sPathRelative "${CMAKE_CURRENT_BINARY_DIR}" "${sArgument}")
		string(SUBSTRING "${sPathRelative}" 0 2 sTest)
		if(NOT sTest STREQUAL ".." AND NOT sTest MATCHES ":$")
			get_filename_component(sPathRelative "${sPathRelative}" DIRECTORY)
			list(APPEND lsDirNames "${sPathRelative}")
		endif()
	endforeach()

	foreach(sDirName ${lsDirNames})
		while(NOT sDirName STREQUAL "" AND NOT sDirName STREQUAL "/")
			if(NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/${sDirName}/_folder.dox")
				if(NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/${sDirName}")
					file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${sDirName}")
				endif()
				file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/${sDirName}/_folder.dox"
						"//! @dir ${sDirName}\n" "//! Generated Files. These files are dynamically-generated.\n")
			endif()
			get_filename_component(sDirName "${sDirName}" DIRECTORY)
		endwhile()
	endforeach()

	_nx_function_end()
endfunction()

# ===================================================================

function(nx_string_limit vOut sIn nLength)
	_nx_function_begin()

	string(MAKE_C_IDENTIFIER "${sIn}" sIn)
	string(REGEX REPLACE "^_" "" sIn "${sIn}")
	string(REGEX REPLACE "([a-z])([A-Z])" "\\1_\\2" sIn "${sIn}")

	string(REPLACE "_" ";" lsIn "${sIn}")
	list(LENGTH lsIn nScored)
	math(EXPR nLength "${nLength} + ${nScored} - 1")

	string(LENGTH "${sIn}" nCurrent)
	if(nCurrent GREATER ${nLength})
		string(REGEX REPLACE "([AaEeIiOoUu])[AaEeIiOoUu]" "\\1" sIn "${sIn}")
		string(REGEX REPLACE "[BbCcDdFfHhJjKkLlMmNnPpQqRrSsTtVvWwXxYyZz]([BbCcDdFfHhJjKkLlMmNnPpQqRrSsTtVvWwXxYyZz])" "\\1" sIn "${sIn}")

		math(EXPR nLength "${nLength} - ${nScored} + 1")
		string(REPLACE "_" "" sIn "${sIn}")

		string(LENGTH "${sIn}" nCurrent)
		if(nCurrent GREATER ${nLength})
			string(REGEX REPLACE "[AaEeIiOoUu]" "" sIn "${sIn}")

			string(LENGTH "${sIn}" nCurrent)
			if(nCurrent GREATER ${nLength})
				string(SUBSTRING "${sIn}" 0 ${nLength} sIn)
			endif()
		endif()
	endif()
	set(${vOut}
		"${sIn}"
		PARENT_SCOPE)

	_nx_function_end()
endfunction()

# ===================================================================

macro(_nx_parser_initialize)
	unset(lsKeywordParse)
	unset(lsKeywordCombo)
	unset(lsKeywordToggle)
	unset(lsKeywordSingle)
	unset(lsKeywordMultiple)
	set(sParseMode "NONE")

	foreach(sCombo ${ARGN})
		list(APPEND lsKeywordCombo "${sCombo}")
		unset(lsKeywordToggle${sCombo})
		unset(lsKeywordSingle${sCombo})
		unset(lsKeywordMultiple${sCombo})
	endforeach()

	if(DEFINED lsKeywordCombo)
		set(sComboMode "NONE")
	else()
		unset(sComboMode)
	endif()
endmacro()

macro(_nx_parser_clear)
	foreach(sKeyword ${lsKeywordToggle})
		unset(bArg${sKeyword})
	endforeach()
	foreach(sKeyword ${lsKeywordSingle})
		unset(sArg${sKeyword})
		unset(sNext${sKeyword})
	endforeach()
	foreach(sKeyword ${lsKeywordMultiple})
		unset(lsArg${sKeyword})
	endforeach()
	list(APPEND lsKeywordParse ${lsKeywordToggle} ${lsKeywordSingle} ${lsKeywordMultiple})

	foreach(sCombo ${lsKeywordCombo})
		unset(sDefault${sCombo})
		foreach(sKeyword ${lsKeywordToggle${sCombo}})
			unset(bArg${sKeyword}_${sCombo})
		endforeach()
		foreach(sKeyword ${lsKeywordSingle${sCombo}})
			unset(sArg${sKeyword}_${sCombo})
			unset(sNext${sKeyword}_${sCombo})
		endforeach()
		foreach(sKeyword ${lsKeywordMultiple${sCombo}})
			unset(lsArg${sKeyword}_${sCombo})
		endforeach()
		list(APPEND lsKeywordParse${sCombo} ${lsKeywordToggle${sCombo}} ${lsKeywordSingle${sCombo}} ${lsKeywordMultiple${sCombo}})
	endforeach()
endmacro()

macro(_nx_parser_run)
	foreach(sArgument ${ARGN})
		if(DEFINED lsKeywordCombo AND "${sArgument}" IN_LIST lsKeywordCombo)
			set(sComboMode "${sArgument}")
			if(DEFINED sDefault${sComboMode})
				set(sParseMode ${sDefault${sComboMode}})
			endif()
		elseif(DEFINED lsKeywordToggle AND "${sArgument}" IN_LIST lsKeywordToggle)
			if(DEFINED bArg${sArgument})
				message(AUTHOR_WARNING "_nx_parser_run: Option ${sArgument} Already Set")
			endif()
			set(bArg${sArgument} 1)
		elseif(DEFINED lsKeywordToggle${sComboMode} AND "${sArgument}" IN_LIST lsKeywordToggle${sComboMode})
			if(DEFINED bArg${sArgument}_${sComboMode})
				message(AUTHOR_WARNING "_nx_parser_run: Option ${sArgument}_${sComboMode} Already Set")
			endif()
			set(bArg${sArgument}_${sComboMode} 1)
		elseif(DEFINED lsKeywordParse AND "${sArgument}" IN_LIST lsKeywordParse)
			set(sParseMode "${sArgument}")
		elseif(DEFINED lsKeywordParse${sComboMode} AND "${sArgument}" IN_LIST lsKeywordParse${sComboMode})
			set(sParseMode "${sArgument}")
		elseif(DEFINED lsKeywordSingle AND "${sParseMode}" IN_LIST lsKeywordSingle)
			if(DEFINED sArg${sParseMode})
				message(AUTHOR_WARNING "_nx_parser_run: Option ${sParseMode} Already Set")
			endif()
			set(sArg${sParseMode} "${sArgument}")
			if(DEFINED sNext${sParseMode})
				set(sParseMode "${sNext${sParseMode}}")
			endif()
		elseif(DEFINED lsKeywordSingle${sComboMode} AND "${sParseMode}" IN_LIST lsKeywordSingle${sComboMode})
			if(DEFINED sArg${sParseMode}_${sComboMode})
				message(AUTHOR_WARNING "_nx_parser_run: Option ${sParseMode}_${sComboMode} Already Set")
			endif()
			set(sArg${sParseMode}_${sComboMode} "${sArgument}")
			if(DEFINED sNext${sParseMode}_${sComboMode})
				set(sParseMode "${sNext${sParseMode}_${sComboMode}}")
			endif()
		elseif(DEFINED lsKeywordMultiple AND "${sParseMode}" IN_LIST lsKeywordMultiple)
			list(APPEND lsArg${sParseMode} "${sArgument}")
		elseif(DEFINED lsKeywordMultiple${sComboMode} AND "${sParseMode}" IN_LIST lsKeywordMultiple${sComboMode})
			list(APPEND lsArg${sParseMode}_${sComboMode} "${sArgument}")
		elseif(DEFINED lsKeywordCombo)
			message(AUTHOR_WARNING "_nx_parser_run: Parse Mode ${sParseMode}_${sComboMode} Unknown")
		else()
			message(AUTHOR_WARNING "_nx_parser_run: Parse Mode ${sParseMode} Unknown")
		endif()
	endforeach()
endmacro()

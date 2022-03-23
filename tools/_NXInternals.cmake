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

if(CMAKE_VERSION VERSION_LESS "3.14")
	message(FATAL_ERROR "_NXInternals: Requires CMake 3.14+")
endif()

if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.22")
	# cmake_dependent_option() supports full Condition Syntax
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

foreach(_NX_TEMP ${_NX_VARLISTS_RESET})
	if(DEFINED ${_NX_TEMP})
		unset(${_NX_TEMP})
	endif()
endforeach()

# ===================================================================

macro(nx_function_begin)
	if(NOT DEFINED _NX_SCOPE_FUNCTION_ENABLED)
		set(_NX_SCOPE_FUNCTION_ENABLED ON)
	else()
		set(_NX_SCOPE_FUNCTION_CHILD ON)
	endif()
endmacro()

macro(nx_function_end)
	if(_NX_SCOPE_FUNCTION_ENABLED)
		if(DEFINED _NX_VARLISTS_SORTED AND _NX_VARLISTS_SORTED)
			list(REMOVE_DUPLICATES _NX_VARLISTS_SORTED)
		endif()

		foreach(vPropagate "_NX_VARLISTS_RESET" "_NX_VARLISTS_GLOBAL" "_NX_VARLISTS_SET" "_NX_VARLISTS_LATCHED" ${_NX_VARLISTS_SORTED})
			if(DEFINED ${vPropagate} AND ${vPropagate})
				list(SORT ${vPropagate})
				list(REMOVE_DUPLICATES ${vPropagate})
			endif()
		endforeach()

		foreach(vPropagate "_NX_VARLISTS_RESET" "_NX_VARLISTS_GLOBAL" "_NX_VARLISTS_SORTED" ${_NX_VARLISTS_GLOBAL} ${_NX_VARLISTS_SET}
							${_NX_VARLISTS_LATCHED})
			if(DEFINED ${vPropagate})
				set(${vPropagate}
					"${${vPropagate}}"
					PARENT_SCOPE)
			else()
				unset(${vPropagate} PARENT_SCOPE)
			endif()
		endforeach()

		if(DEFINED _NX_SCOPE_FUNCTION_CHILD)
			if(DEFINED _NX_VARLISTS_SET)
				set(_NX_VARLISTS_SET
					"${_NX_VARLISTS_SET}"
					PARENT_SCOPE)
			else()
				unset(_NX_VARLISTS_SET PARENT_SCOPE)
			endif()
		endif()
	endif()
endmacro()

# ===================================================================

function(nx_set vName)
	nx_function_begin()
	unset(${vName})

	set(bIsCacheVar OFF)
	if(DEFINED CACHE{${vName}})
		set(bIsCacheVar ON)
		get_property(
			sCacheType
			CACHE ${vName}
			PROPERTY TYPE)
		unset(${vName} CACHE)
	endif()

	if(ARGC GREATER 1)
		list(APPEND ${vName} ${ARGN})
	endif()

	if(bIsCacheVar)
		set(${vName}
			"${${vName}}"
			CACHE ${sCacheType} "")
	endif()

	if(vName MATCHES "^${NX_PROJECT_NAME}|_${NX_PROJECT_NAME}_")
		list(APPEND _NX_VARLISTS_GLOBAL "${vName}")
		# message(STATUS "Globalizing ${vName}: ${${vName}}")
	elseif(vName MATCHES "^NX_|^CPACK_|^CMAKE_")
		list(APPEND _NX_VARLISTS_RESET "${vName}")
		list(APPEND _NX_VARLISTS_SET "${vName}")
	else()
		list(APPEND _NX_VARLISTS_SET "${vName}")
	endif()
	nx_function_end()
endfunction()

function(nx_set_global vName)
	nx_function_begin()
	unset(${vName})

	set(bIsCacheVar OFF)
	if(DEFINED CACHE{${vName}})
		set(bIsCacheVar ON)
		get_property(
			sCacheType
			CACHE ${vName}
			PROPERTY TYPE)
		unset(${vName} CACHE)
	endif()

	if(ARGC GREATER 1)
		list(APPEND ${vName} ${ARGN})
	endif()

	if(bIsCacheVar)
		set(${vName}
			"${${vName}}"
			CACHE ${sCacheType} "")
	endif()

	list(APPEND _NX_VARLISTS_GLOBAL "${vName}")
	nx_function_end()
endfunction()

function(nx_set_latched vName)
	nx_function_begin()
	unset(${vName})

	set(bIsCacheVar OFF)
	if(DEFINED CACHE{${vName}})
		set(bIsCacheVar ON)
		get_property(
			sCacheType
			CACHE ${vName}
			PROPERTY TYPE)
		unset(${vName} CACHE)
	endif()

	if(ARGC GREATER 1)
		list(APPEND ${vName} ${ARGN})
	endif()

	if(bIsCacheVar)
		set(${vName}
			"${${vName}}"
			CACHE ${sCacheType} "")
	endif()

	list(APPEND _NX_VARLISTS_LATCHED "${vName}")
	nx_function_end()
endfunction()

function(nx_append vName)
	nx_function_begin()

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
		list(APPEND _NX_VARLISTS_GLOBAL "${vName}")
		# message(STATUS "Globalizing ${vName}: ${${vName}}")
	elseif(vName MATCHES "^NX_|^CPACK_|^CMAKE_")
		list(APPEND _NX_VARLISTS_RESET "${vName}")
		list(APPEND _NX_VARLISTS_SET "${vName}")
	else()
		list(APPEND _NX_VARLISTS_SET "${vName}")
	endif()
	list(APPEND _NX_VARLISTS_SORTED "${vName}")
	nx_function_end()
endfunction()

function(nx_append_global vName)
	nx_function_begin()

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
	list(APPEND _NX_VARLISTS_GLOBAL "${vName}")
	list(APPEND _NX_VARLISTS_SORTED "${vName}")
	nx_function_end()
endfunction()

function(nx_latch)
	nx_function_begin()
	foreach(vLatch _NX_VARLISTS_GLOBAL _NX_VARLISTS_SET ${_NX_VARLISTS_GLOBAL} ${_NX_VARLISTS_SET})
		nx_set_latched(LATCHED_${vLatch} ${${vLatch}})
	endforeach()
	nx_function_end()
endfunction()

function(nx_unlatch)
	nx_function_begin()
	foreach(vLatch _NX_VARLISTS_GLOBAL ${LATCHED_NX_VARLISTS_GLOBAL})
		nx_set_global(${vLatch} ${LATCHED_${vLatch}})
	endforeach()
	foreach(vLatch _NX_VARLISTS_SET ${LATCHED_NX_VARLISTS_SET})
		nx_set(${vLatch} ${LATCHED_${vLatch}})
	endforeach()
	nx_function_end()
endfunction()

# ===================================================================

macro(nx_guard_file)
	get_filename_component(vIncludeGuard "${CMAKE_CURRENT_LIST_FILE}" NAME_WE)
	string(TOUPPER "${vIncludeGuard}_FILE_GUARD" vIncludeGuard)
	string(MAKE_C_IDENTIFIER "${vIncludeGuard}" vIncludeGuard)

	if(DEFINED ${vIncludeGuard})
		return()
	endif()

	nx_set(${vIncludeGuard} ON)
endmacro()

macro(nx_guard_function sFunctionName)
	string(TOUPPER "${NX_PROJECT_NAME}_${sFunctionName}_GUARD" vFunctionGuard)
	string(MAKE_C_IDENTIFIER "${vFunctionGuard}" vFunctionGuard)

	if(DEFINED ${vFunctionGuard})
		return()
	endif()

	nx_set(${vFunctionGuard} ON)
endmacro()

# ===================================================================

include(CMakeDependentOption)

macro(nx_option sFeature sDescription bDefault)
	string(TOUPPER "${sFeature}" sOption)
	string(MAKE_C_IDENTIFIER "${sOption}" sOption)

	option(${sOption} "${sDescription}" ${bDefault})
	if(COMMAND add_feature_info)
		add_feature_info("${sFeature}" ${sOption} "${sDescription}.")
	endif()
endmacro()

macro(nx_dependent_option sFeature sDescription bDefault lsDepends bForce)
	string(TOUPPER "${sFeature}" sOption)
	string(MAKE_C_IDENTIFIER "${sOption}" sOption)

	cmake_dependent_option(${sOption} "${sDescription}" ${bDefault} "${lsDepends}" ${bForce})
	if(COMMAND add_feature_info)
		set(_NX_TEMP ON)
		foreach(_d ${lsDepends})
			string(REGEX REPLACE " +" ";" _d "${_d}")
			if(${_d})

			else()
				set(_NX_TEMP OFF)
			endif()
		endforeach()
		if(_NX_TEMP OR ${bForce})
			add_feature_info("${sFeature}" ${sOption} "${sDescription}.")
		endif()
	endif()
endmacro()

# ===================================================================

macro(nx_find_package sPackage sType sDescription)
	find_package(${sPackage} MODULE)
	if(COMMAND set_package_properties)
		set_package_properties(
			${sPackage} PROPERTIES
			TYPE ${sType}
			PURPOSE "${sDescription}.")
	endif()
endmacro()

macro(nx_find_package_components sPackage lsComponents sType sDescription)
	find_package(${sPackage} MODULE COMPONENTS ${lsComponents})
	if(COMMAND set_package_properties)
		set_package_properties(
			${sPackage} PROPERTIES
			TYPE ${sType}
			PURPOSE "${sDescription}.")
	endif()
endmacro()

# ===================================================================

function(nx_mkpath)
	nx_function_begin()

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

	nx_function_end()
endfunction()

# ===================================================================

function(nx_string_limit vOut sIn iMaxLen)
	nx_function_begin()

	string(MAKE_C_IDENTIFIER "${sIn}" sIn)
	string(REGEX REPLACE "^_" "" sIn "${sIn}")
	string(REGEX REPLACE "([a-z])([A-Z])" "\\1_\\2" sIn "${sIn}")

	string(REPLACE "_" ";" lsIn "${sIn}")
	list(LENGTH lsIn iUScore)
	math(EXPR iMaxLen "${iMaxLen} + ${iUScore} - 1")

	string(LENGTH "${sIn}" iCurLen)
	if(iCurLen GREATER ${iMaxLen})
		string(REGEX REPLACE "([AaEeIiOoUu])[AaEeIiOoUu]" "\\1" sIn "${sIn}")
		string(REGEX REPLACE "[BbCcDdFfHhJjKkLlMmNnPpQqRrSsTtVvWwXxYyZz]([BbCcDdFfHhJjKkLlMmNnPpQqRrSsTtVvWwXxYyZz])" "\\1" sIn "${sIn}")

		math(EXPR iMaxLen "${iMaxLen} - ${iUScore} + 1")
		string(REPLACE "_" "" sIn "${sIn}")

		string(LENGTH "${sIn}" iCurLen)
		if(iCurLen GREATER ${iMaxLen})
			string(REGEX REPLACE "[AaEeIiOoUu]" "" sIn "${sIn}")

			string(LENGTH "${sIn}" iCurLen)
			if(iCurLen GREATER ${iMaxLen})
				string(SUBSTRING "${sIn}" 0 ${iMaxLen} sIn)
			endif()
		endif()
	endif()
	set(${vOut}
		"${sIn}"
		PARENT_SCOPE)

	nx_function_end()
endfunction()

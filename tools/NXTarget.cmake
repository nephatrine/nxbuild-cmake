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

# cmake-lint: disable=C0301,C0307,R0912,R0915

include(CMakePackageConfigHelpers)
include(NXGenerate)
include(NXInstall)

nx_guard_file()

# ===================================================================

set(CMAKE_SHARED_MODULE_PREFIX "")

if(NX_TARGET_PLATFORM_DARWIN)
	set(CMAKE_SHARED_MODULE_SUFFIX ".bundle")
endif()

# if("x${CMAKE_STATIC_LIBRARY_SUFFIX}" STREQUAL "x${CMAKE_IMPORT_LIBRARY_SUFFIX}") set(CMAKE_IMPORT_LIBRARY_SUFFIX
# "${CMAKE_SHARED_LIBRARY_SUFFIX}${CMAKE_STATIC_LIBRARY_SUFFIX}") endif()

# ===================================================================

if(NOT DEFINED BUILD_SHARED_LIBS)
	if(NX_TARGET_PLATFORM_ANDROID OR NX_TARGET_PLATFORM_MSDOS)
		set(BUILD_SHARED_LIBS OFF)
	else()
		set(BUILD_SHARED_LIBS ON)
	endif()
endif()

if(NX_TARGET_PLATFORM_MSDOS)
	set(CMAKE_POSITION_INDEPENDENT_CODE OFF)
else()
	set(CMAKE_POSITION_INDEPENDENT_CODE ON)
endif()

# ===================================================================

include(CMakePushCheckState)

if(NX_HOST_LANGUAGE_C)
	include(CheckCSourceCompiles)

	function(nx_check_c_compiles var_out lst_cflags lst_ldflags)
		nx_function_begin()
		cmake_push_check_state()

		if(DEFINED ${lst_cflags})
			list(APPEND CMAKE_REQUIRED_DEFINITIONS ${${lst_cflags}})
		endif()
		if(DEFINED ${lst_ldflags})
			list(APPEND CMAKE_REQUIRED_LINK_OPTIONS ${${lst_ldflags}})
		endif()
		list(APPEND CMAKE_REQUIRED_LIBRARIES ${ARGN})
		set(CMAKE_REQUIRED_QUIET OFF)

		set(lst_fail_regex
			FAIL_REGEX
			"argument unused during compilation"
			FAIL_REGEX
			"unsupported .*option"
			FAIL_REGEX
			"unknown .*option"
			FAIL_REGEX
			"unrecognized .*option"
			FAIL_REGEX
			"ignoring unknown option"
			FAIL_REGEX
			"warning:.*ignored"
			FAIL_REGEX
			"warning:.*is valid for.*but not for"
			FAIL_REGEX
			"warning:.*redefined"
			FAIL_REGEX
			"[Ww]arning: [Oo]ption")

		set(str_code
			[[
#include <stdio.h>

int main(int argc, char *argv[])
{
	const char *hello = "Hello World";
	printf("%s!", hello);
	return 0;
}
	]])

		check_c_source_compiles("${str_code}" ${var_out} ${lst_fail_regex})
		if(${var_out})
			nx_set(${var_out} ON)
		else()
			nx_set(${var_out} OFF)
		endif()

		cmake_pop_check_state()
		nx_function_end()
	endfunction()
endif()

if(NX_HOST_LANGUAGE_CXX)
	include(CheckCXXSourceCompiles)

	function(nx_check_cxx_compiles var_out lst_cflags lst_ldflags)
		nx_function_begin()
		cmake_push_check_state()

		if(DEFINED ${lst_cflags})
			list(APPEND CMAKE_REQUIRED_DEFINITIONS ${${lst_cflags}})
		endif()
		if(DEFINED ${lst_ldflags})
			list(APPEND CMAKE_REQUIRED_LINK_OPTIONS ${${lst_ldflags}})
		endif()
		list(APPEND CMAKE_REQUIRED_LIBRARIES ${ARGN})
		set(CMAKE_REQUIRED_QUIET OFF)

		set(lst_fail_regex
			FAIL_REGEX
			"argument unused during compilation"
			FAIL_REGEX
			"unsupported .*option"
			FAIL_REGEX
			"unknown .*option"
			FAIL_REGEX
			"unrecognized .*option"
			FAIL_REGEX
			"ignoring unknown option"
			FAIL_REGEX
			"warning:.*ignored"
			FAIL_REGEX
			"warning:.*is valid for.*but not for"
			FAIL_REGEX
			"warning:.*redefined"
			FAIL_REGEX
			"[Ww]arning: [Oo]ption")

		set(str_code
			[[
#include <iostream>
#include <string>

int main(int argc, char *argv[])
{
	const std::string hello = "Hello World";
	std::cout << hello << "!" << std::endl;
	return 0;
}
	]])

		check_cxx_source_compiles("${str_code}" ${var_out} ${lst_fail_regex})
		if(${var_out})
			nx_set(${var_out} ON)
		else()
			nx_set(${var_out} OFF)
		endif()

		cmake_pop_check_state()
		nx_function_end()
	endfunction()
endif()

#
# nx_check_compiles: Test CFLAG and LDFLAG combinations!
#
function(nx_check_compiles var_out lst_cflags lst_ldflags)
	nx_function_begin()

	if(NX_HOST_LANGUAGE_CXX)
		nx_check_cxx_compiles(${var_out} ${lst_cflags} ${lst_ldflags} ${ARGN})
	elseif(NX_HOST_LANGUAGE_C)
		nx_check_c_compiles(${var_out} ${lst_cflags} ${lst_ldflags} ${ARGN})
	else()
		nx_set(${var_out} OFF)
	endif()

	nx_function_end()
endfunction()

# ===================================================================

#
# nx_target_compile_definitions: Set Preprocessor Definitions
#
function(nx_target_compile_definitions)
	nx_function_begin()

	# === Available Parsing Modes ===

	set(lst_pmode_single "DEFINE_SYMBOL" "STATIC_DEFINE")
	set(lst_pmode_multi "TARGET" "PRIVATE" "PUBLIC" "INTERFACE")

	foreach(tmp_pmode ${lst_pmode_single} ${lst_pmode_multi})
		string(TOLOWER "${tmp_pmode}" tmp_pmode)
		unset(arg_define_${tmp_pmode})
	endforeach()

	set(str_pmode_cur "TARGET")

	# === Parse Arguments ===

	foreach(tmp_argv ${ARGN})
		if("${tmp_argv}" IN_LIST lst_pmode_single OR "${tmp_argv}" IN_LIST lst_pmode_multi)
			set(str_pmode_cur "${tmp_argv}")
		elseif("${str_pmode_cur}" IN_LIST lst_pmode_single)
			string(TOLOWER "${str_pmode_cur}" tmp_pmode)
			if(DEFINED arg_define_${tmp_pmode})
				message(AUTHOR_WARNING "nx_target_compile_definitions: Option ${str_pmode_cur} Already Set")
			else()
				set(arg_define_${tmp_pmode} "${tmp_argv}")
			endif()
		elseif("${str_pmode_cur}" IN_LIST lst_pmode_multi)
			string(TOLOWER "${str_pmode_cur}" tmp_pmode)
			list(APPEND arg_define_${tmp_pmode} "${tmp_argv}")
		else()
			message(AUTHOR_WARNING "nx_target_compile_definitions: Parse Mode ${str_pmode_cur} Unknown")
		endif()
	endforeach()

	# === Set Definitions ===

	foreach(tmp_target ${arg_define_target})
		get_target_property(tmp_prop_type ${tmp_target} TYPE)
		if(DEFINED arg_define_define_symbol)
			if(tmp_prop_type MATCHES "SHARED_LIBRARY|MODULE_LIBRARY")
				set_target_properties("${tmp_target}" PROPERTIES DEFINE_SYMBOL "${arg_define_define_symbol}")
			elseif(tmp_prop_type MATCHES "STATIC_LIBRARY|OBJECT_LIBRARY")
				list(APPEND arg_define_private "${arg_define_define_symbol}")
			else()
				message(AUTHOR_WARNING "nx_target_compile_definitions: Ignoring DEFINE_SYMBOL For ${tmp_prop_type}")
			endif()
		endif()
		if(DEFINED arg_define_static_define)
			if(tmp_prop_type STREQUAL "INTERFACE_LIBRARY")
				list(APPEND arg_define_interface "${arg_define_static_define}")
			elseif(tmp_prop_type MATCHES "STATIC_LIBRARY|OBJECT_LIBRARY")
				list(APPEND arg_define_public "${arg_define_static_define}")
			else()
				message(AUTHOR_WARNING "nx_target_compile_definitions: Ignoring STATIC_DEFINE For ${tmp_prop_type}")
			endif()
		endif()

		foreach(tmp_visibility "PUBLIC" "PRIVATE" "INTERFACE")
			string(TOLOWER "${tmp_visibility}" tmp_pmode)
			if(DEFINED arg_define_${tmp_pmode})
				string(REPLACE ">:-D" ">:" arg_define_${tmp_pmode} "${arg_define_${tmp_pmode}}")
				target_compile_definitions("${tmp_target}" ${tmp_visibility} ${arg_define_${tmp_pmode}})
			endif()
		endforeach()
	endforeach()

	nx_function_end()
endfunction()

# ===================================================================

#
# nx_target_compile_features: Set Compiler Features
#
function(nx_target_compile_features)
	nx_function_begin()

	# === Available Parsing Modes ===

	set(lst_pmode_multi "TARGET" "PRIVATE" "PUBLIC" "INTERFACE")

	foreach(tmp_pmode ${lst_pmode_multi})
		string(TOLOWER "${tmp_pmode}" tmp_pmode)
		unset(arg_feature_${tmp_pmode})
	endforeach()

	set(str_pmode_cur "TARGET")

	# === Parse Arguments ===

	foreach(tmp_argv ${ARGN})
		if("${tmp_argv}" IN_LIST lst_pmode_multi)
			set(str_pmode_cur "${tmp_argv}")
		elseif(str_pmode_cur STREQUAL "TARGET")
			string(TOLOWER "${str_pmode_cur}" tmp_pmode)
			list(APPEND arg_feature_${tmp_pmode} "${tmp_argv}")
		elseif("${str_pmode_cur}" IN_LIST lst_pmode_multi)
			string(TOLOWER "${str_pmode_cur}" tmp_pmode)
			if("${tmp_argv}" IN_LIST CMAKE_C_COMPILE_FEATURES OR "${tmp_argv}" IN_LIST CMAKE_CXX_COMPILE_FEATURES)
				list(APPEND arg_feature_${tmp_pmode} "${tmp_argv}")
			else()
				message(WARNING "nx_target_compile_features: Feature '${tmp_argv}' Not Found")
			endif()
		else()
			message(AUTHOR_WARNING "nx_target_compile_features: Parse Mode ${str_pmode_cur} Unknown")
		endif()
	endforeach()

	# === Set Features ===

	foreach(tmp_target ${arg_feature_target})
		foreach(tmp_visibility "PUBLIC" "PRIVATE" "INTERFACE")
			string(TOLOWER "${tmp_visibility}" tmp_pmode)
			if(DEFINED arg_feature_${tmp_pmode})
				target_compile_features("${tmp_target}" ${tmp_visibility} ${arg_feature_${tmp_pmode}})
			endif()
		endforeach()
	endforeach()

	nx_function_end()
endfunction()

# ===================================================================

#
# nx_target_compile_options: Set Compiler Flags
#
function(nx_target_compile_options)
	nx_function_begin()

	# === Available Parsing Modes ===

	set(lst_pmode_multi "TARGET" "PRIVATE" "PUBLIC" "INTERFACE")

	foreach(tmp_pmode ${lst_pmode_multi})
		string(TOLOWER "${tmp_pmode}" tmp_pmode)
		unset(arg_option_${tmp_pmode})
	endforeach()

	set(str_pmode_cur "TARGET")

	# === Parse Arguments ===

	foreach(tmp_argv ${ARGN})
		if("${tmp_argv}" IN_LIST lst_pmode_multi)
			set(str_pmode_cur "${tmp_argv}")
		elseif("${str_pmode_cur}" IN_LIST lst_pmode_multi)
			string(TOLOWER "${str_pmode_cur}" tmp_pmode)
			list(APPEND arg_option_${tmp_pmode} "${tmp_argv}")
		else()
			message(AUTHOR_WARNING "nx_target_compile_options: Parse Mode ${str_pmode_cur} Unknown")
		endif()
	endforeach()

	# === Set Flags ===

	foreach(tmp_target ${arg_option_target})
		foreach(tmp_visibility "PUBLIC" "PRIVATE" "INTERFACE")
			string(TOLOWER "${tmp_visibility}" tmp_pmode)
			if(DEFINED arg_option_${tmp_pmode})
				target_compile_options("${tmp_target}" ${tmp_visibility} ${arg_option_${tmp_pmode}})
			endif()
		endforeach()
	endforeach()

	nx_function_end()
endfunction()

# ===================================================================

#
# nx_target_include_directories: Set Include Directories
#
function(nx_target_include_directories)
	nx_function_begin()

	# === Available Parsing Modes ===

	set(lst_pmode_single "EXPORTABLE")
	set(lst_pmode_multi "TARGET" "PRIVATE" "PUBLIC" "INTERFACE")

	foreach(tmp_pmode ${lst_pmode_multi} ${lst_pmode_single})
		string(TOLOWER "${tmp_pmode}" tmp_pmode)
		unset(arg_include_${tmp_pmode})
		unset(arg_internal_${tmp_pmode})
	endforeach()

	set(str_pmode_cur "TARGET")

	# === Parse Arguments ===

	foreach(tmp_argv ${ARGN})
		if("${tmp_argv}" IN_LIST lst_pmode_multi OR "${tmp_argv}" IN_LIST lst_pmode_single)
			set(str_pmode_cur "${tmp_argv}")
		elseif(str_pmode_cur STREQUAL "TARGET")
			string(TOLOWER "${str_pmode_cur}" tmp_pmode)
			list(APPEND arg_include_${tmp_pmode} "${tmp_argv}")
		elseif("${str_pmode_cur}" IN_LIST lst_pmode_single)
			string(TOLOWER "${str_pmode_cur}" tmp_pmode)
			if(DEFINED arg_include_${tmp_pmode})
				message(AUTHOR_WARNING "nx_target_include_directories: Option ${str_pmode_cur} Already Set")
			else()
				set(arg_include_${tmp_pmode} "${tmp_argv}")
			endif()
		elseif("${str_pmode_cur}" IN_LIST lst_pmode_multi)
			string(TOLOWER "${str_pmode_cur}" tmp_pmode)
			if(tmp_argv MATCHES "<[^>]+:")
				list(APPEND arg_include_${tmp_pmode} "${tmp_argv}")
			else()
				get_filename_component(tmp_argv "${tmp_argv}" ABSOLUTE)
				file(RELATIVE_PATH tmp_path_rel "${CMAKE_CURRENT_BINARY_DIR}" "${tmp_argv}")
				string(SUBSTRING "${tmp_path_rel}" 0 2 tmp_path_test)
				if(tmp_path_test STREQUAL ".." OR tmp_path_test MATCHES ":$")
					file(RELATIVE_PATH tmp_path_rel "${CMAKE_CURRENT_SOURCE_DIR}" "${tmp_argv}")
					string(SUBSTRING "${tmp_path_rel}" 0 2 tmp_path_test)
					if(tmp_path_test STREQUAL ".." OR tmp_path_test MATCHES ":$")
						list(APPEND arg_include_${tmp_pmode} "${tmp_argv}")
					else()
						list(APPEND arg_internal_${tmp_pmode} "${CMAKE_CURRENT_SOURCE_DIR}/${tmp_path_rel}"
								"${CMAKE_CURRENT_BINARY_DIR}/${tmp_path_rel}")
					endif()
				else()
					list(APPEND arg_internal_${tmp_pmode} "${CMAKE_CURRENT_BINARY_DIR}/${tmp_path_rel}")
				endif()
			endif()
		else()
			message(AUTHOR_WARNING "nx_target_include_directories: Parse Mode ${str_pmode_cur} Unknown")
		endif()
	endforeach()

	# === Set Includes ===

	if(NOT DEFINED arg_include_exportable)
		set(arg_include_exportable ON)
	endif()

	foreach(tmp_visibility "PUBLIC" "INTERFACE")
		string(TOLOWER "${tmp_visibility}" tmp_pmode)
		if(DEFINED arg_internal_${tmp_pmode} AND arg_include_exportable)
			nx_append(${NX_PROJECT_NAME}_DIRS_INCLUDE ${arg_internal_${tmp_pmode}})
			list(APPEND arg_include_${tmp_pmode} "$<INSTALL_INTERFACE:${NX_INSTALL_PATHDEV_HEADERS}>")
		endif()
		foreach(tmp_include ${arg_internal_${tmp_pmode}})
			list(APPEND arg_include_${tmp_pmode} "$<BUILD_INTERFACE:${tmp_include}>")
		endforeach()
	endforeach()

	foreach(tmp_visibility "PRIVATE")
		string(TOLOWER "${tmp_visibility}" tmp_pmode)
		list(APPEND arg_include_${tmp_pmode} ${arg_internal_${tmp_pmode}})
	endforeach()

	foreach(tmp_target ${arg_include_target})
		foreach(tmp_visibility "PUBLIC" "PRIVATE" "INTERFACE")
			string(TOLOWER "${tmp_visibility}" tmp_pmode)
			if(DEFINED arg_include_${tmp_pmode})
				target_include_directories("${tmp_target}" ${tmp_visibility} ${arg_include_${tmp_pmode}})
			endif()
		endforeach()
	endforeach()

	nx_function_end()
endfunction()

# ===================================================================

#
# nx_target_link_libraries: Set Library Dependencies
#
function(nx_target_link_libraries)
	nx_function_begin()

	# === Available Parsing Modes ===

	set(lst_pmode_multi "TARGET" "PRIVATE" "PUBLIC" "INTERFACE")

	foreach(tmp_pmode ${lst_pmode_multi})
		string(TOLOWER "${tmp_pmode}" tmp_pmode)
		unset(arg_library_${tmp_pmode})
	endforeach()

	set(str_pmode_cur "TARGET")

	# === Parse Arguments ===

	foreach(tmp_argv ${ARGN})
		if("${tmp_argv}" IN_LIST lst_pmode_multi)
			set(str_pmode_cur "${tmp_argv}")
		elseif("${str_pmode_cur}" IN_LIST lst_pmode_multi)
			string(TOLOWER "${str_pmode_cur}" tmp_pmode)
			list(APPEND arg_library_${tmp_pmode} "${tmp_argv}")
		else()
			message(AUTHOR_WARNING "nx_target_link_libraries: Parse Mode ${str_pmode_cur} Unknown")
		endif()
	endforeach()

	# === Set Libraries ===

	unset(arg_library_depend)
	foreach(tmp_target ${arg_library_public} ${arg_library_private})
		if(TARGET "${tmp_target}")
			get_target_property(tmp_prop_aliased "${tmp_target}" ALIASED_TARGET)
			if(tmp_prop_aliased AND TARGET "${tmp_prop_aliased}")
				set(tmp_target "${tmp_prop_aliased}")
			endif()
			list(APPEND arg_library_depend "${tmp_target}")
		endif()
	endforeach()

	# TODO: Is this still needed?
	unset(arg_library_previous)
	while(NOT "x${arg_library_depend}" STREQUAL "x${arg_library_previous}")
		set(arg_library_previous ${arg_library_depend})
		foreach(tmp_target ${arg_library_previous})
			get_target_property(tmp_prop_type "${tmp_target}" TYPE)
			if(NOT tmp_prop_type STREQUAL "INTERFACE_LIBRARY")
				get_target_property(tmp_prop_linked "${tmp_target}" LINK_LIBRARIES)
				foreach(tmp_candidate ${tmp_prop_linked})
					if(TARGET "${tmp_candidate}")
						get_target_property(tmp_prop_aliased "${tmp_candidate}" ALIASED_TARGET)
						if(tmp_prop_aliased AND TARGET "${tmp_prop_aliased}")
							set(tmp_candidate "${tmp_prop_aliased}")
						endif()
						list(APPEND arg_library_depend "${tmp_candidate}")
					endif()
				endforeach()
			endif()
			get_target_property(tmp_prop_linked "${tmp_target}" INTERFACE_LINK_LIBRARIES)
			foreach(tmp_candidate ${tmp_prop_linked})
				if(TARGET "${tmp_candidate}")
					get_target_property(tmp_prop_aliased "${tmp_candidate}" ALIASED_TARGET)
					if(tmp_prop_aliased AND TARGET "${tmp_prop_aliased}")
						set(tmp_candidate "${tmp_prop_aliased}")
					endif()
					list(APPEND arg_library_depend "${tmp_candidate}")
				endif()
			endforeach()
		endforeach()
		if(DEFINED arg_library_depend)
			list(REMOVE_DUPLICATES arg_library_depend)
		endif()
	endwhile()
	if(DEFINED arg_library_depend)
		nx_append(${NX_PROJECT_NAME}_DEPENDENCIES "${arg_library_depend}")
	endif()

	# TODO: Is this still needed?
	foreach(tmp_target ${arg_library_depend})
		get_target_property(tmp_prop_type "${tmp_target}" TYPE)
		if(tmp_prop_type STREQUAL "SHARED_LIBRARY")
			get_target_property(tmp_prop_imported "${tmp_target}" IMPORTED)
			if(tmp_prop_imported)
				get_target_property(tmp_prop_location "${tmp_target}" IMPORTED_LOCATION)
				if(tmp_prop_location)
					nx_append(${NX_PROJECT_NAME}_SHLIBS "${tmp_prop_location}")
					nx_append(${NX_PROJECT_NAME}_SHLIBS_NOCONFIG "${tmp_prop_location}")
				endif()
				foreach(tmp_config "NOCONFIG" ${CMAKE_CONFIGURATION_TYPES} ${CMAKE_BUILD_TYPE})
					string(TOUPPER "_${tmp_config}" tmp_config)
					get_target_property(tmp_prop_location "${tmp_target}" IMPORTED_LOCATION${tmp_config})
					if(tmp_prop_location)
						nx_append(${NX_PROJECT_NAME}_SHLIBS "${tmp_prop_location}")
						nx_append(${NX_PROJECT_NAME}_SHLIBS${tmp_config} "${tmp_prop_location}")
					endif()
				endforeach()
			endif()
		endif()
	endforeach()

	foreach(tmp_target ${arg_library_target})
		foreach(tmp_visibility "PUBLIC" "PRIVATE" "INTERFACE")
			string(TOLOWER "${tmp_visibility}" tmp_pmode)
			if(DEFINED arg_library_${tmp_pmode})
				target_link_libraries("${tmp_target}" ${tmp_visibility} ${arg_library_${tmp_pmode}})
			endif()
		endforeach()
	endforeach()

	nx_function_end()
endfunction()

# ===================================================================

#
# nx_target_link_options: Set Linker Flags
#
function(nx_target_link_options)
	nx_function_begin()

	# === Available Parsing Modes ===

	set(lst_pmode_multi "TARGET" "PRIVATE" "PUBLIC" "INTERFACE" "STATIC")

	foreach(tmp_pmode ${lst_pmode_multi})
		string(TOLOWER "${tmp_pmode}" tmp_pmode)
		unset(arg_option_${tmp_pmode})
	endforeach()

	set(str_pmode_cur "TARGET")

	# === Parse Arguments ===

	foreach(tmp_argv ${ARGN})
		if("${tmp_argv}" IN_LIST lst_pmode_multi)
			set(str_pmode_cur "${tmp_argv}")
		elseif("${str_pmode_cur}" IN_LIST lst_pmode_multi)
			string(TOLOWER "${str_pmode_cur}" tmp_pmode)
			list(APPEND arg_option_${tmp_pmode} "${tmp_argv}")
		else()
			message(AUTHOR_WARNING "nx_target_link_options: Parse Mode ${str_pmode_cur} Unknown")
		endif()
	endforeach()

	# === Set Flags ===

	foreach(tmp_target ${arg_option_target})
		foreach(tmp_visibility "PUBLIC" "PRIVATE" "INTERFACE")
			string(TOLOWER "${tmp_visibility}" tmp_pmode)
			if(DEFINED arg_option_${tmp_pmode})
				target_link_options("${tmp_target}" ${tmp_visibility} ${arg_option_${tmp_pmode}})
			endif()
		endforeach()
		foreach(tmp_visibility "STATIC")
			string(TOLOWER "${tmp_visibility}" tmp_pmode)
			if(DEFINED arg_option_${tmp_pmode})
				get_target_property(tmp_prop_slo "${tmp_target}" STATIC_LIBRARY_OPTIONS)
				if(NOT tmp_prop_slo)
					unset(tmp_prop_slo)
				endif()
				list(APPEND tmp_prop_slo ${arg_option_${tmp_pmode}})
				set_target_properties("${tmp_target}" PROPERTIES STATIC_LIBRARY_OPTIONS "${tmp_prop_slo}")
			endif()
		endforeach()
	endforeach()

	nx_function_end()
endfunction()

# ===================================================================

#
# nx_target_link_options: Set Source Files
#
function(nx_target_sources)
	nx_function_begin()

	# === Available Parsing Modes ===

	set(lst_pmode_single "EXPORTABLE")
	set(lst_pmode_multi "TARGET" "PRIVATE" "PUBLIC" "INTERFACE" "STRIP")

	foreach(tmp_pmode ${lst_pmode_multi} ${lst_pmode_single})
		string(TOLOWER "${tmp_pmode}" tmp_pmode)
		unset(arg_source_${tmp_pmode})
		unset(arg_internal_${tmp_pmode})
	endforeach()

	set(str_pmode_cur "TARGET")

	# === Parse Arguments ===

	if(NOT DEFINED _CURRENT_YEAR)
		string(TIMESTAMP _CURRENT_YEAR "%Y")
	endif()
	if(NOT DEFINED _CURRENT_DATE)
		string(TIMESTAMP _CURRENT_DATE "%Y%m%d")
	endif()

	foreach(tmp_argv ${ARGN})
		if("${tmp_argv}" IN_LIST lst_pmode_multi OR "${tmp_argv}" IN_LIST lst_pmode_single)
			set(str_pmode_cur "${tmp_argv}")
		elseif(str_pmode_cur STREQUAL "TARGET")
			string(TOLOWER "${str_pmode_cur}" tmp_pmode)
			list(APPEND arg_source_${tmp_pmode} "${tmp_argv}")
		elseif(str_pmode_cur STREQUAL "STRIP")
			string(TOLOWER "${str_pmode_cur}" tmp_pmode)
			get_filename_component(tmp_argv "${tmp_argv}" ABSOLUTE)
			file(RELATIVE_PATH tmp_path_rel "${CMAKE_CURRENT_BINARY_DIR}" "${tmp_argv}")
			string(SUBSTRING "${tmp_path_rel}" 0 2 tmp_path_test)
			if(tmp_path_test STREQUAL ".." OR tmp_path_test MATCHES ":$")
				file(RELATIVE_PATH tmp_path_rel "${CMAKE_CURRENT_SOURCE_DIR}" "${tmp_argv}")
				string(SUBSTRING "${tmp_path_rel}" 0 2 tmp_path_test)
				if(NOT tmp_path_test STREQUAL ".." AND NOT tmp_path_test MATCHES ":$")
					list(APPEND arg_source_${tmp_pmode} "${CMAKE_CURRENT_SOURCE_DIR}/${tmp_path_rel}"
							"${CMAKE_CURRENT_BINARY_DIR}/${tmp_path_rel}")
				endif()
			else()
				list(APPEND arg_source_${tmp_pmode} "${CMAKE_CURRENT_BINARY_DIR}/${tmp_path_rel}")
			endif()
		elseif("${str_pmode_cur}" IN_LIST lst_pmode_single)
			string(TOLOWER "${str_pmode_cur}" tmp_pmode)
			if(DEFINED arg_source_${tmp_pmode})
				message(AUTHOR_WARNING "nx_target_sources: Option ${str_pmode_cur} Already Set")
			else()
				set(arg_source_${tmp_pmode} "${tmp_argv}")
			endif()
		elseif("${str_pmode_cur}" IN_LIST lst_pmode_multi)
			string(TOLOWER "${str_pmode_cur}" tmp_pmode)
			if(tmp_argv MATCHES "<[^>]+:")
				list(APPEND arg_source_${tmp_pmode} "${tmp_argv}")
			else()
				if(tmp_argv MATCHES ".in$")
					string(REPLACE ".in" "" tmp_argv "${tmp_argv}")
				endif()
				unset(tmp_candidate)

				get_filename_component(tmp_argv "${tmp_argv}" ABSOLUTE)
				file(RELATIVE_PATH tmp_path_rel "${CMAKE_CURRENT_BINARY_DIR}" "${tmp_argv}")
				string(SUBSTRING "${tmp_path_rel}" 0 2 tmp_path_test)
				if(tmp_path_test STREQUAL ".." OR tmp_path_test MATCHES ":$")
					file(RELATIVE_PATH tmp_path_rel "${CMAKE_CURRENT_SOURCE_DIR}" "${tmp_argv}")
					string(SUBSTRING "${tmp_path_rel}" 0 2 tmp_path_test)
					if(tmp_path_test STREQUAL ".." OR tmp_path_test MATCHES ":$")
						list(APPEND arg_source_${tmp_pmode} "${tmp_argv}")
						unset(tmp_path_rel)
					else()
						if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${tmp_path_rel}.in")
							if(NOT str_pmode_cur STREQUAL "PRIVATE")
								nx_mkpath("${CMAKE_CURRENT_BINARY_DIR}/${tmp_path_rel}")
							endif()
							configure_file("${CMAKE_CURRENT_SOURCE_DIR}/${tmp_path_rel}.in" "${CMAKE_CURRENT_BINARY_DIR}/${tmp_path_rel}")
							set(tmp_candidate "${CMAKE_CURRENT_BINARY_DIR}/${tmp_path_rel}")
						else()
							set(tmp_candidate "${CMAKE_CURRENT_SOURCE_DIR}/${tmp_path_rel}")
						endif()
					endif()
				else()
					if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${tmp_path_rel}.in")
						if(NOT str_pmode_cur STREQUAL "PRIVATE")
							nx_mkpath("${CMAKE_CURRENT_BINARY_DIR}/${tmp_path_rel}")
						endif()
						configure_file("${CMAKE_CURRENT_SOURCE_DIR}/${tmp_path_rel}.in" "${CMAKE_CURRENT_BINARY_DIR}/${tmp_path_rel}")
					endif()
					set(tmp_candidate "${CMAKE_CURRENT_BINARY_DIR}/${tmp_path_rel}")
				endif()

				if(DEFINED tmp_candidate)
					if(tmp_candidate MATCHES ".rc$")
						if(WIN32 AND str_pmode_cur STREQUAL "PRIVATE")
							list(APPEND arg_internal_${tmp_pmode} "${tmp_candidate}")
						endif()
					else()
						list(APPEND arg_internal_${tmp_pmode} "${tmp_candidate}")
					endif()
				endif()
			endif()
		else()
			message(AUTHOR_WARNING "nx_target_sources: Parse Mode ${str_pmode_cur} Unknown")
		endif()
	endforeach()

	# === Set Source ===

	if(DEFINED arg_source_strip)
		nx_append(${NX_PROJECT_NAME}_DIRS_SOURCE ${arg_source_strip})
	endif()
	if(NOT DEFINED arg_source_exportable)
		set(arg_source_exportable ON)
	endif()

	foreach(tmp_visibility "PUBLIC" "INTERFACE")
		string(TOLOWER "${tmp_visibility}" tmp_pmode)
		foreach(tmp_candidate ${arg_internal_${tmp_pmode}})
			set(tmp_is_include OFF)
			set(tmp_is_source OFF)
			if(tmp_candidate MATCHES ".c$|.cpp$|.cxx$|.cc$|.rc$")
				set(tmp_is_source ON)
			elseif(tmp_candidate MATCHES ".h$|.hpp$|.hxx$|.hh$")
				set(tmp_is_include ON)
			endif()

			unset(tmp_found_include)
			foreach(tmp_path_include ${${NX_PROJECT_NAME}_DIRS_INCLUDE})
				file(RELATIVE_PATH tmp_path_rel "${tmp_path_include}" "${tmp_candidate}")
				string(SUBSTRING "${tmp_path_rel}" 0 2 tmp_path_test)
				if(NOT tmp_path_test STREQUAL ".." AND NOT tmp_path_test MATCHES ":$")
					set(tmp_found_include "${tmp_path_rel}")
				endif()
			endforeach()

			unset(tmp_found_source)
			foreach(tmp_path_source "${CMAKE_CURRENT_SOURCE_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}/src" "${CMAKE_CURRENT_BINARY_DIR}"
									${${NX_PROJECT_NAME}_DIRS_SOURCE})
				file(RELATIVE_PATH tmp_path_rel "${tmp_path_source}" "${tmp_candidate}")
				string(SUBSTRING "${tmp_path_rel}" 0 2 tmp_path_test)
				if(NOT tmp_path_test STREQUAL ".." AND NOT tmp_path_test MATCHES ":$")
					set(tmp_found_source "${tmp_path_rel}")
				endif()
			endforeach()

			if(DEFINED tmp_found_include AND arg_source_exportable)
				list(APPEND arg_source_${tmp_pmode} "$<BUILD_INTERFACE:${tmp_candidate}>")
				if(tmp_is_source)
					list(APPEND arg_source_${tmp_pmode} "$<INSTALL_INTERFACE:${NX_INSTALL_PATHDEV_HEADERS}/${tmp_found_include}>")
				endif()
			elseif(DEFINED tmp_found_source)
				list(APPEND arg_source_${tmp_pmode} "$<BUILD_INTERFACE:${tmp_candidate}>")
				if(tmp_is_source AND arg_source_exportable)
					list(APPEND arg_source_${tmp_pmode} "$<INSTALL_INTERFACE:${NX_INSTALL_PATHDEV_SOURCE}/${tmp_found_source}>")
				endif()
				if(arg_source_exportable)
					nx_append(${NX_PROJECT_NAME}_FILES_INTERFACE "${tmp_candidate}::${tmp_found_source}")
				endif()
			else()
				list(APPEND arg_source_${tmp_pmode} "${tmp_candidate}")
			endif()
		endforeach()
		if(DEFINED arg_internal_${tmp_pmode})
			nx_append(${NX_PROJECT_NAME}_FILES_SOURCE ${arg_internal_${tmp_pmode}})
		endif()
	endforeach()
	foreach(tmp_visibility "PRIVATE")
		string(TOLOWER "${tmp_visibility}" tmp_pmode)
		if(DEFINED arg_internal_${tmp_pmode})
			list(APPEND arg_source_${tmp_pmode} ${arg_internal_${tmp_pmode}})
			nx_append(${NX_PROJECT_NAME}_FILES_SOURCE ${arg_internal_${tmp_pmode}})
		endif()
	endforeach()

	foreach(tmp_target ${arg_source_target})
		foreach(tmp_visibility "PUBLIC" "PRIVATE" "INTERFACE")
			string(TOLOWER "${tmp_visibility}" tmp_pmode)
			if(DEFINED arg_source_${tmp_pmode})
				target_sources("${tmp_target}" ${tmp_visibility} ${arg_source_${tmp_pmode}})
			endif()
		endforeach()
	endforeach()

	nx_function_end()
endfunction()

# ===================================================================

#
# nx_target: Build Target
#
function(nx_target var_target_list str_target_name str_type_optional)
	nx_function_begin()

	string(TOUPPER "${str_target_name}" str_target_upper)
	string(MAKE_C_IDENTIFIER "${str_target_upper}" str_target_upper)

	# === Handle Optional Argument ===

	set(str_target_type "EXECUTABLE")

	if(str_type_optional STREQUAL "APPLICATION")
		set(str_target_type "APPLICATION")
		unset(str_type_optional)
	elseif(str_type_optional STREQUAL "DAEMON")
		set(str_target_type "DAEMON")
		unset(str_type_optional)
	elseif(str_type_optional STREQUAL "EXECUTABLE")
		set(str_target_type "EXECUTABLE")
		unset(str_type_optional)
	elseif(str_type_optional STREQUAL "TEST")
		set(str_target_type "TEST")
		unset(str_type_optional)
	elseif(str_type_optional STREQUAL "MODULE")
		set(str_target_type "MODULE")
		unset(str_type_optional)
	elseif(str_type_optional STREQUAL "PLUGIN")
		set(str_target_type "PLUGIN")
		unset(str_type_optional)
	elseif(str_type_optional STREQUAL "SHARED")
		set(str_target_type "SHARED")
		unset(str_type_optional)
	elseif(str_type_optional STREQUAL "STATIC")
		set(str_target_type "STATIC")
		unset(str_type_optional)
	elseif(str_type_optional STREQUAL "OBJECTS")
		set(str_target_type "OBJECTS")
		unset(str_type_optional)
	elseif(str_type_optional STREQUAL "VIRTUAL")
		set(str_target_type "INTERFACE")
		unset(str_type_optional)
	elseif(str_type_optional STREQUAL "LIBRARY")
		set(str_target_type "LIBRARY")
		unset(str_type_optional)
	endif()

	# === Available Parsing Modes ===

	set(lst_pmode_visibility "PUBLIC" "PRIVATE" "INTERFACE")
	set(lst_pmode_single "DEFINE_SYMBOL" "STATIC_DEFINE" "OUTPUT_NAME" "OUTPUT_SHORT" "STRIP" "EXPORTABLE")
	set(lst_pmode_single_v "GENERATE_EXPORT" "GENERATE_VERSION")
	set(lst_pmode_multi
		"CFLAGS"
		"CXXFLAGS"
		"DEFINES"
		"DEPENDS"
		"LIBDEPS"
		"FEATURES"
		"INCLUDES"
		"LDFLAGS"
		"SOURCES")
	set(lst_pmode_multi_s "DXEFLAGS")

	foreach(tmp_pmode ${lst_pmode_single} ${lst_pmode_multi_s})
		string(TOLOWER "${tmp_pmode}" tmp_pmode)
		unset(arg_target_${tmp_pmode})
	endforeach()

	foreach(tmp_vmode ${lst_pmode_visibility})
		foreach(tmp_pmode ${lst_pmode_single_v} ${lst_pmode_multi})
			string(TOLOWER "${tmp_pmode}_${tmp_vmode}" tmp_pmode)
			unset(arg_target_${tmp_pmode})
		endforeach()
	endforeach()

	set(str_pmode_cur "SOURCES")
	set(str_vmode_cur "PRIVATE")
	set(opt_exportable OFF)

	# === Parse Arguments ===

	foreach(tmp_argv ${str_type_optional} ${ARGN})
		if("${tmp_argv}" IN_LIST lst_pmode_single
			OR "${tmp_argv}" IN_LIST lst_pmode_single_v
			OR "${tmp_argv}" IN_LIST lst_pmode_multi
			OR "${tmp_argv}" IN_LIST lst_pmode_multi_s)
			set(str_pmode_cur "${tmp_argv}")
		elseif("${tmp_argv}" IN_LIST lst_pmode_visibility)
			set(str_vmode_cur "${tmp_argv}")
		elseif("${str_pmode_cur}" IN_LIST lst_pmode_single)
			string(TOLOWER "${str_pmode_cur}" tmp_pmode)
			if(DEFINED arg_target_${tmp_pmode})
				message(AUTHOR_WARNING "nx_target: Option ${str_pmode_cur} Already Set")
			else()
				set(arg_target_${tmp_pmode} "${tmp_argv}")
			endif()
			if(str_pmode_cur STREQUAL "OUTPUT_NAME")
				set(str_pmode_cur "OUTPUT_SHORT")
			endif()
		elseif("${str_pmode_cur}" IN_LIST lst_pmode_single_v AND "${str_vmode_cur}" IN_LIST lst_pmode_visibility)
			if(NOT "${str_vmode_cur}" STREQUAL "PRIVATE")
				set(opt_exportable ON)
			endif()
			string(TOLOWER "${str_pmode_cur}_${str_vmode_cur}" tmp_pmode)
			if(DEFINED arg_target_${tmp_pmode})
				message(AUTHOR_WARNING "nx_target: Option ${str_pmode_cur} Already Set")
			else()
				set(arg_target_${tmp_pmode} "${tmp_argv}")
			endif()
		elseif("${str_pmode_cur}" IN_LIST lst_pmode_multi_s)
			string(TOLOWER "${str_pmode_cur}" tmp_pmode)
			list(APPEND arg_target_${tmp_pmode} "${tmp_argv}")
		elseif("${str_pmode_cur}" IN_LIST lst_pmode_multi AND "${str_vmode_cur}" IN_LIST lst_pmode_visibility)
			if(NOT "${str_vmode_cur}" STREQUAL "PRIVATE")
				set(opt_exportable ON)
			endif()
			string(TOLOWER "${str_pmode_cur}_${str_vmode_cur}" tmp_pmode)
			list(APPEND arg_target_${tmp_pmode} "${tmp_argv}")
		else()
			message(AUTHOR_WARNING "nx_target: Parse Mode ${str_vmode_cur} ${str_pmode_cur} Unknown")
		endif()
	endforeach()

	if(DEFINED arg_target_exportable)
		set(opt_exportable ${arg_target_exportable})
	endif()

	# === Generate Export Header ===

	unset(arg_target_generate_export)
	unset(arg_target_generate_export_vis)

	if(DEFINED arg_target_generate_export_private)
		set(arg_target_generate_export "${arg_target_generate_export_private}")
		set(arg_target_generate_export_vis private)
	endif()
	if(DEFINED arg_target_generate_export_public)
		set(arg_target_generate_export "${arg_target_generate_export_public}")
		set(arg_target_generate_export_vis public)
	endif()
	if(DEFINED arg_target_generate_export_interface)
		set(arg_target_generate_export "${arg_target_generate_export_interface}")
		set(arg_target_generate_export_vis interface)
	endif()

	if(DEFINED arg_target_generate_export)
		nx_generate_export_header(
			"${str_target_name}"
			EXPORT_FILE_NAME "${arg_target_generate_export}"
			DEFINE_SYMBOL ${arg_target_define_symbol}
			STATIC_DEFINE ${arg_target_static_define})
		list(APPEND arg_target_sources_${arg_target_generate_export_vis} "${CMAKE_CURRENT_BINARY_DIR}/${arg_target_generate_export}")
		if(NOT str_target_type STREQUAL "INTERFACE")
			if(NOT DEFINED arg_target_define_symbol AND DEFINED ${str_target_upper}_DEFINE_SYMBOL)
				set(arg_target_define_symbol "${${str_target_upper}_DEFINE_SYMBOL}")
			endif()
			if(NOT DEFINED arg_target_static_define AND DEFINED ${str_target_upper}_STATIC_DEFINE)
				set(arg_target_static_define "${${str_target_upper}_STATIC_DEFINE}")
			endif()
		endif()
	endif()

	# === Generate Version Header ===

	unset(arg_target_generate_version)
	unset(arg_target_generate_version_vis)

	if(DEFINED arg_target_generate_version_private)
		set(arg_target_generate_version "${arg_target_generate_version_private}")
		set(arg_target_generate_version_vis private)
	endif()
	if(DEFINED arg_target_generate_export_public)
		set(arg_target_generate_version "${arg_target_generate_version_public}")
		set(arg_target_generate_version_vis public)
	endif()
	if(DEFINED arg_target_generate_version_interface)
		set(arg_target_generate_version "${arg_target_generate_version_interface}")
		set(arg_target_generate_version_vis interface)
	endif()

	if(DEFINED arg_target_generate_version)
		if(DEFINED NX_GIT_WATCH_VARS)
			nx_generate_version_header(
				"${str_target_name}"
				VERSION_FILE_NAME "${arg_target_generate_version}"
				QUERY_GIT)
		else()
			nx_generate_version_header("${str_target_name}" VERSION_FILE_NAME "${arg_target_generate_version}")
		endif()
		list(APPEND arg_target_sources_${arg_target_generate_version_vis} "${CMAKE_CURRENT_BINARY_DIR}/${arg_target_generate_version}")
	endif()

	if(NX_TARGET_PLATFORM_MSDOS AND DEFINED arg_target_output_short)
		set(arg_target_output_name "${arg_target_output_short}")
	endif()
	if(NOT DEFINED arg_target_output_name)
		set(arg_target_output_name "${str_target_name}")
	endif()

	# === Determine Targets To Build ===

	set(opt_can_compile OFF)
	if(DEFINED arg_target_sources_private OR DEFINED arg_target_sources_public)
		set(opt_can_compile ON)
	endif()

	set(opt_can_static OFF)
	if(DEFINED arg_target_static_define)
		set(opt_can_static ON)
	endif()

	set(opt_pure_interface OFF)
	if(NOT opt_can_compile)
		set(opt_pure_interface ON)
	endif()

	if(str_target_type STREQUAL "APPLICATION")
		if(NX_TARGET_PLATFORM_ANDROID)
			nx_option(BUILD_MODULE_${str_target_upper} "Build '${str_target_name}' Android Module" ON)
		else()
			nx_option(BUILD_EXECUTABLE_${str_target_upper} "Build '${str_target_name}' Executable" ON)
		endif()
	elseif(str_target_type STREQUAL "DAEMON")
		nx_option(BUILD_EXECUTABLE_${str_target_upper} "Build '${str_target_name}' Executable" ON)
	elseif(str_target_type MATCHES "EXECUTABLE|TEST")
		nx_option(BUILD_EXECUTABLE_${str_target_upper} "Build '${str_target_name}' Executable" ON)
	elseif(str_target_type MATCHES "TEST")
		nx_set_global(BUILD_EXECUTABLE_${str_target_upper} ON)
	elseif(str_target_type STREQUAL "MODULE")
		nx_dependent_option(BUILD_MODULE_${str_target_upper} "Build '${str_target_name}' Shared Module" ON "opt_can_compile" OFF)
		nx_dependent_option(BUILD_STATIC_${str_target_upper} "Build '${str_target_name}' Static Library" ON
							"opt_can_compile; opt_can_static" OFF)
		nx_dependent_option(BUILD_OBJECTS_${str_target_upper} "Build '${str_target_name}' Object Library" OFF
							"opt_can_compile; opt_can_static" OFF)
		nx_dependent_option(BUILD_INTERFACE_${str_target_upper} "Build '${str_target_name}' Interface Library" ${opt_pure_interface}
							"opt_can_static" OFF)
	elseif(str_target_type STREQUAL "PLUGIN")
		nx_option(BUILD_MODULE_${str_target_upper} "Build '${str_target_name}' Shared Module" ON)
	elseif(str_target_type STREQUAL "SHARED")
		nx_option(BUILD_SHARED_${str_target_upper} "Build '${str_target_name}' Shared Library" ON)
	elseif(str_target_type STREQUAL "STATIC")
		nx_option(BUILD_STATIC_${str_target_upper} "Build '${str_target_name}' Static Library" ON)
	elseif(str_target_type STREQUAL "OBJECTS")
		nx_option(BUILD_OBJECTS_${str_target_upper} "Build '${str_target_name}' Object Library" ON)
	elseif(str_target_type STREQUAL "INTERFACE")
		nx_option(BUILD_INTERFACE_${str_target_upper} "Build '${str_target_name}' Interface Library" ON)
	elseif(str_target_type STREQUAL "LIBRARY")
		nx_dependent_option(BUILD_SHARED_${str_target_upper} "Build '${str_target_name}' Shared Library" ${BUILD_SHARED_LIBS}
							"opt_can_compile" OFF)
		nx_dependent_option(BUILD_STATIC_${str_target_upper} "Build '${str_target_name}' Static Library" ON "opt_can_compile" OFF)
		nx_dependent_option(BUILD_OBJECTS_${str_target_upper} "Build '${str_target_name}' Object Library" OFF "opt_can_compile" OFF)
		nx_option(BUILD_INTERFACE_${str_target_upper} "Build '${str_target_name}' Interface Library" ${opt_pure_interface})
	else()
		message(AUTHOR_WARNING "nx_target: Target Type ${str_target_type} Unknown")
	endif()

	# === Target Naming ===

	foreach(tmp_type "executable" "module" "shared" "static" "objects" "interface")
		string(TOUPPER "${tmp_type}" str_type_upper)

		unset(str_tname_${tmp_type})
		if(DEFINED BUILD_${str_type_upper}_${str_target_upper} AND BUILD_${str_type_upper}_${str_target_upper})
			set(str_tname_${tmp_type} "${str_target_name}")
		endif()

		set(str_oname_${tmp_type} "${arg_target_output_name}")
	endforeach()

	set(opt_soversion OFF)
	set(opt_importlib OFF)
	if(NX_TARGET_PLATFORM_CYGWIN
		OR NX_TARGET_PLATFORM_MSDOS
		OR NX_TARGET_PLATFORM_WINDOWS)
		set(opt_importlib ON)
	endif()
	if(DEFINED ${NX_PROJECT_NAME}_PROJECT_SOVERSION_COMPAT)
		string(REPLACE "." "-" tmp_soversion "${${NX_PROJECT_NAME}_PROJECT_SOVERSION_COMPAT}")
		if(opt_importlib)
			set(str_oname_shared "${str_oname_shared}${tmp_soversion}")
		else()
			set(opt_soversion ON)
			set(str_oname_shared "${str_oname_shared}")
		endif()
		set(str_oname_static "${str_oname_static}${tmp_soversion}")
		set(str_oname_objects "${str_oname_objects}${tmp_soversion}")
	elseif(DEFINED ${NX_PROJECT_NAME}_PROJECT_VERSION_COMPAT AND opt_exportable)
		string(REPLACE "." "-" tmp_version "${${NX_PROJECT_NAME}_PROJECT_VERSION_COMPAT}")
		set(str_oname_shared "${str_oname_shared}-${tmp_version}")
		set(str_oname_static "${str_oname_static}-${tmp_version}")
		set(str_oname_objects "${str_oname_objects}-${tmp_version}")
	endif()
	if(opt_importlib)
		if("x${CMAKE_STATIC_LIBRARY_SUFFIX}" STREQUAL "x${CMAKE_IMPORT_LIBRARY_SUFFIX}")
			if("x${str_oname_shared}" STREQUAL "x${str_oname_static}")
				set(str_oname_static "${str_oname_static}_s")
			endif()
		endif()
	endif()
	if(NX_HOST_LANGUAGE_CXX AND DEFINED NX_TARGET_CXXABI_STRING)
		set(str_oname_shared "${str_oname_shared}-${NX_TARGET_CXXABI_STRING}")
		set(str_oname_static "${str_oname_static}-${NX_TARGET_CXXABI_STRING}")
		set(str_oname_objects "${str_oname_objects}-${NX_TARGET_CXXABI_STRING}")
	endif()

	foreach(tmp_type "executable" "module" "shared")
		if(NX_TARGET_PLATFORM_MSDOS)
			if(NOT str_target_type STREQUAL "TEST")
				nx_string_limit(str_oname_${tmp_type} "${str_oname_${tmp_type}}" 8)
			endif()
			string(TOUPPER "${str_oname_${tmp_type}}" str_oname_${tmp_type})
		elseif(NX_TARGET_PLATFORM_POSIX AND NOT NX_TARGET_PLATFORM_HAIKU)
			string(TOLOWER "${str_oname_${tmp_type}}" str_oname_${tmp_type})
		endif()
	endforeach()
	foreach(tmp_type "static" "objects" "interface")
		if(NX_TARGET_PLATFORM_MSDOS)
			string(TOUPPER "${str_oname_${tmp_type}}" str_oname_${tmp_type})
		elseif(NX_TARGET_PLATFORM_POSIX AND NOT NX_TARGET_PLATFORM_HAIKU)
			string(TOLOWER "${str_oname_${tmp_type}}" str_oname_${tmp_type})
		endif()
	endforeach()

	# NOTE: Object folder name is the target name rather than output name.
	if(DEFINED str_tname_objects)
		set(str_tname_objects "${str_oname_objects}")
	endif()

	# === Determine Filenames ===

	unset(str_fname_sonl1)
	unset(str_fname_sonl2)

	string(TOUPPER "CMAKE_${CMAKE_BUILD_TYPE}_POSTFIX" var_postfix)
	set(str_fname_executable "${CMAKE_EXECUTABLE_PREFIX}${str_oname_executable}${${var_postfix}}${CMAKE_EXECUTABLE_SUFFIX}")
	set(str_fname_module "${CMAKE_SHARED_MODULE_PREFIX}${str_oname_module}${${var_postfix}}${CMAKE_SHARED_MODULE_SUFFIX}")
	set(str_fname_static "${CMAKE_STATIC_LIBRARY_PREFIX}${str_oname_static}${${var_postfix}}${CMAKE_STATIC_LIBRARY_SUFFIX}")

	if(opt_soversion)
		if(NX_TARGET_PLATFORM_DARWIN)
			set(str_fname_shared
				"${CMAKE_SHARED_LIBRARY_PREFIX}${str_oname_shared}${${var_postfix}}.${${NX_PROJECT_NAME}_PROJECT_SOVERSION}${CMAKE_SHARED_LIBRARY_SUFFIX}"
			)
			set(str_fname_import
				"${CMAKE_IMPORT_LIBRARY_PREFIX}${str_oname_shared}${${var_postfix}}.${${NX_PROJECT_NAME}_PROJECT_SOVERSION}${CMAKE_IMPORT_LIBRARY_SUFFIX}"
			)
			set(str_fname_sonl1
				"${CMAKE_SHARED_LIBRARY_PREFIX}${str_oname_shared}${${var_postfix}}.${${NX_PROJECT_NAME}_PROJECT_SOVERSION_COMPAT}${CMAKE_SHARED_LIBRARY_SUFFIX}"
			)
		else()
			set(str_fname_shared
				"${CMAKE_SHARED_LIBRARY_PREFIX}${str_oname_shared}${${var_postfix}}${CMAKE_SHARED_LIBRARY_SUFFIX}.${${NX_PROJECT_NAME}_PROJECT_SOVERSION}"
			)
			set(str_fname_import
				"${CMAKE_IMPORT_LIBRARY_PREFIX}${str_oname_shared}${${var_postfix}}${CMAKE_IMPORT_LIBRARY_SUFFIX}.${${NX_PROJECT_NAME}_PROJECT_SOVERSION}"
			)
			set(str_fname_sonl1
				"${CMAKE_SHARED_LIBRARY_PREFIX}${str_oname_shared}${${var_postfix}}${CMAKE_SHARED_LIBRARY_SUFFIX}.${${NX_PROJECT_NAME}_PROJECT_SOVERSION_COMPAT}"
			)
		endif()
		set(str_fname_sonl2 "${CMAKE_SHARED_LIBRARY_PREFIX}${str_oname_shared}${${var_postfix}}${CMAKE_SHARED_LIBRARY_SUFFIX}")
	else()
		set(str_fname_shared "${CMAKE_SHARED_LIBRARY_PREFIX}${str_oname_shared}${${var_postfix}}${CMAKE_SHARED_LIBRARY_SUFFIX}")
		set(str_fname_import "${CMAKE_IMPORT_LIBRARY_PREFIX}${str_oname_shared}${${var_postfix}}${CMAKE_IMPORT_LIBRARY_SUFFIX}")
	endif()

	# === General Settings ===

	unset(lst_general_defines)
	unset(lst_general_cflags)
	unset(lst_general_ldflags)
	unset(lst_general_libs)

	set(opt_has_safe_flags OFF)
	unset(lst_safe_cflags)
	unset(lst_safe_ldflags)

	set(opt_has_unsafe_flags OFF)
	unset(lst_unsafe_cflags)
	unset(lst_unsafe_ldflags)

	set(opt_build_ndebug ON)
	if(NX_TARGET_BUILD_DEBUG)
		set(opt_build_ndebug OFF)
	endif()

	set(opt_try_cflags ON)
	set(opt_try_ldflags ON)
	if(NOT DEFINED str_tname_executable
		AND NOT DEFINED str_tname_module
		AND NOT DEFINED str_tname_shared
		AND NOT DEFINED str_tname_static
		AND NOT DEFINED str_tname_objects)
		set(opt_try_cflags OFF)
	endif()
	if(NX_TARGET_PLATFORM_MSDOS)
		if(NOT DEFINED str_tname_executable)
			set(opt_try_ldflags OFF)
		endif()
	else()
		if(NOT DEFINED str_tname_executable
			AND NOT DEFINED str_tname_module
			AND NOT DEFINED str_tname_shared)
			set(opt_try_ldflags OFF)
		endif()
	endif()

	set(opt_format_mach OFF)
	set(opt_format_pe OFF)
	set(opt_format_coff OFF)
	set(opt_format_elf OFF)

	if(NX_TARGET_PLATFORM_DARWIN)
		set(opt_format_mach ON)
	elseif(NX_TARGET_PLATFORM_MSDOS)
		set(opt_format_coff ON)
	elseif(NX_TARGET_PLATFORM_WINDOWS OR NX_TARGET_PLATFORM_CYGWIN)
		set(opt_format_pe ON)
	else()
		set(opt_format_elf ON)
	endif()

	if(NX_HOST_COMPILER_MSVC)
		list(APPEND lst_general_defines "_CRT_SECURE_NO_WARNINGS")
	endif()

	set(opt_has_linker OFF)
	if(opt_try_cflags)
		if(DEFINED CMAKE_EXE_LINKER_FLAGS)
			if(CMAKE_EXE_LINKER_FLAGS MATCHES "fuse-ld")
				set(opt_has_linker ON)
			endif()
		endif()

		if(NX_HOST_COMPILER_MSVC)
			set(opt_has_linker ON)
		endif()

		if(NOT opt_has_linker)
			if(opt_format_elf OR opt_format_pe)
				if(NX_HOST_COMPILER_CLANG)
					set(lst_try_cflags ${lst_general_cflags})
					set(lst_try_ldflags ${lst_general_ldflags} "-fuse-ld=lld")
					nx_check_compiles(HAS_LDFLAG_FUSE_LD_LLD lst_try_cflags lst_try_ldflags ${lst_general_libs})
					if(HAS_LDFLAG_FUSE_LD_LLD)
						set(opt_has_linker ON)
						list(APPEND lst_general_ldflags "-fuse-ld=lld")
					endif()
				endif()
			endif()
		endif()

		if(NOT opt_has_linker)
			if(opt_format_elf)
				if(NX_HOST_COMPILER_CLANG OR NX_HOST_COMPILER_GNU)
					set(lst_try_cflags ${lst_general_cflags})
					set(lst_try_ldflags ${lst_general_ldflags} "-fuse-ld=gold")
					nx_check_compiles(HAS_LDFLAG_FUSE_LD_GOLD lst_try_cflags lst_try_ldflags ${lst_general_libs})
					if(HAS_LDFLAG_FUSE_LD_GOLD)
						set(opt_has_linker ON)
						list(APPEND lst_general_ldflags "-fuse-ld=gold")
					endif()
				endif()
			endif()
		endif()

		if(NX_HOST_COMPILER_CLANG OR NX_HOST_COMPILER_GNU)
			set(lst_try_cflags ${lst_general_cflags})
			set(lst_try_ldflags ${lst_general_ldflags} "-fuse-linker-plugin")
			nx_check_compiles(HAS_LDFLAG_FUSE_LINKER_PLUGIN lst_try_cflags lst_try_ldflags ${lst_general_libs})
			if(HAS_LDFLAG_FUSE_LINKER_PLUGIN)
				set(opt_has_linker ON)
				list(APPEND lst_general_ldflags "-fuse-linker-plugin")
			endif()
		endif()
	endif()

	nx_dependent_option(ENABLE_PEDANTIC_WARNINGS "Enable Various Extra Warnings" ON "opt_try_cflags" OFF)
	nx_dependent_option(ENABLE_HARDENED_BUILD "Enable Security Hardening" ON "opt_build_ndebug;opt_try_cflags" OFF)
	nx_dependent_option(ENABLE_LTO_OPTIONS "Enable Link-Time Opimization" ON "opt_build_ndebug;opt_has_linker" OFF)

	if(ENABLE_PEDANTIC_WARNINGS)
		if(NX_HOST_COMPILER_MSVC)
			list(APPEND lst_general_cflags "-W4")
		elseif(NX_HOST_COMPILER_CLANG OR NX_HOST_COMPILER_GNU)
			list(APPEND lst_general_cflags "-Wall" "-Wextra" "-pedantic")
		endif()
	endif()

	if(ENABLE_HARDENED_BUILD)
		if(NX_HOST_COMPILER_MSVC)
			set(lst_try_cflags ${lst_general_cflags} "-GS" "-sdl")
			set(lst_try_ldflags ${lst_general_ldflags})
			nx_check_compiles(HAS_CFLAG_SDL lst_try_cflags lst_try_ldflags ${lst_general_libs})
			if(HAS_CFLAG_SDL)
				list(APPEND lst_general_cflags "-GS" "-sdl")
			endif()

			set(lst_try_cflags ${lst_general_cflags} "-guard:cf")
			set(lst_try_ldflags ${lst_general_ldflags} "-GUARD:CF")
			nx_check_compiles(HAS_CFLAG_GUARD_CF lst_try_cflags lst_try_ldflags ${lst_general_libs})
			if(HAS_CFLAG_GUARD_CF)
				list(APPEND lst_general_cflags "-guard:cf")
				list(APPEND lst_general_ldflags "-GUARD:CF")
			endif()

			set(lst_try_cflags ${lst_general_cflags} "-guard:ehcont")
			set(lst_try_ldflags ${lst_general_ldflags} "-GUARD:EHCONT")
			nx_check_compiles(HAS_CFLAG_GUARD_EHCONT lst_try_cflags lst_try_ldflags ${lst_general_libs})
			if(HAS_CFLAG_GUARD_EHCONT)
				list(APPEND lst_general_cflags "-guard:ehcont")
				list(APPEND lst_general_ldflags "-GUARD:EHCONT")
			endif()
		elseif(NX_HOST_COMPILER_CLANG OR NX_HOST_COMPILER_GNU)
			set(lst_try_cflags ${lst_general_cflags} "-Warray-bounds" "-Werror=array-bounds")
			set(lst_try_ldflags ${lst_general_ldflags})
			nx_check_compiles(HAS_CFLAG_WARRAY_BOUNDS lst_try_cflags lst_try_ldflags ${lst_general_libs})
			if(HAS_CFLAG_WARRAY_BOUNDS)
				list(APPEND lst_general_cflags "-Warray-bounds" "-Werror=array-bounds")
			endif()

			set(lst_try_cflags ${lst_general_cflags} "-Wformat=2" "-Wformat-security" "-Werror=format-security")
			set(lst_try_ldflags ${lst_general_ldflags})
			nx_check_compiles(HAS_CFLAG_WFORMAT_SECURITY lst_try_cflags lst_try_ldflags ${lst_general_libs})
			if(HAS_CFLAG_WFORMAT_SECURITY)
				list(APPEND lst_general_cflags "-Wformat=2" "-Wformat-security" "-Werror=format-security")
			endif()

			if(NOT NX_TARGET_PLATFORM_MSDOS)
				set(lst_try_cflags ${lst_general_cflags} "-fcf-protection")
				set(lst_try_ldflags ${lst_general_ldflags} "-fcf-protection")
				nx_check_compiles(HAS_CFLAG_FCF_PROTECTION lst_try_cflags lst_try_ldflags ${lst_general_libs})
				if(HAS_CFLAG_FCF_PROTECTION)
					list(APPEND lst_general_cflags "-fcf-protection")
					list(APPEND lst_general_ldflags "-fcf-protection")
				endif()
			endif()

			set(lst_try_cflags ${lst_general_cflags} "-fstack-clash-protection")
			set(lst_try_ldflags ${lst_general_ldflags} "-fstack-clash-protection")
			nx_check_compiles(HAS_CFLAG_FSTACK_CLASH_PROTECTION lst_try_cflags lst_try_ldflags ${lst_general_libs})
			if(HAS_CFLAG_FSTACK_CLASH_PROTECTION)
				list(APPEND lst_general_cflags "-fstack-clash-protection")
				list(APPEND lst_general_ldflags "-fstack-clash-protection")
			endif()

			# TODO: msys2/clang64 << undefined symbol: __stack_chk_guard >>
			if(NOT NX_TARGET_PLATFORM_WINDOWS
				OR NOT NX_HOST_COMPILER_CLANG
				OR NOT NX_HOST_PLATFORM_WINDOWS
				OR NOT ENABLE_LTO_OPTIONS)
				set(lst_try_cflags ${lst_general_cflags} "-fstack-protector-strong")
				set(lst_try_ldflags ${lst_general_ldflags} "-fstack-protector-strong")
				nx_check_compiles(HAS_CFLAG_FSTACK_PROTECTOR_STRONG lst_try_cflags lst_try_ldflags ${lst_general_libs})
				if(HAS_CFLAG_FSTACK_PROTECTOR_STRONG)
					list(APPEND lst_general_cflags "-fstack-protector-strong")
					list(APPEND lst_general_ldflags "-fstack-protector-strong")
				endif()
			else()
				set(HAS_CFLAG_FSTACK_PROTECTOR_STRONG OFF)
			endif()

			# TODO: msys2/mingw64 << internal compiler error: in seh_emit_stackalloc >>
			if(NX_TARGET_PLATFORM_WINDOWS
				AND NX_HOST_COMPILER_GNU
				AND NX_HOST_PLATFORM_WINDOWS
				AND HAS_CFLAG_FSTACK_CLASH_PROTECTION)
				list(APPEND lst_general_defines "_FORTIFY_SOURCE=0")
			else()
				list(APPEND lst_general_defines "_FORTIFY_SOURCE=2" "_GLIBCXX_ASSERTIONS")
				if(NOT HAS_CFLAG_FSTACK_PROTECTOR_STRONG)
					list(APPEND lst_general_libs "ssp")
				endif()
			endif()

			if(NX_HOST_COMPILER_CLANG)
				set(lst_try_cflags ${lst_general_cflags} "-fsanitize=safe-stack")
				set(lst_try_ldflags ${lst_general_ldflags} "-fsanitize=safe-stack")
				nx_check_compiles(HAS_CFLAG_FSANITIZE_SAFE_STACK lst_try_cflags lst_try_ldflags ${lst_general_libs})
				if(HAS_CFLAG_FSANITIZE_SAFE_STACK)
					list(APPEND lst_general_cflags "-fsanitize=safe-stack")
					list(APPEND lst_general_ldflags "-fsanitize=safe-stack")
				endif()
			endif()
		endif()

		if(ENABLE_LTO_OPTIONS)
			if(NX_HOST_COMPILER_MSVC)
				set(opt_has_unsafe_flags ON)
				list(APPEND lst_unsafe_cflags "$<$<NOT:$<CONFIG:Debug>>:-GL>")
				list(APPEND lst_unsafe_ldflags "$<$<NOT:$<CONFIG:Debug>>:-LTCG>" "$<$<CONFIG:RelWithDebInfo>:-INCREMENTAL:NO>")
			elseif(NX_HOST_COMPILER_CLANG)
				if(NOT NX_HOST_COMPILER_CLANG_VERSION VERSION_LESS 3.9)
					set(lst_try_cflags ${lst_general_cflags} ${lst_unsafe_cflags} "-flto=thin")
					set(lst_try_ldflags ${lst_general_ldflags} ${lst_unsafe_ldflags} "-flto=thin")
					nx_check_compiles(HAS_CFLAG_FLTO_THIN lst_try_cflags lst_try_ldflags ${lst_general_libs})
					if(HAS_CFLAG_FLTO_THIN)
						set(opt_has_unsafe_flags ON)
						list(APPEND lst_unsafe_cflags "-flto=thin")
						list(APPEND lst_unsafe_ldflags "-flto=thin")
					endif()

					set(lst_try_cflags ${lst_general_cflags} ${lst_safe_cflags} "-flto=full")
					set(lst_try_ldflags ${lst_general_ldflags} ${lst_safe_ldflags} "-flto=full")
					nx_check_compiles(HAS_CFLAG_FLTO_FULL lst_try_cflags lst_try_ldflags ${lst_general_libs})
					if(HAS_CFLAG_FLTO_FULL)
						set(opt_has_safe_flags ON)
						list(APPEND lst_safe_cflags "-flto=full")
						list(APPEND lst_safe_ldflags "-flto=full")
					endif()
				else()
					set(lst_try_cflags ${lst_general_cflags} "-flto")
					set(lst_try_ldflags ${lst_general_cflags} "-flto")
					nx_check_compiles(HAS_CFLAG_FLTO lst_try_cflags lst_try_ldflags ${lst_general_libs})
					if(HAS_CFLAG_FLTO)
						list(APPEND lst_general_cflags "-flto")
						list(APPEND lst_general_cflags "-flto")
					endif()
				endif()
			elseif(NX_HOST_COMPILER_GNU)
				if(NOT NX_HOST_COMPILER_GNU_VERSION VERSION_LESS 4.7)
					set(lst_try_cflags ${lst_general_cflags} ${lst_unsafe_cflags} "-flto" "-fno-fat-lto-objects")
					set(lst_try_ldflags ${lst_general_ldflags} ${lst_unsafe_ldflags} "-flto" "-fno-fat-lto-objects")
					nx_check_compiles(HAS_CFLAG_FNO_FAT_LTO_OBJECTS lst_try_cflags lst_try_ldflags ${lst_general_libs})
					if(HAS_CFLAG_FNO_FAT_LTO_OBJECTS)
						set(opt_has_unsafe_flags ON)
						list(APPEND lst_unsafe_cflags "-flto" "-fno-fat-lto-objects")
						list(APPEND lst_unsafe_ldflags "-flto" "-fno-fat-lto-objects")
					endif()

					set(lst_try_cflags ${lst_general_cflags} ${lst_safe_cflags} "-flto" "-ffat-lto-objects")
					set(lst_try_ldflags ${lst_general_ldflags} ${lst_safe_ldflags} "-flto" "-ffat-lto-objects")
					nx_check_compiles(HAS_CFLAG_FFAT_LTO_OBJECTS lst_try_cflags lst_try_ldflags ${lst_general_libs})
					if(HAS_CFLAG_FFAT_LTO_OBJECTS)
						set(opt_has_safe_flags ON)
						list(APPEND lst_safe_cflags "-flto" "-ffat-lto-objects")
						list(APPEND lst_safe_ldflags "-flto" "-ffat-lto-objects")
					endif()
				else()
					set(lst_try_cflags ${lst_general_cflags} "-flto")
					set(lst_try_ldflags ${lst_general_cflags} "-flto")
					nx_check_compiles(HAS_CFLAG_FLTO lst_try_cflags lst_try_ldflags ${lst_general_libs})
					if(HAS_CFLAG_FLTO)
						list(APPEND lst_general_cflags "-flto")
						list(APPEND lst_general_cflags "-flto")
					endif()
				endif()
			endif()
		endif()
	endif()

	if(opt_try_ldflags)
		if(NX_HOST_COMPILER_MSVC)
			set(lst_try_cflags ${lst_general_cflags})
			set(lst_try_ldflags ${lst_general_ldflags} "-CETCOMPAT")
			nx_check_compiles(HAS_LDFLAG_CETCOMPAT lst_try_cflags lst_try_ldflags ${lst_general_libs})
			if(HAS_LDFLAG_CETCOMPAT)
				list(APPEND lst_general_ldflags "-CETCOMPAT")
			endif()

			set(lst_try_cflags ${lst_general_cflags})
			set(lst_try_ldflags ${lst_general_ldflags} "-DYNAMICBASE")
			nx_check_compiles(HAS_LDFLAG_DYNAMICBASE lst_try_cflags lst_try_ldflags ${lst_general_libs})
			if(HAS_LDFLAG_DYNAMICBASE)
				list(APPEND lst_general_ldflags "-DYNAMICBASE")
			endif()

			set(lst_try_cflags ${lst_general_cflags})
			set(lst_try_ldflags ${lst_general_ldflags} "-NXCOMPAT")
			nx_check_compiles(HAS_LDFLAG_CETCOMPAT lst_try_cflags lst_try_ldflags ${lst_general_libs})
			if(HAS_LDFLAG_CETCOMPAT)
				list(APPEND lst_general_ldflags "-NXCOMPAT")
			endif()

			if(NX_TARGET_ARCHITECTURE_AMD64)
				set(lst_try_cflags ${lst_general_cflags})
				set(lst_try_ldflags ${lst_general_ldflags} "-HIGHENTROPYVA")
				nx_check_compiles(HAS_LDFLAG_HIGHENTROPYVA lst_try_cflags lst_try_ldflags ${lst_general_libs})
				if(HAS_LDFLAG_HIGHENTROPYVA)
					list(APPEND lst_general_ldflags "-HIGHENTROPYVA")
				endif()
			elseif(NX_TARGET_ARCHITECTURE_IA32)
				set(lst_try_cflags ${lst_general_cflags})
				set(lst_try_ldflags ${lst_general_ldflags} "-SAFESEH")
				nx_check_compiles(HAS_LDFLAG_SAFESEH lst_try_cflags lst_try_ldflags ${lst_general_libs})
				if(HAS_LDFLAG_SAFESEH)
					list(APPEND lst_general_ldflags "-SAFESEH")
				endif()
			endif()
		elseif(NX_HOST_COMPILER_CLANG OR NX_HOST_COMPILER_GNU)
			set(lst_try_cflags ${lst_general_cflags})
			set(lst_try_ldflags ${lst_general_ldflags} "LINKER:--as-needed")
			nx_check_compiles(HAS_LDFLAG_AS_NEEDED lst_try_cflags lst_try_ldflags ${lst_general_libs})
			if(HAS_LDFLAG_AS_NEEDED)
				list(APPEND lst_general_ldflags "LINKER:--as-needed")
			endif()

			set(lst_try_cflags ${lst_general_cflags})
			set(lst_try_ldflags ${lst_general_ldflags} "LINKER:--no-undefined")
			nx_check_compiles(HAS_LDFLAG_NO_UNDEFINED lst_try_cflags lst_try_ldflags ${lst_general_libs})
			if(HAS_LDFLAG_NO_UNDEFINED)
				list(APPEND lst_general_ldflags "LINKER:--no-undefined")
			endif()

			if(opt_format_elf)
				set(lst_try_cflags ${lst_general_cflags})
				set(lst_try_ldflags ${lst_general_ldflags} "LINKER:-z,defs")
				nx_check_compiles(HAS_LDFLAG_Z_DEFS lst_try_cflags lst_try_ldflags ${lst_general_libs})
				if(HAS_LDFLAG_Z_DEFS)
					list(APPEND lst_general_ldflags "LINKER:-z,defs")
				endif()

				set(lst_try_cflags ${lst_general_cflags})
				set(lst_try_ldflags ${lst_general_ldflags} "LINKER:-z,noexecstack")
				nx_check_compiles(HAS_LDFLAG_Z_NOEXECSTACK lst_try_cflags lst_try_ldflags ${lst_general_libs})
				if(HAS_LDFLAG_Z_NOEXECSTACK)
					list(APPEND lst_general_ldflags "LINKER:-z,noexecstack")
				endif()

				set(lst_try_cflags ${lst_general_cflags})
				set(lst_try_ldflags ${lst_general_ldflags} "LINKER:-z,now")
				nx_check_compiles(HAS_LDFLAG_Z_NOW lst_try_cflags lst_try_ldflags ${lst_general_libs})
				if(HAS_LDFLAG_Z_NOW)
					list(APPEND lst_general_ldflags "LINKER:-z,now")
				endif()

				set(lst_try_cflags ${lst_general_cflags})
				set(lst_try_ldflags ${lst_general_ldflags} "LINKER:-z,relro")
				nx_check_compiles(HAS_LDFLAG_Z_RELRO lst_try_cflags lst_try_ldflags ${lst_general_libs})
				if(HAS_LDFLAG_Z_RELRO)
					list(APPEND lst_general_ldflags "LINKER:-z,relro")
				endif()

				set(lst_try_cflags ${lst_general_cflags})
				set(lst_try_ldflags ${lst_general_ldflags} "LINKER:-z,separate-code")
				nx_check_compiles(HAS_LDFLAG_Z_SEPARATE_CODE lst_try_cflags lst_try_ldflags ${lst_general_libs})
				if(HAS_LDFLAG_Z_SEPARATE_CODE)
					list(APPEND lst_general_ldflags "LINKER:-z,separate-code")
				endif()

				set(lst_try_cflags ${lst_general_cflags})
				set(lst_try_ldflags ${lst_general_ldflags} "LINKER:-z,text")
				nx_check_compiles(HAS_LDFLAG_Z_TEXT lst_try_cflags lst_try_ldflags ${lst_general_libs})
				if(HAS_LDFLAG_Z_TEXT)
					list(APPEND lst_general_ldflags "LINKER:-z,text")
				endif()
			elseif(opt_format_pe)
				set(lst_try_cflags ${lst_general_cflags})
				set(lst_try_ldflags ${lst_general_ldflags} "LINKER:--dynamicbase")
				nx_check_compiles(HAS_LDFLAG_DYNAMICBASE lst_try_cflags lst_try_ldflags ${lst_general_libs})
				if(HAS_LDFLAG_DYNAMICBASE)
					list(APPEND lst_general_ldflags "LINKER:--dynamicbase")
				endif()

				set(lst_try_cflags ${lst_general_cflags})
				set(lst_try_ldflags ${lst_general_ldflags} "LINKER:--nxcompat")
				nx_check_compiles(HAS_LDFLAG_NXCOMPAT lst_try_cflags lst_try_ldflags ${lst_general_libs})
				if(HAS_LDFLAG_NXCOMPAT)
					list(APPEND lst_general_ldflags "LINKER:--nxcompat")
				endif()

				set(lst_try_cflags ${lst_general_cflags})
				set(lst_try_ldflags ${lst_general_ldflags} "LINKER:--disable-auto-image-base")
				nx_check_compiles(HAS_LDFLAG_DISABLE_AUTO_IMAGE_BASE lst_try_cflags lst_try_ldflags ${lst_general_libs})
				if(HAS_LDFLAG_DISABLE_AUTO_IMAGE_BASE)
					list(APPEND lst_general_ldflags "LINKER:--disable-auto-image-base")
				endif()

				if(NX_TARGET_ARCHITECTURE_AMD64)
					set(lst_try_cflags ${lst_general_cflags})
					set(lst_try_ldflags ${lst_general_ldflags} "LINKER:--high-entropy-va")
					nx_check_compiles(HAS_LDFLAG_HIGH_ENTROPY_VA lst_try_cflags lst_try_ldflags ${lst_general_libs})
					if(HAS_LDFLAG_HIGH_ENTROPY_VA)
						list(APPEND lst_general_ldflags "LINKER:--high-entropy-va")
					endif()
				elseif(NX_TARGET_ARCHITECTURE_IA32)
					set(lst_try_cflags ${lst_general_cflags})
					set(lst_try_ldflags ${lst_general_ldflags} "LINKER:--no-seh")
					nx_check_compiles(HAS_LDFLAG_NO_SEH lst_try_cflags lst_try_ldflags ${lst_general_libs})
					if(HAS_LDFLAG_NO_SEH)
						list(APPEND lst_general_ldflags "LINKER:--no-seh")
					endif()
				endif()
			endif()
		endif()
	endif()

	if(opt_has_safe_flags AND NOT opt_has_unsafe_flags)
		set(lst_unsafe_cflags ${lst_safe_cflags})
		set(lst_unsafe_ldflags ${lst_safe_ldflags})
	endif()

	if(ENABLE_LTO_OPTIONS AND NOT NX_HOST_COMPILER_MSVC)
		if(NOT CMAKE_AR MATCHES "gcc-ar|llvm-ar")
			if(NX_HOST_LANGUAGE_CXX AND DEFINED CMAKE_CXX_COMPILER_AR)
				nx_set(CMAKE_AR "${CMAKE_CXX_COMPILER_AR}")
			elseif(NX_HOST_LANGUAGE_C AND DEFINED CMAKE_C_COMPILER_AR)
				nx_set(CMAKE_AR "${CMAKE_C_COMPILER_AR}")
			endif()
		endif()
		if(NOT CMAKE_RANLIB MATCHES "gcc-ranlib|llvm-ranlib")
			if(NX_HOST_LANGUAGE_CXX AND DEFINED CMAKE_CXX_COMPILER_RANLIB)
				nx_set(CMAKE_RANLIB "${CMAKE_CXX_COMPILER_RANLIB}")
			elseif(NX_HOST_LANGUAGE_C AND DEFINED CMAKE_C_COMPILER_RANLIB)
				nx_set(CMAKE_RANLIB "${CMAKE_C_COMPILER_RANLIB}")
			endif()
		endif()

		if(CMAKE_AR MATCHES "gcc-ar|llvm-ar")
			nx_set(CMAKE_C_ARCHIVE_CREATE "<CMAKE_AR> cr <TARGET> <LINK_FLAGS> <OBJECTS>")
			nx_set(CMAKE_CXX_ARCHIVE_CREATE "<CMAKE_AR> cr <TARGET> <LINK_FLAGS> <OBJECTS>")
			nx_set(CMAKE_C_ARCHIVE_APPEND "<CMAKE_AR> r <TARGET> <LINK_FLAGS> <OBJECTS>")
			nx_set(CMAKE_CXX_ARCHIVE_APPEND "<CMAKE_AR> r <TARGET> <LINK_FLAGS> <OBJECTS>")
		endif()
		if(CMAKE_RANLIB MATCHES "gcc-ranlib|llvm-ranlib")
			nx_set(CMAKE_C_ARCHIVE_FINISH "<CMAKE_RANLIB> <TARGET>")
			nx_set(CMAKE_CXX_ARCHIVE_FINISH "<CMAKE_RANLIB> <TARGET>")
		endif()
	endif()

	# === Parse LIBDEPS ===

	foreach(tmp_visibility "private" "public" "interface")
		unset(arg_target_libdeps_${tmp_visibility}_shared)
		unset(arg_target_libdeps_${tmp_visibility}_static)
		unset(arg_target_libdeps_${tmp_visibility}_object)
		unset(arg_target_libdeps_${tmp_visibility}_source)

		foreach(tmp_libdep ${arg_target_libdeps_${tmp_visibility}})
			if(TARGET ${tmp_libdep})
				get_target_property(tmp_libdep_type ${tmp_libdep} TYPE)
				if(tmp_libdep_type STREQUAL "SHARED_LIBRARY")
					list(APPEND arg_target_libdeps_${tmp_visibility}_shared ${tmp_libdep})
				endif()
				if(tmp_libdep_type STREQUAL "STATIC_LIBRARY")
					list(APPEND arg_target_libdeps_${tmp_visibility}_static ${tmp_libdep})
				endif()
				if(tmp_libdep_type STREQUAL "OBJECT_LIBRARY")
					list(APPEND arg_target_libdeps_${tmp_visibility}_object ${tmp_libdep})
				endif()
				if(tmp_libdep_type STREQUAL "INTERFACE_LIBRARY")
					list(APPEND arg_target_libdeps_${tmp_visibility}_source ${tmp_libdep})
				endif()
			endif()
		endforeach()
	endforeach()

	# === Build DXEFlags ===

	foreach(tmp_libdep ${arg_target_depends_private} ${arg_target_libdeps_private})
		get_target_property(tmp_libdep_type ${tmp_libdep} TYPE)
		if(tmp_libdep_type STREQUAL "SHARED_LIBRARY")
			list(APPEND arg_target_dxeflags "-P" "$<TARGET_FILE:${tmp_libdep}>")
		endif()
	endforeach()

	# === Build Executable ===

	if(DEFINED str_tname_executable)
		while(TARGET "${str_tname_executable}")
			set(str_tname_executable "${str_tname_executable}_bin")
		endwhile()
		if(str_target_type STREQUAL "TEST")
			nx_append(${NX_PROJECT_NAME}_TARGETS_TESTS "${str_tname_executable}")
		else()
			nx_append(${NX_PROJECT_NAME}_TARGETS_EXECUTABLE "${str_tname_executable}")
		endif()
		nx_append(${var_target_list} "${str_tname_executable}")

		if(NX_TARGET_PLATFORM_WINDOWS AND str_target_type STREQUAL "APPLICATION")
			# list(APPEND arg_target_defines_private "_UNICODE" "UNICODE")
			list(APPEND arg_target_defines_private "_UNICODE")
		endif()

		add_executable("${str_tname_executable}")
		set_target_properties("${str_tname_executable}" PROPERTIES OUTPUT_NAME "${str_oname_executable}")
		nx_target_compile_definitions(
			"${str_tname_executable}"
			PRIVATE ${arg_target_defines_private} ${${NX_PROJECT_NAME}_ARCHITECTURE_DEFINES} ${${NX_PROJECT_NAME}_BUILD_DEFINES}
					${${NX_PROJECT_NAME}_COMPILER_DEFINES} ${${NX_PROJECT_NAME}_PLATFORM_DEFINES} ${lst_general_defines}
			PUBLIC ${arg_target_defines_public}
			INTERFACE ${arg_target_defines_interface})
		nx_target_compile_features(
			"${str_tname_executable}"
			PRIVATE ${arg_target_features_private}
			PUBLIC ${arg_target_features_public}
			INTERFACE ${arg_target_features_interface})
		nx_target_compile_options(
			"${str_tname_executable}"
			PRIVATE ${arg_target_cflags_private} ${arg_target_cxxflags_private} ${lst_general_cflags} ${lst_unsafe_cflags}
			PUBLIC ${arg_target_cflags_public} ${arg_target_cxxflags_public}
			INTERFACE ${arg_target_cflags_interface} ${arg_target_cxxflags_interface})
		nx_target_include_directories(
			"${str_tname_executable}"
			PRIVATE ${arg_target_includes_private}
			PUBLIC ${arg_target_includes_public}
			INTERFACE ${arg_target_includes_interface}
			EXPORTABLE ${arg_target_exportable})
		nx_target_link_libraries(
			"${str_tname_executable}"
			PRIVATE ${arg_target_depends_private} ${lst_general_libs}
			PUBLIC ${arg_target_depends_public}
			INTERFACE ${arg_target_depends_interface})
		nx_target_link_options(
			"${str_tname_executable}"
			PRIVATE ${arg_target_ldflags_private} ${lst_general_ldflags} ${lst_unsafe_ldflags}
			PUBLIC ${arg_target_ldflags_public}
			INTERFACE ${arg_target_ldflags_interface})
		nx_target_sources(
			"${str_tname_executable}"
			PRIVATE ${arg_target_sources_private}
			PUBLIC ${arg_target_sources_public}
			INTERFACE ${arg_target_sources_interface}
			STRIP ${arg_target_strip}
			EXPORTABLE ${arg_target_exportable})

		if(str_target_type STREQUAL "APPLICATION")
			set_target_properties("${str_tname_executable}" PROPERTIES INSTALL_RPATH "${CMAKE_INSTALL_RPATH}/${NX_INSTALL_PATH_APPS_RPATH}"
																		WIN32_EXECUTABLE TRUE)
			if(INSTALL_TARGETS${NX_PROJECT_NAME})
				nx_set(${NX_PROJECT_NAME}_COMPONENT_APP ON)
				install(
					TARGETS "${str_tname_executable}"
					COMPONENT ${NX_PROJECT_NAME}_APP
					DESTINATION "${NX_INSTALL_PATH_APPS}")
				nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATH_APPS}/${str_fname_executable}")
				nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATH_APPS}")
			endif()
		elseif(str_target_type STREQUAL "DAEMON")
			set_target_properties("${str_tname_executable}"
									PROPERTIES INSTALL_RPATH "${CMAKE_INSTALL_RPATH}/${NX_INSTALL_PATH_SERVERS_RPATH}" WIN32_EXECUTABLE FALSE)
			if(INSTALL_TARGETS${NX_PROJECT_NAME})
				nx_set(${NX_PROJECT_NAME}_COMPONENT_SRV ON)
				install(
					TARGETS "${str_tname_executable}"
					COMPONENT ${NX_PROJECT_NAME}_SRV
					DESTINATION "${NX_INSTALL_PATH_SERVERS}")
				nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATH_SERVERS}/${str_fname_executable}")
				nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATH_SERVERS}")
			endif()
		elseif(str_target_type STREQUAL "EXECUTABLE")
			set_target_properties(
				"${str_tname_executable}" PROPERTIES INSTALL_RPATH "${CMAKE_INSTALL_RPATH}/${NX_INSTALL_PATH_BINARIES_RPATH}"
														WIN32_EXECUTABLE FALSE)
			if(INSTALL_TARGETS${NX_PROJECT_NAME})
				nx_set(${NX_PROJECT_NAME}_COMPONENT_BIN ON)
				install(
					TARGETS "${str_tname_executable}"
					COMPONENT ${NX_PROJECT_NAME}_BIN
					DESTINATION "${NX_INSTALL_PATH_BINARIES}")
				nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATH_BINARIES}/${str_fname_executable}")
				nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATH_BINARIES}")
			endif()
		endif()
	endif()

	# === Targetted LTO Handling ===

	set(opt_has_static_libs OFF)
	if(DEFINED str_tname_static OR DEFINED str_tname_objects)
		set(opt_has_static_libs ON)
	endif()

	set(opt_nodist_default ON)
	if(DEFINED NX_INSTALL_SYSTEM AND NX_INSTALL_SYSTEM)
		set(opt_nodist_default OFF)
	endif()

	nx_dependent_option(BUILD_NODIST_STATIC_LIBS "Build Tightly-Coupled ${str_target_name} Static Libs" ${opt_nodist_default}
						"opt_has_unsafe_flags;opt_has_static_libs" OFF)
	if(BUILD_NODIST_STATIC_LIBS)
		set(lst_safe_cflags ${lst_unsafe_cflags})
		set(lst_safe_ldflags ${lst_unsafe_ldflags})
	endif()

	# NOTE: DXEs are not like other shared libraries
	if(NX_TARGET_PLATFORM_MSDOS)
		unset(lst_unsafe_cflags)
		unset(lst_unsafe_ldflags)
	endif()

	# === Build Shared Module ===

	if(DEFINED str_tname_module)
		while(TARGET "${str_tname_module}")
			set(str_tname_module "${str_tname_module}_mod")
		endwhile()
		nx_append(${NX_PROJECT_NAME}_TARGETS_MODULE "${str_tname_module}")
		nx_append(${var_target_list} "${str_tname_module}")

		add_library("${str_tname_module}" MODULE)
		set_target_properties("${str_tname_module}" PROPERTIES OUTPUT_NAME "${str_oname_module}")
		nx_target_compile_definitions(
			"${str_tname_module}"
			PRIVATE ${arg_target_defines_private} ${${NX_PROJECT_NAME}_ARCHITECTURE_DEFINES} ${${NX_PROJECT_NAME}_BUILD_DEFINES}
					${${NX_PROJECT_NAME}_COMPILER_DEFINES} ${${NX_PROJECT_NAME}_PLATFORM_DEFINES} ${lst_general_defines}
			PUBLIC ${arg_target_defines_public}
			INTERFACE ${arg_target_defines_interface}
			DEFINE_SYMBOL ${arg_target_define_symbol})
		nx_target_compile_features(
			"${str_tname_module}"
			PRIVATE ${arg_target_features_private}
			PUBLIC ${arg_target_features_public}
			INTERFACE ${arg_target_features_interface})
		nx_target_compile_options(
			"${str_tname_module}"
			PRIVATE ${arg_target_cflags_private} ${arg_target_cxxflags_private} ${lst_general_cflags} ${lst_unsafe_cflags}
			PUBLIC ${arg_target_cflags_public} ${arg_target_cxxflags_public}
			INTERFACE ${arg_target_cflags_interface} ${arg_target_cxxflags_interface})
		nx_target_include_directories(
			"${str_tname_module}"
			PRIVATE ${arg_target_includes_private}
			PUBLIC ${arg_target_includes_public}
			INTERFACE ${arg_target_includes_interface}
			EXPORTABLE ${arg_target_exportable})
		if(NX_TARGET_PLATFORM_MSDOS)
			nx_target_link_libraries(
				"${str_tname_module}"
				PUBLIC ${arg_target_depends_private} ${lst_general_libs} ${arg_target_depends_public}
				INTERFACE ${arg_target_depends_interface})
			nx_target_link_options(
				"${str_tname_module}"
				PRIVATE ${arg_target_dxeflags}
				INTERFACE ${arg_target_ldflags_public} ${arg_target_ldflags_interface})
		else()
			nx_target_link_libraries(
				"${str_tname_module}"
				PRIVATE ${arg_target_depends_private} ${lst_general_libs}
				PUBLIC ${arg_target_depends_public}
				INTERFACE ${arg_target_depends_interface})
			nx_target_link_options(
				"${str_tname_module}"
				PRIVATE ${arg_target_ldflags_private} ${lst_general_ldflags} ${lst_unsafe_ldflags}
				PUBLIC ${arg_target_ldflags_public}
				INTERFACE ${arg_target_ldflags_interface})
		endif()
		nx_target_sources(
			"${str_tname_module}"
			PRIVATE ${arg_target_sources_private}
			PUBLIC ${arg_target_sources_public}
			INTERFACE ${arg_target_sources_interface}
			STRIP ${arg_target_strip}
			EXPORTABLE ${arg_target_exportable})

		if(str_target_type STREQUAL "APPLICATION")
			set_target_properties("${str_tname_module}" PROPERTIES INSTALL_RPATH "${CMAKE_INSTALL_RPATH}/${NX_INSTALL_PATH_APPS_RPATH}")
			if(INSTALL_TARGETS${NX_PROJECT_NAME})
				nx_set(${NX_PROJECT_NAME}_COMPONENT_APP ON)
				install(
					TARGETS "${str_tname_module}"
					COMPONENT ${NX_PROJECT_NAME}_APP
					DESTINATION "${NX_INSTALL_PATH_APPS}")
				nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATH_APPS}/${str_fname_module}")
				nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATH_APPS}")
			endif()
		else()
			set_target_properties("${str_tname_module}" PROPERTIES INSTALL_RPATH
																	"${CMAKE_INSTALL_RPATH}/${NX_INSTALL_PATHEXT_LIBRARIES_RPATH}")
			if(INSTALL_TARGETS${NX_PROJECT_NAME})
				nx_set(${NX_PROJECT_NAME}_COMPONENT_MOD ON)
				install(
					TARGETS "${str_tname_module}"
					COMPONENT ${NX_PROJECT_NAME}_MOD
					DESTINATION "${NX_INSTALL_PATHEXT_LIBRARIES}")
				nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATHEXT_LIBRARIES}/${str_fname_module}")
				nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATHEXT_LIBRARIES}")
			endif()
		endif()
	endif()

	# === Build Shared Library ===

	if(DEFINED str_tname_shared)
		while(TARGET "${str_tname_shared}")
			set(str_tname_shared "${str_tname_shared}_dll")
		endwhile()
		nx_append(${NX_PROJECT_NAME}_TARGETS_SHARED "${str_tname_shared}")
		nx_append(${var_target_list} "${str_tname_shared}")

		add_library("${str_tname_shared}" SHARED)
		set_target_properties("${str_tname_shared}" PROPERTIES OUTPUT_NAME "${str_oname_shared}")
		nx_target_compile_definitions(
			"${str_tname_shared}"
			PRIVATE ${arg_target_defines_private} ${${NX_PROJECT_NAME}_ARCHITECTURE_DEFINES} ${${NX_PROJECT_NAME}_BUILD_DEFINES}
					${${NX_PROJECT_NAME}_COMPILER_DEFINES} ${${NX_PROJECT_NAME}_PLATFORM_DEFINES} ${lst_general_defines}
			PUBLIC ${arg_target_defines_public}
			INTERFACE ${arg_target_defines_interface}
			DEFINE_SYMBOL ${arg_target_define_symbol})
		nx_target_compile_features(
			"${str_tname_shared}"
			PRIVATE ${arg_target_features_private}
			PUBLIC ${arg_target_features_public}
			INTERFACE ${arg_target_features_interface})
		nx_target_compile_options(
			"${str_tname_shared}"
			PRIVATE ${arg_target_cflags_private} ${arg_target_cxxflags_private} ${lst_general_cflags} ${lst_unsafe_cflags}
			PUBLIC ${arg_target_cflags_public} ${arg_target_cxxflags_public}
			INTERFACE ${arg_target_cflags_interface} ${arg_target_cxxflags_interface})
		nx_target_include_directories(
			"${str_tname_shared}"
			PRIVATE ${arg_target_includes_private}
			PUBLIC ${arg_target_includes_public}
			INTERFACE ${arg_target_includes_interface}
			EXPORTABLE ${arg_target_exportable})
		if(NX_TARGET_PLATFORM_MSDOS)
			nx_target_link_libraries(
				"${str_tname_shared}"
				PUBLIC ${arg_target_depends_private} ${arg_target_libdeps_private_shared} ${lst_general_libs} ${arg_target_depends_public}
						${arg_target_libdeps_public_shared}
				INTERFACE ${arg_target_depends_interface} ${arg_target_libdeps_interface_shared})
			nx_target_link_options(
				"${str_tname_shared}"
				PRIVATE ${arg_target_dxeflags}
				INTERFACE ${arg_target_ldflags_public} ${arg_target_ldflags_interface})
		else()
			nx_target_link_libraries(
				"${str_tname_shared}"
				PRIVATE ${arg_target_depends_private} ${arg_target_libdeps_private_shared} ${lst_general_libs}
				PUBLIC ${arg_target_depends_public} ${arg_target_libdeps_public_shared}
				INTERFACE ${arg_target_depends_interface} ${arg_target_libdeps_interface_shared})
			nx_target_link_options(
				"${str_tname_shared}"
				PRIVATE ${arg_target_ldflags_private} ${lst_general_ldflags} ${lst_unsafe_ldflags}
				PUBLIC ${arg_target_ldflags_public}
				INTERFACE ${arg_target_ldflags_interface})
		endif()
		nx_target_sources(
			"${str_tname_shared}"
			PRIVATE ${arg_target_sources_private}
			PUBLIC ${arg_target_sources_public}
			INTERFACE ${arg_target_sources_interface}
			STRIP ${arg_target_strip}
			EXPORTABLE ${arg_target_exportable})

		if(NX_TARGET_PLATFORM_MSDOS)
			if(NX_HOST_LANGUAGE_CXX AND arg_target_sources_private MATCHES ".cc|.cpp|.cxx")
				nx_target_link_libraries("${str_tname_shared}" INTERFACE "stdc++")
			endif()
		endif()
		if(NX_TARGET_PLATFORM_MSDOS AND DEFINED CMAKE_DXE3RES)
			set(str_dxe_export "${CMAKE_CURRENT_BINARY_DIR}/${str_tname_shared}_DXE.c")
			set(str_dxe_object "${CMAKE_CURRENT_BINARY_DIR}/${str_tname_shared}_DXE.o")
			if(NOT EXISTS "${str_dxe_object}")
				file(WRITE "${str_dxe_object}" "")
			endif()
			add_custom_command(
				TARGET "${str_tname_shared}"
				POST_BUILD
				COMMAND "${CMAKE_DXE3RES}" -o "${str_dxe_export}" "$<TARGET_FILE:${str_tname_shared}>"
				COMMAND "${CMAKE_C_COMPILER}" -c -O2 ${lst_general_cflags} -o "${str_dxe_object}" "${str_dxe_export}")
			nx_target_sources("${str_tname_shared}" INTERFACE "${str_dxe_object}")
		endif()

		if(opt_soversion)
			set_target_properties("${str_tname_shared}" PROPERTIES SOVERSION "${${NX_PROJECT_NAME}_PROJECT_SOVERSION_COMPAT}"
																	VERSION "${${NX_PROJECT_NAME}_PROJECT_SOVERSION}")
		elseif(DEFINED ${NX_PROJECT_NAME}_PROJECT_SOVERSION)
			set_target_properties("${str_tname_shared}" PROPERTIES VERSION "${${NX_PROJECT_NAME}_PROJECT_SOVERSION}")
		elseif(DEFINED ${NX_PROJECT_NAME}_PROJECT_VERSION)
			set_target_properties("${str_tname_shared}" PROPERTIES VERSION "${${NX_PROJECT_NAME}_PROJECT_VERSION}")
		endif()

		if(NX_TARGET_PLATFORM_DARWIN)
			if(DEFINED ${NX_PROJECT_NAME}_PROJECT_MACHO_COMPAT)
				set_target_properties("${str_tname_shared}" PROPERTIES MACHO_COMPATIBILITY_VERSION
																		"${${NX_PROJECT_NAME}_PROJECT_MACHO_COMPAT}")
			endif()
			if(DEFINED ${NX_PROJECT_NAME}_PROJECT_MACHO)
				set_target_properties("${str_tname_shared}" PROPERTIES MACHO_CURRENT_VERSION "${${NX_PROJECT_NAME}_PROJECT_MACHO}")
			endif()
		endif()

		if(INSTALL_TARGETS${NX_PROJECT_NAME})
			if(NX_TARGET_PLATFORM_CYGWIN
				OR NX_TARGET_PLATFORM_MSDOS
				OR NX_TARGET_PLATFORM_WINDOWS)
				nx_set(${NX_PROJECT_NAME}_COMPONENT_LIB ON)
				nx_set(${NX_PROJECT_NAME}_COMPONENT_OBJ ON)
				install(
					TARGETS "${str_tname_shared}"
					EXPORT "${NX_PROJECT_NAME}"
					RUNTIME COMPONENT ${NX_PROJECT_NAME}_LIB DESTINATION "${NX_INSTALL_PATH_BINARIES}"
					ARCHIVE COMPONENT ${NX_PROJECT_NAME}_OBJ DESTINATION "${NX_INSTALL_PATHDEV_LIBRARIES}")
				nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATH_BINARIES}/${str_fname_shared}")
				nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATHDEV_LIBRARIES}/${str_fname_import}")
				nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATH_BINARIES}")
				nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATHDEV_LIBRARIES}")
			elseif(opt_soversion)
				nx_set(${NX_PROJECT_NAME}_COMPONENT_LIB ON)
				nx_set(${NX_PROJECT_NAME}_COMPONENT_OBJ ON)
				install(
					TARGETS "${str_tname_shared}"
					EXPORT "${NX_PROJECT_NAME}"
					LIBRARY COMPONENT ${NX_PROJECT_NAME}_LIB
							NAMELINK_COMPONENT ${NX_PROJECT_NAME}_OBJ
							DESTINATION "${NX_INSTALL_PATH_LIBRARIES}")
				nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATH_LIBRARIES}/${str_fname_shared}")
				nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATH_LIBRARIES}/${str_fname_sonl1}")
				nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATH_LIBRARIES}/${str_fname_sonl2}")
				nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATH_LIBRARIES}")
			else()
				nx_set(${NX_PROJECT_NAME}_COMPONENT_LIB ON)
				install(
					TARGETS "${str_tname_shared}"
					EXPORT "${NX_PROJECT_NAME}"
					LIBRARY COMPONENT ${NX_PROJECT_NAME}_LIB DESTINATION "${NX_INSTALL_PATH_LIBRARIES}")
				nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATH_LIBRARIES}/${str_fname_shared}")
				nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATH_LIBRARIES}")
			endif()
		endif()
	endif()

	# === Build Static Library ===

	if(DEFINED str_tname_static)
		while(TARGET "${str_tname_static}")
			set(str_tname_static "${str_tname_static}_lib")
		endwhile()
		nx_append(${NX_PROJECT_NAME}_TARGETS_STATIC "${str_tname_static}")
		nx_append(${var_target_list} "${str_tname_static}")

		add_library("${str_tname_static}" STATIC)
		set_target_properties("${str_tname_static}" PROPERTIES OUTPUT_NAME "${str_oname_static}")
		nx_target_compile_definitions(
			"${str_tname_static}"
			PRIVATE ${arg_target_defines_private} ${${NX_PROJECT_NAME}_ARCHITECTURE_DEFINES} ${${NX_PROJECT_NAME}_BUILD_DEFINES}
					${${NX_PROJECT_NAME}_COMPILER_DEFINES} ${${NX_PROJECT_NAME}_PLATFORM_DEFINES} ${lst_general_defines}
			PUBLIC ${arg_target_defines_public}
			INTERFACE ${arg_target_defines_interface}
			DEFINE_SYMBOL ${arg_target_define_symbol}
			STATIC_DEFINE ${arg_target_static_define})
		nx_target_compile_features(
			"${str_tname_static}"
			PRIVATE ${arg_target_features_private}
			PUBLIC ${arg_target_features_public}
			INTERFACE ${arg_target_features_interface})
		nx_target_compile_options(
			"${str_tname_static}"
			PRIVATE ${arg_target_cflags_private} ${arg_target_cxxflags_private} ${lst_general_cflags} ${lst_safe_cflags}
			PUBLIC ${arg_target_cflags_public} ${arg_target_cxxflags_public}
			INTERFACE ${arg_target_cflags_interface} ${arg_target_cxxflags_interface})
		nx_target_include_directories(
			"${str_tname_static}"
			PRIVATE ${arg_target_includes_private}
			PUBLIC ${arg_target_includes_public}
			INTERFACE ${arg_target_includes_interface}
			EXPORTABLE ${arg_target_exportable})
		nx_target_link_libraries(
			"${str_tname_static}"
			PUBLIC ${arg_target_depends_private} ${arg_target_depends_public} ${arg_target_libdeps_private_static}
					${arg_target_libdeps_public_static}
			INTERFACE ${arg_target_depends_interface} ${arg_target_libdeps_interface_static})
		nx_target_link_options("${str_tname_static}" INTERFACE ${arg_target_ldflags_private} ${arg_target_ldflags_public}
																${arg_target_ldflags_interface})
		nx_target_sources(
			"${str_tname_static}"
			PRIVATE ${arg_target_sources_private}
			PUBLIC ${arg_target_sources_public}
			INTERFACE ${arg_target_sources_interface}
			STRIP ${arg_target_strip}
			EXPORTABLE ${arg_target_exportable})

		if(INSTALL_TARGETS${NX_PROJECT_NAME} AND opt_exportable)
			nx_set(${NX_PROJECT_NAME}_COMPONENT_OBJ ON)
			install(
				TARGETS "${str_tname_static}"
				EXPORT "${NX_PROJECT_NAME}"
				COMPONENT ${NX_PROJECT_NAME}_OBJ
				DESTINATION "${NX_INSTALL_PATHDEV_LIBRARIES}")
			nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATHDEV_LIBRARIES}/${str_fname_static}")
			nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATHDEV_LIBRARIES}")
		endif()
	endif()

	# === Build Object Library ===

	if(DEFINED str_tname_objects)
		while(TARGET "${str_tname_objects}")
			set(str_tname_objects "${str_tname_objects}_obj")
		endwhile()
		nx_append(${NX_PROJECT_NAME}_TARGETS_OBJECTS "${str_tname_objects}")
		nx_append(${var_target_list} "${str_tname_objects}")

		add_library("${str_tname_objects}" OBJECT)
		set_target_properties("${str_tname_objects}" PROPERTIES OUTPUT_NAME "${str_oname_objects}")
		nx_target_compile_definitions(
			"${str_tname_objects}"
			PRIVATE ${arg_target_defines_private} ${${NX_PROJECT_NAME}_ARCHITECTURE_DEFINES} ${${NX_PROJECT_NAME}_BUILD_DEFINES}
					${${NX_PROJECT_NAME}_COMPILER_DEFINES} ${${NX_PROJECT_NAME}_PLATFORM_DEFINES} ${lst_general_defines}
			PUBLIC ${arg_target_defines_public}
			INTERFACE ${arg_target_defines_interface}
			DEFINE_SYMBOL ${arg_target_define_symbol}
			STATIC_DEFINE ${arg_target_static_define})
		nx_target_compile_features(
			"${str_tname_objects}"
			PRIVATE ${arg_target_features_private}
			PUBLIC ${arg_target_features_public}
			INTERFACE ${arg_target_features_interface})
		nx_target_compile_options(
			"${str_tname_objects}"
			PRIVATE ${arg_target_cflags_private} ${arg_target_cxxflags_private} ${lst_general_cflags} ${lst_safe_cflags}
			PUBLIC ${arg_target_cflags_public} ${arg_target_cxxflags_public}
			INTERFACE ${arg_target_cflags_interface} ${arg_target_cxxflags_interface})
		nx_target_include_directories(
			"${str_tname_objects}"
			PRIVATE ${arg_target_includes_private}
			PUBLIC ${arg_target_includes_public}
			INTERFACE ${arg_target_includes_interface}
			EXPORTABLE ${arg_target_exportable})
		nx_target_link_libraries(
			"${str_tname_objects}"
			PUBLIC ${arg_target_depends_private} ${arg_target_depends_public} ${arg_target_libdeps_private_object}
					${arg_target_libdeps_public_object}
			INTERFACE ${arg_target_depends_interface} ${arg_target_libdeps_interface_object})
		nx_target_link_options("${str_tname_objects}" INTERFACE ${arg_target_ldflags_private} ${arg_target_ldflags_public}
																${arg_target_ldflags_interface})
		nx_target_sources(
			"${str_tname_objects}"
			PRIVATE ${arg_target_sources_private}
			PUBLIC ${arg_target_sources_public}
			INTERFACE ${arg_target_sources_interface}
			STRIP ${arg_target_strip}
			EXPORTABLE ${arg_target_exportable})

		if(INSTALL_TARGETS${NX_PROJECT_NAME} AND opt_exportable)
			nx_set(${NX_PROJECT_NAME}_COMPONENT_OBJ ON)
			install(
				TARGETS "${str_tname_objects}"
				EXPORT "${NX_PROJECT_NAME}"
				COMPONENT ${NX_PROJECT_NAME}_OBJ
				DESTINATION "${NX_INSTALL_PATHDEV_LIBRARIES}")
			nx_append_global(NX_CLEANUP_RMDIR_F "${NX_INSTALL_PATHDEV_LIBRARIES}/objects-${CMAKE_BUILD_TYPE}/${str_tname_objects}")
		endif()
	endif()

	# === Configure Interface Library ===

	if(DEFINED str_tname_interface)
		while(TARGET "${str_tname_interface}")
			set(str_tname_interface "${str_tname_interface}_src")
		endwhile()
		nx_append(${NX_PROJECT_NAME}_TARGETS_INTERFACE "${str_tname_interface}")
		nx_append(${var_target_list} "${str_tname_interface}")

		add_library("${str_tname_interface}" INTERFACE)
		nx_target_compile_definitions(
			"${str_tname_interface}"
			INTERFACE ${arg_target_defines_private} ${arg_target_defines_public} ${arg_target_defines_interface}
			DEFINE_SYMBOL ${arg_target_define_symbol}
			STATIC_DEFINE ${arg_target_static_define})
		nx_target_compile_features("${str_tname_interface}" INTERFACE ${arg_target_features_private} ${arg_target_features_public}
																		${arg_target_features_interface})
		nx_target_compile_options(
			"${str_tname_interface}"
			INTERFACE ${arg_target_cflags_private} ${arg_target_cxxflags_private} ${arg_target_cflags_public} ${arg_target_cxxflags_public}
						${arg_target_cflags_interface} ${arg_target_cxxflags_interface})
		nx_target_include_directories(
			"${str_tname_interface}"
			INTERFACE ${arg_target_includes_private} ${arg_target_includes_public} ${arg_target_includes_interface}
			EXPORTABLE ${opt_exportable})
		nx_target_link_libraries(
			"${str_tname_interface}"
			INTERFACE ${arg_target_depends_private} ${arg_target_depends_public} ${arg_target_depends_interface}
						${arg_target_libdeps_private_source} ${arg_target_libdeps_public_source} ${arg_target_libdeps_interface_source})
		nx_target_link_options("${str_tname_interface}" INTERFACE ${arg_target_ldflags_private} ${arg_target_ldflags_public}
																	${arg_target_ldflags_interface})
		nx_target_sources(
			"${str_tname_interface}"
			INTERFACE ${arg_target_sources_private} ${arg_target_sources_public} ${arg_target_sources_interface}
			STRIP ${arg_target_strip}
			EXPORTABLE ${opt_exportable})

		if(INSTALL_TARGETS${NX_PROJECT_NAME} AND opt_exportable)
			install(TARGETS "${str_tname_interface}" EXPORT "${NX_PROJECT_NAME}")
		endif()
	endif()

	# === Add Target Alias ===

	if(opt_exportable)
		foreach(tmp_type "shared" "static" "objects" "interface")
			if(DEFINED str_tname_${tmp_type})
				add_library(${${NX_PROJECT_NAME}_PROJECT_PARENT}::${str_tname_${tmp_type}} ALIAS ${str_tname_${tmp_type}})
				nx_append(${NX_PROJECT_NAME}_TARGLIST_EXPORT "${str_tname_${tmp_type}}")
			endif()
		endforeach()
	endif()

	# === Post-Build Steps ===

	unset(lst_pbs_executable)
	unset(lst_pbs_module)
	unset(lst_pbs_shared)

	if(NOT NX_TARGET_PLATFORM_ANDROID
		AND NOT NX_TARGET_PLATFORM_MSDOS
		AND NX_TARGET_BUILD_RELEASE)
		if(DEFINED CMAKE_OBJCOPY
			AND EXISTS "${CMAKE_OBJCOPY}"
			AND NOT str_target_type STREQUAL "TEST")
			foreach(tmp_type "executable" "module" "shared")
				if(DEFINED str_tname_${tmp_type})
					list(
						APPEND
						lst_pbs_${tmp_type}
						COMMAND
						"${CMAKE_OBJCOPY}"
						"--only-keep-debug"
						"$<TARGET_FILE:${str_tname_${tmp_type}}>"
						"$<TARGET_FILE:${str_tname_${tmp_type}}>.debug"
						COMMAND
						"${CMAKE_OBJCOPY}"
						"--strip-debug"
						"$<TARGET_FILE:${str_tname_${tmp_type}}>"
						COMMAND
						"${CMAKE_OBJCOPY}"
						"--add-gnu-debuglink"
						"$<TARGET_FILE:${str_tname_${tmp_type}}>.debug"
						"$<TARGET_FILE:${str_tname_${tmp_type}}>")
				endif()
			endforeach()

			if(INSTALL_TARGETS${NX_PROJECT_NAME})
				if(DEFINED str_tname_executable AND str_target_type STREQUAL "APPLICATION")
					nx_set(${NX_PROJECT_NAME}_COMPONENT_DBG ON)
					nx_append(${NX_PROJECT_NAME}_FILES_DEBUG "${CMAKE_CURRENT_BINARY_DIR}/${str_fname_executable}.debug")
					install(
						FILES "${CMAKE_CURRENT_BINARY_DIR}/${str_fname_executable}.debug"
						DESTINATION "${NX_INSTALL_PATH_APPS_DEBUG}"
						COMPONENT ${NX_PROJECT_NAME}_DBG)
					nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATH_APPS_DEBUG}/${str_fname_executable}.debug")
					nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATH_APPS_DEBUG}")
				elseif(DEFINED str_tname_executable AND str_target_type STREQUAL "DAEMON")
					nx_set(${NX_PROJECT_NAME}_COMPONENT_DBG ON)
					nx_append(${NX_PROJECT_NAME}_FILES_DEBUG "${CMAKE_CURRENT_BINARY_DIR}/${str_fname_executable}.debug")
					install(
						FILES "${CMAKE_CURRENT_BINARY_DIR}/${str_fname_executable}.debug"
						DESTINATION "${NX_INSTALL_PATH_SERVERS_DEBUG}"
						COMPONENT ${NX_PROJECT_NAME}_DBG)
					nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATH_SERVERS_DEBUG}/${str_fname_executable}.debug")
					nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATH_SERVERS_DEBUG}")
				elseif(DEFINED str_tname_executable AND str_target_type STREQUAL "EXECUTABLE")
					nx_set(${NX_PROJECT_NAME}_COMPONENT_DBG ON)
					nx_append(${NX_PROJECT_NAME}_FILES_DEBUG "${CMAKE_CURRENT_BINARY_DIR}/${str_fname_executable}.debug")
					install(
						FILES "${CMAKE_CURRENT_BINARY_DIR}/${str_fname_executable}.debug"
						DESTINATION "${NX_INSTALL_PATH_BINARIES_DEBUG}"
						COMPONENT ${NX_PROJECT_NAME}_DBG)
					nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATH_BINARIES_DEBUG}/${str_fname_executable}.debug")
					nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATH_BINARIES_DEBUG}")
				elseif(DEFINED str_tname_shared)
					nx_set(${NX_PROJECT_NAME}_COMPONENT_DBG ON)
					nx_append(${NX_PROJECT_NAME}_FILES_DEBUG "${CMAKE_CURRENT_BINARY_DIR}/${str_fname_shared}.debug")
					install(
						FILES "${CMAKE_CURRENT_BINARY_DIR}/${str_fname_shared}.debug"
						DESTINATION "${NX_INSTALL_PATH_LIBRARIES_DEBUG}"
						COMPONENT ${NX_PROJECT_NAME}_DBG)
					nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATH_LIBRARIES_DEBUG}/${str_fname_shared}.debug")
					nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATH_LIBRARIES_DEBUG}")
				elseif(DEFINED str_tname_module)
					nx_set(${NX_PROJECT_NAME}_COMPONENT_DBG ON)
					nx_append(${NX_PROJECT_NAME}_FILES_DEBUG "${CMAKE_CURRENT_BINARY_DIR}/${str_fname_module}.debug")
					install(
						FILES "${CMAKE_CURRENT_BINARY_DIR}/${str_fname_module}.debug"
						DESTINATION "${NX_INSTALL_PATHEXT_LIBRARIES_DEBUG}"
						COMPONENT ${NX_PROJECT_NAME}_DBG)
					nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATHEXT_LIBRARIES_DEBUG}/${str_fname_module}.debug")
					nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATHEXT_LIBRARIES_DEBUG}")
				endif()
			endif()
		endif()
	endif()

	if(NX_TARGET_PLATFORM_CYGWIN OR NX_TARGET_PLATFORM_WINDOWS)
		if(DEFINED str_tname_executable
			OR DEFINED str_tname_module
			OR DEFINED str_tname_shared)
			if(NOT str_target_type STREQUAL "TEST")
				set(opt_certificate OFF)
				unset(str_certificate_file)
				unset(str_certificate_password)
				unset(str_certificate_passfile)

				if(NOT "x$ENV{NXPACKAGE_PKCS12}" STREQUAL "x" AND EXISTS "$ENV{NXPACKAGE_PKCS12}")
					set(str_certificate_file "$ENV{NXPACKAGE_PKCS12}")
				endif()

				if(DEFINED str_certificate_file)
					if(NOT "x$ENV{NXPACKAGE_PKCS12READPASS}" STREQUAL "x")
						set(str_certificate_passfile "$ENV{NXPACKAGE_PKCS12READPASS}")
					elseif(EXISTS "${str_certificate_file}cred")
						set(str_certificate_passfile "${str_certificate_file}cred")
					elseif(NOT "x$ENV{NXPACKAGE_PKCS12PASS}" STREQUAL "x")
						set(str_certificate_password "$ENV{NXPACKAGE_PKCS12PASS}")
					endif()
				endif()

				if(DEFINED str_certificate_file)
					find_program(OSSLSIGNCODE_EXECUTABLE NAMES "osslsigncode")
					if(OSSLSIGNCODE_EXECUTABLE)
						set(opt_certificate ON)
					endif()
				endif()

				set(opt_default_sign ON)
				if(NX_TARGET_BUILD_DEBUG)
					set(opt_default_sign OFF)
				endif()

				nx_dependent_option(DIGSIGN_TARGETS_ALL "Digitally-Sign Targets" ${opt_default_sign} "opt_certificate" OFF)
				nx_dependent_option(DIGSIGN_TARGETS${NX_PROJECT_NAME} "Digitally-Sign Targets - ${PROJECT_NAME}" ON "DIGSIGN_TARGETS_ALL"
									OFF)

				if(DIGSIGN_TARGETS${NX_PROJECT_NAME})
					unset(tmp_password)
					if(NOT "x$ENV{NXPACKAGE_PKCS12CRED}" STREQUAL "x")
						list(APPEND tmp_password "-pass" "${str_certificate_password}")
					elseif(EXISTS "$ENV{NXPACKAGE_PKCS12}cred")
						list(APPEND tmp_password "-readpass" "${str_certificate_passfile}")
					endif()

					foreach(tmp_type "executable" "module" "shared")
						if(DEFINED str_tname_${tmp_type})
							list(
								APPEND
								lst_pbs_${tmp_type}
								COMMAND
								"${OSSLSIGNCODE_EXECUTABLE}"
								"-pkcs12"
								"${str_certificate_file}"
								${tmp_password}
								"-ts"
								"http://timestamp.digicert.com"
								"-h"
								"sha1"
								"-in"
								"$<TARGET_FILE:${str_tname_${tmp_type}}>"
								"-out"
								"$<TARGET_FILE:${str_tname_${tmp_type}}>.signed"
								COMMAND
								"${OSSLSIGNCODE_EXECUTABLE}"
								"-pkcs12"
								"${str_certificate_file}"
								${tmp_password}
								"-ts"
								"http://timestamp.digicert.com"
								"-nest"
								"-h"
								"sha256"
								"-in"
								"$<TARGET_FILE:${str_tname_${tmp_type}}>.signed"
								"-out"
								"$<TARGET_FILE:${str_tname_${tmp_type}}>"
								COMMAND
								"${CMAKE_COMMAND}"
								"-E"
								"remove"
								"$<TARGET_FILE:${str_tname_${tmp_type}}>.signed")
						endif()
					endforeach()

					unset(tmp_password)
				endif()

				unset(str_certificate_password)
				unset(str_certificate_passfile)
			endif()
		endif()
	endif()

	foreach(tmp_type "executable" "module" "shared")
		if(DEFINED str_tname_${tmp_type} AND DEFINED lst_pbs_${tmp_type})
			# cmake-lint: disable=E1125
			add_custom_command(
				TARGET ${str_tname_${tmp_type}}
				POST_BUILD ${lst_pbs_${tmp_type}}
				WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
				COMMENT "[cmake] Post-Build: ${str_tname_${tmp_type}}"
				VERBATIM)
		endif()
	endforeach()

	nx_function_end()
endfunction()

# ===================================================================

#
# Export Package Configuration
#
# NOTE: Called automatically at nx_project_end for internal targets.
#
function(nx_target_export)
	nx_guard_function(nx_target_export)
	nx_function_begin()

	if(DEFINED ${NX_PROJECT_NAME}_TARGLIST_EXPORT)
		unset(str_export_version)
		set(str_export_compat "AnyNewerVersion")
		if(DEFINED ${NX_PROJECT_NAME}_PROJECT_VERSION_COMPAT)
			if("${${NX_PROJECT_NAME}_PROJECT_VERSION_COMPAT}"
				STREQUAL
				"${${NX_PROJECT_NAME}_PROJECT_VERSION_MAJOR}.${${NX_PROJECT_NAME}_PROJECT_VERSION_MINOR}.${${NX_PROJECT_NAME}_PROJECT_VERSION_PATCH}"
			)
				set(str_export_compat "ExactVersion")
			elseif("${${NX_PROJECT_NAME}_PROJECT_VERSION_COMPAT}" STREQUAL
					"${${NX_PROJECT_NAME}_PROJECT_VERSION_MAJOR}.${${NX_PROJECT_NAME}_PROJECT_VERSION_MINOR}")
				set(str_export_compat "SameMinorVersion")
			elseif("${${NX_PROJECT_NAME}_PROJECT_VERSION_COMPAT}" STREQUAL "${${NX_PROJECT_NAME}_PROJECT_VERSION_MAJOR}")
				set(str_export_compat "SameMajorVersion")
			endif()
			set(str_export_version "-${${NX_PROJECT_NAME}_PROJECT_VERSION_COMPAT}")
		elseif(DEFINED ${NX_PROJECT_NAME}_PROJECT_SOVERSION_COMPAT)
			if("${${NX_PROJECT_NAME}_PROJECT_SOVERSION_COMPAT}"
				STREQUAL
				"${${NX_PROJECT_NAME}_PROJECT_SOVERSION_MAJOR}.${${NX_PROJECT_NAME}_PROJECT_SOVERSION_MINOR}.${${NX_PROJECT_NAME}_PROJECT_SOVERSION_PATCH}"
			)
				set(str_export_compat "ExactVersion")
			elseif("${${NX_PROJECT_NAME}_PROJECT_SOVERSION_COMPAT}" STREQUAL
					"${${NX_PROJECT_NAME}_PROJECT_SOVERSION_MAJOR}.${${NX_PROJECT_NAME}_PROJECT_SOVERSION_MINOR}")
				set(str_export_compat "SameMinorVersion")
			elseif("${${NX_PROJECT_NAME}_PROJECT_SOVERSION_COMPAT}" STREQUAL "${${NX_PROJECT_NAME}_PROJECT_SOVERSION_MAJOR}")
				set(str_export_compat "SameMajorVersion")
			endif()
			set(str_export_version "-${${NX_PROJECT_NAME}_PROJECT_SOVERSION_COMPAT}")
		endif()

		set(str_export_component "DEV")
		if(DEFINED ${NX_PROJECT_NAME}_COMPONENT_OBJ AND ${NX_PROJECT_NAME}_COMPONENT_OBJ)
			set(str_export_component "OBJ")
		endif()
		if(DEFINED ${NX_PROJECT_NAME}_COMPONENT_LIB AND ${NX_PROJECT_NAME}_COMPONENT_LIB)
			set(str_export_component "OBJ")
		endif()

		export(
			EXPORT "${NX_PROJECT_NAME}"
			NAMESPACE "${${NX_PROJECT_NAME}_PROJECT_PARENT}::"
			FILE "${PROJECT_NAME}Config.cmake")

		if(INSTALL_TARGETS${NX_PROJECT_NAME})
			nx_set(${NX_PROJECT_NAME}_COMPONENT_${str_export_component} ON)
			install(
				EXPORT "${NX_PROJECT_NAME}"
				NAMESPACE "${${NX_PROJECT_NAME}_PROJECT_PARENT}::"
				FILE "${PROJECT_NAME}Config.cmake"
				DESTINATION "${NX_INSTALL_PATHDEV_EXPORT}/${PROJECT_NAME}${str_export_version}"
				COMPONENT ${NX_PROJECT_NAME}_${str_export_component})
			nx_append_global(NX_CLEANUP_RMDIR_F "${NX_INSTALL_PATHDEV_EXPORT}/${PROJECT_NAME}${str_export_version}")
		endif()

		if(DEFINED str_export_version)
			write_basic_package_version_file(
				"${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
				VERSION "${${NX_PROJECT_NAME}_PROJECT_VERSION}"
				COMPATIBILITY "${str_export_compat}")
			if(INSTALL_TARGETS${NX_PROJECT_NAME})
				nx_set(${NX_PROJECT_NAME}_COMPONENT_${str_export_component} ON)
				install(
					FILES "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
					DESTINATION "${NX_INSTALL_PATHDEV_EXPORT}/${PROJECT_NAME}${str_export_version}"
					COMPONENT ${NX_PROJECT_NAME}_${str_export_component})
				nx_append_global(NX_CLEANUP_DELETE
									"${NX_INSTALL_PATHDEV_EXPORT}/${PROJECT_NAME}${str_export_version}/${PROJECT_NAME}ConfigVersion.cmake")
				nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATHDEV_EXPORT}/${PROJECT_NAME}${str_export_version}")
			endif()
		endif()
	endif()

	nx_function_end()
endfunction()

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

include(NXTarget)

nx_guard_file()

# ===================================================================

if(NOT DEFINED CMAKE_CROSSCOMPILING_EMULATOR AND NOT NX_TARGET_PLATFORM_NATIVE)
	if(NX_TARGET_PLATFORM_WINDOWS AND (NX_TARGET_ARCHITECTURE_AMD64 OR NX_TARGET_ARCHITECTURE_IA32))
		find_program(CMAKE_CROSSCOMPILING_EMULATOR NAMES "wine64" "wine")
		if(NOT CMAKE_CROSSCOMPILING_EMULATOR)
			unset(CMAKE_CROSSCOMPILING_EMULATOR)
		endif()
	endif()
endif()

if(NOT DEFINED BUILD_TESTING)
	if(DEFINED ENABLE_TESTS_ALL)
		set(BUILD_TESTING ${ENABLE_TESTS_ALL})
	elseif(NX_TARGET_ARCHITECTURE_NATIVE AND NX_TARGET_PLATFORM_NATIVE)
		set(BUILD_TESTING ON)
	elseif(DEFINED CMAKE_CROSSCOMPILING_EMULATOR)
		set(BUILD_TESTING ON)
	else()
		set(BUILD_TESTING OFF)
	endif()
endif()

include(CTest)

# ===================================================================

#
# nx_test: Create TestCase
#
function(nx_test var_target_list str_target_name)
	nx_function_begin()

	# === Do Not Test External Projects By Default ===

	set(opt_default_test_build ON)
	set(opt_default_test_enable ${BUILD_TESTING})
	if(${NX_PROJECT_NAME}_IS_EXTERNAL)
		set(opt_default_test_build OFF)
		set(opt_default_test_enable OFF)
	endif()

	nx_option(BUILD_TESTS_ALL "Build Tests" ON)
	nx_dependent_option(BUILD_TESTS${NX_PROJECT_NAME} "Build Tests - ${PROJECT_NAME}" ${opt_default_test_build} "BUILD_TESTS_ALL" OFF)

	nx_dependent_option(ENABLE_TESTS_ALL "Enable Tests" ${BUILD_TESTING} "BUILD_TESTS_ALL" OFF)
	nx_dependent_option(ENABLE_TESTS${NX_PROJECT_NAME} "Enable Tests - ${PROJECT_NAME}" ${opt_default_test_enable}
						"ENABLE_TESTS_ALL;BUILD_TESTS${NX_PROJECT_NAME}" OFF)

	if(BUILD_TESTS${NX_PROJECT_NAME})

		# === Available Parsing Modes ===

		set(lst_pmode_single "WORKING_DIRECTORY")
		set(lst_pmode_multi "CMDSET" "ENVIRONMENT" "BUILDARGS")

		foreach(tmp_pmode ${lst_pmode_single} ${lst_pmode_multi})
			string(TOLOWER "${tmp_pmode}" tmp_pmode)
			unset(arg_test_${tmp_pmode})
		endforeach()

		set(str_pmode_cur "BUILDARGS")

		# === Parse Arguments ===

		foreach(tmp_argv ${ARGN})
			if("${tmp_argv}" IN_LIST lst_pmode_single OR "${tmp_argv}" IN_LIST lst_pmode_multi)
				set(str_pmode_cur "${tmp_argv}")
			elseif(tmp_argv STREQUAL "--")
				set(str_pmode_cur "BUILDARGS")
			elseif("${str_pmode_cur}" IN_LIST lst_pmode_single)
				string(TOLOWER "${str_pmode_cur}" tmp_pmode)
				if(DEFINED arg_test_${tmp_pmode})
					message(AUTHOR_WARNING "nx_test: Option ${str_pmode_cur} Already Set")
				else()
					set(arg_test_${tmp_pmode} "${tmp_argv}")
				endif()
			elseif("${str_pmode_cur}" IN_LIST lst_pmode_multi)
				string(TOLOWER "${str_pmode_cur}" tmp_pmode)
				list(APPEND arg_test_${tmp_pmode} "${tmp_argv}")
			else()
				message(AUTHOR_WARNING "nx_test: Parse Mode ${str_pmode_cur} Unknown")
			endif()
		endforeach()

		if(NOT DEFINED arg_test_working_directory)
			set(arg_test_working_directory "${CMAKE_CURRENT_BINARY_DIR}")
		endif()

		# === Create Tests ===

		nx_target(lst_targets_test "test-${str_target_name}" TEST ${arg_test_buildargs})
		nx_append(${var_target_list} ${lst_targets_test})

		if(ENABLE_TESTS${NX_PROJECT_NAME})
			foreach(tmp_target ${lst_targets_test})
				foreach(tmp_cmdset ${arg_test_cmdset})
					string(MAKE_C_IDENTIFIER "${tmp_cmdset}" tmp_suffix)
					string(REPLACE " " ";" tmp_cmdset "${tmp_cmdset}")
					add_test(
						NAME "${tmp_target}_${tmp_suffix}"
						WORKING_DIRECTORY "${arg_test_working_directory}"
						COMMAND ${CMAKE_CROSSCOMPILING_EMULATOR} $<TARGET_FILE:${tmp_target}> ${tmp_cmdset})
					if(DEFINED arg_test_environment)
						set_tests_properties("${tmp_target}_${tmp_suffix}" PROPERTIES ENVIRONMENT ${arg_test_environment})
					endif()
				endforeach()
				if(NOT DEFINED arg_test_cmdset)
					add_test(
						NAME "${tmp_target}"
						WORKING_DIRECTORY "${arg_test_working_directory}"
						COMMAND ${CMAKE_CROSSCOMPILING_EMULATOR} $<TARGET_FILE:${tmp_target}>)
					if(DEFINED arg_test_environment)
						set_tests_properties("${tmp_target}" PROPERTIES ENVIRONMENT ${arg_test_environment})
					endif()
				endif()
			endforeach()
			unset(lst_targets_test)
		endif()

	endif()

	nx_function_end()
endfunction()

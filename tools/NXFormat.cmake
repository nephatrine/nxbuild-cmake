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

_nx_guard_file()

# ===================================================================

function(nx_format_clang)
	_nx_guard_function(nx_format_clang)
	_nx_function_begin()

	# PARSER START ====

	_nx_parser_initialize()

	set(lsKeywordToggle "ALL")
	set(lsKeywordSingle "CONFIG")
	set(lsKeywordMultiple "FILES")

	set(sParseMode "FILES")

	_nx_parser_clear()
	_nx_parser_run(${ARGN})

	# ==== PARSER END

	if(NOT DEFINED bArgALL)
		set(bArgALL OFF)
	endif()

	find_program(CLANG_FORMAT_EXECUTABLE NAMES "clang-format")

	unset(sAll)
	if(bArgALL)
		set(sAll "ALL")
	endif()

	set(bCanFormat ON)
	if(NOT DEFINED lsArgFILES AND DEFINED ${NX_PROJECT_NAME}_FILES_SOURCE)
		list(APPEND lsArgFILES ${${NX_PROJECT_NAME}_FILES_SOURCE})
	endif()
	if(NOT DEFINED lsArgFILES)
		set(bCanFormat OFF)
	endif()

	set(bDefaultFormat OFF)
	if(NOT DEFINED sArgCONFIG)
		if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.clang-format")
			set(sArgCONFIG "${CMAKE_CURRENT_SOURCE_DIR}/.clang-format")
		elseif(EXISTS "${CMAKE_SOURCE_DIR}/.clang-format")
			set(sArgCONFIG "${CMAKE_SOURCE_DIR}/.clang-format")
		endif()
	endif()
	if(DEFINED sArgCONFIG)
		if(NOT DEFINED ${NX_PROJECT_NAME}_IS_EXTERNAL OR NOT ${NX_PROJECT_NAME}_IS_EXTERNAL)
			set(bDefaultFormat ON)
		endif()
	endif()

	cmake_dependent_option(ENABLE_CLANG_FORMAT${NX_PROJECT_NAME} "Enable 'clang-format' - ${PROJECT_NAME}" ${bDefaultFormat}
							"CLANG_FORMAT_EXECUTABLE;bCanFormat" OFF)

	if(ENABLE_CLANG_FORMAT${NX_PROJECT_NAME})
		list(REMOVE_DUPLICATES lsArgFILES)
		unset(sConfigFile)
		if(DEFINED sArgCONFIG)
			get_filename_component(sArgCONFIG "${sArgCONFIG}" ABSOLUTE)
			get_filename_component(sConfigFile "${sArgCONFIG}" NAME)

			file(RELATIVE_PATH sConfigPath "${CMAKE_CURRENT_SOURCE_DIR}" "${sArgCONFIG}")
			get_filename_component(sConfigPath "${sConfigPath}" DIRECTORY)
			if(NOT sConfigPath MATCHES "^[./]*$" AND NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${sConfigFile}")
				file(COPY "${sArgCONFIG}" DESTINATION "${CMAKE_CURRENT_SOURCE_DIR}")
			endif()
			if(NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/${sConfigFile}")
				file(COPY "${sArgCONFIG}" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
			endif()
		endif()

		if(NOT DEFINED sConfigFile OR sConfigFile STREQUAL ".clang-format")
			add_custom_target(
				clang-format${NX_PROJECT_NAME}
				${sAll}
				COMMAND "${CLANG_FORMAT_EXECUTABLE}" -fallback-style=none -style=file -i ${lsArgFILES}
				DEPENDS ${lsArgFILES}
				WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
				COMMENT "[clang-format] Formatting '${PROJECT_NAME}' Source Files"
				VERBATIM)
		elseif(sConfigFile STREQUAL ".clang-format")
			add_custom_target(
				clang-format${NX_PROJECT_NAME}
				${sAll}
				COMMAND "${CLANG_FORMAT_EXECUTABLE}" -fallback-style=none -style=file -i ${lsArgFILES}
				DEPENDS ${lsArgFILES} "${sArgCONFIG}"
				WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
				COMMENT "[clang-format] Formatting '${PROJECT_NAME}' Source Files"
				VERBATIM)
		else()
			add_custom_target(
				clang-format${NX_PROJECT_NAME}
				${sAll}
				COMMAND "${CLANG_FORMAT_EXECUTABLE}" -fallback-style=none -style=file:${sConfigFile} -i ${lsArgFILES}
				DEPENDS ${lsArgFILES} "${sArgCONFIG}"
				WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
				COMMENT "[clang-format] Formatting '${PROJECT_NAME}' Source Files"
				VERBATIM)
		endif()
		if(NOT TARGET format)
			add_custom_target(format COMMENT "Formatting Project(s)")
		endif()
		add_dependencies(format clang-format${NX_PROJECT_NAME})
	endif()

	_nx_function_end()
endfunction()

# ===================================================================

function(nx_format_cmake)
	_nx_guard_function(nx_format_cmake)
	_nx_function_begin()

	# PARSER START ====

	_nx_parser_initialize()

	set(lsKeywordToggle "ALL" "FORMAT" "TIDY")
	set(lsKeywordSingle "CONFIG")
	set(lsKeywordMultiple "FILES")

	set(sParseMode "FILES")

	_nx_parser_clear()
	_nx_parser_run(${ARGN})

	# ==== PARSER END

	if(NOT DEFINED bArgALL)
		set(bArgALL OFF)
	endif()

	if(NOT DEFINED bArgFORMAT AND NOT DEFINED bArgTIDY)
		set(bArgFORMAT ON)
		set(bArgTIDY ON)
	elseif(NOT DEFINED bArgFORMAT)
		set(bArgFORMAT OFF)
	elseif(NOT DEFINED bArgTIDY)
		set(bArgTIDY OFF)
	endif()

	find_program(CMAKE_FORMAT_EXECUTABLE NAMES "cmake-format")
	find_program(CMAKE_LINT_EXECUTABLE NAMES "cmake-lint")

	unset(sAll)
	if(bArgALL)
		set(sAll "ALL")
	endif()

	set(bCanFormat ON)
	if(NOT DEFINED lsArgFILES)
		file(
			GLOB lsArgFILES
			LIST_DIRECTORIES false
			"cmake/*.cmake" "tools/*.cmake")
		list(APPEND lsArgFILES "${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt")
	endif()
	if(NOT DEFINED lsArgFILES)
		set(bCanFormat OFF)
	endif()

	set(bDefaultFormat OFF)
	if(NOT DEFINED sArgCONFIG)
		if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.cmake-format")
			set(sArgCONFIG "${CMAKE_CURRENT_SOURCE_DIR}/.cmake-format")
		elseif(EXISTS "${CMAKE_SOURCE_DIR}/.cmake-format")
			set(sArgCONFIG "${CMAKE_SOURCE_DIR}/.cmake-format")
		elseif(DEFINED nxbuild_SOURCE_DIR AND EXISTS "${nxbuild_SOURCE_DIR}/.cmake-format")
			set(sArgCONFIG "${nxbuild_SOURCE_DIR}/.cmake-format")
		endif()
	endif()
	if(DEFINED sArgCONFIG)
		if(NOT DEFINED ${NX_PROJECT_NAME}_IS_EXTERNAL OR NOT ${NX_PROJECT_NAME}_IS_EXTERNAL)
			set(bDefaultFormat ON)
		endif()
	endif()

	cmake_dependent_option(ENABLE_CMAKE_FORMAT${NX_PROJECT_NAME} "Enable 'cmake-format' - ${PROJECT_NAME}" ${bDefaultFormat}
							"CMAKE_FORMAT_EXECUTABLE;bCanFormat;bArgFORMAT" OFF)
	cmake_dependent_option(ENABLE_CMAKE_LINT${NX_PROJECT_NAME} "Enable 'cmake-lint' - ${PROJECT_NAME}" ${bDefaultFormat}
							"CMAKE_LINT_EXECUTABLE;bCanFormat;bArgTIDY" OFF)

	if(ENABLE_CMAKE_FORMAT${NX_PROJECT_NAME})
		list(REMOVE_DUPLICATES lsArgFILES)
		if(DEFINED sArgCONFIG)
			add_custom_target(
				cmake-format${NX_PROJECT_NAME}
				${sAll}
				COMMAND "${CMAKE_FORMAT_EXECUTABLE}" --config "${sArgCONFIG}" -i ${lsArgFILES}
				DEPENDS ${lsArgFILES} "${sArgCONFIG}"
				WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
				COMMENT "[cmake-format] Formatting '${PROJECT_NAME}' CMake Files"
				VERBATIM)
		else()
			add_custom_target(
				cmake-format${NX_PROJECT_NAME}
				${sAll}
				COMMAND "${CMAKE_FORMAT_EXECUTABLE}" -i ${lsArgFILES}
				DEPENDS ${lsArgFILES}
				WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
				COMMENT "[cmake-format] Formatting '${PROJECT_NAME}' CMake Files"
				VERBATIM)
		endif()
		if(NOT TARGET format)
			add_custom_target(format COMMENT "Formatting Project(s)")
		endif()
		add_dependencies(format cmake-format${NX_PROJECT_NAME})
	endif()

	if(ENABLE_CMAKE_LINT${NX_PROJECT_NAME})
		list(REMOVE_DUPLICATES lsArgFILES)
		if(DEFINED sArgCONFIG)
			add_custom_target(
				cmake-lint${NX_PROJECT_NAME}
				${sAll}
				COMMAND "${CMAKE_LINT_EXECUTABLE}" ${lsArgFILES} -c "${sArgCONFIG}"
				DEPENDS ${lsArgFILES} "${sArgCONFIG}"
				WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
				COMMENT "[cmake-lint] Scanning '${PROJECT_NAME}' CMake Files"
				VERBATIM)
		else()
			add_custom_target(
				cmake-lint${NX_PROJECT_NAME}
				${sAll}
				COMMAND "${CMAKE_LINT_EXECUTABLE}" ${lsArgFILES}
				DEPENDS ${lsArgFILES}
				WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
				COMMENT "[cmake-lint] Scanning '${PROJECT_NAME}' CMake Files"
				VERBATIM)
		endif()
		if(NOT TARGET tidy)
			add_custom_target(tidy COMMENT "Scanning Project(s)")
		endif()
		add_dependencies(tidy cmake-lint${NX_PROJECT_NAME})
	endif()

	_nx_function_end()
endfunction()

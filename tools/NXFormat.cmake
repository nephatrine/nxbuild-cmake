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

include(_NXInternals)

nx_guard_file()

# ===================================================================

function(nx_format_clang)
	nx_guard_function(nx_format_clang)
	nx_function_begin()

	find_program(CLANG_FORMAT_EXECUTABLE NAMES "clang-format")

	set(bCanFormat ON)
	set(bDefaultFormat OFF)

	unset(sFormatRules)

	unset(sAll)
	unset(lsSourceFiles)
	foreach(sSourceFile ${ARGN})
		if(sSourceFile STREQUAL "ALL")
			set(sAll "ALL")
		else()
			list(APPEND lsSourceFiles "${sSourceFile}")
		endif()
	endforeach()

	if(NOT DEFINED lsSourceFiles AND DEFINED ${NX_PROJECT_NAME}_FILES_SOURCE)
		list(APPEND lsSourceFiles ${${NX_PROJECT_NAME}_FILES_SOURCE})
	endif()
	if(NOT DEFINED lsSourceFiles)
		set(bCanFormat OFF)
	endif()

	if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.clang-format")
		set(sFormatRules "${CMAKE_CURRENT_SOURCE_DIR}/.clang-format")
		set(bDefaultFormat ON)
	elseif(EXISTS "${CMAKE_SOURCE_DIR}/.clang-format")
		set(sFormatRules "${CMAKE_SOURCE_DIR}/.clang-format")
		set(bDefaultFormat ON)
	endif()
	if(${NX_PROJECT_NAME}_IS_EXTERNAL)
		set(bDefaultFormat OFF)
	endif()

	nx_dependent_option(ENABLE_FORMAT_CLANG_ALL "Enable Clang-Format" ON "CLANG_FORMAT_EXECUTABLE" OFF)
	nx_dependent_option(ENABLE_FORMAT_CLANG${NX_PROJECT_NAME} "Enable Clang-Format - ${PROJECT_NAME}" ${bDefaultFormat}
						"ENABLE_FORMAT_CLANG_ALL; bCanFormat" OFF)

	if(ENABLE_FORMAT_CLANG${NX_PROJECT_NAME})
		list(REMOVE_DUPLICATES lsSourceFiles)
		if(DEFINED sFormatRules AND NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/.clang-format")
			file(COPY "${sFormatRules}" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
		endif()
		add_custom_target(
			clang-format${NX_PROJECT_NAME}
			${sAll}
			COMMAND "${CLANG_FORMAT_EXECUTABLE}" -fallback-style=none -style=file -i ${lsSourceFiles}
			DEPENDS ${lsSourceFiles} ${sFormatRules}
			WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
			COMMENT "[clang-format] Formatting '${PROJECT_NAME}' Source Files"
			VERBATIM)
		if(NOT TARGET format)
			add_custom_target(format)
		endif()
		add_dependencies(format clang-format${NX_PROJECT_NAME})
	endif()

	nx_function_end()
endfunction()

# ===================================================================

function(nx_format_cmake)
	nx_guard_function(nx_format_cmake)
	nx_function_begin()

	find_program(CMAKE_FORMAT_EXECUTABLE NAMES "cmake-format")

	set(bCanFormat ON)
	set(bDefaultFormat OFF)

	unset(sFormatRules)

	unset(sAll)
	unset(lsSourceFiles)
	foreach(sSourceFile ${ARGN})
		if(sSourceFile STREQUAL "ALL")
			set(sAll "ALL")
		else()
			list(APPEND lsSourceFiles "${sSourceFile}")
		endif()
	endforeach()

	if(NOT DEFINED lsSourceFiles)
		file(
			GLOB lsSourceFiles
			LIST_DIRECTORIES false
			"cmake/*.cmake" "tools/*.cmake")
	endif()

	if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt")
		list(APPEND lsSourceFiles "${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt")
	endif()
	if(NOT DEFINED lsSourceFiles)
		set(bCanFormat OFF)
	endif()

	if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.cmake-format")
		set(sFormatRules "${CMAKE_CURRENT_SOURCE_DIR}/.cmake-format")
		set(bDefaultFormat ON)
	elseif(EXISTS "${CMAKE_SOURCE_DIR}/.cmake-format")
		set(sFormatRules "${CMAKE_SOURCE_DIR}/.cmake-format")
		set(bDefaultFormat ON)
	elseif(DEFINED nxbuild_SOURCE_DIR AND EXISTS "${nxbuild_SOURCE_DIR}/.cmake-format")
		set(sFormatRules "${nxbuild_SOURCE_DIR}/.cmake-format")
		set(bDefaultFormat ON)
	endif()
	if(${NX_PROJECT_NAME}_IS_EXTERNAL)
		set(bDefaultFormat OFF)
	endif()

	nx_dependent_option(ENABLE_FORMAT_CMAKE_ALL "Enable CMake-Format" ON "CMAKE_FORMAT_EXECUTABLE" OFF)
	nx_dependent_option(ENABLE_FORMAT_CMAKE${NX_PROJECT_NAME} "Enable CMake-Format - ${PROJECT_NAME}" ${bDefaultFormat}
						"ENABLE_FORMAT_CMAKE_ALL; bCanFormat" OFF)

	if(ENABLE_FORMAT_CMAKE${NX_PROJECT_NAME})
		list(REMOVE_DUPLICATES lsSourceFiles)
		if(DEFINED sFormatRules)
			add_custom_target(
				cmake-format${NX_PROJECT_NAME}
				${sAll}
				COMMAND "${CMAKE_FORMAT_EXECUTABLE}" --config "${sFormatRules}" -i ${lsSourceFiles}
				DEPENDS ${lsSourceFiles} ${sFormatRules}
				WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
				COMMENT "[cmake-format] Formatting '${PROJECT_NAME}' CMake Files"
				VERBATIM)
		else()
			add_custom_target(
				cmake-format${NX_PROJECT_NAME}
				${sAll}
				COMMAND "${CMAKE_FORMAT_EXECUTABLE}" -i ${lsSourceFiles}
				DEPENDS ${lsSourceFiles} ${sFormatRules}
				WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
				COMMENT "[cmake-format] Formatting '${PROJECT_NAME}' CMake Files"
				VERBATIM)
		endif()
		if(NOT TARGET format)
			add_custom_target(format)
		endif()
		add_dependencies(format cmake-format${NX_PROJECT_NAME})
	endif()

	nx_function_end()
endfunction()

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

include(NXTarget)

if(NOT DEFINED CMAKE_CROSSCOMPILING_EMULATOR
	AND NX_TARGET_PLATFORM_WINDOWS
	AND NOT NX_TARGET_PLATFORM_NATIVE)
	if(NX_TARGET_ARCHITECTURE_AMD64 OR NX_TARGET_ARCHITECTURE_IA32)
		find_program(CMAKE_CROSSCOMPILING_EMULATOR NAMES "wine64" "wine")
		if(NOT CMAKE_CROSSCOMPILING_EMULATOR)
			unset(CMAKE_CROSSCOMPILING_EMULATOR)
		endif()
	endif()
endif()

if(NX_TARGET_ARCHITECTURE_NATIVE AND NX_TARGET_PLATFORM_NATIVE)
	option(BUILD_TESTING "Build Test Suites" ON)
elseif(DEFINED CMAKE_CROSSCOMPILING_EMULATOR)
	option(BUILD_TESTING "Build Test Suites" ON)
else()
	option(BUILD_TESTING "Build Test Suites" OFF)
endif()

include(CTest)

_nx_guard_file()

# ===================================================================

function(nx_test vTargetList sTargetName)
	_nx_function_begin()

	# PARSER START ====

	_nx_parser_initialize()

	_nx_parser_initialize()

	set(lsKeywordToggle "NO_LTO" "NO_SECURE" "USE_ASAN" "USE_MSAN" "USE_TSAN" "USE_UBSAN")
	set(lsKeywordSingle "WORKING_DIRECTORY")
	set(lsKeywordMultiple
		"CMDSET"
		"ENVIRONMENT"
		"CFLAGS"
		"CXXFLAGS"
		"DEFINES"
		"DEPENDS"
		"FEATURES"
		"INCLUDES"
		"LDFLAGS"
		"SOURCES")

	set(sParseMode "SOURCES")

	_nx_parser_clear()
	_nx_parser_run(${ARGN})

	# ==== PARSER END

	if(NOT DEFINED bArgUSE_ASAN)
		set(bArgUSE_ASAN OFF)
	endif()
	if(NOT DEFINED bArgUSE_MSAN)
		set(bArgUSE_MSAN OFF)
	endif()
	if(NOT DEFINED bArgUSE_TSAN)
		set(bArgUSE_TSAN OFF)
	endif()
	if(NOT DEFINED bArgUSE_UBSAN)
		set(bArgUSE_UBSAN OFF)
	endif()

	if(NOT DEFINED bArgNO_LTO)
		set(bArgNO_LTO OFF)
	endif()
	if(NOT DEFINED bArgNO_SECURE)
		set(bArgNO_SECURE OFF)
	endif()

	unset(sNO_LTO)
	unset(sNO_SECURE)

	if(bArgNO_LTO)
		set(sNO_LTO "NO_LTO")
	endif()
	if(bArgNO_SECURE)
		set(sNO_SECURE "NO_SECURE")
	endif()

	if(NOT DEFINED sArgWORKING_DIRECTORY)
		set(sArgWORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")
	endif()

	set(bDefaultTest OFF)
	if(NOT DEFINED ${NX_PROJECT_NAME}_IS_EXTERNAL OR NOT ${NX_PROJECT_NAME}_IS_EXTERNAL)
		set(bDefaultTest ON)
	endif()

	cmake_dependent_option(BUILD_TESTS${NX_PROJECT_NAME} "Build Tests - ${PROJECT_NAME}" ${bDefaultTest} "BUILD_TESTING" OFF)

	if(BUILD_TESTS${NX_PROJECT_NAME})
		unset(lsTargetTest)
		if(bArgUSE_ASAN)
			nx_target(
				lsTargetTest "asan-${sTargetName}" ${sNO_LTO} ${sNO_SECURE} NO_INSTALL USE_ASAN
				CFLAGS ${lsArgCFLAGS}
				CXXFLAGS ${lsArgCXXFLAGS}
				DEFINES ${lsArgDEFINES}
				DEPENDS ${lsArgDEPENDS}
				FEATURES ${lsArgFEATURES}
				INCLUDES ${lsArgINCLUDES}
				LDFLAGS ${lsArgLDFLAGS}
				SOURCES ${lsArgSOURCES})
		endif()
		if(bArgUSE_MSAN)
			nx_target(
				lsTargetTest "msan-${sTargetName}" ${sNO_LTO} ${sNO_SECURE} NO_INSTALL USE_MSAN
				CFLAGS ${lsArgCFLAGS}
				CXXFLAGS ${lsArgCXXFLAGS}
				DEFINES ${lsArgDEFINES}
				DEPENDS ${lsArgDEPENDS}
				FEATURES ${lsArgFEATURES}
				INCLUDES ${lsArgINCLUDES}
				LDFLAGS ${lsArgLDFLAGS}
				SOURCES ${lsArgSOURCES})
		endif()
		if(bArgUSE_TSAN)
			nx_target(
				lsTargetTest "tsan-${sTargetName}" ${sNO_LTO} ${sNO_SECURE} NO_INSTALL USE_TSAN
				CFLAGS ${lsArgCFLAGS}
				CXXFLAGS ${lsArgCXXFLAGS}
				DEFINES ${lsArgDEFINES}
				DEPENDS ${lsArgDEPENDS}
				FEATURES ${lsArgFEATURES}
				INCLUDES ${lsArgINCLUDES}
				LDFLAGS ${lsArgLDFLAGS}
				SOURCES ${lsArgSOURCES})
		endif()
		if(bArgUSE_UBSAN)
			nx_target(
				lsTargetTest "ubsan-${sTargetName}" ${sNO_LTO} ${sNO_SECURE} NO_INSTALL USE_UBSAN
				CFLAGS ${lsArgCFLAGS}
				CXXFLAGS ${lsArgCXXFLAGS}
				DEFINES ${lsArgDEFINES}
				DEPENDS ${lsArgDEPENDS}
				FEATURES ${lsArgFEATURES}
				INCLUDES ${lsArgINCLUDES}
				LDFLAGS ${lsArgLDFLAGS}
				SOURCES ${lsArgSOURCES})
		endif()
		nx_target(
			lsTargetTest "test-${sTargetName}" ${sNO_LTO} ${sNO_SECURE} NO_INSTALL
			CFLAGS ${lsArgCFLAGS}
			CXXFLAGS ${lsArgCXXFLAGS}
			DEFINES ${lsArgDEFINES}
			DEPENDS ${lsArgDEPENDS}
			FEATURES ${lsArgFEATURES}
			INCLUDES ${lsArgINCLUDES}
			LDFLAGS ${lsArgLDFLAGS}
			SOURCES ${lsArgSOURCES})
		nx_append(${vTargetList} ${lsTargetTest})

		foreach(sTargetTest ${lsTargetTest})
			foreach(sTestArgs ${lsArgCMDSET})
				string(MAKE_C_IDENTIFIER "${sTestArgs}" sTestSuffix)
				string(REPLACE " " ";" lsTestArgs "${sTestArgs}")
				add_test(
					NAME "${sTargetTest}_${sTestSuffix}"
					WORKING_DIRECTORY "${sArgWORKING_DIRECTORY}"
					COMMAND ${CMAKE_CROSSCOMPILING_EMULATOR} $<TARGET_FILE:${sTargetTest}> ${lsTestArgs})
				if(DEFINED lsArgENVIRONMENT)
					set_tests_properties("${sTargetTest}_${sTestSuffix}" PROPERTIES ENVIRONMENT ${lsArgENVIRONMENT})
				endif()
			endforeach()
			if(NOT DEFINED lsArgCMDSET)
				add_test(
					NAME "${sTargetTest}"
					WORKING_DIRECTORY "${sArgWORKING_DIRECTORY}"
					COMMAND ${CMAKE_CROSSCOMPILING_EMULATOR} $<TARGET_FILE:${sTargetTest}>)
				if(DEFINED lsArgENVIRONMENT)
					set_tests_properties("${sTargetTest}" PROPERTIES ENVIRONMENT ${lsArgENVIRONMENT})
				endif()
			endif()
		endforeach()
		unset(vTargetTest)
	endif()

	_nx_function_end()
endfunction()

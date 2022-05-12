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

# cmake-lint: disable=C0111,C0301,R0912,R0915

include(CMakePackageConfigHelpers)
include(NXGenerate)
include(NXInstall)

set(CMAKE_SHARED_MODULE_PREFIX "")

if(NX_TARGET_PLATFORM_DARWIN)
	set(CMAKE_SHARED_MODULE_SUFFIX ".bundle")
endif()

if("x${CMAKE_STATIC_LIBRARY_SUFFIX}" STREQUAL "x${CMAKE_IMPORT_LIBRARY_SUFFIX}")
	set(CMAKE_IMPORT_LIBRARY_SUFFIX "${CMAKE_SHARED_LIBRARY_SUFFIX}${CMAKE_STATIC_LIBRARY_SUFFIX}")
endif()

if(DEFINED TARGET_SUPPORTS_SHARED_LIBS
	AND NX_TARGET_PLATFORM_ANDROID
	OR NX_TARGET_PLATFORM_MSDOS)
	cmake_dependent_option(BUILD_SHARED_LIBS "Build Shared Libs" OFF "TARGET_SUPPORTS_SHARED_LIBS" OFF)
elseif(DEFINED TARGET_SUPPORTS_SHARED_LIBS)
	cmake_dependent_option(BUILD_SHARED_LIBS "Build Shared Libs" ON "TARGET_SUPPORTS_SHARED_LIBS" OFF)
elseif(NX_TARGET_PLATFORM_ANDROID OR NX_TARGET_PLATFORM_MSDOS)
	option(BUILD_SHARED_LIBS "Build Shared Libs" OFF)
else()
	option(BUILD_SHARED_LIBS "Build Shared Libs" ON)
endif()

if(NX_TARGET_PLATFORM_MSDOS)
	set(CMAKE_POSITION_INDEPENDENT_CODE OFF)
else()
	set(CMAKE_POSITION_INDEPENDENT_CODE ON)
endif()

if(NX_TARGET_PLATFORM_WINDOWS)
	set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS OFF)
endif()

if(NOT NX_HOST_COMPILER_MSVC
	AND DEFINED CMAKE_AR
	AND DEFINED CMAKE_RANLIB)
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

	if(CMAKE_AR MATCHES "gcc-ar|llvm-ar" AND CMAKE_RANLIB MATCHES "gcc-ranlib|llvm-ranlib")
		if(NX_HOST_LANGUAGE_C)
			nx_set(CMAKE_C_ARCHIVE_CREATE "<CMAKE_AR> cr <TARGET> <LINK_FLAGS> <OBJECTS>")
			nx_set(CMAKE_C_ARCHIVE_APPEND "<CMAKE_AR> r <TARGET> <LINK_FLAGS> <OBJECTS>")
			nx_set(CMAKE_C_ARCHIVE_FINISH "<CMAKE_RANLIB> <TARGET>")
		endif()
		if(NX_HOST_LANGUAGE_CXX)
			nx_set(CMAKE_CXX_ARCHIVE_CREATE "<CMAKE_AR> cr <TARGET> <LINK_FLAGS> <OBJECTS>")
			nx_set(CMAKE_CXX_ARCHIVE_APPEND "<CMAKE_AR> r <TARGET> <LINK_FLAGS> <OBJECTS>")
			nx_set(CMAKE_CXX_ARCHIVE_FINISH "<CMAKE_RANLIB> <TARGET>")
		endif()
	endif()
endif()

_nx_guard_file()

# ===================================================================

include(CMakePushCheckState)
if(NX_HOST_LANGUAGE_C)
	include(CheckCSourceCompiles)
endif()
if(NX_HOST_LANGUAGE_CXX)
	include(CheckCXXSourceCompiles)
endif()

function(nx_check_compiles vOutput)
	_nx_function_begin()
	cmake_push_check_state()

	# PARSER START ====

	_nx_parser_initialize()

	set(lsKeywordSingle "LANGUAGE" "PROGRAM")
	set(lsKeywordMultiple "CFLAGS" "CXXFLAGS" "LDFLAGS" "LIBRARIES")

	set(sParseMode "CFLAGS")

	_nx_parser_clear()
	_nx_parser_run(${ARGN})

	# ==== PARSER END

	if(NOT DEFINED sArgLANGUAGE)
		if(NX_HOST_LANGUAGE_CXX)
			set(sArgLANGUAGE "CXX")
		elseif(NX_HOST_LANGUAGE_C)
			set(sArgLANGUAGE "C")
		else()
			set(sArgLANGUAGE "NONE")
		endif()
	endif()

	if(NOT DEFINED sArgPROGRAM)
		if(sArgLANGUAGE STREQUAL "CXX")
			set(sArgPROGRAM
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
		elseif(sArgLANGUAGE STREQUAL "C")
			set(sArgPROGRAM
				[[
#include <stdio.h>

int main(int argc, char *argv[])
{
	const char *hello = "Hello World";
	printf("%s!", hello);
	return 0;
}
				]])
		endif()
	endif()

	if(DEFINED lsArgCFLAGS)
		list(APPEND CMAKE_REQUIRED_DEFINITIONS ${lsArgCFLAGS} ${lsArgCXXFLAGS})
	endif()
	if(DEFINED lsArgLDFLAGS)
		list(APPEND CMAKE_REQUIRED_LINK_OPTIONS ${lsArgLDFLAGS})
	endif()
	if(DEFINED lsArgLIBRARIES)
		list(APPEND CMAKE_REQUIRED_LIBRARIES ${lsArgLIBRARIES})
	endif()
	set(CMAKE_REQUIRED_QUIET OFF)

	set(lsFailureChecks
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

	if(sArgLANGUAGE STREQUAL "CXX" AND NX_HOST_LANGUAGE_CXX)
		check_cxx_source_compiles("${sArgPROGRAM}" ${vOutput} ${lsFailureChecks})
	elseif(sArgLANGUAGE STREQUAL "C" AND NX_HOST_LANGUAGE_C)
		check_c_source_compiles("${sArgPROGRAM}" ${vOutput} ${lsFailureChecks})
	else()
		nx_set(${vOutput} OFF)
	endif()

	cmake_pop_check_state()
	_nx_function_end()
endfunction()

# ===================================================================

function(nx_default_flags)
	_nx_function_begin()

	set(bFormatMachO OFF)
	set(bFormatWinPE OFF)
	set(bFormatDJCOFF OFF)
	set(bFormatELF OFF)

	if(NX_TARGET_PLATFORM_DARWIN)
		set(bFormatMachO ON)
	elseif(NX_TARGET_PLATFORM_MSDOS)
		set(bFormatDJCOFF ON)
	elseif(NX_TARGET_PLATFORM_WINDOWS OR NX_TARGET_PLATFORM_CYGWIN)
		set(bFormatWinPE ON)
	else()
		set(bFormatELF ON)
	endif()

	unset(lsDiagnosticFLAGS)
	unset(lsDiagnosticCFLAGS)
	unset(lsDiagnosticCXXFLAGS)

	unset(lsThinCFLAGS)
	unset(lsThinLDFLAGS)
	unset(lsFatCFLAGS)
	unset(lsFatLDFLAGS)

	unset(lsHardenCFLAGS)
	unset(lsHardenLDFLAGS)

	unset(lsHardenCFI_CFLAGS)
	unset(lsHardenCFI_LDFLAGS)
	unset(lsHardenSSP_CFLAGS)
	unset(lsHardenSSP_LDFLAGS)

	unset(lsHardenASLR_LDFLAGS)
	unset(lsHardenDEP_LDFLAGS)
	unset(lsHardenGOT_LDFLAGS)
	unset(lsHardenSEH_LDFLAGS)

	unset(lsUnresolvedLDFLAGS)

	unset(lsSanitize_Address)
	unset(lsSanitize_CFI)
	unset(lsSanitize_Memory)
	unset(lsSanitize_SafeStack)
	unset(lsSanitize_Thread)
	unset(lsSanitize_Undefined)

	if(NX_HOST_COMPILER_MSVC)
		list(APPEND lsDiagnosticFLAGS "-W4")
		list(APPEND lsThinCFLAGS "-GL")
		list(APPEND lsThinLDFLAGS "-LTCG" "-INCREMENTAL:NO")

		list(APPEND lsHardenASLR_LDFLAGS "-DYNAMICBASE")
		list(APPEND lsHardenSSP_CFLAGS "-GS" "-sdl")

		if(NX_TARGET_ARCHITECTURE_IA32)
			list(APPEND lsHardenSEH_LDFLAGS "-SAFESEH")
		elseif(NX_TARGET_ARCHITECTURE_AMD64)
			list(APPEND lsHardenASLR_LDFLAGS "-HIGHENTROPYVA")
		endif()

		if(MSVC_VER GREATER_EQUAL 1910)
			list(APPEND lsHardenCFI_CFLAGS "-guard:cf")
			list(APPEND lsHardenCFI_LDFLAGS "-GUARD:CF")
		endif()

		if(MSVC_VER GREATER_EQUAL 1927)
			if(NX_TARGET_ARCHITECTURE_AMD64 OR NX_TARGET_ARCHITECTURE_ARM64)
				list(APPEND lsHardenCFI_CFLAGS "-guard:ehcont")
				list(APPEND lsHardenCFI_LDFLAGS "-GUARD:EHCONT")
			endif()
			if(NX_TARGET_ARCHITECTURE_AMD64 OR NX_TARGET_ARCHITECTURE_IA32)
				list(APPEND lsHardenCFI_LDFLAGS "-CETCOMPAT")
			endif()
		endif()
	elseif(NX_HOST_COMPILER_CLANG)
		list(
			APPEND
			lsDiagnosticFLAGS
			"-Wall"
			"-Wextra"
			"-Wpedantic"
			"-Wconversion"
			"-Wfloat-equal"
			"-Wformat=2"
			"-Werror=format-security"
			"-Wshadow"
			"-Wthread-safety")
		list(APPEND lsDiagnosticCFLAGS "-Wc++-compat")
		list(APPEND lsDiagnosticCXXFLAGS "-Wnon-virtual-dtor")

		list(APPEND lsFatCFLAGS "-flto=full")
		list(APPEND lsFatLDFLAGS "-flto=full")
		list(APPEND lsThinCFLAGS "-flto=thin")
		list(APPEND lsThinLDFLAGS "-flto=thin")

		list(APPEND lsHardenSSP_CFLAGS "-fstack-protector-strong")
		list(APPEND lsHardenSSP_LDFLAGS "-fstack-protector-strong")

		if(NOT NX_HOST_COMPILER_GNU_VERSION VERSION_LESS 7)
			list(APPEND lsHardenSSP_CFLAGS "-fcf-protection")
			list(APPEND lsHardenSSP_LDFLAGS "-fcf-protection")
		endif()

		if(NOT NX_HOST_COMPILER_GNU_VERSION VERSION_LESS 11)
			if(NOT NX_TARGET_PLATFORM_WINDOWS)
				list(APPEND lsHardenSSP_CFLAGS "-fstack-clash-protection")
				list(APPEND lsHardenSSP_LDFLAGS "-fstack-clash-protection")
			endif()
		endif()

		list(APPEND lsSanitize_Address "-fsanitize=address")
		list(APPEND lsSanitize_CFI "-fsanitize=cfi" "-fsanitize-cfi-cross-dso" "-fvisibility=hidden")
		list(APPEND lsSanitize_Memory "-fsanitize=memory")
		list(APPEND lsSanitize_SafeStack "-fsanitize=safe-stack")
		list(APPEND lsSanitize_Thread "-fsanitize=thread")
		list(APPEND lsSanitize_Undefined "-fsanitize=undefined" "-fsanitize=integer" "-fsanitize=nullability")
	elseif(NX_HOST_COMPILER_GNU)
		list(
			APPEND
			lsDiagnosticFLAGS
			"-Wall"
			"-pedantic"
			"-Wconversion"
			"-Wformat"
			"-Wshadow")
		list(APPEND lsDiagnosticCXXFLAGS "-Wnon-virtual-dtor")

		if(NOT NX_HOST_COMPILER_GNU_VERSION VERSION_LESS 3.0)
			list(APPEND lsDiagnosticFLAGS "-Wfloat-equal")
			string(REPLACE ";-Wformat;" ";-Wformat=2;" lsDiagnosticFLAGS "${lsDiagnosticFLAGS}")
		endif()

		if(NOT NX_HOST_COMPILER_GNU_VERSION VERSION_LESS 3.4)
			string(REPLACE "-Wall;" "-Wall;-Wextra;" lsDiagnosticFLAGS "${lsDiagnosticFLAGS}")
		endif()

		if(NOT NX_HOST_COMPILER_GNU_VERSION VERSION_LESS 4.1)
			list(APPEND lsDiagnosticCFLAGS "-Wc++-compat")

			list(APPEND lsHardenSSP_CFLAGS "-fstack-protector" "--param=ssp-buffer-size=4")
			list(APPEND lsHardenSSP_LDFLAGS "-fstack-protector")
		endif()

		if(NOT NX_HOST_COMPILER_GNU_VERSION VERSION_LESS 4.2)
			string(REPLACE ";-Wformat=2;" ";-Wformat=2;-Werror=format-security;" lsDiagnosticFLAGS "${lsDiagnosticFLAGS}")
		endif()

		if(NOT NX_HOST_COMPILER_GNU_VERSION VERSION_LESS 4.5)
			list(APPEND lsFatCFLAGS "-flto")
			list(APPEND lsFatLDFLAGS "-O2" "-flto" "-fuse-linker-plugin")
		endif()

		if(NOT NX_HOST_COMPILER_GNU_VERSION VERSION_LESS 4.8)
			string(REPLACE ";-pedantic;" ";-Wpedantic;" lsDiagnosticFLAGS "${lsDiagnosticFLAGS}")

			list(APPEND lsSanitize_Address "-fsanitize=address")
			list(APPEND lsSanitize_Thread "-fsanitize=thread")
		endif()

		if(NOT NX_HOST_COMPILER_GNU_VERSION VERSION_LESS 4.9)
			string(REPLACE "-fstack-protector;--param=ssp-buffer-size=4" "-fstack-protector-strong" lsHardenSSP_CFLAGS
							"${lsHardenSSP_CFLAGS}")
			string(REPLACE "-fstack-protector" "-fstack-protector-strong" lsHardenSSP_LDFLAGS "${lsHardenSSP_LDFLAGS}")

			list(APPEND lsSanitize_Undefined "-fsanitize=undefined")
		endif()

		if(NOT NX_HOST_COMPILER_GNU_VERSION VERSION_LESS 6)
			list(APPEND lsDiagnosticFLAGS "-Wduplicated-cond" "-Wnull-dereference")

			list(APPEND lsThinCFLAGS ${sFatCFLAGS} "-fno-fat-lto-objects")
			list(APPEND lsThinLDFLAGS ${sFatLDFLAGS})
			list(APPEND lsFatCFLAGS "-ffat-lto-objects")

			if(NOT NX_TARGET_PLATFORM_WINDOWS)
				list(APPEND lsHardenSSP_CFLAGS "-fstack-check")
				list(APPEND lsHardenSSP_LDFLAGS "-fstack-check")
			endif()
		endif()

		if(NOT NX_HOST_COMPILER_GNU_VERSION VERSION_LESS 8)
			list(APPEND lsHardenSSP_CFLAGS "-fcf-protection")
			list(APPEND lsHardenSSP_LDFLAGS "-fcf-protection")
			if(NOT NX_TARGET_PLATFORM_WINDOWS)
				string(REPLACE "-fstack-check" "-fstack-clash-protection" lsHardenSSP_CFLAGS "${lsHardenSSP_CFLAGS}")
				string(REPLACE "-fstack-check" "-fstack-clash-protection" lsHardenSSP_LDFLAGS "${lsHardenSSP_LDFLAGS}")
			endif()

			list(APPEND lsSanitize_Address "-fsanitize=pointer-compare" "-fsanitize=pointer-subtract")
		endif()
	endif()

	if(NOT NX_HOST_COMPILER_MSVC)
		list(APPEND lsUnresolvedLDFLAGS "LINKER:--no-undefined")

		if(bFormatWinPE)
			list(APPEND lsHardenASLR_LDFLAGS "LINKER:--dynamicbase")
			list(APPEND lsHardenDEP_LDFLAGS "LINKER:--nxcompat")

			if(NX_TARGET_ARCHITECTURE_IA32)
				list(APPEND lsHardenSEH_LDFLAGS "LINKER:--no-seh")
			elseif(NX_TARGET_ARCHITECTURE_AMD64)
				list(APPEND lsHardenASLR_LDFLAGS "LINKER:--high-entropy-va")
			endif()
		elseif(NOT bFormatDJCOFF)
			list(APPEND lsHardenASLR_LDFLAGS "LINKER:-z,text")
			list(APPEND lsHardenDEP_LDFLAGS "LINKER:-z,noexecstack")
			list(APPEND lsHardenGOT_LDFLAGS "LINKER:-z,now" "LINKER:-z,relro")

			list(APPEND lsUnresolvedLDFLAGS "LINKER:--as-needed" "LINKER:-z,defs")
		endif()
	endif()

	nx_check_compiles(SUPPORTS_COMPILATION)
	if(SUPPORTS_COMPILATION)

		# -- Check Diagnostics --

		if(DEFINED lsDiagnosticFLAGS)
			nx_check_compiles(SUPPORTS_DIAGNOSTIC_FLAGS CFLAGS ${lsDiagnosticFLAGS})
			if(NOT SUPPORTS_DIAGNOSTIC_FLAGS)
				unset(lsDiagnosticFLAGS)
			endif()
		endif()

		if(DEFINED lsDiagnosticCFLAGS AND NX_HOST_LANGUAGE_C)
			nx_check_compiles(
				SUPPORTS_DIAGNOSTIC_FLAGS_C
				LANGUAGE C
				CFLAGS ${lsDiagnosticFLAGS} ${lsDiagnosticCFLAGS})
			if(NOT SUPPORTS_DIAGNOSTIC_FLAGS_C)
				unset(lsDiagnosticCFLAGS)
			endif()
		endif()

		if(DEFINED lsDiagnosticCXXFLAGS AND NX_HOST_LANGUAGE_CXX)
			nx_check_compiles(
				SUPPORTS_DIAGNOSTIC_FLAGS_CXX
				LANGUAGE CXX
				CFLAGS ${lsDiagnosticFLAGS} ${lsDiagnosticCXXFLAGS})
			if(NOT SUPPORTS_DIAGNOSTIC_FLAGS_CXX)
				unset(lsDiagnosticCXXFLAGS)
			endif()
		endif()

		if(NX_HOST_LANGUAGE_C)
			foreach(sFlag ${lsDiagnosticCFLAGS})
				list(APPEND lsDiagnosticFLAGS "$<$<COMPILE_LANGUAGE:C>:${sFlag}>")
			endforeach()
		endif()
		if(NX_HOST_LANGUAGE_CXX)
			foreach(sFlag ${lsDiagnosticCXXFLAGS})
				list(APPEND lsDiagnosticFLAGS "$<$<COMPILE_LANGUAGE:CXX>:${sFlag}>")
			endforeach()
		endif()

		# -- Check Hardening --

		if(DEFINED lsHardenASLR_LDFLAGS)
			nx_check_compiles(SUPPORTS_HARDEN_ASLR_FLAGS LDFLAGS ${lsHardenASLR_LDFLAGS})
			if(NOT SUPPORTS_HARDEN_ASLR_FLAGS)
				unset(lsHardenASLR_LDFLAGS)
			endif()
			list(APPEND lsHardenLDFLAGS ${lsHardenASLR_LDFLAGS})
		endif()
		if(DEFINED lsHardenDEP_LDFLAGS)
			nx_check_compiles(SUPPORTS_HARDEN_DEP_FLAGS LDFLAGS ${lsHardenDEP_LDFLAGS})
			if(NOT SUPPORTS_HARDEN_DEP_FLAGS)
				unset(lsHardenDEP_LDFLAGS)
			endif()
			list(APPEND lsHardenLDFLAGS ${lsHardenDEP_LDFLAGS})
		endif()
		if(DEFINED lsHardenGOT_LDFLAGS)
			nx_check_compiles(SUPPORTS_HARDEN_GOT_FLAGS LDFLAGS ${lsHardenGOT_LDFLAGS})
			if(NOT SUPPORTS_HARDEN_GOT_FLAGS)
				unset(lsHardenGOT_LDFLAGS)
			endif()
			list(APPEND lsHardenLDFLAGS ${lsHardenGOT_LDFLAGS})
		endif()
		if(DEFINED lsHardenSEH_LDFLAGS)
			nx_check_compiles(SUPPORTS_HARDEN_SEH_FLAGS LDFLAGS ${lsHardenSEH_LDFLAGS})
			if(NOT SUPPORTS_HARDEN_SEH_FLAGS)
				unset(lsHardenSEH_LDFLAGS)
			endif()
			list(APPEND lsHardenLDFLAGS ${lsHardenSEH_LDFLAGS})
		endif()

		if(DEFINED lsHardenCFI_CFLAGS OR DEFINED lsHardenCFI_LDFLAGS)
			nx_check_compiles(
				SUPPORTS_HARDEN_CFI_FLAGS
				CFLAGS ${lsHardenCFI_CFLAGS}
				LDFLAGS ${lsHardenASLR_LDFLAGS} ${lsHardenCFI_LDFLAGS})
			if(NOT SUPPORTS_HARDEN_CFI_FLAGS)
				unset(lsHardenCFI_CFLAGS)
				unset(lsHardenCFI_LDFLAGS)
			endif()
			list(APPEND lsHardenCFLAGS ${lsHardenCFI_CFLAGS})
			list(APPEND lsHardenLDFLAGS ${lsHardenCFI_LDFLAGS})
		endif()

		if(DEFINED lsHardenSSP_CFLAGS OR DEFINED lsHardenSSP_LDFLAGS)
			nx_check_compiles(
				SUPPORTS_HARDEN_SSP_FLAGS
				CFLAGS ${lsHardenSSP_CFLAGS}
				LDFLAGS ${lsHardenSSP_LDFLAGS})
			if(NOT SUPPORTS_HARDEN_SSP_FLAGS)
				unset(lsHardenSSP_CFLAGS)
				unset(lsHardenSSP_LDFLAGS)
			endif()
			list(APPEND lsHardenCFLAGS ${lsHardenSSP_CFLAGS})
			list(APPEND lsHardenLDFLAGS ${lsHardenSSP_LDFLAGS})
		endif()

		# -- Check LTO --

		if(DEFINED lsFatCFLAGS)
			nx_check_compiles(
				SUPPORTS_LTO_FULL
				CFLAGS ${lsFatCFLAGS}
				LDFLAGS ${lsFatLDFLAGS})
			if(NOT SUPPORTS_LTO_FULL)
				unset(lsFatCFLAGS)
				unset(lsFatLDFLAGS)
			endif()
		endif()

		if(DEFINED lsThinCFLAGS)
			nx_check_compiles(
				SUPPORTS_LTO_THIN
				CFLAGS ${lsThinCFLAGS}
				LDFLAGS ${lsThinLDFLAGS})
			if(NOT SUPPORTS_LTO_THIN)
				unset(lsThinCFLAGS)
				unset(lsThinLDFLAGS)
			endif()
		endif()
	endif()

	if(DEFINED lsFatCFLAGS AND NOT DEFINED lsThinCFLAGS)
		set(lsThinCFLAGS ${lsFatCFLAGS})
		set(lsThinLDFLAGS ${lsFatLDFLAGS})
	endif()

	# -- Check Other Linker Flags --

	if(DEFINED lsUnresolvedLDFLAGS)
		nx_check_compiles(SUPPORTS_EXTRALINK_FLAGS LDFLAGS ${lsUnresolvedLDFLAGS})
		if(NOT SUPPORTS_EXTRALINK_FLAGS)
			unset(lsUnresolvedLDFLAGS)
		endif()
	endif()

	# -- Check Sanitizers --

	if(NX_TARGET_PLATFORM_WINDOWS OR NX_TARGET_PLATFORM_CYGWIN)
		# c++: error: unsupported option '-fsanitize=memory' for target 'i686-w64-windows-gnu'
		unset(lsSanitize_Memory)
		# c++: error: unsupported option '-fsanitize=safe-stack' for target 'i686-w64-windows-gnu'
		unset(lsSanitize_SafeStack)
		# c++: error: unsupported option '-fsanitize=thread' for target 'i686-w64-windows-gnu'
		unset(lsSanitize_Thread)
	endif()

	if(DEFINED lsSanitize_Address)
		nx_check_compiles(
			SUPPORTS_SANITIZER_ADDRESS
			CFLAGS ${lsSanitize_Address}
			LDFLAGS ${lsSanitize_Address})
		if(NOT SUPPORTS_SANITIZER_ADDRESS)
			unset(lsSanitize_Address)
		endif()
	endif()

	if(DEFINED lsSanitize_CFI)
		nx_check_compiles(
			SUPPORTS_SANITIZER_CFI
			CFLAGS ${lsThinCFLAGS} ${lsSanitize_CFI}
			LDFLAGS ${lsThinLDFLAGS} ${lsSanitize_CFI})
		if(NOT SUPPORTS_SANITIZER_CFI)
			unset(lsSanitize_CFI)
		endif()
	endif()

	if(DEFINED lsSanitize_Memory)
		nx_check_compiles(
			SUPPORTS_SANITIZER_MEMORY
			CFLAGS ${lsSanitize_Memory}
			LDFLAGS ${lsSanitize_Memory})
		if(NOT SUPPORTS_SANITIZER_MEMORY)
			unset(lsSanitize_Memory)
		endif()
	endif()

	if(DEFINED lsSanitize_SafeStack)
		nx_check_compiles(
			SUPPORTS_SANITIZER_SAFESTACK
			CFLAGS ${lsSanitize_SafeStack}
			LDFLAGS ${lsSanitize_SafeStack})
		if(NOT SUPPORTS_SANITIZER_SAFESTACK)
			unset(lsSanitize_SafeStack)
		endif()
	endif()

	if(DEFINED lsSanitize_Thread)
		nx_check_compiles(
			SUPPORTS_SANITIZER_THREAD
			CFLAGS ${lsSanitize_Thread}
			LDFLAGS ${lsSanitize_Thread})
		if(NOT SUPPORTS_SANITIZER_THREAD)
			unset(lsSanitize_Thread)
		endif()
	endif()

	if(DEFINED lsSanitize_Undefined)
		nx_check_compiles(
			SUPPORTS_SANITIZER_UNDEFINED
			CFLAGS ${lsSanitize_Undefined}
			LDFLAGS ${lsSanitize_Undefined})
		if(NOT SUPPORTS_SANITIZER_UNDEFINED)
			unset(lsSanitize_Undefined)
		endif()
	endif()

	# -- Set Flag Variables --

	if(NX_HOST_COMPILER_MSVC)
		nx_set(NX_DEFAULT_DEFINES_GENERAL "_CRT_SECURE_NO_WARNINGS")
	elseif(SUPPORTS_HARDEN_SSP_FLAGS)
		nx_set(NX_DEFAULT_DEFINES_HARDEN "$<$<NOT:$<CONFIG:Debug>>:_FORTIFY_SOURCE=2>" "_GLIBCXX_ASSERTIONS")
	endif()

	# TODO: https://github.com/mstorsjo/llvm-mingw/issues/275
	if(DEFINED lsHardenCFLAGS
		AND lsHardenCFLAGS MATCHES "fstack-protector"
		AND NX_TARGET_PLATFORM_WINDOWS
		AND NX_HOST_COMPILER_CLANG)
		if(NX_TARGET_ARCHITECTURE_AMD64)
			list(APPEND lsHardenLDFLAGS "LINKER:--require-defined,__stack_chk_guard")
		elseif(NX_TARGET_ARCHITECTURE_IA32)
			list(APPEND lsHardenLDFLAGS "LINKER:--require-defined,___stack_chk_guard")
		endif()
	endif()

	nx_set(NX_DEFAULT_CFLAGS_DIAGNOSTIC ${lsDiagnosticFLAGS})
	nx_set(NX_DEFAULT_CFLAGS_HARDEN ${lsHardenCFLAGS})
	nx_set(NX_DEFAULT_LDFLAGS_HARDEN ${lsHardenLDFLAGS})
	nx_set(NX_DEFAULT_LDFLAGS_EXTRA ${lsUnresolvedLDFLAGS})

	nx_set(NX_DEFAULT_SANITIZER_CFI ${lsSanitize_CFI})
	nx_set(NX_DEFAULT_SANITIZER_SAFESTACK ${lsSanitize_SafeStack})

	nx_set(NX_DEFAULT_SANITIZER_ADDRESS ${lsSanitize_Address})
	nx_set(NX_DEFAULT_SANITIZER_UNDEFINED ${lsSanitize_Undefined})
	nx_set(NX_DEFAULT_SANITIZER_MEMORY ${lsSanitize_Memory})
	nx_set(NX_DEFAULT_SANITIZER_THREAD ${lsSanitize_Thread})

	if(NX_TARGET_BUILD_MULTI)
		foreach(sFlag ${lsFatCFLAGS})
			nx_append(APPEND NX_DEFAULT_CFLAGS_LTO_FULL "$<$<NOT:$<CONFIG:Debug>>:${sFlag}>")
		endforeach()
		foreach(sFlag ${lsFatLDFLAGS})
			nx_append(APPEND NX_DEFAULT_LDFLAGS_LTO_FULL "$<$<NOT:$<CONFIG:Debug>>:${sFlag}>")
		endforeach()
		foreach(sFlag ${lsThinCFLAGS})
			nx_append(APPEND NX_DEFAULT_CFLAGS_LTO_THIN "$<$<NOT:$<CONFIG:Debug>>:${sFlag}>")
		endforeach()
		foreach(sFlag ${lsThinLDFLAGS})
			nx_append(APPEND NX_DEFAULT_LDFLAGS_LTO_THIN "$<$<NOT:$<CONFIG:Debug>>:${sFlag}>")
		endforeach()
	elseif(NOT NX_TARGET_BUILD_DEBUG)
		if(DEFINED lsFatCFLAGS)
			nx_set(NX_DEFAULT_CFLAGS_LTO_FULL ${lsFatCFLAGS})
			nx_set(NX_DEFAULT_LDFLAGS_LTO_FULL ${lsFatLDFLAGS})
		endif()
		if(DEFINED lsThinCFLAGS)
			nx_set(NX_DEFAULT_CFLAGS_LTO_THIN ${lsThinCFLAGS})
			nx_set(NX_DEFAULT_LDFLAGS_LTO_THIN ${lsThinLDFLAGS})
		endif()
	endif()

	_nx_function_end()
endfunction()

# ===================================================================

function(nx_target_compile_definitions)
	_nx_function_begin()

	# PARSER START ====

	_nx_parser_initialize()

	set(lsKeywordSingle "DEFINE_SYMBOL" "STATIC_DEFINE")
	set(lsKeywordMultiple "TARGETS" "PRIVATE" "PUBLIC" "INTERFACE")

	set(sParseMode "TARGETS")

	_nx_parser_clear()
	_nx_parser_run(${ARGN})

	# ==== PARSER END

	foreach(sTarget ${lsArgTARGETS})
		get_target_property(sTargetType ${sTarget} TYPE)

		if(DEFINED sArgDEFINE_SYMBOL)
			if(sTargetType MATCHES "SHARED_LIBRARY|MODULE_LIBRARY")
				set_target_properties("${sTarget}" PROPERTIES DEFINE_SYMBOL "${sArgDEFINE_SYMBOL}")
			elseif(sTargetType MATCHES "STATIC_LIBRARY|OBJECT_LIBRARY")
				list(APPEND lsArgPRIVATE "${sArgDEFINE_SYMBOL}")
			endif()
		endif()
		if(DEFINED sArgSTATIC_DEFINE)
			if(sTargetType STREQUAL "INTERFACE_LIBRARY")
				list(APPEND lsArgINTERFACE "${sArgSTATIC_DEFINE}")
			elseif(sTargetType MATCHES "STATIC_LIBRARY|OBJECT_LIBRARY")
				list(APPEND lsArgPUBLIC "${sArgSTATIC_DEFINE}")
			endif()
		endif()

		foreach(sVisibility "PUBLIC" "PRIVATE" "INTERFACE")
			if(DEFINED lsArg${sVisibility})
				string(REPLACE ">:-D" ">:" lsArg${sVisibility} "${lsArg${sVisibility}}")
				target_compile_definitions("${sTarget}" ${sVisibility} ${lsArg${sVisibility}})
			endif()
		endforeach()
	endforeach()

	_nx_function_end()
endfunction()

# ===================================================================

function(nx_target_compile_features)
	_nx_function_begin()

	# PARSER START ====

	_nx_parser_initialize()

	set(lsKeywordMultiple "TARGETS" "PRIVATE" "PUBLIC" "INTERFACE")

	set(sParseMode "TARGETS")

	_nx_parser_clear()
	_nx_parser_run(${ARGN})

	# ==== PARSER END

	foreach(sVisibility "PUBLIC" "PRIVATE" "INTERFACE")
		unset(lsFeature${sVisibility})
		foreach(sFeature ${lsArg${sVisibility}})
			if("${sFeature}" IN_LIST CMAKE_C_COMPILE_FEATURES OR "${sFeature}" IN_LIST CMAKE_CXX_COMPILE_FEATURES)
				list(APPEND lsFeature${sVisibility} "${sFeature}")
			else()
				message(WARNING "nx_target_compile_features: Feature '${sFeature}' Not Found")
			endif()
		endforeach()
		foreach(sTarget ${lsArgTARGETS})
			if(DEFINED lsFeature${sVisibility})
				target_compile_features("${sTarget}" ${sVisibility} ${lsFeature${sVisibility}})
			endif()
		endforeach()
	endforeach()

	_nx_function_end()
endfunction()

# ===================================================================

function(nx_target_compile_options)
	_nx_function_begin()

	# PARSER START ====

	_nx_parser_initialize()

	set(lsKeywordMultiple "TARGETS" "PRIVATE" "PUBLIC" "INTERFACE")

	set(sParseMode "TARGETS")

	_nx_parser_clear()
	_nx_parser_run(${ARGN})

	# ==== PARSER END

	foreach(sTarget ${lsArgTARGETS})
		foreach(sVisibility "PUBLIC" "PRIVATE" "INTERFACE")
			if(DEFINED lsArg${sVisibility})
				target_compile_options("${sTarget}" ${sVisibility} ${lsArg${sVisibility}})
			endif()
		endforeach()
	endforeach()

	_nx_function_end()
endfunction()

# ===================================================================

function(nx_target_include_directories)
	_nx_function_begin()

	# PARSER START ====

	_nx_parser_initialize()

	set(lsKeywordToggle "NO_INSTALL")
	set(lsKeywordMultiple "TARGETS" "PRIVATE" "PUBLIC" "INTERFACE")

	set(sParseMode "TARGETS")

	_nx_parser_clear()
	_nx_parser_run(${ARGN})

	# ==== PARSER END

	if(NOT DEFINED bArgNO_INSTALL)
		set(bArgNO_INSTALL OFF)
	endif()

	foreach(sVisibility "PUBLIC" "PRIVATE" "INTERFACE")
		unset(lsInclude${sVisibility})
		unset(lsInternal${sVisibility})
		foreach(sInclude ${lsArg${sVisibility}})
			if(sInclude MATCHES "<[^>]+:")
				list(APPEND lsInclude${sVisibility} "${sInclude}")
			else()
				get_filename_component(sInclude "${sInclude}" ABSOLUTE)
				file(RELATIVE_PATH sRelBuild "${CMAKE_CURRENT_BINARY_DIR}" "${sInclude}")
				string(SUBSTRING "${sRelBuild}" 0 2 sDotDot)
				if(sDotDot STREQUAL ".." OR sDotDot MATCHES ":$")
					file(RELATIVE_PATH sRelSource "${CMAKE_CURRENT_SOURCE_DIR}" "${sInclude}")
					string(SUBSTRING "${sRelSource}" 0 2 sDotDot)
					if(sDotDot STREQUAL ".." OR sDotDot MATCHES ":$")
						list(APPEND lsInclude${sVisibility} "${sInclude}")
					else()
						list(APPEND lsInternal${sVisibility} "${CMAKE_CURRENT_SOURCE_DIR}/${sRelSource}"
								"${CMAKE_CURRENT_BINARY_DIR}/${sRelSource}")
					endif()
				else()
					list(APPEND lsInternal${sVisibility} "${CMAKE_CURRENT_BINARY_DIR}/${sRelBuild}")
				endif()
			endif()
		endforeach()
	endforeach()

	foreach(sVisibility "PUBLIC" "INTERFACE")
		if(DEFINED lsInternal${tmp_pmode} AND NOT bArgNO_INSTALL)
			nx_append(${NX_PROJECT_NAME}_DIRS_INCLUDE ${lsInternal${sVisibility}})
			list(APPEND lsInclude${sVisibility} "$<INSTALL_INTERFACE:${NX_INSTALL_PATH_INCLUDE}>")
		endif()
		foreach(sInclude ${lsInternal${sVisibility}})
			list(APPEND lsInclude${sVisibility} "$<BUILD_INTERFACE:${sInclude}>")
		endforeach()
	endforeach()
	list(APPEND lsIncludePRIVATE ${lsInternalPRIVATE})

	foreach(sTarget ${lsArgTARGETS})
		foreach(sVisibility "PUBLIC" "PRIVATE" "INTERFACE")
			if(DEFINED lsInclude${sVisibility})
				target_include_directories("${sTarget}" ${sVisibility} ${lsInclude${sVisibility}})
			endif()
		endforeach()
	endforeach()

	_nx_function_end()
endfunction()

# ===================================================================

function(nx_target_link_libraries)
	_nx_function_begin()

	# PARSER START ====

	_nx_parser_initialize()

	set(lsKeywordMultiple "TARGETS" "PRIVATE" "PUBLIC" "INTERFACE")

	set(sParseMode "TARGETS")

	_nx_parser_clear()
	_nx_parser_run(${ARGN})

	# ==== PARSER END

	unset(lsDependencies)
	foreach(sTarget ${lsArgPUBLIC} ${lsArgPRIVATE})
		if(TARGET "${sTarget}")
			get_target_property(sAliasTarget "${sTarget}" ALIASED_TARGET)
			if(sAliasTarget AND TARGET "${sAliasTarget}")
				set(sTarget "${sAliasTarget}")
			endif()
			list(APPEND lsDependencies "${sTarget}")
		endif()
	endforeach()

	# TODO: Is this still needed?
	unset(lsPrevDeps)
	while(NOT "x${lsDependencies}" STREQUAL "x${lsPrevDeps}")
		set(lsPrevDeps ${lsDependencies})
		foreach(sTarget ${lsPrevDeps})
			get_target_property(sTargetType "${sTarget}" TYPE)
			if(NOT sTargetType STREQUAL "INTERFACE_LIBRARY")
				get_target_property(lsLinkedLibs "${sTarget}" LINK_LIBRARIES)
				foreach(sLibrary ${lsLinkedLibs})
					if(TARGET "${sLibrary}")
						get_target_property(sAliasTarget "${sLibrary}" ALIASED_TARGET)
						if(sAliasTarget AND TARGET "${sAliasTarget}")
							set(sLibrary "${sAliasTarget}")
						endif()
						list(APPEND lsDependencies "${sLibrary}")
					endif()
				endforeach()
			endif()

			get_target_property(lsLinkedLibs "${sTarget}" INTERFACE_LINK_LIBRARIES)
			foreach(sLibrary ${lsLinkedLibs})
				if(TARGET "${sLibrary}")
					get_target_property(sAliasTarget "${sLibrary}" ALIASED_TARGET)
					if(sAliasTarget AND TARGET "${sAliasTarget}")
						set(sLibrary "${sAliasTarget}")
					endif()
					list(APPEND lsDependencies "${sLibrary}")
				endif()
			endforeach()
		endforeach()

		if(DEFINED lsDependencies)
			list(REMOVE_DUPLICATES lsDependencies)
		endif()
	endwhile()

	if(DEFINED lsDependencies)
		nx_append(${NX_PROJECT_NAME}_DEPENDENCIES "${lsDependencies}")
	endif()

	# TODO: Is this still needed?
	foreach(sTarget ${lsDependencies})
		get_target_property(sTargetType "${sTarget}" TYPE)
		if(sTargetType STREQUAL "SHARED_LIBRARY")
			get_target_property(bImported "${sTarget}" IMPORTED)
			if(bImported)
				get_target_property(sImportLibrary "${sTarget}" IMPORTED_LOCATION)
				if(sImportLibrary)
					nx_append(${NX_PROJECT_NAME}_SHLIBS "${sImportLibrary}")
					nx_append(${NX_PROJECT_NAME}_SHLIBS_NOCONFIG "${sImportLibrary}")
				endif()
				foreach(sBuildType "NOCONFIG" ${CMAKE_CONFIGURATION_TYPES} ${CMAKE_BUILD_TYPE})
					string(TOUPPER "_${sBuildType}" sBuildType)
					get_target_property(sImportLibrary "${sTarget}" IMPORTED_LOCATION${sBuildType})
					if(sImportLibrary)
						nx_append(${NX_PROJECT_NAME}_SHLIBS "${sImportLibrary}")
						nx_append(${NX_PROJECT_NAME}_SHLIBS${sBuildType} "${sImportLibrary}")
					endif()
				endforeach()
			endif()
		endif()
	endforeach()

	foreach(sTarget ${lsArgTARGETS})
		foreach(sVisibility "PUBLIC" "PRIVATE" "INTERFACE")
			if(DEFINED lsArg${sVisibility})
				target_link_libraries("${sTarget}" ${sVisibility} ${lsArg${sVisibility}})
			endif()
		endforeach()
	endforeach()

	_nx_function_end()
endfunction()

# ===================================================================

function(nx_target_link_options)
	_nx_function_begin()

	# PARSER START ====

	_nx_parser_initialize()

	set(lsKeywordMultiple "TARGETS" "PRIVATE" "PUBLIC" "INTERFACE" "STATIC")

	set(sParseMode "TARGETS")

	_nx_parser_clear()
	_nx_parser_run(${ARGN})

	# ==== PARSER END

	foreach(sTarget ${lsArgTARGETS})
		foreach(sVisibility "PUBLIC" "PRIVATE" "INTERFACE")
			if(DEFINED lsArg${sVisibility})
				target_link_options("${sTarget}" ${sVisibility} ${lsArg${sVisibility}})
			endif()
		endforeach()

		if(DEFINED lsArgSTATIC)
			get_target_property(lsStaticOpts "${sTarget}" STATIC_LIBRARY_OPTIONS)
			if(NOT lsStaticOpts)
				unset(lsStaticOpts)
			endif()
			list(APPEND lsStaticOpts ${lsArgSTATIC})
			set_target_properties("${sTarget}" PROPERTIES STATIC_LIBRARY_OPTIONS "${lsStaticOpts}")
		endif()
	endforeach()

	_nx_function_end()
endfunction()

# ===================================================================

function(nx_target_sources)
	_nx_function_begin()

	# PARSER START ====

	_nx_parser_initialize()

	set(lsKeywordToggle "NO_INSTALL")
	set(lsKeywordMultiple "TARGETS" "PRIVATE" "PUBLIC" "INTERFACE" "STRIP")

	set(sParseMode "TARGETS")

	_nx_parser_clear()
	_nx_parser_run(${ARGN})

	# ==== PARSER END

	if(NOT DEFINED bArgNO_INSTALL)
		set(bArgNO_INSTALL OFF)
	endif()

	unset(lsStripPaths)
	foreach(sStripPath ${lsArgSTRIP})
		get_filename_component(sStripPath "${sStripPath}" ABSOLUTE)
		file(RELATIVE_PATH sRelBuild "${CMAKE_CURRENT_BINARY_DIR}" "${sStripPath}")
		string(SUBSTRING "${sRelBuild}" 0 2 sDotDot)
		if(sDotDot STREQUAL ".." OR sDotDot MATCHES ":$")
			file(RELATIVE_PATH sRelSource "${CMAKE_CURRENT_SOURCE_DIR}" "${sStripPath}")
			string(SUBSTRING "${sRelSource}" 0 2 sDotDot)
			if(sDotDot STREQUAL ".." OR sDotDot MATCHES ":$")
				message(AUTHOR_WARNING "nx_target_sources: Source Path '${sStripPath}' Outside Scope")
			else()
				list(APPEND lsStripPaths "${CMAKE_CURRENT_SOURCE_DIR}/${sRelSource}" "${CMAKE_CURRENT_BINARY_DIR}/${sRelSource}")
			endif()
		else()
			list(APPEND lsStripPaths "${CMAKE_CURRENT_BINARY_DIR}/${sRelBuild}")
		endif()
	endforeach()
	if(DEFINED lsStripPaths)
		nx_append(${NX_PROJECT_NAME}_DIRS_SOURCE ${lsStripPaths})
	endif()

	if(NOT DEFINED _CURRENT_YEAR)
		string(TIMESTAMP _CURRENT_YEAR "%Y")
	endif()
	if(NOT DEFINED _CURRENT_DATE)
		string(TIMESTAMP _CURRENT_DATE "%Y%m%d")
	endif()

	foreach(sVisibility "PUBLIC" "PRIVATE" "INTERFACE")
		unset(lsSource${sVisibility})
		unset(lsInternal${sVisibility})
		foreach(sSource ${lsArg${sVisibility}})
			if(sSource MATCHES "<[^>]+:")
				list(APPEND lsSource${sVisibility} "${sSource}")
			else()
				unset(sOwnSource)

				if(sSource MATCHES ".in$")
					string(REPLACE ".in" "" sSource "${sSource}")
				endif()
				get_filename_component(sSource "${sSource}" ABSOLUTE)

				file(RELATIVE_PATH sRelBuild "${CMAKE_CURRENT_BINARY_DIR}" "${sSource}")
				string(SUBSTRING "${sRelBuild}" 0 2 sDotDot)
				if(sDotDot STREQUAL ".." OR sDotDot MATCHES ":$")
					file(RELATIVE_PATH sRelSource "${CMAKE_CURRENT_SOURCE_DIR}" "${sSource}")
					string(SUBSTRING "${sRelSource}" 0 2 sDotDot)
					if(sDotDot STREQUAL ".." OR sDotDot MATCHES ":$")
						list(APPEND lsSource${sVisibility} "${sSource}")
					else()
						if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${sRelSource}.in")
							if(NOT sVisibility STREQUAL "PRIVATE")
								nx_mkpath("${CMAKE_CURRENT_BINARY_DIR}/${sRelSource}")
							endif()
							if(sRelSource MATCHES "[.]rc$")
								configure_file("${CMAKE_CURRENT_SOURCE_DIR}/${sRelSource}.in" "${CMAKE_CURRENT_BINARY_DIR}/${sRelSource}"
												NEWLINE_STYLE WIN32)
							else()
								configure_file("${CMAKE_CURRENT_SOURCE_DIR}/${sRelSource}.in" "${CMAKE_CURRENT_BINARY_DIR}/${sRelSource}"
												NEWLINE_STYLE UNIX)
							endif()
							set(sOwnSource "${CMAKE_CURRENT_BINARY_DIR}/${sRelSource}")
						else()
							set(sOwnSource "${CMAKE_CURRENT_SOURCE_DIR}/${sRelSource}")
						endif()
					endif()
				else()
					if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${sRelBuild}.in")
						if(NOT sVisibility STREQUAL "PRIVATE")
							nx_mkpath("${CMAKE_CURRENT_BINARY_DIR}/${sRelBuild}")
						endif()
						if(sRelBuild MATCHES "[.]rc$")
							configure_file("${CMAKE_CURRENT_SOURCE_DIR}/${sRelBuild}.in" "${CMAKE_CURRENT_BINARY_DIR}/${sRelBuild}"
											NEWLINE_STYLE WIN32)
						else()
							configure_file("${CMAKE_CURRENT_SOURCE_DIR}/${sRelBuild}.in" "${CMAKE_CURRENT_BINARY_DIR}/${sRelBuild}"
											NEWLINE_STYLE UNIX)
						endif()
					endif()
					set(sOwnSource "${CMAKE_CURRENT_BINARY_DIR}/${sRelBuild}")
				endif()

				if(DEFINED sOwnSource)
					if(sOwnSource MATCHES ".rc$")
						if(NX_TARGET_PLATFORM_WINDOWS AND sVisibility STREQUAL "PRIVATE")
							list(APPEND lsInternal${sVisibility} "${sOwnSource}")
						endif()
					else()
						list(APPEND lsInternal${sVisibility} "${sOwnSource}")
					endif()
				endif()
			endif()
		endforeach()
	endforeach()

	foreach(sVisibility "PUBLIC" "INTERFACE")
		foreach(sOwnSource ${lsInternal${sVisibility}})
			unset(sIncludePath)
			foreach(sDirectory ${${NX_PROJECT_NAME}_DIRS_INCLUDE})
				file(RELATIVE_PATH sRelInclude "${sDirectory}" "${sOwnSource}")
				string(SUBSTRING "${sRelInclude}" 0 2 sDotDot)
				if(NOT sDotDot STREQUAL ".." AND NOT sDotDot MATCHES ":$")
					set(sIncludePath "${sRelInclude}")
				endif()
			endforeach()

			unset(sSourcePath)
			foreach(sDirectory "${CMAKE_CURRENT_SOURCE_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}/src" "${CMAKE_CURRENT_BINARY_DIR}"
								${${NX_PROJECT_NAME}_DIRS_SOURCE})
				file(RELATIVE_PATH sRelSource "${sDirectory}" "${sOwnSource}")
				string(SUBSTRING "${sRelSource}" 0 2 sDotDot)
				if(NOT sDotDot STREQUAL ".." AND NOT sDotDot MATCHES ":$")
					set(sSourcePath "${sRelSource}")
				endif()
			endforeach()

			if(DEFINED sIncludePath AND NOT bArgNO_INSTALL)
				list(APPEND lsSource${sVisibility} "$<BUILD_INTERFACE:${sOwnSource}>")
				list(APPEND lsSource${sVisibility} "$<INSTALL_INTERFACE:${NX_INSTALL_PATH_INCLUDE}/${sIncludePath}>")
			elseif(DEFINED sSourcePath)
				list(APPEND lsSource${sVisibility} "$<BUILD_INTERFACE:${sOwnSource}>")
				if(NOT bArgNO_INSTALL)
					list(APPEND lsSource${sVisibility} "$<INSTALL_INTERFACE:${NX_INSTALL_PATH_SOURCE}/${sSourcePath}>")
					nx_append(${NX_PROJECT_NAME}_FILES_INTERFACE "${sOwnSource}::${sSourcePath}")
				endif()
			else()
				list(APPEND lsSource${sVisibility} "${sOwnSource}")
			endif()
		endforeach()

		if(DEFINED lsInternal${sVisibility})
			nx_append(${NX_PROJECT_NAME}_FILES_SOURCE ${lsInternal${sVisibility}})
		endif()
	endforeach()
	if(DEFINED lsInternalPRIVATE)
		list(APPEND lsSourcePRIVATE ${lsInternalPRIVATE})
		nx_append(${NX_PROJECT_NAME}_FILES_SOURCE ${lsInternalPRIVATE})
	endif()

	foreach(sTarget ${lsArgTARGETS})
		foreach(sVisibility "PUBLIC" "PRIVATE" "INTERFACE")
			if(DEFINED lsSource${sVisibility})
				target_sources("${sTarget}" ${sVisibility} ${lsSource${sVisibility}})
			endif()
		endforeach()
	endforeach()

	_nx_function_end()
endfunction()

# ===================================================================

# cmake-lint: disable=E1125

function(nx_target vTargetList sTargetName)
	_nx_function_begin()

	if(NOT DEFINED INSTALL_TARGETS${NX_PROJECT_NAME})
		set(bDefaultInstall OFF)
		if(NOT DEFINED ${NX_PROJECT_NAME}_IS_EXTERNAL OR NOT ${NX_PROJECT_NAME}_IS_EXTERNAL)
			set(bDefaultInstall ON)
		endif()

		option(INSTALL_TARGETS${NX_PROJECT_NAME} "Install Targets - ${PROJECT_NAME}" ${bDefaultInstall})
	endif()

	string(TOUPPER "${sTargetName}" sTargetUpper)
	string(MAKE_C_IDENTIFIER "${sTargetUpper}" sTargetUpper)

	# PARSER START ====

	_nx_parser_initialize(
		"GENERATE_EXPORT"
		"GENERATE_VERSION"
		"CFLAGS"
		"CXXFLAGS"
		"DEFINES"
		"DEPENDS"
		"LIBDEPS"
		"FEATURES"
		"INCLUDES"
		"LDFLAGS"
		"SOURCES")

	set(lsKeywordToggle
		"NO_EXPORT"
		"NO_INSTALL"
		"NO_LTO"
		"NO_SECURE"
		"USE_ASAN"
		"USE_MSAN"
		"USE_TSAN"
		"USE_UBSAN")
	set(lsKeywordSingle "TYPE" "DEFINE_SYMBOL" "STATIC_DEFINE" "OUTPUT_NAME" "OUTPUT_SHORT")
	set(lsKeywordMultiple "DXEFLAGS" "DXELIBS" "STRIP")

	set(lsKeywordToggleGENERATE_EXPORT "DEFINE_NO_DEPRECATED")
	set(lsKeywordSingleGENERATE_EXPORT
		"BASE_NAME"
		"CEXPORT_MACRO_NAME"
		"CIMPORT_MACRO_NAME"
		"CUSTOM_CONTENT_FROM_VARIABLE"
		"DEPRECATED_MACRO_NAME"
		"EXPORT_FILE_NAME"
		"EXPORT_MACRO_NAME"
		"IMPORT_MACRO_NAME"
		"INCLUDE_GUARD_NAME"
		"NO_DEPRECATED_MACRO_NAME"
		"NO_EXPORT_MACRO_NAME"
		"PREFIX_NAME")

	set(lsKeywordToggleGENERATE_VERSION "QUERY_GIT")
	set(lsKeywordSingleGENERATE_VERSION
		"BASE_NAME"
		"CUSTOM_CONTENT_FROM_VARIABLE"
		"GIT_MACRO_NAME"
		"INCLUDE_GUARD_NAME"
		"PREFIX_NAME"
		"VERSION"
		"VERSION_FILE_NAME"
		"VERSION_MACRO_NAME")

	set(lsKeywordMultipleCFLAGS "INTERNAL" "PRIVATE" "PUBLIC" "INTERFACE")
	set(lsKeywordMultipleCXXFLAGS "INTERNAL" "PRIVATE" "PUBLIC" "INTERFACE")
	set(lsKeywordMultipleDEFINES "INTERNAL" "PRIVATE" "PUBLIC" "INTERFACE")
	set(lsKeywordMultipleDEPENDS "PRIVATE" "PUBLIC" "INTERFACE")
	set(lsKeywordMultipleLIBDEPS "PRIVATE" "PUBLIC" "INTERFACE")
	set(lsKeywordMultipleFEATURES "PRIVATE" "PUBLIC" "INTERFACE")
	set(lsKeywordMultipleINCLUDES "PRIVATE" "PUBLIC" "INTERFACE")
	set(lsKeywordMultipleLDFLAGS "INTERNAL" "PRIVATE" "PUBLIC" "INTERFACE" "STATIC")
	set(lsKeywordMultipleSOURCES "PRIVATE" "PUBLIC" "INTERFACE")

	set(sComboMode "SOURCES")
	set(sParseMode "TYPE")

	_nx_parser_clear()

	set(sDefaultGENERATE_EXPORT "EXPORT_FILE_NAME")
	set(sNextEXPORT_FILE_NAME_GENERATE_EXPORT "BASE_NAME")
	set(sNextEXPORT_MACRO_NAME_GENERATE_EXPORT "CEXPORT_MACRO_NAME")
	set(sNextIMPORT_MACRO_NAME_GENERATE_EXPORT "CIMPORT_MACRO_NAME")

	set(sDefaultGENERATE_VERSION "VERSION_FILE_NAME")
	set(sNextVERSION_FILE_NAME_GENERATE_VERSION "BASE_NAME")

	set(sDefaultCFLAGS "PRIVATE")
	set(sDefaultCXXFLAGS "PRIVATE")
	set(sDefaultDEFINES "PRIVATE")
	set(sDefaultDEPENDS "PRIVATE")
	set(sDefaultLIBDEPS "PRIVATE")
	set(sDefaultFEATURES "PRIVATE")
	set(sDefaultINCLUDES "PRIVATE")
	set(sDefaultLDFLAGS "PRIVATE")
	set(sDefaultSOURCES "PRIVATE")

	set(sNextTYPE "PRIVATE")
	set(sNextOUTPUT_NAME "OUTPUT_SHORT")

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

	set(bBadSanitizers OFF)
	set(bGoodSanitizers OFF)

	if(bArgUSE_ASAN)
		if(NOT DEFINED SUPPORTS_SANITIZER_ADDRESS OR NOT SUPPORTS_SANITIZER_ADDRESS)
			set(bBadSanitizers ON)
		else()
			set(bGoodSanitizers ON)
		endif()
	endif()
	if(bArgUSE_MSAN)
		if(NOT DEFINED SUPPORTS_SANITIZER_MEMORY OR NOT SUPPORTS_SANITIZER_MEMORY)
			set(bBadSanitizers ON)
		else()
			set(bGoodSanitizers ON)
		endif()
	endif()
	if(bArgUSE_TSAN)
		if(NOT DEFINED SUPPORTS_SANITIZER_THREAD OR NOT SUPPORTS_SANITIZER_THREAD)
			set(bBadSanitizers ON)
		else()
			set(bGoodSanitizers ON)
		endif()
	endif()
	if(bArgUSE_UBSAN)
		if(NOT DEFINED SUPPORTS_SANITIZER_UNDEFINED OR NOT SUPPORTS_SANITIZER_UNDEFINED)
			set(bBadSanitizers ON)
		else()
			set(bGoodSanitizers ON)
		endif()
	endif()

	if(bBadSanitizers AND NOT bGoodSanitizers)
		set(sArgTYPE "INVALID")
	endif()
	if(NOT DEFINED sArgTYPE)
		set(sArgTYPE "EXECUTABLE")
	endif()

	if(NX_TARGET_PLATFORM_MSDOS AND DEFINED sArgOUTPUT_SHORT)
		set(sArgOUTPUT_NAME "${sArgOUTPUT_SHORT}")
	endif()
	if(NOT DEFINED sArgOUTPUT_NAME)
		set(sArgOUTPUT_NAME "${sTargetName}")
	endif()

	if(NOT DEFINED bArgNO_INSTALL)
		set(bArgNO_INSTALL OFF)
	endif()
	if(NOT DEFINED bArgNO_EXPORT)
		set(bArgNO_EXPORT ON)
		if(NOT bArgNO_INSTALL)
			foreach(sVisibility "PUBLIC" "INTERFACE")
				foreach(sCombo ${lsKeywordCombo})
					if(DEFINED lsKeywordMultiple${sCombo} AND DEFINED lsArg${sVisibility}_${sCombo})
						if("${sVisibility}" IN_LIST lsKeywordMultiple${sCombo})
							set(bArgNO_EXPORT OFF)
						endif()
					endif()
				endforeach()
			endforeach()
		endif()
	endif()

	unset(sNO_INSTALL)
	if(bArgNO_EXPORT)
		set(sNO_INSTALL "NO_INSTALL")
	endif()

	if(NOT DEFINED bArgNO_LTO)
		set(bArgNO_LTO OFF)
	endif()
	if(NOT DEFINED bArgNO_SECURE)
		set(bArgNO_SECURE OFF)
	endif()

	# === Generated Headers ===

	if(DEFINED sArgEXPORT_FILE_NAME_GENERATE_EXPORT)
		get_filename_component(sArgEXPORT_FILE_NAME_GENERATE_EXPORT "${sArgEXPORT_FILE_NAME_GENERATE_EXPORT}" ABSOLUTE BASE_DIR
								"${CMAKE_CURRENT_BINARY_DIR}")
		file(RELATIVE_PATH sArgEXPORT_FILE_NAME_GENERATE_EXPORT "${CMAKE_CURRENT_BINARY_DIR}" "${sArgEXPORT_FILE_NAME_GENERATE_EXPORT}")

		unset(sNoDeprecated)
		if(DEFINED bArgDEFINE_NO_DEPRECATED_GENERATE_EXPORT AND bArgDEFINE_NO_DEPRECATED_GENERATE_EXPORT)
			set(sNoDeprecated "DEFINE_NO_DEPRECATED")
		endif()
		if(NOT DEFINED sArgBASE_NAME_GENERATE_EXPORT)
			set(sArgBASE_NAME_GENERATE_EXPORT "${sTargetUpper}")
		endif()
		nx_generate_export_header(
			"${sTargetName}" ${sNoDeprecated}
			EXPORT_FILE_NAME "${sArgEXPORT_FILE_NAME_GENERATE_EXPORT}"
			BASE_NAME "${sArgBASE_NAME_GENERATE_EXPORT}"
			CEXPORT_MACRO_NAME ${sArgCEXPORT_MACRO_NAME_GENERATE_EXPORT}
			CIMPORT_MACRO_NAME ${sArgCIMPORT_MACRO_NAME_GENERATE_EXPORT}
			CUSTOM_CONTENT_FROM_VARIABLE ${sArgCUSTOM_CONTENT_FROM_VARIABLE_GENERATE_EXPORT}
			DEPRECATED_MACRO_NAME ${sArgDEPRECATED_MACRO_NAME_GENERATE_EXPORT}
			EXPORT_MACRO_NAME ${sArgEXPORT_MACRO_NAME_GENERATE_EXPORT}
			IMPORT_MACRO_NAME ${sArgIMPORT_MACRO_NAME_GENERATE_EXPORT}
			INCLUDE_GUARD_NAME ${sArgINCLUDE_GUARD_NAME_GENERATE_EXPORT}
			NO_DEPRECATED_MACRO_NAME ${sArgNO_DEPRECATED_MACRO_NAME_GENERATE_EXPORT}
			NO_EXPORT_MACRO_NAME ${sArgNO_EXPORT_MACRO_NAME_GENERATE_EXPORT}
			PREFIX_NAME ${sArgPREFIX_NAME_GENERATE_EXPORT}
			DEFINE_SYMBOL ${sArgDEFINE_SYMBOL}
			STATIC_DEFINE ${sArgSTATIC_DEFINE})
		if(NOT DEFINED sArgDEFINE_SYMBOL AND DEFINED ${sTargetUpper}_DEFINE_SYMBOL)
			set(sArgDEFINE_SYMBOL "${${sTargetUpper}_DEFINE_SYMBOL}")
		endif()
		if(NOT DEFINED sArgSTATIC_DEFINE AND DEFINED ${sTargetUpper}_STATIC_DEFINE)
			set(sArgSTATIC_DEFINE "${${sTargetUpper}_STATIC_DEFINE}")
		endif()
		list(APPEND lsArgPRIVATE_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${sArgEXPORT_FILE_NAME_GENERATE_EXPORT}")
	endif()

	if(DEFINED sArgVERSION_FILE_NAME_GENERATE_VERSION)
		get_filename_component(sArgVERSION_FILE_NAME_GENERATE_VERSION "${sArgVERSION_FILE_NAME_GENERATE_VERSION}" ABSOLUTE BASE_DIR
								"${CMAKE_CURRENT_BINARY_DIR}")
		file(RELATIVE_PATH sArgVERSION_FILE_NAME_GENERATE_VERSION "${CMAKE_CURRENT_BINARY_DIR}" "${sArgVERSION_FILE_NAME_GENERATE_VERSION}")

		unset(sQueryGit)
		if(DEFINED bArgQUERY_GIT_GENERATE_VERSION AND bArgQUERY_GIT_GENERATE_VERSION)
			set(sQueryGit "QUERY_GIT")
		elseif(NOT DEFINED bArgQUERY_GIT_GENERATE_VERSION AND DEFINED NX_GITWATCH_VARS)
			set(sQueryGit "QUERY_GIT")
		endif()
		if(NOT DEFINED sArgBASE_NAME_GENERATE_VERSION)
			set(sArgBASE_NAME_GENERATE_VERSION "${sTargetUpper}")
		endif()
		nx_generate_version_header(
			"${sTargetName}" ${sQueryGit}
			VERSION_FILE_NAME "${sArgVERSION_FILE_NAME_GENERATE_VERSION}"
			BASE_NAME "${sArgBASE_NAME_GENERATE_VERSION}"
			CUSTOM_CONTENT_FROM_VARIABLE ${sArgCUSTOM_CONTENT_FROM_VARIABLE_GENERATE_VERSION}
			GIT_MACRO_NAME ${sArgGIT_MACRO_NAME_GENERATE_VERSION}
			INCLUDE_GUARD_NAME ${sArgINCLUDE_GUARD_NAME_GENERATE_VERSION}
			PREFIX_NAME ${sArgPREFIX_NAME_GENERATE_VERSION}
			VERSION ${sArgVERSION_GENERATE_VERSION}
			VERSION_MACRO_NAME ${sArgVERSION_MACRO_NAME_GENERATE_VERSION})
		list(APPEND lsArgPRIVATE_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${sArgVERSION_FILE_NAME_GENERATE_VERSION}")
	endif()

	# === Determine Targets To Build ===

	set(bHasSource OFF)
	if(lsArgPRIVATE_SOURCES MATCHES "[.]c$|[.]cpp$|[.]cxx$|[.]cc$|[.]c;|[.]cpp;|[.]cxx;|[.]cc;")
		set(bHasSource ON)
	endif()
	if(lsArgPUBLIC_SOURCES MATCHES "[.]c$|[.]cpp$|[.]cxx$|[.]cc$|[.]c;|[.]cpp;|[.]cxx;|[.]cc;")
		set(bHasSource ON)
	endif()

	if(sArgTYPE STREQUAL "APPLICATION")
		if(NX_TARGET_PLATFORM_ANDROID)
			if(NOT DEFINED BUILD_MODULE_${sTargetUpper})
				if(DEFINED BUILD_EXECUTABLE_${sTargetUpper})
					nx_set_global(BUILD_MODULE_${sTargetUpper} ${BUILD_EXECUTABLE_${sTargetUpper}})
				else()
					nx_set_global(BUILD_MODULE_${sTargetUpper} ON)
				endif()
			endif()
			nx_set_global(BUILD_EXECUTABLE_${sTargetUpper} OFF)
		else()
			if(NOT DEFINED BUILD_EXECUTABLE_${sTargetUpper})
				nx_set_global(BUILD_EXECUTABLE_${sTargetUpper} ON)
			endif()
			nx_set_global(BUILD_MODULE_${sTargetUpper} OFF)
		endif()
		nx_set(BUILD_SHARED_${sTargetUpper} OFF)
		nx_set(BUILD_STATIC_${sTargetUpper} OFF)
		nx_set(BUILD_OBJECTS_${sTargetUpper} OFF)
		nx_set(BUILD_INTERFACE_${sTargetUpper} OFF)
	elseif(sArgTYPE STREQUAL "DAEMON" OR sArgTYPE MATCHES "EXECUTABLE")
		if(NOT DEFINED BUILD_EXECUTABLE_${sTargetUpper})
			nx_set_global(BUILD_EXECUTABLE_${sTargetUpper} ON)
		endif()
		nx_set(BUILD_MODULE_${sTargetUpper} OFF)
		nx_set(BUILD_SHARED_${sTargetUpper} OFF)
		nx_set(BUILD_STATIC_${sTargetUpper} OFF)
		nx_set(BUILD_OBJECTS_${sTargetUpper} OFF)
		nx_set(BUILD_INTERFACE_${sTargetUpper} OFF)
	elseif(sArgTYPE STREQUAL "SHARED_MODULE")
		if(NOT DEFINED BUILD_MODULE_${sTargetUpper})
			nx_set_global(BUILD_MODULE_${sTargetUpper} ON)
		endif()
		nx_set(BUILD_EXECUTABLE_${sTargetUpper} OFF)
		nx_set(BUILD_SHARED_${sTargetUpper} OFF)
		nx_set(BUILD_STATIC_${sTargetUpper} OFF)
		nx_set(BUILD_OBJECTS_${sTargetUpper} OFF)
		nx_set(BUILD_INTERFACE_${sTargetUpper} OFF)
	elseif(sArgTYPE STREQUAL "MODULE")
		if(bHasSource)
			if(NOT DEFINED BUILD_MODULE_${sTargetUpper})
				nx_set_global(BUILD_MODULE_${sTargetUpper} ON)
			endif()
			if(NOT DEFINED BUILD_STATIC_${sTargetUpper})
				if(DEFINED sArgSTATIC_DEFINE)
					nx_set_global(BUILD_STATIC_${sTargetUpper} ON)
				else()
					nx_set_global(BUILD_STATIC_${sTargetUpper} OFF)
				endif()
			endif()
			if(NOT DEFINED BUILD_INTERFACE_${sTargetUpper})
				nx_set_global(BUILD_INTERFACE_${sTargetUpper} OFF)
			endif()
		elseif(DEFINED sArgSTATIC_DEFINE)
			if(NOT DEFINED BUILD_MODULE_${sTargetUpper})
				nx_set_global(BUILD_MODULE_${sTargetUpper} OFF)
			endif()
			if(NOT DEFINED BUILD_STATIC_${sTargetUpper})
				nx_set_global(BUILD_STATIC_${sTargetUpper} OFF)
			endif()
			if(NOT DEFINED BUILD_INTERFACE_${sTargetUpper})
				nx_set_global(BUILD_INTERFACE_${sTargetUpper} ON)
			endif()
		endif()
		nx_set(BUILD_EXECUTABLE_${sTargetUpper} OFF)
		nx_set(BUILD_SHARED_${sTargetUpper} OFF)
		nx_set(BUILD_OBJECTS_${sTargetUpper} OFF)
	elseif(sArgTYPE STREQUAL "SHARED_LIBRARY")
		if(NOT DEFINED BUILD_SHARED_${sTargetUpper})
			nx_set_global(BUILD_SHARED_${sTargetUpper} ON)
		endif()
		nx_set(BUILD_EXECUTABLE_${sTargetUpper} OFF)
		nx_set(BUILD_MODULE_${sTargetUpper} OFF)
		nx_set(BUILD_STATIC_${sTargetUpper} OFF)
		nx_set(BUILD_OBJECTS_${sTargetUpper} OFF)
		nx_set(BUILD_INTERFACE_${sTargetUpper} OFF)
	elseif(sArgTYPE STREQUAL "STATIC_LIBRARY")
		if(NOT DEFINED BUILD_STATIC_${sTargetUpper})
			nx_set_global(BUILD_STATIC_${sTargetUpper} ON)
		endif()
		nx_set(BUILD_EXECUTABLE_${sTargetUpper} OFF)
		nx_set(BUILD_MODULE_${sTargetUpper} OFF)
		nx_set(BUILD_SHARED_${sTargetUpper} OFF)
		nx_set(BUILD_OBJECTS_${sTargetUpper} OFF)
		nx_set(BUILD_INTERFACE_${sTargetUpper} OFF)
	elseif(sArgTYPE STREQUAL "OBJECT_LIBRARY")
		if(NOT DEFINED BUILD_OBJECTS_${sTargetUpper})
			nx_set_global(BUILD_OBJECTS_${sTargetUpper} ON)
		endif()
		nx_set(BUILD_EXECUTABLE_${sTargetUpper} OFF)
		nx_set(BUILD_MODULE_${sTargetUpper} OFF)
		nx_set(BUILD_SHARED_${sTargetUpper} OFF)
		nx_set(BUILD_STATIC_${sTargetUpper} OFF)
		nx_set(BUILD_INTERFACE_${sTargetUpper} OFF)
	elseif(sArgTYPE STREQUAL "INTERFACE_LIBRARY")
		if(NOT DEFINED BUILD_INTERFACE_${sTargetUpper})
			nx_set_global(BUILD_INTERFACE_${sTargetUpper} ON)
		endif()
		nx_set(BUILD_EXECUTABLE_${sTargetUpper} OFF)
		nx_set(BUILD_MODULE_${sTargetUpper} OFF)
		nx_set(BUILD_SHARED_${sTargetUpper} OFF)
		nx_set(BUILD_STATIC_${sTargetUpper} OFF)
		nx_set(BUILD_OBJECTS_${sTargetUpper} OFF)
	elseif(sArgTYPE STREQUAL "LIBRARY")
		if(bHasSource)
			if(NOT DEFINED BUILD_SHARED_${sTargetUpper})
				if(BUILD_SHARED_LIBS)
					nx_set_global(BUILD_SHARED_${sTargetUpper} ON)
				else()
					nx_set_global(BUILD_SHARED_${sTargetUpper} OFF)
				endif()
			endif()
			if(NOT DEFINED BUILD_STATIC_${sTargetUpper})
				nx_set_global(BUILD_STATIC_${sTargetUpper} ON)
			endif()
			if(NOT DEFINED BUILD_INTERFACE_${sTargetUpper})
				nx_set_global(BUILD_INTERFACE_${sTargetUpper} OFF)
			endif()
		else()
			if(NOT DEFINED BUILD_SHARED_${sTargetUpper})
				nx_set_global(BUILD_SHARED_${sTargetUpper} OFF)
			endif()
			if(NOT DEFINED BUILD_STATIC_${sTargetUpper})
				nx_set_global(BUILD_STATIC_${sTargetUpper} OFF)
			endif()
			if(NOT DEFINED BUILD_INTERFACE_${sTargetUpper})
				nx_set_global(BUILD_INTERFACE_${sTargetUpper} ON)
			endif()
		endif()
		nx_set(BUILD_EXECUTABLE_${sTargetUpper} OFF)
		nx_set(BUILD_MODULE_${sTargetUpper} OFF)
		nx_set(BUILD_OBJECTS_${sTargetUpper} OFF)
	elseif(sArgTYPE STREQUAL "INVALID")
		if(NOT bArgNO_INSTALL)
			message(NOTICE "nx_target: Skipping Target '${sTargetName}'")
		endif()
		nx_set(BUILD_EXECUTABLE_${sTargetUpper} OFF)
		nx_set(BUILD_MODULE_${sTargetUpper} OFF)
		nx_set(BUILD_SHARED_${sTargetUpper} OFF)
		nx_set(BUILD_STATIC_${sTargetUpper} OFF)
		nx_set(BUILD_OBJECTS_${sTargetUpper} OFF)
		nx_set(BUILD_INTERFACE_${sTargetUpper} OFF)
	else()
		message(AUTHOR_WARNING "nx_target: Target Type '${sArgTYPE}' Unknown")
	endif()

	foreach(sType "EXECUTABLE" "MODULE" "SHARED" "STATIC" "OBJECTS" "INTERFACE")
		unset(sTarget${sType})
		if(BUILD_${sType}_${sTargetUpper})
			set(sTarget${sType} "${sTargetName}")
		endif()
		set(sOutput${sType} "${sArgOUTPUT_NAME}")
	endforeach()

	# === Parse LIBDEPS ===

	foreach(sVisibility "PRIVATE" "PUBLIC" "INTERFACE")
		unset(lsLibDeps${sVisibility}_SHARED)
		unset(lsLibDeps${sVisibility}_STATIC)
		unset(lsLibDeps${sVisibility}_INTERFACE)

		foreach(vLibrary ${lsArg${sVisibility}_LIBDEPS})
			unset(sLibShared)
			unset(sLibStatic)
			unset(sLibInterface)

			if(TARGET ${vLibrary})
				get_target_property(sType ${vLibrary} TYPE)
				if(sType STREQUAL "SHARED_LIBRARY" AND NOT NX_TARGET_PLATFORM_MSDOS)
					set(sLibShared "${vLibrary}")
				elseif(sType STREQUAL "STATIC_LIBRARY")
					if(NX_TARGET_PLATFORM_MSDOS)
						set(sLibShared "${vLibrary}")
					endif()
					set(sLibStatic "${vLibrary}")
				elseif(sType STREQUAL "INTERFACE_LIBRARY")
					set(sLibInterface "${vLibrary}")
				endif()
			else()
				foreach(sLibrary ${${vLibrary}})
					if(TARGET ${sLibrary})
						get_target_property(sType ${sLibrary} TYPE)
						if(sType STREQUAL "SHARED_LIBRARY" AND NOT NX_TARGET_PLATFORM_MSDOS)
							set(sLibShared "${sLibrary}")
						elseif(sType STREQUAL "STATIC_LIBRARY")
							set(sLibStatic "${sLibrary}")
						elseif(sType STREQUAL "INTERFACE_LIBRARY")
							set(sLibInterface "${sLibrary}")
						endif()
					endif()
				endforeach()

				if(NOT DEFINED sLibShared)
					if(DEFINED sLibStatic)
						set(sLibShared "${sLibStatic}")
					elseif(DEFINED sLibInterface)
						set(sLibShared "${sLibInterface}")
					endif()
				endif()

				if(NOT DEFINED sLibStatic)
					if(DEFINED sLibInterface)
						set(sLibStatic "${sLibInterface}")
					endif()
				endif()
			endif()

			list(APPEND lsLibDeps${sVisibility}_SHARED ${sLibShared})
			list(APPEND lsLibDeps${sVisibility}_STATIC ${sLibStatic})
			list(APPEND lsLibDeps${sVisibility}_INTERFACE ${sLibInterface})
		endforeach()
	endforeach()

	# === Target Naming ===

	set(bFormatMachO OFF)
	set(bFormatWinPE OFF)
	set(bFormatDJCOFF OFF)
	set(bFormatELF OFF)

	if(NX_TARGET_PLATFORM_DARWIN)
		set(bFormatMachO ON)
	elseif(NX_TARGET_PLATFORM_MSDOS)
		set(bFormatDJCOFF ON)
	elseif(NX_TARGET_PLATFORM_WINDOWS OR NX_TARGET_PLATFORM_CYGWIN)
		set(bFormatWinPE ON)
	else()
		set(bFormatELF ON)
	endif()

	set(bUseSOVERSION OFF)
	if(DEFINED ${NX_PROJECT_NAME}_PROJECT_SOVERSION_COMPAT)
		string(REPLACE "." "-" sVersionABI "${${NX_PROJECT_NAME}_PROJECT_SOVERSION_COMPAT}")
		if(bFormatDJCOFF OR bFormatWinPE)
			set(sOutputSHARED "${sOutputSHARED}${sVersionABI}")
		else()
			set(bUseSOVERSION ON)
		endif()
		set(sOutputSTATIC "${sOutputSTATIC}${sVersionABI}")
		set(sOutputOBJECTS "${sOutputOBJECTS}${sVersionABI}")
	elseif(DEFINED ${NX_PROJECT_NAME}_PROJECT_VERSION_COMPAT)
		string(REPLACE "." "-" sVersionAPI "${${NX_PROJECT_NAME}_PROJECT_VERSION_COMPAT}")
		set(sOutputSHARED "${sOutputSHARED}-${sVersionAPI}")
		set(sOutputSTATIC "${sOutputSTATIC}-${sVersionAPI}")
		set(sOutputOBJECTS "${sOutputOBJECTS}-${sVersionAPI}")
	endif()
	if(bFormatDJCOFF OR bFormatWinPE)
		if("x${CMAKE_STATIC_LIBRARY_SUFFIX}" STREQUAL "x${CMAKE_IMPORT_LIBRARY_SUFFIX}" AND "x${sOutputSHARED}" STREQUAL
																							"x${sOutputSTATIC}")
			set(sOutputSTATIC "${sOutputSTATIC}_s")
		endif()
	endif()
	if(NX_HOST_LANGUAGE_CXX AND DEFINED NX_TARGET_CXXABI_STRING)
		set(sOutputSHARED "${sOutputSHARED}-${NX_TARGET_CXXABI_STRING}")
		set(sOutputSTATIC "${sOutputSTATIC}-${NX_TARGET_CXXABI_STRING}")
		set(sOutputOBJECTS "${sOutputOBJECTS}-${NX_TARGET_CXXABI_STRING}")
	endif()
	if(NX_TARGET_PLATFORM_MSDOS)
		if(NOT bArgNO_INSTALL)
			nx_string_limit(sOutputEXECUTABLE "${sOutputEXECUTABLE}" 8)
			nx_string_limit(sOutputMODULE "${sOutputMODULE}" 8)
			nx_string_limit(sOutputSHARED "${sOutputSHARED}" 8)
		endif()
		string(TOUPPER "${sOutputEXECUTABLE}" sOutputEXECUTABLE)
		string(TOUPPER "${sOutputMODULE}" sOutputMODULE)
		string(TOUPPER "${sOutputSHARED}" sOutputSHARED)
		string(TOUPPER "${sOutputSTATIC}" sOutputSTATIC)
		string(TOUPPER "${sOutputOBJECTS}" sOutputOBJECTS)
	elseif(NX_TARGET_PLATFORM_POSIX AND NOT NX_TARGET_PLATFORM_HAIKU)
		string(TOLOWER "${sOutputEXECUTABLE}" sOutputEXECUTABLE)
		string(TOLOWER "${sOutputMODULE}" sOutputMODULE)
		string(TOLOWER "${sOutputSHARED}" sOutputSHARED)
		string(TOLOWER "${sOutputSTATIC}" sOutputSTATIC)
		string(TOLOWER "${sOutputOBJECTS}" sOutputOBJECTS)
	endif()
	if(DEFINED sTargetOBJECTS)
		set(sTargetOBJECTS "${sOutputOBJECTS}")
	endif()

	# === Determine Filenames ===

	string(TOUPPER "CMAKE_${CMAKE_BUILD_TYPE}_POSTFIX" vBuildPostfix)

	set(sFileEXECUTABLE "${CMAKE_EXECUTABLE_PREFIX}${sOutputEXECUTABLE}${${vBuildPostfix}}${CMAKE_EXECUTABLE_SUFFIX}")
	set(sFileMODULE "${CMAKE_SHARED_MODULE_PREFIX}${sOutputMODULE}${${vBuildPostfix}}${CMAKE_SHARED_MODULE_SUFFIX}")
	set(sFileSTATIC "${CMAKE_STATIC_LIBRARY_PREFIX}${sOutputSTATIC}${${vBuildPostfix}}${CMAKE_STATIC_LIBRARY_SUFFIX}")

	if(bUseSOVERSION)
		if(bFormatMachO)
			set(sFileSHARED
				"${CMAKE_SHARED_LIBRARY_PREFIX}${sOutputSHARED}${${vBuildPostfix}}.${${NX_PROJECT_NAME}_PROJECT_SOVERSION}${CMAKE_SHARED_LIBRARY_SUFFIX}"
			)
			set(sFileIMPORT
				"${CMAKE_IMPORT_LIBRARY_PREFIX}${sOutputSHARED}${${vBuildPostfix}}.${${NX_PROJECT_NAME}_PROJECT_SOVERSION}${CMAKE_IMPORT_LIBRARY_SUFFIX}"
			)
			set(sFileSONAME1
				"${CMAKE_SHARED_LIBRARY_PREFIX}${sOutputSHARED}${${vBuildPostfix}}.${${NX_PROJECT_NAME}_PROJECT_SOVERSION_COMPAT}${CMAKE_SHARED_LIBRARY_SUFFIX}"
			)
		else()
			set(sFileSHARED
				"${CMAKE_SHARED_LIBRARY_PREFIX}${sOutputSHARED}${${vBuildPostfix}}${CMAKE_SHARED_LIBRARY_SUFFIX}.${${NX_PROJECT_NAME}_PROJECT_SOVERSION}"
			)
			set(sFileIMPORT
				"${CMAKE_IMPORT_LIBRARY_PREFIX}${sOutputSHARED}${${vBuildPostfix}}${CMAKE_IMPORT_LIBRARY_SUFFIX}.${${NX_PROJECT_NAME}_PROJECT_SOVERSION}"
			)
			set(sFileSONAME1
				"${CMAKE_SHARED_LIBRARY_PREFIX}${sOutputSHARED}${${vBuildPostfix}}${CMAKE_SHARED_LIBRARY_SUFFIX}.${${NX_PROJECT_NAME}_PROJECT_SOVERSION_COMPAT}"
			)
		endif()
		set(sFileSONAME2 "${CMAKE_SHARED_LIBRARY_PREFIX}${sOutputSHARED}${${vBuildPostfix}}${CMAKE_SHARED_LIBRARY_SUFFIX}")
	else()
		set(sFileSHARED "${CMAKE_SHARED_LIBRARY_PREFIX}${sOutputSHARED}${${vBuildPostfix}}${CMAKE_SHARED_LIBRARY_SUFFIX}")
		set(sFileIMPORT "${CMAKE_IMPORT_LIBRARY_PREFIX}${sOutputSHARED}${${vBuildPostfix}}${CMAKE_IMPORT_LIBRARY_SUFFIX}")
		unset(sFileSONAME1)
		unset(sFileSONAME2)
	endif()

	# === Default Flags ===

	list(
		APPEND
		lsArgINTERNAL_DEFINES
		${NX_DEFAULT_DEFINES_GENERAL}
		${${NX_PROJECT_NAME}_ARCHITECTURE_DEFINES}
		${${NX_PROJECT_NAME}_BUILD_DEFINES}
		${${NX_PROJECT_NAME}_COMPILER_DEFINES}
		${${NX_PROJECT_NAME}_PLATFORM_DEFINES})
	list(APPEND lsArgINTERNAL_CFLAGS ${NX_DEFAULT_CFLAGS_DIAGNOSTIC})

	if(NOT bGoodSanitizers)
		list(APPEND lsArgINTERNAL_LDFLAGS ${NX_DEFAULT_LDFLAGS_EXTRA})
	endif()

	if(NOT bArgNO_SECURE)
		list(APPEND lsArgINTERNAL_DEFINES ${NX_DEFAULT_DEFINES_HARDEN})
		list(APPEND lsArgINTERNAL_CFLAGS ${NX_DEFAULT_CFLAGS_HARDEN})
		list(APPEND lsArgINTERNAL_LDFLAGS ${NX_DEFAULT_LDFLAGS_HARDEN})
	endif()

	if(bArgUSE_ASAN)
		list(APPEND lsArgINTERNAL_CFLAGS ${NX_DEFAULT_SANITIZER_ADDRESS})
		list(APPEND lsArgINTERNAL_LDFLAGS ${NX_DEFAULT_SANITIZER_ADDRESS})
	endif()
	if(bArgUSE_MSAN)
		list(APPEND lsArgINTERNAL_CFLAGS ${NX_DEFAULT_SANITIZER_MEMORY})
		list(APPEND lsArgINTERNAL_LDFLAGS ${NX_DEFAULT_SANITIZER_MEMORY})
	endif()
	if(bArgUSE_TSAN)
		list(APPEND lsArgINTERNAL_CFLAGS ${NX_DEFAULT_SANITIZER_THREAD})
		list(APPEND lsArgINTERNAL_LDFLAGS ${NX_DEFAULT_SANITIZER_THREAD})
	endif()
	if(bArgUSE_UBSAN)
		list(APPEND lsArgINTERNAL_CFLAGS ${NX_DEFAULT_SANITIZER_UNDEFINED})
		list(APPEND lsArgINTERNAL_LDFLAGS ${NX_DEFAULT_SANITIZER_UNDEFINED})
	endif()

	unset(lsFullLTO_CFLAGS)
	unset(lsFullLTO_LDFLAGS)
	unset(lsThinLTO_CFLAGS)
	unset(lsThinLTO_LDFLAGS)
	if(NOT bArgNO_LTO)
		if(bArgNO_INSTALL OR NOT DEFINED NXINSTALL_IS_SYSTEM)
			set(lsFullLTO_CFLAGS ${NX_DEFAULT_CFLAGS_LTO_THIN})
			set(lsFullLTO_LDFLAGS ${NX_DEFAULT_LDFLAGS_LTO_THIN})
		else()
			set(lsFullLTO_CFLAGS ${NX_DEFAULT_CFLAGS_LTO_FULL})
			set(lsFullLTO_LDFLAGS ${NX_DEFAULT_LDFLAGS_LTO_FULL})
		endif()
		set(lsThinLTO_CFLAGS ${NX_DEFAULT_CFLAGS_LTO_THIN})
		set(lsThinLTO_LDFLAGS ${NX_DEFAULT_LDFLAGS_LTO_THIN})

		if(NOT bArgNO_SECURE AND NOT bGoodSanitizers)
			list(APPEND lsThinLTO_CFLAGS ${NX_DEFAULT_SANITIZER_CFI})
			list(APPEND lsThinLTO_LDFLAGS ${NX_DEFAULT_SANITIZER_CFI})
			list(APPEND lsFullLTO_CFLAGS ${NX_DEFAULT_SANITIZER_CFI})
			list(APPEND lsFullLTO_LDFLAGS ${NX_DEFAULT_SANITIZER_CFI})
		endif()
	endif()

	if(NOT bArgNO_SECURE AND NOT bGoodSanitizers)
		list(APPEND lsArgINTERNAL_CFLAGS ${NX_DEFAULT_SANITIZER_SAFESTACK})
		list(APPEND lsArgINTERNAL_LDFLAGS ${NX_DEFAULT_SANITIZER_SAFESTACK})
	endif()

	# === Build Executable ===

	list(APPEND lsArgINTERNAL_DEFINES ${lsArgPRIVATE_DEFINES})
	list(APPEND lsArgINTERNAL_CFLAGS ${lsArgPRIVATE_CFLAGS})
	list(APPEND lsArgINTERNAL_CXXFLAGS ${lsArgPRIVATE_CXXFLAGS})
	list(APPEND lsArgINTERNAL_LDFLAGS ${lsArgPRIVATE_LDFLAGS})

	if(DEFINED sTargetEXECUTABLE)
		while(TARGET "${sTargetEXECUTABLE}")
			set(sTargetEXECUTABLE "${sTargetEXECUTABLE}_bin")
		endwhile()
		if(NOT bArgNO_INSTALL)
			nx_append(${NX_PROJECT_NAME}_TARGETS_EXECUTABLE "${sTargetEXECUTABLE}")
		endif()
		nx_append(${vTargetList} "${sTargetEXECUTABLE}")

		add_executable("${sTargetEXECUTABLE}")
		set_target_properties("${sTargetEXECUTABLE}" PROPERTIES OUTPUT_NAME "${sOutputEXECUTABLE}")
		nx_target_compile_definitions(
			"${sTargetEXECUTABLE}"
			PRIVATE ${lsArgINTERNAL_DEFINES}
			PUBLIC ${lsArgPUBLIC_DEFINES}
			INTERFACE ${lsArgINTERFACE_DEFINES})
		nx_target_compile_features(
			"${sTargetEXECUTABLE}"
			PRIVATE ${lsArgPRIVATE_FEATURES}
			PUBLIC ${lsArgPUBLIC_FEATURES}
			INTERFACE ${lsArgINTERFACE_FEATURES})
		nx_target_compile_options(
			"${sTargetEXECUTABLE}"
			PRIVATE ${lsArgINTERNAL_CFLAGS} ${lsArgINTERNAL_CXXFLAGS} ${lsThinLTO_CFLAGS}
			PUBLIC ${lsArgPUBLIC_CFLAGS} ${lsArgPUBLIC_CXXFLAGS}
			INTERFACE ${lsArgINTERFACE_CFLAGS} ${lsArgINTERFACE_CXXFLAGS})
		nx_target_include_directories(
			"${sTargetEXECUTABLE}" ${sNO_INSTALL}
			PRIVATE ${lsArgPRIVATE_INCLUDES}
			PUBLIC ${lsArgPUBLIC_INCLUDES}
			INTERFACE ${lsArgINTERFACE_INCLUDES})
		nx_target_link_libraries(
			"${sTargetEXECUTABLE}"
			PRIVATE ${lsArgPRIVATE_DEPENDS} ${lsLibDepsPRIVATE_SHARED}
			PUBLIC ${lsArgPUBLIC_DEPENDS} ${lsLibDepsPUBLIC_SHARED}
			INTERFACE ${lsArgINTERFACE_DEPENDS} ${lsLibDepsINTERFACE_SHARED})
		nx_target_link_options(
			"${sTargetEXECUTABLE}"
			PRIVATE ${lsArgINTERNAL_LDFLAGS} ${lsThinLTO_LDFLAGS}
			PUBLIC ${lsArgPUBLIC_LDFLAGS}
			INTERFACE ${lsArgINTERFACE_LDFLAGS})
		nx_target_sources(
			"${sTargetEXECUTABLE}" ${sNO_INSTALL}
			PRIVATE ${lsArgPRIVATE_SOURCES}
			PUBLIC ${lsArgPUBLIC_SOURCES}
			INTERFACE ${lsArgINTERFACE_SOURCES}
			STRIP ${lsArgSTRIP})

		if(NX_TARGET_PLATFORM_WINDOWS)
			if(sArgTYPE STREQUAL "APPLICATION")
				nx_target_compile_definitions("${sTargetEXECUTABLE}" PRIVATE "_UNICODE" "UNICODE")
				set_target_properties("${sTargetEXECUTABLE}" PROPERTIES WIN32_EXECUTABLE ON)
			else()
				set_target_properties("${sTargetEXECUTABLE}" PROPERTIES WIN32_EXECUTABLE OFF)
			endif()
		endif()

		if(INSTALL_TARGETS${NX_PROJECT_NAME} AND NOT bArgNO_INSTALL)
			if(sArgTYPE STREQUAL "APPLICATION")
				set_target_properties("${sTargetEXECUTABLE}" PROPERTIES
										INSTALL_RPATH "${CMAKE_INSTALL_RPATH}/${NX_INSTALL_RPATH_APPLICATIONS}")
				nx_set(${NX_PROJECT_NAME}_COMPONENT_APP ON)
				install(
					TARGETS "${sTargetEXECUTABLE}"
					COMPONENT ${NX_PROJECT_NAME}_APP
					DESTINATION "${NX_INSTALL_PATH_APPLICATIONS}")
				nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATH_APPLICATIONS}/${sFileEXECUTABLE}")
				nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATH_APPLICATIONS}")
			elseif(sArgTYPE STREQUAL "DAEMON")
				set_target_properties("${sTargetEXECUTABLE}" PROPERTIES INSTALL_RPATH "${CMAKE_INSTALL_RPATH}/${NX_INSTALL_RPATH_DAEMONS}")
				nx_set(${NX_PROJECT_NAME}_COMPONENT_SRV ON)
				install(
					TARGETS "${sTargetEXECUTABLE}"
					COMPONENT ${NX_PROJECT_NAME}_SRV
					DESTINATION "${NX_INSTALL_PATH_DAEMONS}")
				nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATH_DAEMONS}/${sFileEXECUTABLE}")
				nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATH_DAEMONS}")
			else()
				set_target_properties("${sTargetEXECUTABLE}" PROPERTIES INSTALL_RPATH "${CMAKE_INSTALL_RPATH}/${NX_INSTALL_RPATH_BINARIES}")
				nx_set(${NX_PROJECT_NAME}_COMPONENT_BIN ON)
				install(
					TARGETS "${sTargetEXECUTABLE}"
					COMPONENT ${NX_PROJECT_NAME}_BIN
					DESTINATION "${NX_INSTALL_PATH_BINARIES}")
				nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATH_BINARIES}/${sFileEXECUTABLE}")
				nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATH_BINARIES}")
			endif()
		endif()
	endif()

	# === Create DXEFLAGS ===

	if(NX_TARGET_PLATFORM_MSDOS)
		unset(lsArgDXELIB_DEPENDS)
		unset(lsLibDepsDXELIB_SHARED)

		foreach(sLibrary ${lsArgPRIVATE_DEPENDS})
			if(TARGET ${sLibrary})
				get_target_property(sType ${sLibrary} TYPE)

				if(sType STREQUAL "SHARED_LIBRARY")
					list(APPEND lsArgDXEFLAGS "-P" "$<TARGET_FILE:${sLibrary}>")
					list(APPEND lsArgDXELIBS "$<TARGET_LINKER_FILE:${sLibrary}>")
				elseif(sType STREQUAL "STATIC_LIBRARY")
					list(APPEND lsArgDXELIBS "$<TARGET_LINKER_FILE:${sLibrary}>")
				endif()

				list(APPEND lsArgDXELIB_DEPENDS "${sLibrary}")
				list(REMOVE_ITEM lsArgPRIVATE_DEPENDS "${sLibrary}")
			endif()
		endforeach()

		foreach(sLibrary ${lsLibDepsPRIVATE_SHARED})
			if(TARGET ${sLibrary})
				get_target_property(sType ${sLibrary} TYPE)

				if(sType STREQUAL "SHARED_LIBRARY")
					list(APPEND lsArgDXEFLAGS "-P" "$<TARGET_FILE:${sLibrary}>")
					list(APPEND lsArgDXELIBS "$<TARGET_LINKER_FILE:${sLibrary}>")
				elseif(sType STREQUAL "STATIC_LIBRARY")
					list(APPEND lsArgDXELIBS "$<TARGET_LINKER_FILE:${sLibrary}>")
				endif()

				list(APPEND lsLibDepsDXELIB_SHARED "${sLibrary}")
				list(REMOVE_ITEM lsLibDepsPRIVATE_SHARED "${sLibrary}")
			endif()
		endforeach()

		foreach(sLibrary ${lsArgPUBLIC_DEPENDS} ${lsLibDepsPUBLIC_SHARED})
			if(TARGET ${sLibrary})
				get_target_property(sType ${sLibrary} TYPE)

				if(sType STREQUAL "SHARED_LIBRARY")
					list(APPEND lsArgDXEFLAGS "-P" "$<TARGET_FILE:${sLibrary}>")
					list(APPEND lsArgDXELIBS "$<TARGET_LINKER_FILE:${sLibrary}>")
				elseif(sType STREQUAL "STATIC_LIBRARY")
					list(APPEND lsArgDXELIBS "$<TARGET_LINKER_FILE:${sLibrary}>")
				endif()
			endif()
		endforeach()
	endif()

	# === Adjust Executable Flags ===

	foreach(sFlag ${NX_DEFAULT_SANITIZER_SAFESTACK})
		if(DEFINED lsArgINTERNAL_CFLAGS)
			if("${sFlag}" IN_LIST lsArgINTERNAL_CFLAGS)
				list(REMOVE_ITEM lsArgINTERNAL_CFLAGS "${sFlag}")
			endif()
		endif()
		if(DEFINED lsArgINTERNAL_LDFLAGS)
			if("${sFlag}" IN_LIST lsArgINTERNAL_LDFLAGS)
				list(REMOVE_ITEM lsArgINTERNAL_LDFLAGS "${sFlag}")
			endif()
		endif()
	endforeach()

	string(REPLACE "image-base,0x14" "image-base,0x18" lsArgINTERNAL_LDFLAGS "${lsArgINTERNAL_LDFLAGS}")

	# === Build Shared Module ===

	if(DEFINED sTargetMODULE)
		while(TARGET "${sTargetMODULE}")
			set(sTargetMODULE "${sTargetMODULE}_mod")
		endwhile()
		if(NOT bArgNO_INSTALL)
			nx_append(${NX_PROJECT_NAME}_TARGETS_MODULE "${sTargetMODULE}")
		endif()
		nx_append(${vTargetList} "${sTargetMODULE}")

		add_library("${sTargetMODULE}" MODULE)
		set_target_properties("${sTargetMODULE}" PROPERTIES OUTPUT_NAME "${sOutputMODULE}")
		nx_target_compile_definitions(
			"${sTargetMODULE}"
			PRIVATE ${lsArgINTERNAL_DEFINES}
			PUBLIC ${lsArgPUBLIC_DEFINES}
			INTERFACE ${lsArgINTERFACE_DEFINES}
			DEFINE_SYMBOL ${sArgDEFINE_SYMBOL})
		nx_target_compile_features(
			"${sTargetMODULE}"
			PRIVATE ${lsArgPRIVATE_FEATURES}
			PUBLIC ${lsArgPUBLIC_FEATURES}
			INTERFACE ${lsArgINTERFACE_FEATURES})
		nx_target_compile_options(
			"${sTargetMODULE}"
			PRIVATE ${lsArgINTERNAL_CFLAGS} ${lsArgINTERNAL_CXXFLAGS} ${lsThinLTO_CFLAGS}
			PUBLIC ${lsArgPUBLIC_CFLAGS} ${lsArgPUBLIC_CXXFLAGS}
			INTERFACE ${lsArgINTERFACE_CFLAGS} ${lsArgINTERFACE_CXXFLAGS})
		nx_target_include_directories(
			"${sTargetMODULE}" ${sNO_INSTALL}
			PRIVATE ${lsArgPRIVATE_INCLUDES}
			PUBLIC ${lsArgPUBLIC_INCLUDES}
			INTERFACE ${lsArgINTERFACE_INCLUDES})
		if(NX_TARGET_PLATFORM_MSDOS)
			nx_target_link_libraries(
				"${sTargetMODULE}"
				PRIVATE ${lsArgDXELIB_DEPENDS} ${lsLibDepsDXELIB_SHARED}
				PUBLIC ${lsArgPRIVATE_DEPENDS} ${lsArgPUBLIC_DEPENDS} ${lsLibDepsPRIVATE_SHARED} ${lsLibDepsPUBLIC_SHARED}
						${lst_general_libs}
				INTERFACE ${lsArgINTERFACE_DEPENDS} ${lsLibDepsINTERFACE_SHARED})
			nx_target_link_options(
				"${sTargetMODULE}"
				PRIVATE ${lsArgDXEFLAGS} ${lsArgDXELIBS}
				INTERFACE ${lsArgPUBLIC_LDFLAGS} ${lsArgINTERFACE_LDFLAGS})
		else()
			nx_target_link_libraries(
				"${sTargetMODULE}"
				PRIVATE ${lsArgPRIVATE_DEPENDS} ${lsLibDepsPRIVATE_SHARED}
				PUBLIC ${lsArgPUBLIC_DEPENDS} ${lsLibDepsPUBLIC_SHARED}
				INTERFACE ${lsArgINTERFACE_DEPENDS} ${lsLibDepsINTERFACE_SHARED})
			nx_target_link_options(
				"${sTargetMODULE}"
				PRIVATE ${lsArgINTERNAL_LDFLAGS} ${lsThinLTO_LDFLAGS}
				PUBLIC ${lsArgPUBLIC_LDFLAGS}
				INTERFACE ${lsArgINTERFACE_LDFLAGS})
		endif()
		nx_target_sources(
			"${sTargetMODULE}" ${sNO_INSTALL}
			PRIVATE ${lsArgPRIVATE_SOURCES}
			PUBLIC ${lsArgPUBLIC_SOURCES}
			INTERFACE ${lsArgINTERFACE_SOURCES}
			STRIP ${lsArgSTRIP})

		if(INSTALL_TARGETS${NX_PROJECT_NAME} AND NOT bArgNO_INSTALL)
			if(sArgTYPE STREQUAL "APPLICATION")
				set_target_properties("${sTargetMODULE}" PROPERTIES INSTALL_RPATH "${CMAKE_INSTALL_RPATH}/${NX_INSTALL_RPATH_APPLICATIONS}")
				nx_set(${NX_PROJECT_NAME}_COMPONENT_APP ON)
				install(
					TARGETS "${sTargetMODULE}"
					COMPONENT ${NX_PROJECT_NAME}_APP
					DESTINATION "${NX_INSTALL_PATH_APPLICATIONS}")
				nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATH_APPLICATIONS}/${sFileMODULE}")
				nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATH_APPLICATIONS}")
			else()
				set_target_properties("${sTargetMODULE}" PROPERTIES INSTALL_RPATH "${CMAKE_INSTALL_RPATH}/${NX_INSTALL_RPATH_MODULES}")
				nx_set(${NX_PROJECT_NAME}_COMPONENT_MOD ON)
				install(
					TARGETS "${sTargetMODULE}"
					COMPONENT ${NX_PROJECT_NAME}_MOD
					DESTINATION "${NX_INSTALL_PATH_MODULES}")
				nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATH_MODULES}/${sFileMODULE}")
				nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATH_MODULES}")
			endif()
		endif()
	endif()

	# === Build Shared Library ===

	if(DEFINED sTargetSHARED)
		while(TARGET "${sTargetSHARED}")
			set(sTargetSHARED "${sTargetSHARED}_dll")
		endwhile()
		if(NOT bArgNO_INSTALL)
			nx_append(${NX_PROJECT_NAME}_TARGETS_SHARED "${sTargetSHARED}")
		endif()
		nx_append(${vTargetList} "${sTargetSHARED}")

		add_library("${sTargetSHARED}" SHARED)
		set_target_properties("${sTargetSHARED}" PROPERTIES OUTPUT_NAME "${sOutputSHARED}")
		nx_target_compile_definitions(
			"${sTargetSHARED}"
			PRIVATE ${lsArgINTERNAL_DEFINES}
			PUBLIC ${lsArgPUBLIC_DEFINES}
			INTERFACE ${lsArgINTERFACE_DEFINES}
			DEFINE_SYMBOL ${sArgDEFINE_SYMBOL})
		nx_target_compile_features(
			"${sTargetSHARED}"
			PRIVATE ${lsArgPRIVATE_FEATURES}
			PUBLIC ${lsArgPUBLIC_FEATURES}
			INTERFACE ${lsArgINTERFACE_FEATURES})
		nx_target_compile_options(
			"${sTargetSHARED}"
			PRIVATE ${lsArgINTERNAL_CFLAGS} ${lsArgINTERNAL_CXXFLAGS} ${lsThinLTO_CFLAGS}
			PUBLIC ${lsArgPUBLIC_CFLAGS} ${lsArgPUBLIC_CXXFLAGS}
			INTERFACE ${lsArgINTERFACE_CFLAGS} ${lsArgINTERFACE_CXXFLAGS})
		nx_target_include_directories(
			"${sTargetSHARED}"
			PRIVATE ${lsArgPRIVATE_INCLUDES}
			PUBLIC ${lsArgPUBLIC_INCLUDES}
			INTERFACE ${lsArgINTERFACE_INCLUDES} ${sNO_INSTALL})
		if(NX_TARGET_PLATFORM_MSDOS)
			nx_target_link_libraries(
				"${sTargetSHARED}"
				PRIVATE ${lsArgDXELIB_DEPENDS} ${lsLibDepsDXELIB_SHARED}
				PUBLIC ${lsArgPRIVATE_DEPENDS} ${lsArgPUBLIC_DEPENDS} ${lsLibDepsPRIVATE_SHARED} ${lsLibDepsPUBLIC_SHARED}
						${lst_general_libs}
				INTERFACE ${lsArgINTERFACE_DEPENDS} ${lsLibDepsINTERFACE_SHARED})
			nx_target_link_options(
				"${sTargetSHARED}"
				PRIVATE ${lsArgDXEFLAGS} ${lsArgDXELIBS}
				INTERFACE ${lsArgPUBLIC_LDFLAGS} ${lsArgINTERFACE_LDFLAGS})
		else()
			nx_target_link_libraries(
				"${sTargetSHARED}"
				PRIVATE ${lsArgPRIVATE_DEPENDS} ${lsLibDepsPRIVATE_SHARED}
				PUBLIC ${lsArgPUBLIC_DEPENDS} ${lsLibDepsPUBLIC_SHARED}
				INTERFACE ${lsArgINTERFACE_DEPENDS} ${lsLibDepsINTERFACE_SHARED})
			nx_target_link_options(
				"${sTargetSHARED}"
				PRIVATE ${lsArgINTERNAL_LDFLAGS} ${lsThinLTO_LDFLAGS}
				PUBLIC ${lsArgPUBLIC_LDFLAGS}
				INTERFACE ${lsArgINTERFACE_LDFLAGS})
		endif()
		nx_target_sources(
			"${sTargetSHARED}"
			PRIVATE ${lsArgPRIVATE_SOURCES}
			PUBLIC ${lsArgPUBLIC_SOURCES}
			INTERFACE ${lsArgINTERFACE_SOURCES}
			STRIP ${lsArgSTRIP} ${sNO_INSTALL})

		if(NX_TARGET_PLATFORM_MSDOS)
			if(NX_HOST_LANGUAGE_CXX AND lsArgPRIVATE_SOURCES MATCHES "[.]cc$|[.]cpp$|[.]cxx$|[.]cc;|[.]cpp;|[.]cxx;")
				nx_target_link_libraries("${sTargetSHARED}" INTERFACE "stdc++")
			endif()
		endif()
		if(NX_TARGET_PLATFORM_MSDOS AND DEFINED CMAKE_DXE3RES)
			set(sDXEResOutput "${CMAKE_CURRENT_BINARY_DIR}/${sOutputSHARED}${CMAKE_SHARED_LIBRARY_SUFFIX}.c")
			set(sDXEResCompiled "${CMAKE_CURRENT_BINARY_DIR}/${sOutputSHARED}${CMAKE_SHARED_LIBRARY_SUFFIX}.o")
			if(NOT EXISTS "${sDXEResCompiled}")
				file(WRITE "${sDXEResCompiled}" "")
			endif()
			if(NX_HOST_LANGUAGE_C)
				add_custom_command(
					TARGET "${sTargetSHARED}"
					POST_BUILD
					COMMENT "[dxe3res] Generating '${sOutputSHARED}${CMAKE_SHARED_LIBRARY_SUFFIX}.o'"
					COMMAND "${CMAKE_DXE3RES}" -o "${sDXEResOutput}" "$<TARGET_FILE:${sTargetSHARED}>"
					COMMAND "${CMAKE_C_COMPILER}" -c -O2 -o "${sDXEResCompiled}" "${sDXEResOutput}")
			elseif(NX_HOST_LANGUAGE_CXX)
				add_custom_command(
					TARGET "${sTargetSHARED}"
					POST_BUILD
					COMMENT "[dxe3res] Generating '${sOutputSHARED}${CMAKE_SHARED_LIBRARY_SUFFIX}.o'"
					COMMAND "${CMAKE_DXE3RES}" -o "${sDXEResOutput}" "$<TARGET_FILE:${sTargetSHARED}>"
					COMMAND "${CMAKE_CXX_COMPILER}" -c -O2 -o "${sDXEResCompiled}" "${sDXEResOutput}")
			endif()
			nx_target_sources("${sTargetSHARED}" INTERFACE "${sDXEResCompiled}")
		endif()

		if(bUseSOVERSION)
			set_target_properties(
				"${sTargetSHARED}" PROPERTIES
				SOVERSION "${${NX_PROJECT_NAME}_PROJECT_SOVERSION_COMPAT}"
				VERSION "${${NX_PROJECT_NAME}_PROJECT_SOVERSION}")
		elseif(DEFINED ${NX_PROJECT_NAME}_PROJECT_SOVERSION)
			set_target_properties("${sTargetSHARED}" PROPERTIES VERSION "${${NX_PROJECT_NAME}_PROJECT_SOVERSION}")
		elseif(DEFINED ${NX_PROJECT_NAME}_PROJECT_VERSION)
			set_target_properties("${sTargetSHARED}" PROPERTIES VERSION "${${NX_PROJECT_NAME}_PROJECT_VERSION}")
		endif()

		if(NX_TARGET_PLATFORM_DARWIN)
			if(DEFINED ${NX_PROJECT_NAME}_PROJECT_OSX_COMPAT)
				set_target_properties("${sTargetSHARED}" PROPERTIES MACHO_COMPATIBILITY_VERSION "${${NX_PROJECT_NAME}_PROJECT_OSX_COMPAT}")
			endif()
			if(DEFINED ${NX_PROJECT_NAME}_PROJECT_OSX)
				set_target_properties("${sTargetSHARED}" PROPERTIES MACHO_CURRENT_VERSION "${${NX_PROJECT_NAME}_PROJECT_OSX}")
			endif()
		endif()

		if(INSTALL_TARGETS${NX_PROJECT_NAME} AND NOT bArgNO_INSTALL)
			if(bFormatDJCOFF OR bFormatWinPE)
				nx_set(${NX_PROJECT_NAME}_COMPONENT_LIB ON)
				nx_set(${NX_PROJECT_NAME}_COMPONENT_OBJ ON)
				install(
					TARGETS "${sTargetSHARED}"
					EXPORT "${NX_PROJECT_NAME}"
					RUNTIME COMPONENT ${NX_PROJECT_NAME}_LIB DESTINATION "${NX_INSTALL_PATH_BINARIES}"
					ARCHIVE COMPONENT ${NX_PROJECT_NAME}_OBJ DESTINATION "${NX_INSTALL_PATH_STATIC}")
				nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATH_BINARIES}/${sFileSHARED}")
				nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATH_STATIC}/${sFileIMPORT}")
				nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATH_BINARIES}")
				nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATH_STATIC}")
			elseif(bUseSOVERSION)
				nx_set(${NX_PROJECT_NAME}_COMPONENT_LIB ON)
				nx_set(${NX_PROJECT_NAME}_COMPONENT_OBJ ON)
				install(
					TARGETS "${sTargetSHARED}"
					EXPORT "${NX_PROJECT_NAME}"
					LIBRARY COMPONENT ${NX_PROJECT_NAME}_LIB
							NAMELINK_COMPONENT ${NX_PROJECT_NAME}_OBJ
							DESTINATION "${NX_INSTALL_PATH_LIBRARIES}")
				nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATH_LIBRARIES}/${sFileSHARED}")
				nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATH_LIBRARIES}/${sFileSONAME1}")
				nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATH_LIBRARIES}/${sFileSONAME2}")
				nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATH_LIBRARIES}")
			else()
				nx_set(${NX_PROJECT_NAME}_COMPONENT_LIB ON)
				install(
					TARGETS "${sTargetSHARED}"
					EXPORT "${NX_PROJECT_NAME}"
					LIBRARY COMPONENT ${NX_PROJECT_NAME}_LIB DESTINATION "${NX_INSTALL_PATH_LIBRARIES}")
				nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATH_LIBRARIES}/${sFileSHARED}")
				nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATH_LIBRARIES}")
			endif()
		endif()
	endif()

	# === Destroy DXEFLAGS ===

	if(NX_TARGET_PLATFORM_MSDOS)
		list(APPEND lsLibDepsPRIVATE_SHARED ${lsLibDepsDXELIB_SHARED})
		list(APPEND lsArgPRIVATE_DEPENDS ${lsArgDXELIB_DEPENDS})
	endif()

	# === Build Static Library ===

	list(APPEND lsArgPUBLIC_DEPENDS ${lsArgPRIVATE_DEPENDS})
	list(APPEND lsArgINTERFACE_LDFLAGS ${lsArgPUBLIC_LDFLAGS} ${lsArgPRIVATE_LDFLAGS})

	list(APPEND lsLibDepsPUBLIC_SHARED ${lsLibDepsPRIVATE_SHARED})
	list(APPEND lsLibDepsPUBLIC_STATIC ${lsLibDepsPRIVATE_STATIC})
	list(APPEND lsLibDepsPUBLIC_INTERFACE ${lsLibDepsPRIVATE_INTERFACE})

	if(DEFINED sTargetSTATIC)
		while(TARGET "${sTargetSTATIC}")
			set(sTargetSTATIC "${sTargetSTATIC}_lib")
		endwhile()
		if(NOT bArgNO_INSTALL)
			nx_append(${NX_PROJECT_NAME}_TARGETS_STATIC "${sTargetSTATIC}")
		endif()
		nx_append(${vTargetList} "${sTargetSTATIC}")

		add_library("${sTargetSTATIC}" STATIC)
		set_target_properties("${sTargetSTATIC}" PROPERTIES OUTPUT_NAME "${sOutputSTATIC}")
		nx_target_compile_definitions(
			"${sTargetSTATIC}"
			PRIVATE ${lsArgINTERNAL_DEFINES}
			PUBLIC ${lsArgPUBLIC_DEFINES}
			INTERFACE ${lsArgINTERFACE_DEFINES}
			DEFINE_SYMBOL ${sArgDEFINE_SYMBOL}
			STATIC_DEFINE ${sArgSTATIC_DEFINE})
		nx_target_compile_features(
			"${sTargetSTATIC}"
			PRIVATE ${lsArgPRIVATE_FEATURES}
			PUBLIC ${lsArgPUBLIC_FEATURES}
			INTERFACE ${lsArgINTERFACE_FEATURES})
		nx_target_compile_options(
			"${sTargetSTATIC}"
			PRIVATE ${lsArgINTERNAL_CFLAGS} ${lsArgINTERNAL_CXXFLAGS} ${lsFullLTO_CFLAGS}
			PUBLIC ${lsArgPUBLIC_CFLAGS} ${lsArgPUBLIC_CXXFLAGS}
			INTERFACE ${lsArgINTERFACE_CFLAGS} ${lsArgINTERFACE_CXXFLAGS})
		nx_target_include_directories(
			"${sTargetSTATIC}" ${sNO_INSTALL}
			PRIVATE ${lsArgPRIVATE_INCLUDES}
			PUBLIC ${lsArgPUBLIC_INCLUDES}
			INTERFACE ${lsArgINTERFACE_INCLUDES})
		nx_target_link_libraries(
			"${sTargetSTATIC}"
			PUBLIC ${lsArgPUBLIC_DEPENDS} ${lsLibDepsPUBLIC_STATIC}
			INTERFACE ${lsArgINTERFACE_DEPENDS} ${lsLibDepsINTERFACE_STATIC})
		nx_target_link_options(
			"${sTargetSTATIC}"
			STATIC ${lsArgSTATIC_LDFLAGS}
			INTERFACE ${lsArgINTERFACE_LDFLAGS})
		nx_target_sources(
			"${sTargetSTATIC}" ${sNO_INSTALL}
			PRIVATE ${lsArgPRIVATE_SOURCES}
			PUBLIC ${lsArgPUBLIC_SOURCES}
			INTERFACE ${lsArgINTERFACE_SOURCES}
			STRIP ${lsArgSTRIP})

		if(INSTALL_TARGETS${NX_PROJECT_NAME} AND NOT bArgNO_INSTALL)
			nx_set(${NX_PROJECT_NAME}_COMPONENT_OBJ ON)
			install(
				TARGETS "${sTargetSTATIC}"
				EXPORT "${NX_PROJECT_NAME}"
				COMPONENT ${NX_PROJECT_NAME}_OBJ
				DESTINATION "${NX_INSTALL_PATH_STATIC}")
			nx_append_global(NX_CLEANUP_DELETE "${NX_INSTALL_PATH_STATIC}/${sFileSTATIC}")
			nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATH_STATIC}")
		endif()
	endif()

	# === Build Object Library ===

	if(DEFINED sTargetOBJECTS)
		while(TARGET "${sTargetOBJECTS}")
			set(sTargetOBJECTS "${sTargetOBJECTS}_obj")
		endwhile()
		if(NOT bArgNO_INSTALL)
			nx_append(${NX_PROJECT_NAME}_TARGETS_OBJECTS "${sTargetOBJECTS}")
		endif()
		nx_append(${vTargetList} "${sTargetOBJECTS}")

		add_library("${sTargetOBJECTS}" OBJECT)
		set_target_properties("${sTargetOBJECTS}" PROPERTIES OUTPUT_NAME "${sOutputOBJECTS}")
		nx_target_compile_definitions(
			"${sTargetOBJECTS}"
			PRIVATE ${lsArgiNTERNAL_DEFINES}
			PUBLIC ${lsArgPUBLIC_DEFINES}
			INTERFACE ${lsArgINTERFACE_DEFINES}
			DEFINE_SYMBOL ${sArgDEFINE_SYMBOL}
			STATIC_DEFINE ${sArgSTATIC_DEFINE})
		nx_target_compile_features(
			"${sTargetOBJECTS}"
			PRIVATE ${lsArgPRIVATE_FEATURES}
			PUBLIC ${lsArgPUBLIC_FEATURES}
			INTERFACE ${lsArgINTERFACE_FEATURES})
		nx_target_compile_options(
			"${sTargetOBJECTS}"
			PRIVATE ${lsArgINTERNAL_CFLAGS} ${lsArgINTERNAL_CXXFLAGS} ${lsFullLTO_CFLAGS}
			PUBLIC ${lsArgPUBLIC_CFLAGS} ${lsArgPUBLIC_CXXFLAGS}
			INTERFACE ${lsArgINTERFACE_CFLAGS} ${lsArgINTERFACE_CXXFLAGS})
		nx_target_include_directories(
			"${sTargetOBJECTS}" ${sNO_INSTALL}
			PRIVATE ${lsArgPRIVATE_INCLUDES}
			PUBLIC ${lsArgPUBLIC_INCLUDES}
			INTERFACE ${lsArgINTERFACE_INCLUDES})
		nx_target_link_libraries(
			"${sTargetOBJECTS}"
			PUBLIC ${lsArgPUBLIC_DEPENDS}
			INTERFACE ${lsArgINTERFACE_DEPENDS})
		nx_target_link_options("${sTargetOBJECTS}" INTERFACE ${lsArgINTERFACE_LDFLAGS})
		nx_target_sources(
			"${sTargetOBJECTS}" ${sNO_INSTALL}
			PRIVATE ${lsArgPRIVATE_SOURCES}
			PUBLIC ${lsArgPUBLIC_SOURCES}
			INTERFACE ${lsArgINTERFACE_SOURCES}
			STRIP ${lsArgSTRIP})

		if(INSTALL_TARGETS${NX_PROJECT_NAME} AND NOT bArgNO_INSTALL)
			nx_set(${NX_PROJECT_NAME}_COMPONENT_OBJ ON)
			install(
				TARGETS "${sTargetOBJECTS}"
				EXPORT "${NX_PROJECT_NAME}"
				COMPONENT ${NX_PROJECT_NAME}_OBJ
				DESTINATION "${NX_INSTALL_PATH_STATIC}")
			nx_append_global(NX_CLEANUP_RMDIR_F "${NX_INSTALL_PATH_STATIC}/objects-${CMAKE_BUILD_TYPE}/${sTargetOBJECTS}")
		endif()
	endif()

	# === Configure Interface Library ===

	list(APPEND lsArgINTERFACE_DEFINES ${lsArgPUBLIC_DEFINES} ${lsArgPRIVATE_DEFINES})
	list(APPEND lsArgINTERFACE_FEATURES ${lsArgPUBLIC_FEATURES} ${lsArgPRIVATE_FEATURES})
	list(APPEND lsArgINTERFACE_CFLAGS ${lsArgPUBLIC_CFLAGS} ${lsArgPRIVATE_CFLAGS})
	list(APPEND lsArgINTERFACE_CXXFLAGS ${lsArgPUBLIC_CXXFLAGS} ${lsArgPRIVATE_CXXFLAGS})
	list(APPEND lsArgINTERFACE_INCLUDES ${lsArgPUBLIC_INCLUDES} ${lsArgPRIVATE_INCLUDES})
	list(APPEND lsArgINTERFACE_DEPENDS ${lsArgPUBLIC_DEPENDS})
	list(APPEND lsArgINTERFACE_SOURCES ${lsArgPUBLIC_SOURCES} ${lsArgPRIVATE_SOURCES})

	list(APPEND lsLibDepsINTERFACE_SHARED ${lsLibDepsPUBLIC_SHARED})
	list(APPEND lsLibDepsINTERFACE_STATIC ${lsLibDepsPUBLIC_STATIC})
	list(APPEND lsLibDepsINTERFACE_INTERFACE ${lsLibDepsPUBLIC_INTERFACE})

	if(DEFINED sTargetINTERFACE)
		while(TARGET "${sTargetINTERFACE}")
			set(sTargetINTERFACE "${sTargetINTERFACE}_src")
		endwhile()
		if(NOT bArgNO_INSTALL)
			nx_append(${NX_PROJECT_NAME}_TARGETS_INTERFACE "${sTargetINTERFACE}")
		endif()
		nx_append(${vTargetList} "${sTargetINTERFACE}")

		add_library("${sTargetINTERFACE}" INTERFACE)
		nx_target_compile_definitions(
			"${sTargetINTERFACE}"
			INTERFACE ${lsArgINTERFACE_DEFINES}
			DEFINE_SYMBOL ${sArgDEFINE_SYMBOL}
			STATIC_DEFINE ${sArgSTATIC_DEFINE})
		nx_target_compile_features("${sTargetINTERFACE}" INTERFACE ${lsArgINTERFACE_FEATURES})
		nx_target_compile_options("${sTargetINTERFACE}" INTERFACE ${lsArgINTERFACE_CFLAGS} ${lsArgINTERFACE_CXXFLAGS})
		nx_target_include_directories("${sTargetINTERFACE}" ${sNO_INSTALL} INTERFACE ${lsArgINTERFACE_INCLUDES})
		nx_target_link_libraries("${sTargetINTERFACE}" INTERFACE ${lsArgINTERFACE_DEPENDS} ${lsLibDepsINTERFACE_INTERFACE})
		nx_target_link_options("${sTargetINTERFACE}" INTERFACE ${lsArgINTERFACE_LDFLAGS})
		nx_target_sources(
			"${sTargetINTERFACE}" ${sNO_INSTALL}
			INTERFACE ${lsArgINTERFACE_SOURCES}
			STRIP ${lsArgSTRIP})

		if(INSTALL_TARGETS${NX_PROJECT_NAME} AND NOT bArgNO_INSTALL)
			install(TARGETS "${sTargetINTERFACE}" EXPORT "${NX_PROJECT_NAME}")
		endif()
	endif()

	# === Add Target Alias ===

	if(NOT bArgNO_INSTALL)
		foreach(sType "SHARED" "STATIC" "OBJECTS" "INTERFACE")
			if(DEFINED sTarget${sType})
				add_library(${${NX_PROJECT_NAME}_PROJECT_PARENT}::${sTarget${sType}} ALIAS ${sTarget${sType}})
				nx_append(${NX_PROJECT_NAME}_TARGLIST_EXPORT "${sTarget${sType}}")
			endif()
		endforeach()
	endif()

	# === Post-Build Steps ===

	unset(lsPostBuildEXECUTABLE)
	unset(lsPostBuildMODULE)
	unset(lsPostBuildSHARED)

	if(sArgTYPE STREQUAL "APPLICATION")
		set(sDPATH "${NX_INSTALL_DPATH_APPLICATIONS}")
	elseif(sArgTYPE STREQUAL "DAEMON")
		set(sDPATH "${NX_INSTALL_DPATH_DAEMONS}")
	elseif(sArgTYPE STREQUAL "EXECUTABLE")
		set(sDPATH "${NX_INSTALL_DPATH_BINARIES}")
	elseif(sArgTYPE STREQUAL "SHARED_MODULE" OR sArgTYPE STREQUAL "MODULE")
		set(sDPATH "${NX_INSTALL_DPATH_MODULES}")
	else()
		set(sDPATH "${NX_INSTALL_DPATH_LIBRARIES}")
	endif()

	if(NX_TARGET_BUILD_DEBUG OR NX_TARGET_BUILD_RELEASE)
		if(NX_HOST_COMPILER_MSVC)
			foreach(sType "EXECUTABLE" "MODULE" "SHARED")
				if(DEFINED sTarget${sType}
					AND INSTALL_TARGETS${NX_PROJECT_NAME}
					AND NOT bArgNO_INSTALL)
					get_filename_component(sFileNoExt "${sFile${sType}}" NAME_WLE)
					nx_set(${NX_PROJECT_NAME}_COMPONENT_DBG ON)
					install(
						FILES "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/${sFileNoExt}.pdb"
						DESTINATION "${sDPATH}"
						COMPONENT ${NX_PROJECT_NAME}_DBG)
					nx_append_global(NX_CLEANUP_DELETE "${sDPATH}/${sFileNoExt}.pdb")
					nx_append_global(NX_CLEANUP_RMDIR "${sDPATH}")
				endif()
			endforeach()
		elseif(
			DEFINED CMAKE_OBJCOPY
			AND EXISTS "${CMAKE_OBJCOPY}"
			AND NOT NX_TARGET_PLATFORM_ANDROID
			AND NOT NX_TARGET_PLATFORM_MSDOS)
			foreach(sType "EXECUTABLE" "MODULE" "SHARED")
				if(DEFINED sTarget${sType}
					AND INSTALL_TARGETS${NX_PROJECT_NAME}
					AND NOT bArgNO_INSTALL)
					list(
						APPEND
						lsPostBuild${sType}
						COMMAND
						"${CMAKE_OBJCOPY}"
						"--only-keep-debug"
						"$<TARGET_FILE:${sTarget${sType}}>"
						"$<TARGET_FILE:${sTarget${sType}}>.debug"
						COMMAND
						"${CMAKE_OBJCOPY}"
						"--strip-debug"
						"$<TARGET_FILE:${sTarget${sType}}>"
						COMMAND
						"${CMAKE_OBJCOPY}"
						"--add-gnu-debuglink"
						"$<TARGET_FILE:${sTarget${sType}}>.debug"
						"$<TARGET_FILE:${sTarget${sType}}>")

					nx_set(${NX_PROJECT_NAME}_COMPONENT_DBG ON)
					install(
						FILES "${CMAKE_CURRENT_BINARY_DIR}/${sFile${sType}}.debug"
						DESTINATION "${sDPATH}"
						COMPONENT ${NX_PROJECT_NAME}_DBG)
					nx_append_global(NX_CLEANUP_DELETE "${sDPATH}/${sFile${sType}}.debug")
					nx_append_global(NX_CLEANUP_RMDIR "${sDPATH}")
				endif()
			endforeach()
		endif()
	endif()

	if(bFormatWinPE
		AND INSTALL_TARGETS${NX_PROJECT_NAME}
		AND NOT bArgNO_INSTALL
		AND NOT NX_TARGET_BUILD_DEBUG)
		unset(sPFXCertificate)
		unset(sPFXPassword)
		unset(sPFXPassFile)

		if(DEFINED PKCS12_CERTIFICATE AND EXISTS "${PKCS12_CERTIFICATE}")
			set(sPFXCertificate "${PKCS12_CERTIFICATE}")
		elseif(NOT "x$ENV{PKCS12_CERTIFICATE}" STREQUAL "x" AND EXISTS "$ENV{PKCS12_CERTIFICATE}")
			set(sPFXCertificate "$ENV{PKCS12_CERTIFICATE}")
		endif()

		if(DEFINED PKCS12_PASSFILE AND EXISTS "${PKCS12_PASSFILE}")
			set(sPFXPassFile "${PKCS12_PASSFILE}")
		elseif(DEFINED PKCS12_PASSWORD)
			set(sPFXPassword "${PKCS12_PASSWORD}")
		elseif(NOT "x$ENV{PKCS12_PASSFILE}" STREQUAL "x" AND EXISTS "$ENV{PKCS12_PASSFILE}")
			set(sPFXPassFile "$ENV{PKCS12_PASSFILE}")
		elseif(NOT "x$ENV{PKCS12_PASSWORD}" STREQUAL "x")
			set(sPFXPassword "$ENV{PKCS12_PASSWORD}")
		elseif(DEFINED sPFXCertificate AND EXISTS "${sPFXCertificate}cred")
			set(sPFXPassFile "${sPFXCertificate}cred")
		endif()

		if(DEFINED sPFXCertificate)
			find_program(OSSLSIGNCODE_EXECUTABLE NAMES "osslsigncode")
			cmake_dependent_option(DIGSIGN_TARGETS${NX_PROJECT_NAME} "Digitally-Sign Targets - ${PROJECT_NAME}" ON
									"OSSLSIGNCODE_EXECUTABLE" OFF)

			if(DIGSIGN_TARGETS${NX_PROJECT_NAME})
				unset(lsPFXArgs)
				if(DEFINED sPFXPassFile)
					list(APPEND lsPFXArgs "-readpass" "${sPFXPassFile}")
				elseif(DEFINED sPFXPassword)
					list(APPEND lsPFXArgs "-pass" "${sPFXPassword}")
				endif()

				foreach(sType "EXECUTABLE" "MODULE" "SHARED")
					if(DEFINED sTarget${sType})
						list(
							APPEND
							lsPostBuild${sType}
							COMMAND
							"${OSSLSIGNCODE_EXECUTABLE}"
							"sign"
							"-pkcs12"
							"${sPFXCertificate}"
							${lsPFXArgs}
							"-ts"
							"http://timestamp.digicert.com"
							"-h"
							"sha1"
							"-in"
							"$<TARGET_FILE:${sTarget${sType}}>"
							"-out"
							"$<TARGET_FILE:${sTarget${sType}}>.signed"
							COMMAND
							"${CMAKE_COMMAND};-E;remove;$<TARGET_FILE:${sTarget${sType}}>"
							COMMAND
							"${OSSLSIGNCODE_EXECUTABLE}"
							"sign"
							"-pkcs12"
							"${sPFXCertificate}"
							${lsPFXArgs}
							"-ts"
							"http://timestamp.digicert.com"
							"-nest"
							"-h"
							"sha256"
							"-in"
							"$<TARGET_FILE:${sTarget${sType}}>.signed"
							"-out"
							"$<TARGET_FILE:${sTarget${sType}}>"
							COMMAND
							"${CMAKE_COMMAND};-E;remove;$<TARGET_FILE:${sTarget${sType}}>.signed")
					endif()
				endforeach()
			endif()
		endif()

		unset(lsPFXArgs)
		unset(sPFXPassword)
		unset(sPFXPassFile)
	endif()

	foreach(sType "EXECUTABLE" "MODULE" "SHARED")
		if(DEFINED sTarget${sType} AND DEFINED lsPostBuild${sType})
			add_custom_command(
				TARGET ${sTarget${sType}}
				POST_BUILD ${lsPostBuild${sType}}
				WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
				COMMENT "[cmake] Post-Build: ${sTarget${sType}}"
				VERBATIM)
		endif()
	endforeach()

	_nx_function_end()
endfunction()

# ===================================================================

function(nx_target_export)
	_nx_guard_function(nx_target_export)
	_nx_function_begin()

	if(DEFINED ${NX_PROJECT_NAME}_TARGLIST_EXPORT)
		unset(sVersionSuffix)
		set(sExportCompatibility "AnyNewerVersion")
		if(DEFINED ${NX_PROJECT_NAME}_PROJECT_VERSION_COMPAT)
			if("${${NX_PROJECT_NAME}_PROJECT_VERSION_COMPAT}"
				STREQUAL
				"${${NX_PROJECT_NAME}_PROJECT_VERSION_MAJOR}.${${NX_PROJECT_NAME}_PROJECT_VERSION_MINOR}.${${NX_PROJECT_NAME}_PROJECT_VERSION_PATCH}"
			)
				set(sExportCompatibility "ExactVersion")
			elseif("${${NX_PROJECT_NAME}_PROJECT_VERSION_COMPAT}" STREQUAL
					"${${NX_PROJECT_NAME}_PROJECT_VERSION_MAJOR}.${${NX_PROJECT_NAME}_PROJECT_VERSION_MINOR}")
				set(sExportCompatibility "SameMinorVersion")
			elseif("${${NX_PROJECT_NAME}_PROJECT_VERSION_COMPAT}" STREQUAL "${${NX_PROJECT_NAME}_PROJECT_VERSION_MAJOR}")
				set(sExportCompatibility "SameMajorVersion")
			endif()
			set(sVersionSuffix "-${${NX_PROJECT_NAME}_PROJECT_VERSION_COMPAT}")
		elseif(DEFINED ${NX_PROJECT_NAME}_PROJECT_SOVERSION_COMPAT)
			if("${${NX_PROJECT_NAME}_PROJECT_SOVERSION_COMPAT}"
				STREQUAL
				"${${NX_PROJECT_NAME}_PROJECT_SOVERSION_MAJOR}.${${NX_PROJECT_NAME}_PROJECT_SOVERSION_MINOR}.${${NX_PROJECT_NAME}_PROJECT_SOVERSION_PATCH}"
			)
				set(sExportCompatibility "ExactVersion")
			elseif("${${NX_PROJECT_NAME}_PROJECT_SOVERSION_COMPAT}" STREQUAL
					"${${NX_PROJECT_NAME}_PROJECT_SOVERSION_MAJOR}.${${NX_PROJECT_NAME}_PROJECT_SOVERSION_MINOR}")
				set(sExportCompatibility "SameMinorVersion")
			elseif("${${NX_PROJECT_NAME}_PROJECT_SOVERSION_COMPAT}" STREQUAL "${${NX_PROJECT_NAME}_PROJECT_SOVERSION_MAJOR}")
				set(sExportCompatibility "SameMajorVersion")
			endif()
			set(sVersionSuffix "-${${NX_PROJECT_NAME}_PROJECT_SOVERSION_COMPAT}")
		endif()

		set(sExportComponent "DEV")
		if(DEFINED ${NX_PROJECT_NAME}_COMPONENT_OBJ AND ${NX_PROJECT_NAME}_COMPONENT_OBJ)
			set(sExportComponent "OBJ")
		endif()
		if(DEFINED ${NX_PROJECT_NAME}_COMPONENT_LIB AND ${NX_PROJECT_NAME}_COMPONENT_LIB)
			set(sExportComponent "LIB")
		endif()

		export(
			EXPORT "${NX_PROJECT_NAME}"
			NAMESPACE "${${NX_PROJECT_NAME}_PROJECT_PARENT}::"
			FILE "${PROJECT_NAME}Config.cmake")

		if(INSTALL_TARGETS${NX_PROJECT_NAME})
			nx_set(${NX_PROJECT_NAME}_COMPONENT_${sExportComponent} ON)
			install(
				EXPORT "${NX_PROJECT_NAME}"
				NAMESPACE "${${NX_PROJECT_NAME}_PROJECT_PARENT}::"
				FILE "${PROJECT_NAME}Config.cmake"
				DESTINATION "${NX_INSTALL_PATH_EXPORT}/${PROJECT_NAME}${sVersionSuffix}"
				COMPONENT ${NX_PROJECT_NAME}_${sExportComponent})
			nx_append_global(NX_CLEANUP_RMDIR_F "${NX_INSTALL_PATH_EXPORT}/${PROJECT_NAME}${sVersionSuffix}")
		endif()

		if(DEFINED sVersionSuffix)
			write_basic_package_version_file(
				"${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
				VERSION "${${NX_PROJECT_NAME}_PROJECT_VERSION}"
				COMPATIBILITY "${sExportCompatibility}")
			if(INSTALL_TARGETS${NX_PROJECT_NAME})
				nx_set(${NX_PROJECT_NAME}_COMPONENT_${sExportComponent} ON)
				install(
					FILES "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
					DESTINATION "${NX_INSTALL_PATH_EXPORT}/${PROJECT_NAME}${sVersionSuffix}"
					COMPONENT ${NX_PROJECT_NAME}_${sExportComponent})
				nx_append_global(NX_CLEANUP_DELETE
									"${NX_INSTALL_PATH_EXPORT}/${PROJECT_NAME}${sVersionSuffix}/${PROJECT_NAME}ConfigVersion.cmake")
				nx_append_global(NX_CLEANUP_RMDIR "${NX_INSTALL_PATH_EXPORT}/${PROJECT_NAME}${sVersionSuffix}")
			endif()
		endif()
	endif()

	_nx_function_end()
endfunction()

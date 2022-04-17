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

# ===================================================================

function(nx_identify_language)
	_nx_function_begin()

	# Get Current Information

	get_property(lsEnabledLanguages GLOBAL PROPERTY ENABLED_LANGUAGES)

	# Default Host Variables

	foreach(sTargetLanguage "C" "CXX" "RC")
		if("${sTargetLanguage}" IN_LIST lsEnabledLanguages)
			nx_set(NX_HOST_LANGUAGE_${sTargetLanguage} ON)
		else()
			nx_set(NX_HOST_LANGUAGE_${sTargetLanguage} OFF)
		endif()
		nx_set(${NX_PROJECT_NAME}_LANGUAGE_${sTargetLanguage} ${NX_HOST_LANGUAGE_${sTargetLanguage}})
	endforeach()

	if(NOT NX_HOST_LANGUAGE_C AND NOT NX_HOST_LANGUAGE_CXX)
		nx_set(NX_HOST_LANGUAGE_NONE ON)
	else()
		nx_set(NX_HOST_LANGUAGE_NONE OFF)
	endif()
	nx_set(${NX_PROJECT_NAME}_LANGUAGE_NONE ${NX_HOST_LANGUAGE_NONE})

	_nx_function_end()
endfunction()

nx_identify_language()

# ===================================================================

function(nx_identify_platform)
	_nx_function_begin()

	# Get Current Information

	string(TOUPPER "${CMAKE_HOST_SYSTEM_NAME}" sHostSystemName)
	string(TOUPPER "${CMAKE_SYSTEM_NAME}" sTargetSystemName)

	# Helpful Lists

	set(lsPlatformsAndroid "ANDROID")
	set(lsPlatformsCygwin "CYGWIN" "MSYS")
	set(lsPlatformsDarwin "DARWIN")
	set(lsPlatformsFreeBSD "DRAGONFLY" "FREEBSD")
	set(lsPlatformsHaiku "BEOS" "HAIKU")
	set(lsPlatformsLinux "LINUX")
	set(lsPlatformsMSDOS "DJGPP" "MSDOS")
	set(lsPlatformsWindows "MINGW" "WINDOWS")

	# Determine Host Information

	foreach(sHostPlatform "CYGWIN" "DARWIN" "FREEBSD" "HAIKU" "LINUX" "WINDOWS")
		nx_set(NX_HOST_PLATFORM_${sHostPlatform} OFF)
	endforeach()

	if("${sHostSystemName}" IN_LIST lsPlatformsCygwin)
		nx_set(NX_HOST_PLATFORM_CYGWIN ON)
	elseif("${sHostSystemName}" IN_LIST lsPlatformsDarwin)
		nx_set(NX_HOST_PLATFORM_DARWIN ON)
	elseif("${sHostSystemName}" IN_LIST lsPlatformsFreeBSD)
		nx_set(NX_HOST_PLATFORM_FREEBSD ON)
	elseif("${sHostSystemName}" IN_LIST lsPlatformsHaiku)
		nx_set(NX_HOST_PLATFORM_HAIKU ON)
	elseif("${sHostSystemName}" IN_LIST lsPlatformsLinux)
		nx_set(NX_HOST_PLATFORM_LINUX ON)
	elseif("${sHostSystemName}" IN_LIST lsPlatformsWindows)
		nx_set(NX_HOST_PLATFORM_WINDOWS ON)
	else()
		message(WARNING "Unknown Host Platform ('${sHostSystemName}')")
	endif()

	# Determine Target Information

	foreach(
		sTargetPlatform
		"ANDROID"
		"CYGWIN"
		"DARWIN"
		"FREEBSD"
		"HAIKU"
		"LINUX"
		"MSDOS"
		"WINDOWS"
		"WINDOWS_MINGW"
		"WINDOWS_NATIVE"
		"NATIVE"
		"CROSS"
		"POSIX")
		nx_set(NX_TARGET_PLATFORM_${sTargetPlatform} OFF)
	endforeach()

	if(NOT DEFINED NX_TARGET_PLATFORM_GENERIC)
		nx_set(NX_TARGET_PLATFORM_GENERIC OFF)
	endif()

	if(NOT NX_TARGET_PLATFORM_GENERIC)
		if("${sTargetSystemName}" IN_LIST lsPlatformsAndroid)
			nx_set(NX_TARGET_PLATFORM_STRING "Android")
			nx_set(NX_TARGET_PLATFORM_ANDROID ON)
			nx_set(NX_TARGET_PLATFORM_POSIX ON)
		elseif("${sTargetSystemName}" IN_LIST lsPlatformsCygwin)
			if(DEFINED MSYS AND MSYS)
				nx_set(NX_TARGET_PLATFORM_STRING "MSYS")
			else()
				nx_set(NX_TARGET_PLATFORM_STRING "Cygwin")
			endif()
			nx_set(NX_TARGET_PLATFORM_CYGWIN ON)
			nx_set(NX_TARGET_PLATFORM_POSIX ON)
			if(NX_HOST_PLATFORM_CYGWIN)
				nx_set(NX_TARGET_PLATFORM_NATIVE ON)
			endif()
		elseif("${sTargetSystemName}" IN_LIST lsPlatformsDarwin)
			nx_set(NX_TARGET_PLATFORM_STRING "Darwin")
			nx_set(NX_TARGET_PLATFORM_DARWIN ON)
			nx_set(NX_TARGET_PLATFORM_POSIX ON)
			if(NX_HOST_PLATFORM_DARWIN)
				nx_set(NX_TARGET_PLATFORM_NATIVE ON)
			endif()
		elseif("${sTargetSystemName}" IN_LIST lsPlatformsFreeBSD)
			nx_set(NX_TARGET_PLATFORM_STRING "FreeBSD")
			nx_set(NX_TARGET_PLATFORM_FREEBSD ON)
			nx_set(NX_TARGET_PLATFORM_POSIX ON)
			if(NX_HOST_PLATFORM_FREEBSD)
				nx_set(NX_TARGET_PLATFORM_NATIVE ON)
			endif()
		elseif("${sTargetSystemName}" IN_LIST lsPlatformsHaiku)
			nx_set(NX_TARGET_PLATFORM_STRING "Haiku")
			nx_set(NX_TARGET_PLATFORM_HAIKU ON)
			nx_set(NX_TARGET_PLATFORM_POSIX ON)
			if(NX_HOST_PLATFORM_HAIKU)
				nx_set(NX_TARGET_PLATFORM_NATIVE ON)
			endif()
		elseif("${sTargetSystemName}" IN_LIST lsPlatformsLinux)
			nx_set(NX_TARGET_PLATFORM_STRING "Linux")
			nx_set(NX_TARGET_PLATFORM_LINUX ON)
			nx_set(NX_TARGET_PLATFORM_POSIX ON)
			if(NX_HOST_PLATFORM_LINUX)
				nx_set(NX_TARGET_PLATFORM_NATIVE ON)
			endif()
		elseif("${sTargetSystemName}" IN_LIST lsPlatformsMSDOS)
			nx_set(NX_TARGET_PLATFORM_STRING "MSDOS")
			nx_set(NX_TARGET_PLATFORM_MSDOS ON)
		elseif("${sTargetSystemName}" IN_LIST lsPlatformsWindows)
			if(DEFINED NX_TARGET_MSYS_MINGW AND NX_TARGET_MSYS_MINGW)
				nx_set(NX_TARGET_PLATFORM_WINDOWS_MINGW ON)
			else()
				nx_set(NX_TARGET_PLATFORM_WINDOWS_NATIVE ON)
			endif()
			nx_set(NX_TARGET_PLATFORM_STRING "Windows")
			nx_set(NX_TARGET_PLATFORM_WINDOWS ON)
			if(NX_HOST_PLATFORM_WINDOWS)
				nx_set(NX_TARGET_PLATFORM_NATIVE ON)
			endif()
		else()
			message(FATAL_ERROR "Unsupported Platform Type ('${sTargetSystemName}')")
		endif()
	else()
		nx_set(NX_TARGET_PLATFORM_STRING "Generic")
		nx_set(NX_TARGET_PLATFORM_NATIVE ON)
	endif()

	if(NOT NX_TARGET_PLATFORM_NATIVE)
		nx_set(NX_TARGET_PLATFORM_CROSS ON)
	endif()

	foreach(
		sTargetPlatform
		"ANDROID"
		"CYGWIN"
		"DARWIN"
		"FREEBSD"
		"HAIKU"
		"LINUX"
		"MSDOS"
		"WINDOWS"
		"WINDOWS_MINGW"
		"WINDOWS_NATIVE"
		"GENERIC"
		"NATIVE"
		"CROSS"
		"POSIX")
		nx_set(${NX_PROJECT_NAME}_PLATFORM_${sTargetPlatform} ${NX_TARGET_PLATFORM_${sTargetPlatform}})
	endforeach()

	# Set Identity Macros

	string(TOUPPER "${NX_INTERNAL_PROJECT}" sMacroPrefix)
	string(MAKE_C_IDENTIFIER "${sMacroPrefix}" sMacroPrefix)

	string(TOUPPER "${NX_TARGET_PLATFORM_STRING}" sMacroPlatform)
	if(sMacroPlatform STREQUAL "MSYS")
		set(sMacroPlatform "CYGWIN")
	endif()
	nx_set(NX_TARGET_PLATFORM_DEFINES ${sMacroPrefix}_OS_${sMacroPlatform}=1 ${sMacroPrefix}_OS_STRING="${NX_TARGET_PLATFORM_STRING}")
	if(NX_TARGET_PLATFORM_POSIX)
		nx_append(NX_TARGET_PLATFORM_DEFINES ${sMacroPrefix}_OS_POSIX=1)
	endif()
	nx_set(${NX_PROJECT_NAME}_PLATFORM_DEFINES ${NX_TARGET_PLATFORM_DEFINES})

	_nx_function_end()
endfunction()

nx_identify_platform()

# ===================================================================

function(nx_identify_build)
	_nx_function_begin()

	# Get Current Information

	get_property(sGeneratorMultiConfig GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
	if(NOT sGeneratorMultiConfig)
		if(NOT DEFINED CMAKE_BUILD_TYPE OR NOT CMAKE_BUILD_TYPE)
			if(NX_TARGET_PLATFORM_ANDROID OR NX_TARGET_PLATFORM_MSDOS)
				nx_set_cache(CMAKE_BUILD_TYPE "Release" STRING "Build Configuration")
			else()
				nx_set_cache(CMAKE_BUILD_TYPE "RelWithDebInfo" STRING "Build Configuration")
			endif()
		endif()
	endif()

	string(TOUPPER "${CMAKE_BUILD_TYPE}" sBuildType)

	# Determine Target Information

	foreach(sTargetBuild "DEBUG" "MINSIZE" "RELEASE" "MAXSPEED" "MULTI")
		nx_set(NX_TARGET_BUILD_${sTargetBuild} OFF)
	endforeach()

	if(NOT sGeneratorMultiConfig)
		if(sBuildType STREQUAL "DEBUG")
			nx_set(NX_TARGET_BUILD_STRING "Debug")
			nx_set(NX_TARGET_BUILD_DEBUG ON)
		elseif(sBuildType STREQUAL "MINSIZEREL")
			nx_set(NX_TARGET_BUILD_STRING "MinSize")
			nx_set(NX_TARGET_BUILD_MINSIZE ON)
		elseif(sBuildType STREQUAL "RELWITHDEBINFO")
			nx_set(NX_TARGET_BUILD_STRING "Release")
			nx_set(NX_TARGET_BUILD_RELEASE ON)
		elseif(sBuildType STREQUAL "RELEASE")
			nx_set(NX_TARGET_BUILD_STRING "MaxSpeed")
			nx_set(NX_TARGET_BUILD_MAXSPEED ON)
		else()
			message(FATAL_ERROR "Unsupported Build Type ('${sBuildType}')")
		endif()
	else()
		nx_set(NX_TARGET_BUILD_STRING "Unknown")
		nx_set(NX_TARGET_BUILD_MULTI ON)
	endif()

	foreach(sTargetBuild "DEBUG" "MINSIZE" "RELEASE" "MAXSPEED" "MULTI")
		nx_set(${NX_PROJECT_NAME}_BUILD_${sTargetBuild} ${NX_TARGET_BUILD_${sTargetBuild}})
	endforeach()

	# Set Identity Macros

	string(TOUPPER "${NX_INTERNAL_PROJECT}" sMacroPrefix)
	string(MAKE_C_IDENTIFIER "${sMacroPrefix}" sMacroPrefix)

	if(NOT sGeneratorMultiConfig)
		string(TOUPPER "${NX_TARGET_BUILD_STRING}" sMacroBuild)
		nx_set(NX_TARGET_BUILD_DEFINES ${sMacroPrefix}_BUILD_${sMacroBuild}=1 ${sMacroPrefix}_BUILD_STRING="${NX_TARGET_BUILD_STRING}")
	else()
		nx_set(
			NX_TARGET_BUILD_DEFINES
			$<$<CONFIG:Debug>:${sMacroPrefix}_BUILD_DEBUG=1>
			$<$<CONFIG:Debug>:${sMacroPrefix}_BUILD_STRING="Debug">
			$<$<CONFIG:MinSizeRel>:${sMacroPrefix}_BUILD_MINSIZE=1>
			$<$<CONFIG:MinSizeRel>:${sMacroPrefix}_BUILD_STRING="MinSize">
			$<$<CONFIG:RelWithDebInfo>:${sMacroPrefix}_BUILD_RELEASE=1>
			$<$<CONFIG:RelWithDebInfo>:${sMacroPrefix}_BUILD_STRING="Release">
			$<$<CONFIG:Release>:${sMacroPrefix}_BUILD_MAXSPEED=1>
			$<$<CONFIG:Release>:${sMacroPrefix}_BUILD_STRING="MaxSpeed">)
	endif()
	nx_set(${NX_PROJECT_NAME}_BUILD_DEFINES ${NX_TARGET_BUILD_DEFINES})

	_nx_function_end()
endfunction()

nx_identify_build()

# ===================================================================

function(nx_identify_architecture)
	_nx_function_begin()

	# Get Current Information

	string(TOUPPER "${CMAKE_HOST_SYSTEM_PROCESSOR}" sHostProcessor)

	if(DEFINED CMAKE_VS_PLATFORM_NAME)
		string(TOUPPER "${CMAKE_VS_PLATFORM_NAME}" sTargetProcessor)
	else()
		string(TOUPPER "${CMAKE_SYSTEM_PROCESSOR}" sTargetProcessor)
	endif()

	if(DEFINED CMAKE_SIZEOF_VOID_P AND CMAKE_SIZEOF_VOID_P GREATER 0)
		math(EXPR nPointerSize "${CMAKE_SIZEOF_VOID_P} * 8")
	else()
		set(nPointerSize 0)
	endif()

	# Helpful Lists

	set(lsArchitecturesAMD64 "AMD64" "EM64T" "X64" "X86_64" "X86_64H")
	set(lsArchitecturesARM64 "AARCH64" "ARM64" "ARM64E")
	set(lsArchitecturesARMv7 "ARM" "ARMHF")
	set(lsArchitecturesIA32
		"I386"
		"I486"
		"I586"
		"I686"
		"I86PC"
		"IA32"
		"WIN32"
		"X86")
	set(lsArchitecturesRV64 "RISCV64")

	# Determine Host Information

	foreach(sHostArchitecture "AMD64" "ARM64" "ARMV7" "IA32" "RV64")
		nx_set(NX_HOST_ARCHITECTURE_${sHostArchitecture} OFF)
	endforeach()

	if("${sHostProcessor}" IN_LIST lsArchitecturesAMD64)
		nx_set(NX_HOST_ARCHITECTURE_AMD64 ON)
	elseif("${sHostProcessor}" IN_LIST lsArchitecturesARM64)
		nx_set(NX_HOST_ARCHITECTURE_ARM64 ON)
	elseif("${sHostProcessor}" IN_LIST lsArchitecturesARMv7)
		nx_set(NX_HOST_ARCHITECTURE_ARMV7 ON)
	elseif("${sHostProcessor}" IN_LIST lsArchitecturesIA32)
		nx_set(NX_HOST_ARCHITECTURE_IA32 ON)
	elseif("${sHostProcessor}" IN_LIST lsArchitecturesRV64)
		nx_set(NX_HOST_ARCHITECTURE_RV64 ON)
	else()
		message(WARNING "Unknown Host Architecture ('${sHostProcessor}')")
	endif()

	list(APPEND lsArchitecturesIA32 ${lsArchitecturesAMD64})
	list(APPEND lsArchitecturesARMv7 ${lsArchitecturesARM64})

	# This should really be in nx_identify_platform... but has to be here.

	if(NX_TARGET_PLATFORM_MSDOS
		AND NX_HOST_PLATFORM_WINDOWS
		AND NX_HOST_ARCHITECTURE_IA32
		AND NOT NX_TARGET_PLATFORM_NATIVE)
		nx_set(NX_TARGET_PLATFORM_NATIVE ON)
		nx_set(NX_TARGET_PLATFORM_CROSS OFF)
	endif()

	# Determine Target Information

	foreach(
		sTargetArchitecture
		"AMD64"
		"ARM64"
		"ARMV7"
		"IA32"
		"RV64"
		"NATIVE"
		"CROSS")
		nx_set(NX_TARGET_ARCHITECTURE_${sTargetArchitecture} OFF)
	endforeach()

	if(NOT DEFINED NX_TARGET_ARCHITECTURE_GENERIC)
		nx_set(NX_TARGET_ARCHITECTURE_GENERIC OFF)
	endif()

	if(NOT NX_TARGET_ARCHITECTURE_GENERIC)
		if(NX_HOST_LANGUAGE_NONE OR NX_TARGET_PLATFORM_GENERIC)
			nx_set(NX_TARGET_ARCHITECTURE_STRING "Generic")
			nx_set(NX_TARGET_ARCHITECTURE_GENERIC ON)
			nx_set(NX_TARGET_ARCHITECTURE_NATIVE ON)
		elseif("${sTargetProcessor}" IN_LIST lsArchitecturesAMD64 AND nPointerSize EQUAL 64)
			nx_set(NX_TARGET_ARCHITECTURE_STRING "AMD64")
			nx_set(NX_TARGET_ARCHITECTURE_AMD64 ON)
			if(NX_HOST_ARCHITECTURE_AMD64)
				nx_set(NX_TARGET_ARCHITECTURE_NATIVE ON)
			endif()
		elseif("${sTargetProcessor}" IN_LIST lsArchitecturesARM64 AND nPointerSize EQUAL 64)
			nx_set(NX_TARGET_ARCHITECTURE_STRING "ARM64")
			nx_set(NX_TARGET_ARCHITECTURE_ARM64 ON)
			if(NX_HOST_ARCHITECTURE_ARM64)
				nx_set(NX_TARGET_ARCHITECTURE_NATIVE ON)
			endif()
		elseif("${sTargetProcessor}" IN_LIST lsArchitecturesARMv7 AND nPointerSize EQUAL 32)
			nx_set(NX_TARGET_ARCHITECTURE_STRING "ARMv7")
			nx_set(NX_TARGET_ARCHITECTURE_ARMV7 ON)
			if(NX_HOST_ARCHITECTURE_ARMV7 OR NX_HOST_ARCHITECTURE_ARM64)
				nx_set(NX_TARGET_ARCHITECTURE_NATIVE ON)
			endif()
		elseif("${sTargetProcessor}" IN_LIST lsArchitecturesIA32 AND nPointerSize EQUAL 32)
			nx_set(NX_TARGET_ARCHITECTURE_STRING "IA32")
			nx_set(NX_TARGET_ARCHITECTURE_IA32 ON)
			if(NX_HOST_ARCHITECTURE_IA32 OR NX_HOST_ARCHITECTURE_AMD64)
				nx_set(NX_TARGET_ARCHITECTURE_NATIVE ON)
			endif()
		elseif("${sTargetProcessor}" IN_LIST lsArchitecturesRV64 AND nPointerSize EQUAL 64)
			nx_set(NX_TARGET_ARCHITECTURE_STRING "RV64")
			nx_set(NX_TARGET_ARCHITECTURE_RV64 ON)
			if(NX_HOST_ARCHITECTURE_RV64)
				nx_set(NX_TARGET_ARCHITECTURE_NATIVE ON)
			endif()
		else()
			message(FATAL_ERROR "Unsupported Architecture Type ('${sTargetProcessor;${nPointerSize}-Bit}')")
		endif()
	else()
		nx_set(NX_TARGET_ARCHITECTURE_STRING "Generic")
		nx_set(NX_TARGET_ARCHITECTURE_NATIVE ON)
	endif()

	if(NOT NX_TARGET_ARCHITECTURE_NATIVE)
		nx_set(NX_TARGET_ARCHITECTURE_CROSS ON)
	endif()

	foreach(
		sTargetArchitecture
		"AMD64"
		"ARM64"
		"ARMV7"
		"IA32"
		"RV64"
		"GENERIC"
		"NATIVE"
		"CROSS")
		nx_set(${NX_PROJECT_NAME}_ARCHITECTURE_${sTargetArchitecture} ${NX_TARGET_ARCHITECTURE_${sTargetArchitecture}})
	endforeach()

	# Set Identity Macros

	string(TOUPPER "${NX_INTERNAL_PROJECT}" sMacroPrefix)
	string(MAKE_C_IDENTIFIER "${sMacroPrefix}" sMacroPrefix)

	string(TOUPPER "${NX_TARGET_ARCHITECTURE_STRING}" sMacroArchitecture)
	nx_set(NX_TARGET_ARCHITECTURE_DEFINES ${sMacroPrefix}_ARCH_${sMacroArchitecture}=1
			${sMacroPrefix}_ARCH_STRING="${NX_TARGET_ARCHITECTURE_STRING}" ${sMacroPrefix}_ARCH_BITS=${nPointerSize})
	nx_set(${NX_PROJECT_NAME}_ARCHITECTURE_DEFINES ${NX_TARGET_ARCHITECTURE_DEFINES})

	_nx_function_end()
endfunction()

nx_identify_architecture()

# ===================================================================

function(nx_identify_compiler)
	if(NX_HOST_LANGUAGE_NONE)
		return()
	endif()
	_nx_function_begin()

	# Helpful Lists

	set(lsCompilersClang "CLANG")
	set(lsCompilersGNU "GNU")
	set(lsCompilersMSVC "MSVC")

	# Determine C Information

	foreach(sHostCompiler "CLANG" "GNU" "MSVC" "UNKNOWN")
		nx_set(NX_HOST_C_COMPILER_${sHostCompiler} OFF)
	endforeach()

	if(NX_HOST_LANGUAGE_C)
		set(bFoundOne OFF)

		if(DEFINED CMAKE_C_SIMULATE_ID AND CMAKE_C_SIMULATE_ID)
			string(TOUPPER "${CMAKE_C_SIMULATE_ID}" sSimulatedIdC)
			if("${sSimulatedIdC}" IN_LIST lsCompilersClang)
				nx_set(NX_HOST_C_COMPILER_STRING "Clang")
				nx_set(NX_HOST_C_COMPILER_CLANG ON)
				nx_set(NX_HOST_C_VERSION_CLANG ${CMAKE_C_SIMULATE_VERSION})
				set(bFoundOne ON)
			elseif("${sSimulatedIdC}" IN_LIST lsCompilersGNU)
				nx_set(NX_HOST_C_COMPILER_STRING "GNU")
				nx_set(NX_HOST_C_COMPILER_GNU ON)
				nx_set(NX_HOST_C_VERSION_GNU ${CMAKE_C_SIMULATE_VERSION})
				set(bFoundOne ON)
			elseif("${sSimulatedIdC}" IN_LIST lsCompilersMSVC)
				nx_set(NX_HOST_C_COMPILER_STRING "MSVC")
				nx_set(NX_HOST_C_COMPILER_MSVC ON)
				nx_set(NX_HOST_C_VERSION_MSVC ${CMAKE_C_SIMULATE_VERSION})
				set(bFoundOne ON)
			endif()
		endif()

		if(DEFINED CMAKE_C_COMPILER_ID AND CMAKE_C_COMPILER_ID)
			string(TOUPPER "${CMAKE_C_COMPILER_ID}" sCompilerIdC)
			if("${sCompilerIdC}" IN_LIST lsCompilersClang)
				nx_set(NX_HOST_C_COMPILER_STRING "Clang")
				nx_set(NX_HOST_C_COMPILER_CLANG ON)
				nx_set(NX_HOST_C_VERSION_CLANG ${CMAKE_C_COMPILER_VERSION})
				set(bFoundOne ON)
			elseif("${sCompilerIdC}" IN_LIST lsCompilersGNU)
				nx_set(NX_HOST_C_COMPILER_STRING "GNU")
				nx_set(NX_HOST_C_COMPILER_GNU ON)
				nx_set(NX_HOST_C_VERSION_GNU ${CMAKE_C_COMPILER_VERSION})
				set(bFoundOne ON)
			elseif("${sCompilerIdC}" IN_LIST lsCompilersMSVC)
				nx_set(NX_HOST_C_COMPILER_STRING "MSVC")
				nx_set(NX_HOST_C_COMPILER_MSVC ON)
				nx_set(NX_HOST_C_VERSION_MSVC ${CMAKE_C_COMPILER_VERSION})
				set(bFoundOne ON)
			endif()
		endif()

		if(NOT bFoundOne)
			nx_set(NX_HOST_C_COMPILER_STRING "Unknown")
			nx_set(NX_HOST_C_COMPILER_UNKNOWN ON)
		endif()
	endif()

	if(NX_HOST_LANGUAGE_C AND NX_HOST_C_COMPILER_UNKNOWN)
		message(FATAL_ERROR "Unsupported C Compiler ('${CMAKE_C_COMPILER_ID}')")
	endif()

	# Determine CXX Information

	foreach(sHostCompiler "CLANG" "GNU" "MSVC" "UNKNOWN")
		nx_set(NX_HOST_CXX_COMPILER_${sHostCompiler} OFF)
	endforeach()

	if(NX_HOST_LANGUAGE_CXX)
		set(bFoundOne OFF)

		if(DEFINED CMAKE_CXX_SIMULATE_ID AND CMAKE_CXX_SIMULATE_ID)
			string(TOUPPER "${CMAKE_CXX_SIMULATE_ID}" sSimulatedIdCXX)
			if("${sSimulatedIdCXX}" IN_LIST lsCompilersClang)
				nx_set(NX_HOST_CXX_COMPILER_STRING "Clang")
				nx_set(NX_HOST_CXX_COMPILER_CLANG ON)
				nx_set(NX_HOST_CXX_VERSION_CLANG ${CMAKE_CXX_SIMULATE_VERSION})
				set(bFoundOne ON)
			elseif("${sSimulatedIdCXX}" IN_LIST lsCompilersGNU)
				nx_set(NX_HOST_CXX_COMPILER_STRING "GNU")
				nx_set(NX_HOST_CXX_COMPILER_GNU ON)
				nx_set(NX_HOST_CXX_VERSION_GNU ${CMAKE_CXX_SIMULATE_VERSION})
				set(bFoundOne ON)
			elseif("${sSimulatedIdCXX}" IN_LIST lsCompilersMSVC)
				nx_set(NX_HOST_CXX_COMPILER_STRING "MSVC")
				nx_set(NX_HOST_CXX_COMPILER_MSVC ON)
				nx_set(NX_HOST_CXX_VERSION_MSVC ${CMAKE_CXX_SIMULATE_VERSION})
				set(bFoundOne ON)
			endif()
		endif()

		if(DEFINED CMAKE_CXX_COMPILER_ID AND CMAKE_CXX_COMPILER_ID)
			string(TOUPPER "${CMAKE_CXX_COMPILER_ID}" sCompilerIdCXX)
			if("${sCompilerIdCXX}" IN_LIST lsCompilersClang)
				nx_set(NX_HOST_CXX_COMPILER_STRING "Clang")
				nx_set(NX_HOST_CXX_COMPILER_CLANG ON)
				nx_set(NX_HOST_CXX_VERSION_CLANG ${CMAKE_CXX_COMPILER_VERSION})
				set(bFoundOne ON)
			elseif("${sCompilerIdCXX}" IN_LIST lsCompilersGNU)
				nx_set(NX_HOST_CXX_COMPILER_STRING "GNU")
				nx_set(NX_HOST_CXX_COMPILER_GNU ON)
				nx_set(NX_HOST_CXX_VERSION_GNU ${CMAKE_CXX_COMPILER_VERSION})
				set(bFoundOne ON)
			elseif("${sCompilerIdCXX}" IN_LIST lsCompilersMSVC)
				nx_set(NX_HOST_CXX_COMPILER_STRING "MSVC")
				nx_set(NX_HOST_CXX_COMPILER_MSVC ON)
				nx_set(NX_HOST_CXX_VERSION_MSVC ${CMAKE_CXX_COMPILER_VERSION})
				set(bFoundOne ON)
			endif()
		endif()

		if(NOT bFoundOne)
			nx_set(NX_HOST_CXX_COMPILER_STRING "Unknown")
			nx_set(NX_HOST_CXX_COMPILER_UNKNOWN ON)
		endif()
	endif()

	if(NX_HOST_LANGUAGE_CXX AND NX_HOST_CXX_COMPILER_UNKNOWN)
		message(FATAL_ERROR "Unsupported C++ Compiler ('${CMAKE_CXX_COMPILER_ID}')")
	endif()

	# Set Actual Compiler

	foreach(sHostCompiler "CLANG" "GNU" "MSVC" "UNKNOWN")
		if(NX_HOST_C_COMPILER_${sHostCompiler} AND NX_HOST_CXX_COMPILER_${sHostCompiler})
			nx_set(NX_HOST_COMPILER_${sHostCompiler} ON)
			nx_set(NX_HOST_COMPILER_${sHostCompiler}_VERSION ${NX_HOST_CXX_VERSION_${sHostCompiler}})
		elseif(NX_HOST_C_COMPILER_${sHostCompiler} AND NOT NX_HOST_LANGUAGE_CXX)
			nx_set(NX_HOST_COMPILER_${sHostCompiler} ON)
			nx_set(NX_HOST_COMPILER_${sHostCompiler}_VERSION ${NX_HOST_C_VERSION_${sHostCompiler}})
		elseif(NX_HOST_CXX_COMPILER_${sHostCompiler} AND NOT NX_HOST_LANGUAGE_C)
			nx_set(NX_HOST_COMPILER_${sHostCompiler} ON)
			nx_set(NX_HOST_COMPILER_${sHostCompiler}_VERSION ${NX_HOST_CXX_VERSION_${sHostCompiler}})
		else()
			nx_set(NX_HOST_COMPILER_${sHostCompiler} OFF)
		endif()
		nx_set(${NX_PROJECT_NAME}_COMPILER_${sHostCompiler} ${NX_HOST_COMPILER_${sHostCompiler}})
	endforeach()

	if("x${NX_HOST_C_COMPILER_STRING}" STREQUAL "x${NX_HOST_CXX_COMPILER_STRING}")
		nx_set(NX_HOST_COMPILER_STRING ${NX_HOST_CXX_COMPILER_STRING})
	elseif(NOT NX_HOST_LANGUAGE_CXX)
		nx_set(NX_HOST_COMPILER_STRING ${NX_HOST_C_COMPILER_STRING})
	elseif(NOT NX_HOST_LANGUAGE_C)
		nx_set(NX_HOST_COMPILER_STRING ${NX_HOST_CXX_COMPILER_STRING})
	else()
		message(FATAL_ERROR "Unsupported Compiler Combination ('${NX_HOST_C_COMPILER_STRING}')('${NX_HOST_CXX_COMPILER_STRING}')")
	endif()

	# Set Native Compilers

	if(NX_TARGET_PLATFORM_ANDROID AND NX_HOST_COMPILER_CLANG)
		nx_set(NX_HOST_COMPILER_NATIVE ON)
	elseif(NX_TARGET_PLATFORM_CYGWIN AND NX_HOST_COMPILER_GNU)
		nx_set(NX_HOST_COMPILER_NATIVE ON)
	elseif(NX_TARGET_PLATFORM_DARWIN AND NX_HOST_COMPILER_CLANG)
		nx_set(NX_HOST_COMPILER_NATIVE ON)
	elseif(NX_TARGET_PLATFORM_FREEBSD AND NX_HOST_COMPILER_CLANG)
		nx_set(NX_HOST_COMPILER_NATIVE ON)
	elseif(NX_TARGET_PLATFORM_HAIKU AND NX_HOST_COMPILER_GNU)
		nx_set(NX_HOST_COMPILER_NATIVE ON)
	elseif(NX_TARGET_PLATFORM_LINUX AND NX_HOST_COMPILER_GNU)
		nx_set(NX_HOST_COMPILER_NATIVE ON)
	elseif(NX_TARGET_PLATFORM_WINDOWS_MINGW AND NX_HOST_COMPILER_GNU)
		nx_set(NX_HOST_COMPILER_NATIVE ON)
	elseif(NX_TARGET_PLATFORM_WINDOWS_NATIVE AND NX_HOST_COMPILER_MSVC)
		nx_set(NX_HOST_COMPILER_NATIVE ON)
	else()
		nx_set(NX_HOST_COMPILER_NATIVE OFF)
	endif()
	nx_set(${NX_PROJECT_NAME}_COMPILER_NATIVE ${NX_HOST_COMPILER_NATIVE})

	# Set Identity Macros

	string(TOUPPER "${NX_INTERNAL_PROJECT}" sMacroPrefix)
	string(MAKE_C_IDENTIFIER "${sMacroPrefix}" sMacroPrefix)

	string(TOUPPER "${NX_HOST_COMPILER_STRING}" sMacroCompiler)
	nx_set(NX_HOST_COMPILER_DEFINES ${sMacroPrefix}_COMPILER_${sMacroCompiler}=1
			${sMacroPrefix}_COMPILER_STRING="${NX_HOST_COMPILER_STRING}")
	if(NX_HOST_LANGUAGE_C)
		string(TOUPPER "${NX_HOST_C_COMPILER_STRING}" sMacroCompiler)
		if(NX_HOST_LANGUAGE_CXX)
			nx_append(NX_HOST_COMPILER_DEFINES $<$<COMPILE_LANGUAGE:C>:${sMacroPrefix}_C_${sMacroCompiler}=1>
						$<$<COMPILE_LANGUAGE:C>:${sMacroPrefix}_C_STRING="${NX_HOST_C_COMPILER_STRING}">)
		else()
			nx_append(NX_HOST_COMPILER_DEFINES ${sMacroPrefix}_C_${sMacroCompiler}=1
						${sMacroPrefix}_C_STRING="${NX_HOST_C_COMPILER_STRING}")
		endif()
	endif()
	if(NX_HOST_LANGUAGE_CXX)
		string(TOUPPER "${NX_HOST_CXX_COMPILER_STRING}" sMacroCompiler)
		if(NX_HOST_LANGUAGE_C)
			nx_append(NX_HOST_COMPILER_DEFINES $<$<COMPILE_LANGUAGE:CXX>:${sMacroPrefix}_CXX_${sMacroCompiler}=1>
						$<$<COMPILE_LANGUAGE:CXX>:${sMacroPrefix}_CXX_STRING="${NX_HOST_CXX_COMPILER_STRING}">)
		else()
			nx_append(NX_HOST_COMPILER_DEFINES ${sMacroPrefix}_CXX_${sMacroCompiler}=1
						${sMacroPrefix}_CXX_STRING="${NX_HOST_CXX_COMPILER_STRING}")
		endif()
	endif()
	nx_set(${NX_PROJECT_NAME}_COMPILER_DEFINES ${NX_HOST_COMPILER_DEFINES})

	_nx_function_end()
endfunction()

nx_identify_compiler()

if(NX_HOST_COMPILER_CLANG)
	set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
endif()

# ===================================================================

function(nx_identify_cxxabi)
	_nx_function_begin()

	if(NX_HOST_LANGUAGE_CXX)

		# Determine Target Information

		include(CheckCXXSourceCompiles)

		set(sCheckDinkumware
			[[
#include <utility>
#if defined(_YVALS) || defined(_CPPLIB_VER)
int main(int argc, char *argv[]) {return 0;}
#endif
			]])
		set(sCheckLibStdCXX
			[[
#include <bits/c++config.h>
#ifdef __GLIBCXX__
int main(int argc, char *argv[]) {return 0;}
#endif
			]])
		set(sCheckLibCXX
			[[
#include <ciso646>
#ifdef _LIBCPP_VERSION
int main(int argc, char *argv[]) {return 0;}
#endif
			]])

		check_cxx_source_compiles("${sCheckDinkumware}" HAS_DEFINE_CPPLIB_VER)
		check_cxx_source_compiles("${sCheckLibStdCXX}" HAS_DEFINE_GLIBCXX)
		check_cxx_source_compiles("${sCheckLibCXX}" HAS_DEFINE_LIBCPP_VERSION)

		# Determine Target Information

		foreach(sTargetABI "GNU" "CLANG" "MSVC" "UNKNOWN")
			nx_set(NX_TARGET_CXXABI_${sTargetABI} OFF)
		endforeach()

		if(HAS_DEFINE_LIBCPP_VERSION)
			if(NX_TARGET_PLATFORM_DARWIN OR NX_TARGET_PLATFORM_FREEBSD)
				nx_set(NX_TARGET_CXXABI_STRING)
			else()
				nx_set(NX_TARGET_CXXABI_STRING "libc++")
			endif()
			nx_set(NX_TARGET_CXXABI_CLANG ON)
		elseif(HAS_DEFINE_GLIBCXX)
			if(NX_TARGET_PLATFORM_CYGWIN
				OR NX_TARGET_PLATFORM_HAIKU
				OR NX_TARGET_PLATFORM_LINUX
				OR NX_TARGET_PLATFORM_WINDOWS_MINGW)
				nx_set(NX_TARGET_CXXABI_STRING)
			else()
				nx_set(NX_TARGET_CXXABI_STRING "libstdc++")
			endif()
			nx_set(NX_TARGET_CXXABI_GNU ON)
		elseif(HAS_DEFINE_CPPLIB_VER)
			if(NX_TARGET_PLATFORM_WINDOWS_NATIVE)
				nx_set(NX_TARGET_CXXABI_STRING)
			else()
				nx_set(NX_TARGET_CXXABI_STRING "msvc")
			endif()
			nx_set(NX_TARGET_CXXABI_MSVC ON)
		else()
			message(FATAL_ERROR "Unsupported C++ Standard Library")
			nx_set(NX_TARGET_CXXABI_UNKNOWN ON)
		endif()

		if(NX_TARGET_PLATFORM_ANDROID OR NX_TARGET_PLATFORM_MSDOS)
			nx_set(NX_TARGET_CXXABI_STRING)
		endif()

		foreach(sTargetABI "GNU" "CLANG" "MSVC" "UNKNOWN")
			nx_set(${NX_PROJECT_NAME}_CXXABI_${sTargetABI} ${NX_TARGET_CXXABI_${sTargetABI}})
		endforeach()
	endif()

	_nx_function_end()
endfunction()

nx_identify_cxxabi()

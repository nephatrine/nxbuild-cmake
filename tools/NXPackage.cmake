# -------------------------------
# SPDX-License-Identifier: ISC
#
# Copyright © 2021 Daniel Wolf <<nephatrine@gmail.com>>
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

# cmake-lint: disable=C0111,C0301,R0912,R0915,W0106

include(NXInstall)
include(NXProject)

_nx_guard_file()

nx_set(NXPACKAGE_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}")

# ===================================================================

function(nx_package)
	_nx_guard_function(nx_package)
	_nx_function_begin()

	set(bShouldPackage OFF)
	if(CMAKE_CURRENT_SOURCE_DIR STREQUAL "${CMAKE_SOURCE_DIR}")
		set(bShouldPackage ON)
	endif()

	cmake_dependent_option(PACKAGE_TARGETS${NX_PROJECT_NAME} "Package Targets - ${PROJECT_NAME}" ON
							"INSTALL_TARGETS${NX_PROJECT_NAME};bShouldPackage" OFF)

	# ---- Eligible Components ----

	unset(lsProjectComponents)
	foreach(
		sComponent
		"APP"
		"SRV"
		"BIN"
		"MOD"
		"LIB"
		"OBJ"
		"DEV"
		"DAT"
		"DOC"
		"DBG"
		"RTM")
		if(DEFINED ${NX_PROJECT_NAME}_COMPONENT_${sComponent} AND ${NX_PROJECT_NAME}_COMPONENT_${sComponent})
			list(APPEND lsProjectComponents "${sComponent}")
			nx_append_global(NX_COMPONENT_LIST "${NX_PROJECT_NAME}_${sComponent}")
			if(DEFINED NX_COMPONENT_UNSORTED)
				nx_set_global(NX_COMPONENT_UNSORTED "${NX_COMPONENT_UNSORTED};${NX_PROJECT_NAME}_${sComponent}")
			else()
				nx_set_global(NX_COMPONENT_UNSORTED "${NX_PROJECT_NAME}_${sComponent}")
			endif()
		endif()
	endforeach()

	set(bPrimaryBinary OFF)
	set(bPrimaryLibrary OFF)
	set(bPrimaryCompiled OFF)

	if("APP" IN_LIST lsProjectComponents
		OR "SRV" IN_LIST lsProjectComponents
		OR "BIN" IN_LIST lsProjectComponents
		OR "MOD" IN_LIST lsProjectComponents)
		set(bPrimaryBinary ON)
		set(bPrimaryCompiled ON)
	elseif("LIB" IN_LIST lsProjectComponents)
		set(bPrimaryBinary ON)
		set(bPrimaryLibrary ON)
		set(bPrimaryCompiled ON)
	elseif("OBJ" IN_LIST lsProjectComponents)
		set(bPrimaryLibrary ON)
		set(bPrimaryCompiled ON)
	elseif("DEV" IN_LIST lsProjectComponents)
		if(DEFINED ${NX_PROJECT_NAME}_DIRS_INCLUDE OR DEFINED ${NX_PROJECT_NAME}_FILES_INTERFACE)
			set(bPrimaryLibrary ON)
		endif()
	endif()

	# ---- CPack Configuration ----

	if(NOT DEFINED CPACK_PROJECT_CONFIG_FILE)
		nx_set(CPACK_PROJECT_CONFIG_FILE "${NXPACKAGE_DIRECTORY}/CPackOptions.cmake")
	else()
		message(
			AUTHOR_WARNING
				"Please ensure contents of '${NXPACKAGE_DIRECTORY}/CPackOptions.cmake' are included in '${CPACK_PROJECT_CONFIG_FILE}'.")
	endif()

	# NOTE: We set this ON for source packages in CPackOptions.cmake.
	if(NOT DEFINED CPACK_INCLUDE_TOPLEVEL_DIRECTORY)
		nx_set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY OFF)
	endif()

	if(NOT DEFINED CPACK_INSTALL_PREFIX)
		nx_set(CPACK_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")
	endif()

	if(DEFINED NX_INSTALL_IS_FLAT
		OR NX_TARGET_PLATFORM_MSDOS
		OR NX_TARGET_PLATFORM_WINDOWS_NATIVE)
		get_filename_component(sInstallDir "${CPACK_INSTALL_PREFIX}" NAME)
		nx_set(CPACK_PACKAGE_INSTALL_DIRECTORY "${sInstallDir}")
	else()
		nx_set(CPACK_PACKAGE_INSTALL_DIRECTORY "${${NX_PROJECT_NAME}_PROJECT_PARENT}")
	endif()

	if(NOT DEFINED CPACK_PACKAGE_INSTALL_REGISTRY_KEY)
		nx_set(CPACK_PACKAGE_INSTALL_REGISTRY_KEY "${CPACK_PACKAGE_INSTALL_DIRECTORY}")
	endif()

	if(NOT DEFINED CPACK_NSIS_INSTALL_ROOT)
		set(sWinDrive "C:")
		if(CPACK_INSTALL_PREFIX MATCHES "^([A-Z]:)")
			set(sWinDrive "${CMAKE_MATCH_1}")
		endif()
		string(REPLACE "${sWinDrive}" "" sWinPath "${CPACK_INSTALL_PREFIX}")

		get_filename_component(sWinPath "${sWinPath}" DIRECTORY)
		if(sWinPath STREQUAL "/")
			unset(sWinPath)
		endif()
		file(TO_NATIVE_PATH "${sWinDrive}${sWinPath}" sWinPath)
		nx_set(CPACK_NSIS_INSTALL_ROOT "${sWinPath}")
	endif()

	# ---- Parse Linux Distro ----

	unset(sDistroId)
	unset(sDistroRelease)
	unset(sDistroCodename)
	unset(sDistroPlatform)

	if(NX_TARGET_PLATFORM_LINUX OR NX_TARGET_PLATFORM_CYGWIN)
		if(NOT DEFINED sDistroId AND EXISTS "${CMAKE_SYSROOT}/usr/lib/os-release")
			file(STRINGS "${CMAKE_SYSROOT}/usr/lib/os-release" lsDistroStrings REGEX "^ID=")
			foreach(sDistroString ${lsDistroStrings})
				if(sDistroString MATCHES "^ID=(.*)$")
					set(sDistroId "${CMAKE_MATCH_1}")
				endif()
			endforeach()

			file(STRINGS "${CMAKE_SYSROOT}/usr/lib/os-release" lsDistroStrings REGEX "^VERSION_CODENAME=")
			foreach(sDistroString ${lsDistroStrings})
				if(sDistroString MATCHES "^VERSION_CODENAME=(.*)$")
					set(sDistroCodename "${CMAKE_MATCH_1}")
				endif()
			endforeach()

			file(STRINGS "${CMAKE_SYSROOT}/usr/lib/os-release" lsDistroStrings REGEX "^PLATFORM_ID=")
			foreach(sDistroString ${lsDistroStrings})
				if(sDistroString MATCHES "^PLATFORM_ID=(.*)$")
					set(sDistroPlatform "${CMAKE_MATCH_1}")
				endif()
			endforeach()

			if(DEFINED sDistroId)
				file(STRINGS "${CMAKE_SYSROOT}/usr/lib/os-release" lsDistroStrings REGEX "^VERSION_ID=")
				foreach(sDistroString ${lsDistroStrings})
					if(sDistroString MATCHES "^VERSION_ID=(.*)$")
						set(sDistroRelease "${CMAKE_MATCH_1}")
					endif()
				endforeach()
			endif()
		endif()

		if(NOT DEFINED sDistroId AND EXISTS "${CMAKE_SYSROOT}/etc/os-release")
			file(STRINGS "${CMAKE_SYSROOT}/etc/os-release" lsDistroStrings REGEX "^ID=")
			foreach(sDistroString ${lsDistroStrings})
				if(sDistroString MATCHES "^ID=(.*)$")
					set(sDistroId "${CMAKE_MATCH_1}")
				endif()
			endforeach()

			file(STRINGS "${CMAKE_SYSROOT}/etc/os-release" lsDistroStrings REGEX "^VERSION_CODENAME=")
			foreach(sDistroString ${lsDistroStrings})
				if(sDistroString MATCHES "^VERSION_CODENAME=(.*)$")
					set(sDistroCodename "${CMAKE_MATCH_1}")
				endif()
			endforeach()

			file(STRINGS "${CMAKE_SYSROOT}/etc/os-release" lsDistroStrings REGEX "^PLATFORM_ID=")
			foreach(sDistroString ${lsDistroStrings})
				if(sDistroString MATCHES "^PLATFORM_ID=(.*)$")
					set(sDistroPlatform "${CMAKE_MATCH_1}")
				endif()
			endforeach()

			if(DEFINED sDistroId)
				file(STRINGS "${CMAKE_SYSROOT}/etc/os-release" lsDistroStrings REGEX "^VERSION_ID=")
				foreach(sDistroString ${lsDistroStrings})
					if(sDistroString MATCHES "^VERSION_ID=(.*)$")
						set(sDistroRelease "${CMAKE_MATCH_1}")
					endif()
				endforeach()
			endif()
		endif()

		if(NOT DEFINED sDistroId AND NX_TARGET_PLATFORM_NATIVE)
			find_program(LSB_RELEASE_EXECUTABLE NAMES "lsb_release")
			execute_process(
				COMMAND "${LSB_RELEASE_EXECUTABLE}" "-si"
				OUTPUT_VARIABLE sDistroId
				OUTPUT_STRIP_TRAILING_WHITESPACE)
			execute_process(
				COMMAND "${LSB_RELEASE_EXECUTABLE}" "-sc"
				OUTPUT_VARIABLE sDistroCodename
				OUTPUT_STRIP_TRAILING_WHITESPACE)

			if(NOT sDistroCodename)
				unset(sDistroCodename)
			endif()

			if(NOT sDistroId)
				unset(sDistroId)
			else()
				execute_process(
					COMMAND "${LSB_RELEASE_EXECUTABLE}" "-sr"
					OUTPUT_VARIABLE sDistroRelease
					OUTPUT_STRIP_TRAILING_WHITESPACE)
				if(NOT sDistroRelease)
					unset(sDistroRelease)
				endif()
			endif()
		endif()

		if(NOT DEFINED sDistroId AND EXISTS "${CMAKE_SYSROOT}/etc/lsb-release")
			file(STRINGS "${CMAKE_SYSROOT}/etc/lsb-release" lsDistroStrings REGEX "^DISTRIB_ID=")
			foreach(sDistroString ${lsDistroStrings})
				if(sDistroString MATCHES "^DISTRIB_ID=(.*)$")
					set(sDistroId "${CMAKE_MATCH_1}")
				endif()
			endforeach()

			file(STRINGS "${CMAKE_SYSROOT}/etc/lsb-release" lsDistroStrings REGEX "^DISTRIB_CODENAME=")
			foreach(sDistroString ${lsDistroStrings})
				if(sDistroString MATCHES "^DISTRIB_CODENAME=(.*)$")
					set(sDistroCodename "${CMAKE_MATCH_1}")
				endif()
			endforeach()

			if(DEFINED sDistroId)
				file(STRINGS "${CMAKE_SYSROOT}/etc/lsb-release" lsDistroStrings REGEX "^DISTRIB_RELEASE=")
				foreach(sDistroString ${lsDistroStrings})
					if(sDistroString MATCHES "^DISTRIB_RELEASE=(.*)$")
						set(sDistroRelease "${CMAKE_MATCH_1}")
					endif()
				endforeach()
			endif()
		endif()

		if(DEFINED sDistroId)
			string(TOLOWER "${sDistroId}" sDistroId)
			string(STRIP "${sDistroId}" sDistroId)
			if(NOT DEFINED sDistroRelease AND sDistroId MATCHES "([0-9]+)")
				set(sDistroRelease "${CMAKE_MATCH_1}")
			endif()
			if(sDistroId MATCHES "([a-z]+)")
				set(sDistroId "${CMAKE_MATCH_1}")
			else()
				unset(sDistroId)
			endif()
		endif()
		if(DEFINED sDistroCodename)
			string(TOLOWER "${sDistroCodename}" sDistroCodename)
			string(STRIP "${sDistroCodename}" sDistroCodename)
			if(sDistroCodename MATCHES "([a-z]+)")
				set(sDistroCodename "${CMAKE_MATCH_1}")
			else()
				unset(sDistroCodename)
			endif()
		endif()
		if(DEFINED sDistroPlatform)
			string(TOLOWER "${sDistroPlatform}" sDistroPlatform)
			string(STRIP "${sDistroPlatform}" sDistroPlatform)
			if(sDistroPlatform MATCHES "platform:([a-z]+)")
				set(sDistroPlatform "${CMAKE_MATCH_1}")
			else()
				unset(sDistroPlatform)
			endif()
		endif()
		if(DEFINED sDistroRelease)
			string(STRIP "${sDistroRelease}" sDistroRelease)
			if(sDistroRelease MATCHES "([0-9]+\.[0-9]+)")
				set(sDistroRelease "${CMAKE_MATCH_1}")
			elseif(sDistroRelease MATCHES "([0-9\.]+)")
				set(sDistroRelease "${CMAKE_MATCH_1}")
			else()
				unset(sDistroRelease)
			endif()
		endif()
	endif()

	# ---- CPack Package Architecture ----

	if(NOT DEFINED CPACK_PACKAGE_ARCHITECTURE)
		nx_set(CPACK_PACKAGE_ARCHITECTURE "${NX_TARGET_ARCHITECTURE_STRING}")
	endif()
	if(DEFINED NX_INSTALL_CROSS AND NX_INSTALL_CROSS)
		if(DEFINED CPACK_PACKAGE_ARCHITECTURE AND NOT CPACK_PACKAGE_ARCHITECTURE STREQUAL "Generic")
			nx_set(CPACK_CROSS_ARCHITECTURE "${CPACK_PACKAGE_ARCHITECTURE}")
			nx_set(CPACK_PACKAGE_ARCHITECTURE "${NX_HOST_ARCHITECTURE_STRING}")
			if(CPACK_PACKAGE_ARCHITECTURE STREQUAL CPACK_CROSS_ARCHITECTURE AND NX_HOST_ARCHITECTURE_AMD64)
				nx_set(CPACK_PACKAGE_ARCHITECTURE "IA32")
			endif()
		endif()
	endif()

	if(DEFINED CPACK_SYSTEM_NAME)
		set(sGenericSystem "${CPACK_SYSTEM_NAME}")
		set(sBinarySystem "${CPACK_SYSTEM_NAME}")
	else()
		set(sGenericSystem "${NX_TARGET_PLATFORM_STRING}")
		if(DEFINED sDistroId)
			set(sBinarySystem "${sDistroId}${sDistroRelease}-${CPACK_PACKAGE_ARCHITECTURE}")
		else()
			set(sBinarySystem "${NX_TARGET_PLATFORM_STRING}-${CPACK_PACKAGE_ARCHITECTURE}")
		endif()
	endif()

	if(NOT DEFINED CPACK_SYSTEM_NAME)
		if(NX_TARGET_ARCHITECTURE_GENERIC OR NOT bPrimaryCompiled)
			nx_set(CPACK_SYSTEM_NAME "${sGenericSystem}")
		else()
			nx_set(CPACK_SYSTEM_NAME "${sBinarySystem}")
		endif()
	endif()

	if(NOT DEFINED CPACK_DEBIAN_PACKAGE_ARCHITECTURE)
		if(NX_TARGET_ARCHITECTURE_GENERIC OR NOT bPrimaryCompiled)
			nx_set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "all")
		elseif(NX_TARGET_ARCHITECTURE_AMD64)
			nx_set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "amd64")
		elseif(NX_TARGET_ARCHITECTURE_ARM64)
			nx_set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "arm64")
		elseif(NX_TARGET_ARCHITECTURE_ARMV7)
			nx_set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "armhf")
		elseif(NX_TARGET_ARCHITECTURE_IA32)
			nx_set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "i386")
		elseif(NX_TARGET_ARCHITECTURE_RV64)
			nx_set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "riscv64")
		endif()
	endif()
	if(DEFINED NX_INSTALL_CROSS AND NX_INSTALL_CROSS)
		if(DEFINED CPACK_DEBIAN_PACKAGE_ARCHITECTURE AND NOT CPACK_DEBIAN_PACKAGE_ARCHITECTURE STREQUAL "all")
			nx_set(CPACK_DEBIAN_CROSS_ARCHITECTURE "${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}")
			if(NX_HOST_ARCHITECTURE_AMD64)
				nx_set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "amd64")
				if(CPACK_DEBIAN_PACKAGE_ARCHITECTURE STREQUAL CPACK_DEBIAN_CROSS_ARCHITECTURE)
					nx_set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "i386")
				endif()
			elseif(NX_HOST_ARCHITECTURE_ARM64)
				nx_set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "arm64")
			elseif(NX_HOST_ARCHITECTURE_ARMV7)
				nx_set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "armhf")
			elseif(NX_HOST_ARCHITECTURE_IA32)
				nx_set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "i386")
			elseif(NX_HOST_ARCHITECTURE_RV64)
				nx_set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "riscv64")
			else()
				nx_set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE)
			endif()
		endif()
	endif()

	if(NOT DEFINED CPACK_MSIX_PACKAGE_ARCHITECTURE)
		if(NX_TARGET_ARCHITECTURE_GENERIC OR NOT bPrimaryCompiled)
			nx_set(CPACK_MSIX_PACKAGE_ARCHITECTURE "Neutral")
		elseif(NX_TARGET_ARCHITECTURE_AMD64)
			nx_set(CPACK_MSIX_PACKAGE_ARCHITECTURE "x64")
		elseif(NX_TARGET_ARCHITECTURE_ARM64)
			nx_set(CPACK_MSIX_PACKAGE_ARCHITECTURE "ARM64")
		elseif(NX_TARGET_ARCHITECTURE_ARMV7)
			nx_set(CPACK_MSIX_PACKAGE_ARCHITECTURE "ARM")
		elseif(NX_TARGET_ARCHITECTURE_IA32)
			nx_set(CPACK_MSIX_PACKAGE_ARCHITECTURE "x86")
		endif()
	endif()
	if(DEFINED NX_INSTALL_CROSS AND NX_INSTALL_CROSS)
		nx_set(CPACK_MSIX_PACKAGE_ARCHITECTURE)
	endif()

	if(NOT DEFINED CPACK_NSIS_PACKAGE_ARCHITECTURE)
		if(NX_TARGET_ARCHITECTURE_GENERIC)
			if("x$ENV{MSYSTEM}" MATCHES "64")
				nx_set(CPACK_NSIS_PACKAGE_ARCHITECTURE "amd64-unicode")
			elseif("x$ENV{MSYSTEM}" MATCHES "32")
				nx_set(CPACK_NSIS_PACKAGE_ARCHITECTURE "x86-unicode")
			elseif(NX_HOST_ARCHITECTURE_AMD64)
				nx_set(CPACK_NSIS_PACKAGE_ARCHITECTURE "amd64-unicode")
			elseif(NX_HOST_ARCHITECTURE_IA32)
				nx_set(CPACK_NSIS_PACKAGE_ARCHITECTURE "x86-unicode")
			endif()
		elseif(NX_TARGET_ARCHITECTURE_AMD64)
			nx_set(CPACK_NSIS_PACKAGE_ARCHITECTURE "amd64-unicode")
		elseif(NX_TARGET_ARCHITECTURE_IA32)
			nx_set(CPACK_NSIS_PACKAGE_ARCHITECTURE "x86-unicode")
		endif()
	endif()
	if(DEFINED NX_INSTALL_CROSS AND NX_INSTALL_CROSS)
		nx_set(CPACK_NSIS_PACKAGE_ARCHITECTURE)
	endif()

	if(NOT DEFINED CPACK_PKGBUILD_PACKAGE_ARCHITECTURE)
		if(NX_TARGET_ARCHITECTURE_GENERIC OR NOT bPrimaryCompiled)
			nx_set(CPACK_PKGBUILD_PACKAGE_ARCHITECTURE "any")
		elseif(NX_TARGET_ARCHITECTURE_AMD64)
			nx_set(CPACK_PKGBUILD_PACKAGE_ARCHITECTURE "x86_64")
		elseif(NX_TARGET_ARCHITECTURE_ARM64)
			nx_set(CPACK_PKGBUILD_PACKAGE_ARCHITECTURE "aarch64")
		elseif(NX_TARGET_ARCHITECTURE_ARMV7)
			nx_set(CPACK_PKGBUILD_PACKAGE_ARCHITECTURE "armv7h")
		elseif(NX_TARGET_ARCHITECTURE_IA32)
			nx_set(CPACK_PKGBUILD_PACKAGE_ARCHITECTURE "i686")
		elseif(NX_TARGET_ARCHITECTURE_RV64)
			nx_set(CPACK_PKGBUILD_PACKAGE_ARCHITECTURE "riscv64")
		endif()
	endif()
	if(DEFINED NX_INSTALL_CROSS AND NX_INSTALL_CROSS)
		if(DEFINED CPACK_PKGBUILD_PACKAGE_ARCHITECTURE AND NOT CPACK_PKGBUILD_PACKAGE_ARCHITECTURE STREQUAL "any")
			nx_set(CPACK_PKGBUILD_CROSS_ARCHITECTURE "${CPACK_PKGBUILD_PACKAGE_ARCHITECTURE}")
			if(NX_HOST_ARCHITECTURE_AMD64)
				nx_set(CPACK_PKGBUILD_PACKAGE_ARCHITECTURE "x86_64")
				if(CPACK_PKGBUILD_PACKAGE_ARCHITECTURE STREQUAL CPACK_PKGBUILD_CROSS_ARCHITECTURE)
					nx_set(CPACK_PKGBUILD_PACKAGE_ARCHITECTURE "i686")
				endif()
			elseif(NX_HOST_ARCHITECTURE_ARM64)
				nx_set(CPACK_PKGBUILD_PACKAGE_ARCHITECTURE "aarch64")
			elseif(NX_HOST_ARCHITECTURE_ARMV7)
				nx_set(CPACK_PKGBUILD_PACKAGE_ARCHITECTURE "armv7h")
			elseif(NX_HOST_ARCHITECTURE_IA32)
				nx_set(CPACK_PKGBUILD_PACKAGE_ARCHITECTURE "i686")
			elseif(NX_HOST_ARCHITECTURE_RV64)
				nx_set(CPACK_PKGBUILD_PACKAGE_ARCHITECTURE "riscv64")
			else()
				nx_set(CPACK_PKGBUILD_PACKAGE_ARCHITECTURE)
			endif()
		endif()
	endif()

	if(NOT DEFINED CPACK_MINGW_PACKAGE_ARCHITECTURE)
		nx_set(CPACK_MINGW_PACKAGE_ARCHITECTURE "any")
	endif()

	if(NOT DEFINED CPACK_RPM_PACKAGE_ARCHITECTURE)
		if(NX_TARGET_ARCHITECTURE_GENERIC OR NOT bPrimaryCompiled)
			nx_set(CPACK_RPM_PACKAGE_ARCHITECTURE "noarch")
		elseif(NX_TARGET_ARCHITECTURE_AMD64)
			nx_set(CPACK_RPM_PACKAGE_ARCHITECTURE "x86_64")
		elseif(NX_TARGET_ARCHITECTURE_ARM64)
			nx_set(CPACK_RPM_PACKAGE_ARCHITECTURE "aarch64")
		elseif(NX_TARGET_ARCHITECTURE_ARMV7)
			nx_set(CPACK_RPM_PACKAGE_ARCHITECTURE "armv7h")
		elseif(NX_TARGET_ARCHITECTURE_IA32)
			nx_set(CPACK_RPM_PACKAGE_ARCHITECTURE "i686")
		elseif(NX_TARGET_ARCHITECTURE_RV64)
			nx_set(CPACK_RPM_PACKAGE_ARCHITECTURE "riscv64")
		endif()
	endif()
	if(DEFINED NX_INSTALL_CROSS AND NX_INSTALL_CROSS)
		if(DEFINED CPACK_RPM_PACKAGE_ARCHITECTURE AND NOT CPACK_RPM_PACKAGE_ARCHITECTURE STREQUAL "noarch")
			nx_set(CPACK_RPM_CROSS_ARCHITECTURE "${CPACK_RPM_PACKAGE_ARCHITECTURE}")
			if(NX_HOST_ARCHITECTURE_AMD64)
				nx_set(CPACK_RPM_PACKAGE_ARCHITECTURE "x86_64")
				if(CPACK_RPM_PACKAGE_ARCHITECTURE STREQUAL CPACK_RPM_CROSS_ARCHITECTURE)
					nx_set(CPACK_RPM_PACKAGE_ARCHITECTURE "i686")
				endif()
			elseif(NX_HOST_ARCHITECTURE_ARM64)
				nx_set(CPACK_RPM_PACKAGE_ARCHITECTURE "aarch64")
			elseif(NX_HOST_ARCHITECTURE_ARMV7)
				nx_set(CPACK_RPM_PACKAGE_ARCHITECTURE "armv7h")
			elseif(NX_HOST_ARCHITECTURE_IA32)
				nx_set(CPACK_RPM_PACKAGE_ARCHITECTURE "i686")
			elseif(NX_HOST_ARCHITECTURE_RV64)
				nx_set(CPACK_RPM_PACKAGE_ARCHITECTURE "riscv64")
			else()
				nx_set(CPACK_RPM_PACKAGE_ARCHITECTURE)
			endif()
		endif()
	endif()

	foreach(sComponent ${lsProjectComponents})
		if(sComponent MATCHES "^(DEV|DAT|DOC)$")
			nx_set_global(CPACK_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_ARCHITECTURE "Generic")
			nx_set_global(CPACK_DEBIAN_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_ARCHITECTURE "all")
			nx_set_global(CPACK_PKGBUILD_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_ARCHITECTURE "any")
			nx_set_global(CPACK_RPM_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_ARCHITECTURE "noarch")
			nx_set_global(CPACK_${NX_PROJECT_NAME}_${sComponent}_SYSTEM_NAME "${sGenericSystem}")
		else()
			nx_set_global(CPACK_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_ARCHITECTURE "${CPACK_PACKAGE_ARCHITECTURE}")
			nx_set_global(CPACK_DEBIAN_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_ARCHITECTURE "${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}")
			nx_set_global(CPACK_PKGBUILD_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_ARCHITECTURE "${CPACK_PKGBUILD_PACKAGE_ARCHITECTURE}")
			nx_set_global(CPACK_RPM_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_ARCHITECTURE "${CPACK_RPM_PACKAGE_ARCHITECTURE}")
			nx_set_global(CPACK_${NX_PROJECT_NAME}_${sComponent}_SYSTEM_NAME "${sBinarySystem}")

			if(DEFINED CPACK_CROSS_ARCHITECTURE)
				nx_set_global(CPACK_${NX_PROJECT_NAME}_${sComponent}_CROSS_ARCHITECTURE "${CPACK_CROSS_ARCHITECTURE}")
			endif()
			if(DEFINED CPACK_DEBIAN_CROSS_ARCHITECTURE)
				nx_set_global(CPACK_DEBIAN_${NX_PROJECT_NAME}_${sComponent}_CROSS_ARCHITECTURE "${CPACK_DEBIAN_CROSS_ARCHITECTURE}")
			endif()
			if(DEFINED CPACK_PKGBUILD_CROSS_ARCHITECTURE)
				nx_set_global(CPACK_PKGBUILD_${NX_PROJECT_NAME}_${sComponent}_CROSS_ARCHITECTURE "${CPACK_PKGBUILD_CROSS_ARCHITECTURE}")
			endif()
			if(DEFINED CPACK_RPM_CROSS_ARCHITECTURE)
				nx_set_global(CPACK_RPM_${NX_PROJECT_NAME}_${sComponent}_CROSS_ARCHITECTURE "${CPACK_RPM_CROSS_ARCHITECTURE}")
			endif()
		endif()
	endforeach()

	# ---- CPack Package Name ----

	unset(sVersionCompat)
	if(DEFINED ${NX_PROJECT_NAME}_PROJECT_SOVERSION_COMPAT)
		string(REPLACE "." "-" sVersionCompat "${${NX_PROJECT_NAME}_PROJECT_SOVERSION_COMPAT}")
	endif()

	if(NOT ${NX_PROJECT_NAME}_PROJECT_NAME STREQUAL "${${NX_PROJECT_NAME}_PROJECT_PARENT}")
		set(sGenericName "${${NX_PROJECT_NAME}_PROJECT_PARENT}-${${NX_PROJECT_NAME}_PROJECT_NAME}")
		if(NOT sGenericName MATCHES "^lib|-lib")
			set(sGenericLib "${${NX_PROJECT_NAME}_PROJECT_PARENT}-lib${${NX_PROJECT_NAME}_PROJECT_NAME}")
		else()
			set(sGenericLib "${sGenericName}")
		endif()
	else()
		set(sGenericName "${${NX_PROJECT_NAME}_PROJECT_NAME}")
		if(NOT sGenericName MATCHES "^lib|-lib")
			set(sGenericLib "lib${${NX_PROJECT_NAME}_PROJECT_NAME}")
		else()
			set(sGenericLib "${sGenericName}")
		endif()
	endif()

	if(NX_HOST_LANGUAGE_CXX AND DEFINED NX_TARGET_CXXABI_STRING)
		set(sBinaryName "${sGenericName}-${NX_TARGET_CXXABI_STRING}")
		set(sBinaryLib "${sGenericLib}-${NX_TARGET_CXXABI_STRING}")
	else()
		set(sBinaryName "${sGenericName}")
		set(sBinaryLib "${sGenericLib}${sVersionCompat}")
	endif()
	if(DEFINED CPACK_CROSS_ARCHITECTURE)
		set(sBinaryName "${sBinaryName}-${CPACK_CROSS_ARCHITECTURE}-cross")
		if(NX_TARGET_ARCHITECTURE_AMD64 AND NOT DEFINED CMAKE_LIBRARY_ARCHITECTURE)
			string(REGEX REPLACE "^lib" "lib64" sBinaryLib "${sBinaryLib}")
		elseif(NX_TARGET_ARCHITECTURE_IA32 AND NOT DEFINED CMAKE_LIBRARY_ARCHITECTURE)
			string(REGEX REPLACE "^lib" "lib32" sBinaryLib "${sBinaryLib}")
		else()
			set(sBinaryLib "${sBinaryLib}-${CPACK_CROSS_ARCHITECTURE}-cross")
		endif()
	endif()

	if(DEFINED CPACK_PACKAGE_NAME)
		set(sBinaryName "${CPACK_PACKAGE_NAME}")
		set(sBinaryLib "${CPACK_PACKAGE_NAME}")
	endif()
	if(DEFINED CPACK_SOURCE_PACKAGE_NAME)
		set(sGenericName "${CPACK_SOURCE_PACKAGE_NAME}")
		set(sGenericLib "${CPACK_SOURCE_PACKAGE_NAME}")
	endif()
	if(bPrimaryLibrary)
		if(NOT DEFINED CPACK_SOURCE_PACKAGE_NAME)
			nx_set(CPACK_SOURCE_PACKAGE_NAME "${sGenericLib}")
		endif()
		if(NOT DEFINED CPACK_PACKAGE_NAME)
			if(NOT NX_TARGET_ARCHITECTURE_GENERIC AND bPrimaryCompiled)
				nx_set(CPACK_PACKAGE_NAME "${sBinaryLib}")
			else()
				nx_set(CPACK_PACKAGE_NAME "${CPACK_SOURCE_PACKAGE_NAME}")
			endif()
		endif()
	else()
		if(NOT DEFINED CPACK_SOURCE_PACKAGE_NAME)
			nx_set(CPACK_SOURCE_PACKAGE_NAME "${sGenericName}")
		endif()
		if(NOT DEFINED CPACK_PACKAGE_NAME)
			if(NOT NX_TARGET_ARCHITECTURE_GENERIC AND bPrimaryCompiled)
				nx_set(CPACK_PACKAGE_NAME "${sBinaryName}")
			else()
				nx_set(CPACK_PACKAGE_NAME "${CPACK_SOURCE_PACKAGE_NAME}")
			endif()
		endif()
	endif()

	if(DEFINED CPACK_DEBIAN_PACKAGE_NAME)
		set(sBinaryNameDEB "${CPACK_DEBIAN_PACKAGE_NAME}")
		set(sBinaryLibDEB "${CPACK_DEBIAN_PACKAGE_NAME}")
	else()
		string(REPLACE "${CPACK_CROSS_ARCHITECTURE}-cross" "${CPACK_DEBIAN_CROSS_ARCHITECTURE}-cross" sBinaryNameDEB "${sBinaryName}")
		string(REPLACE "${CPACK_CROSS_ARCHITECTURE}-cross" "${CPACK_DEBIAN_CROSS_ARCHITECTURE}-cross" sBinaryLibDEB "${sBinaryLib}")
		string(TOLOWER "${sBinaryNameDEB}" sBinaryNameDEB)
		string(TOLOWER "${sBinaryLibDEB}" sBinaryLibDEB)
	endif()
	if(DEFINED CPACK_DEBIAN_PACKAGE_SOURCE)
		set(sGenericNameDEB "${CPACK_DEBIAN_PACKAGE_SOURCE}")
		set(sGenericLibDEB "${CPACK_DEBIAN_PACKAGE_SOURCE}")
	else()
		string(TOLOWER "${sGenericName}" sGenericNameDEB)
		string(TOLOWER "${sGenericLib}" sGenericLibDEB)
	endif()
	if(bPrimaryLibrary)
		if(NOT DEFINED CPACK_DEBIAN_PACKAGE_SOURCE)
			nx_set(CPACK_DEBIAN_PACKAGE_SOURCE "${sGenericLibDEB}")
		endif()
		if(NOT DEFINED CPACK_DEBIAN_PACKAGE_NAME)
			if(NOT NX_TARGET_ARCHITECTURE_GENERIC AND bPrimaryCompiled)
				nx_set(CPACK_DEBIAN_PACKAGE_NAME "${sBinaryLibDEB}")
			else()
				nx_set(CPACK_DEBIAN_PACKAGE_NAME "${CPACK_DEBIAN_PACKAGE_SOURCE}")
			endif()
		endif()
	else()
		if(NOT DEFINED CPACK_DEBIAN_PACKAGE_SOURCE)
			nx_set(CPACK_DEBIAN_PACKAGE_SOURCE "${sGenericNameDEB}")
		endif()
		if(NOT DEFINED CPACK_DEBIAN_PACKAGE_NAME)
			if(NOT NX_TARGET_ARCHITECTURE_GENERIC AND bPrimaryCompiled)
				nx_set(CPACK_DEBIAN_PACKAGE_NAME "${sBinaryNameDEB}")
			else()
				nx_set(CPACK_DEBIAN_PACKAGE_NAME "${CPACK_DEBIAN_PACKAGE_SOURCE}")
			endif()
		endif()
	endif()

	if(DEFINED CPACK_PKGBUILD_PACKAGE_NAME)
		set(sBinaryNamePKG "${CPACK_PKGBUILD_PACKAGE_NAME}")
		set(sBinaryLibPKG "${CPACK_PKGBUILD_PACKAGE_NAME}")
	else()
		string(REPLACE "${CPACK_CROSS_ARCHITECTURE}-cross" "${CPACK_PKGBUILD_CROSS_ARCHITECTURE}-cross" sBinaryNamePKG "${sBinaryName}")
		string(REPLACE "${CPACK_CROSS_ARCHITECTURE}-cross" "${CPACK_PKGBUILD_CROSS_ARCHITECTURE}-cross" sBinaryLibPKG "${sBinaryLib}")
		string(TOLOWER "${sBinaryNamePKG}" sBinaryNamePKG)
		string(TOLOWER "${sBinaryLibPKG}" sBinaryLibPKG)
	endif()
	if(DEFINED CPACK_PKGBUILD_PACKAGE_SOURCE)
		set(sGenericNamePKG "${CPACK_PKGBUILD_PACKAGE_SOURCE}")
		set(sGenericLibPKG "${CPACK_PKGBUILD_PACKAGE_SOURCE}")
	else()
		string(TOLOWER "${sGenericName}" sGenericNamePKG)
		string(TOLOWER "${sGenericLib}" sGenericLibPKG)
	endif()
	if(bPrimaryLibrary)
		if(NOT DEFINED CPACK_PKGBUILD_PACKAGE_SOURCE)
			nx_set(CPACK_PKGBUILD_PACKAGE_SOURCE "${sGenericLibPKG}")
		endif()
		if(NOT DEFINED CPACK_PKGBUILD_PACKAGE_NAME)
			if(NOT NX_TARGET_ARCHITECTURE_GENERIC AND bPrimaryCompiled)
				nx_set(CPACK_PKGBUILD_PACKAGE_NAME "${sBinaryLibPKG}")
			else()
				nx_set(CPACK_PKGBUILD_PACKAGE_NAME "${CPACK_PKGBUILD_PACKAGE_SOURCE}")
			endif()
		endif()
	else()
		if(NOT DEFINED CPACK_PKGBUILD_PACKAGE_SOURCE)
			nx_set(CPACK_PKGBUILD_PACKAGE_SOURCE "${sGenericNamePKG}")
		endif()
		if(NOT DEFINED CPACK_PKGBUILD_PACKAGE_NAME)
			if(NOT NX_TARGET_ARCHITECTURE_GENERIC AND bPrimaryCompiled)
				nx_set(CPACK_PKGBUILD_PACKAGE_NAME "${sBinaryNamePKG}")
			else()
				nx_set(CPACK_PKGBUILD_PACKAGE_NAME "${CPACK_PKGBUILD_PACKAGE_SOURCE}")
			endif()
		endif()
	endif()

	if(DEFINED CPACK_RPM_PACKAGE_NAME)
		set(sBinaryNameRPM "${CPACK_RPM_PACKAGE_NAME}")
		set(sBinaryLibRPM "${CPACK_RPM_PACKAGE_NAME}")
	else()
		string(REPLACE "${CPACK_CROSS_ARCHITECTURE}-cross" "${CPACK_RPM_CROSS_ARCHITECTURE}-cross" sBinaryNameRPM "${sBinaryName}")
		string(REPLACE "${CPACK_CROSS_ARCHITECTURE}-cross" "${CPACK_RPM_CROSS_ARCHITECTURE}-cross" sBinaryLibRPM "${sBinaryLib}")
		string(TOLOWER "${sBinaryNameRPM}" sBinaryNameRPM)
		string(TOLOWER "${sBinaryLibRPM}" sBinaryLibRPM)
	endif()
	if(DEFINED CPACK_RPM_PACKAGE_SOURCE)
		set(sGenericNameRPM "${CPACK_RPM_PACKAGE_SOURCE}")
		set(sGenericLibRPM "${CPACK_RPM_PACKAGE_SOURCE}")
	else()
		string(TOLOWER "${sGenericName}" sGenericNameRPM)
		string(TOLOWER "${sGenericLib}" sGenericLibRPM)
	endif()
	if(bPrimaryLibrary)
		if(NOT DEFINED CPACK_RPM_PACKAGE_SOURCE)
			nx_set(CPACK_RPM_PACKAGE_SOURCE "${sGenericLibRPM}")
		endif()
		if(NOT DEFINED CPACK_RPM_PACKAGE_NAME)
			if(NOT NX_TARGET_ARCHITECTURE_GENERIC AND bPrimaryCompiled)
				nx_set(CPACK_RPM_PACKAGE_NAME "${sBinaryLibRPM}")
			else()
				nx_set(CPACK_RPM_PACKAGE_NAME "${CPACK_RPM_PACKAGE_SOURCE}")
			endif()
		endif()
	else()
		if(NOT DEFINED CPACK_RPM_PACKAGE_SOURCE)
			nx_set(CPACK_RPM_PACKAGE_SOURCE "${sGenericNameRPM}")
		endif()
		if(NOT DEFINED CPACK_RPM_PACKAGE_NAME)
			if(NOT NX_TARGET_ARCHITECTURE_GENERIC AND bPrimaryCompiled)
				nx_set(CPACK_RPM_PACKAGE_NAME "${sBinaryNameRPM}")
			else()
				nx_set(CPACK_RPM_PACKAGE_NAME "${CPACK_RPM_PACKAGE_SOURCE}")
			endif()
		endif()
	endif()

	if(NOT DEFINED CPACK_MINGW_PACKAGE_NAME)
		nx_set(CPACK_MINGW_PACKAGE_NAME "\${MINGW_PACKAGE_PREFIX}-${CPACK_PKGBUILD_PACKAGE_NAME}")
	endif()
	if(NOT DEFINED CPACK_MINGW_PACKAGE_SOURCE)
		nx_set(CPACK_MINGW_PACKAGE_SOURCE "mingw-w64-${CPACK_PKGBUILD_PACKAGE_SOURCE}")
	endif()

	if(NOT DEFINED CPACK_NSIS_PACKAGE_NAME)
		nx_set(CPACK_NSIS_PACKAGE_NAME "${CPACK_PACKAGE_NAME}")
	endif()
	if(NOT DEFINED CPACK_NSIS_DISPLAY_NAME)
		nx_set(CPACK_NSIS_DISPLAY_NAME "${CPACK_NSIS_PACKAGE_NAME}")
	endif()

	set(sComponentSuffixAPP "-gui")
	set(sComponentSuffixSRV "-server")
	set(sComponentSuffixBIN "-tools")
	set(sComponentSuffixMOD "-plugin")
	set(sComponentSuffixLIB "-libs")
	set(sComponentSuffixOBJ "-static")
	set(sComponentSuffixDEV "-dev")
	set(sComponentSuffixDAT "-common")
	set(sComponentSuffixDOC "-doc")
	set(sComponentSuffixDBG "-dbg")
	set(sComponentSuffixRTM "-deps")

	foreach(sComponent ${lsProjectComponents})
		unset(sComponentSuffix${sComponent}_ALT)
	endforeach()
	set(sComponentSuffixOBJ_ALT "-devel")
	set(sComponentSuffixDEV_ALT "-devel")
	set(sComponentSuffixDBG_ALT "-debug")

	set(bHasMainComponent OFF)

	foreach(sComponent ${lsProjectComponents})
		set(bComponentNoArch OFF)
		if(sComponent MATCHES "^(DEV|DAT|DOC)$")
			set(bComponentNoArch ON)
			set(sPkgNameZIP "${CPACK_SOURCE_PACKAGE_NAME}")
			set(sPkgNameDEB "${CPACK_DEBIAN_PACKAGE_SOURCE}")
			set(sPkgNamePKG "${CPACK_PKGBUILD_PACKAGE_SOURCE}")
			set(sPkgNameRPM "${CPACK_RPM_PACKAGE_SOURCE}")
		elseif(sComponent MATCHES "^(LIB|OBJ)$")
			set(sPkgNameZIP "${sBinaryLib}")
			set(sPkgNameDEB "${sBinaryLibDEB}")
			set(sPkgNamePKG "${sBinaryLibPKG}")
			set(sPkgNameRPM "${sBinaryLibRPM}")
		else()
			set(sPkgNameZIP "${CPACK_PACKAGE_NAME}")
			set(sPkgNameDEB "${CPACK_DEBIAN_PACKAGE_NAME}")
			set(sPkgNamePKG "${CPACK_PKGBUILD_PACKAGE_NAME}")
			set(sPkgNameRPM "${CPACK_RPM_PACKAGE_NAME}")
		endif()

		nx_set_global(CPACK_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME "${sPkgNameZIP}${sComponentSuffix${sComponent}}")
		nx_set_global(CPACK_DEBIAN_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME "${sPkgNameDEB}${sComponentSuffix${sComponent}}")

		if(DEFINED sComponentSuffix${sComponent}_ALT)
			nx_set_global(CPACK_PKGBUILD_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME "${sPkgNamePKG}${sComponentSuffix${sComponent}_ALT}")
			nx_set_global(CPACK_RPM_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME "${sPkgNameRPM}${sComponentSuffix${sComponent}_ALT}")
		else()
			nx_set_global(CPACK_PKGBUILD_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME "${sPkgNamePKG}${sComponentSuffix${sComponent}}")
			nx_set_global(CPACK_RPM_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME "${sPkgNameRPM}${sComponentSuffix${sComponent}}")
		endif()

		if(NOT bHasMainComponent AND NOT sComponent MATCHES "^(OBJ|DEV|DOC|DBG|RTM)$")
			set(bHasMainComponent ON)
			nx_set_global(CPACK_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME "${sPkgNameZIP}")
			nx_set_global(CPACK_DEBIAN_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME "${sPkgNameDEB}")
			nx_set_global(CPACK_PKGBUILD_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME "${sPkgNamePKG}")
			nx_set_global(CPACK_RPM_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME "${sPkgNameRPM}")
			nx_set_global(CPACK_COMPONENT_${NX_PROJECT_NAME}_${sComponent}_REQUIRED ON)
			nx_set(CPACK_RPM_MAIN_COMPONENT "${NX_PROJECT_NAME}_${sComponent}")
		elseif(sComponent STREQUAL "LIB")
			if(NOT sPkgNameZIP STREQUAL "${CPACK_PACKAGE_NAME}")
				nx_set_global(CPACK_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME "${sPkgNameZIP}")
			endif()
			if(NOT sPkgNameDEB STREQUAL "${CPACK_DEBIAN_PACKAGE_NAME}")
				nx_set_global(CPACK_DEBIAN_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME "${sPkgNameDEB}")
			endif()
			if(NOT sPkgNamePKG STREQUAL "${CPACK_PKGBUILD_PACKAGE_NAME}")
				nx_set_global(CPACK_PKGBUILD_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME "${sPkgNamePKG}")
			endif()
			if(NOT sPkgNameRPM STREQUAL "${CPACK_RPM_PACKAGE_NAME}")
				nx_set_global(CPACK_RPM_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME "${sPkgNameRPM}")
			endif()
		endif()

		if(DEFINED CPACK_CROSS_ARCHITECTURE)
			string(REGEX
					REPLACE "-(${CPACK_CROSS_ARCHITECTURE}-cross)-([a-z]+)" "-\\2-\\1" CPACK_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME
							"${CPACK_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME}")
			string(
				REGEX
				REPLACE "-(${CPACK_DEBIAN_CROSS_ARCHITECTURE}-cross)-([a-z]+)" "-\\2-\\1"
						CPACK_DEBIAN_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME
						"${CPACK_DEBIAN_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME}")
			string(
				REGEX
				REPLACE "-(${CPACK_PKGBUILD_CROSS_ARCHITECTURE}-cross)-([a-z]+)" "-\\2-\\1"
						CPACK_PKGBUILD_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME
						"${CPACK_PKGBUILD_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME}")
			string(
				REGEX
				REPLACE "-(${CPACK_RPM_CROSS_ARCHITECTURE}-cross)-([a-z]+)" "-\\2-\\1"
						CPACK_RPM_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME
						"${CPACK_RPM_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME}")
		endif()

		nx_set_global(CPACK_COMPONENT_${NX_PROJECT_NAME}_${sComponent}_DISPLAY_NAME
						"${CPACK_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME}")
	endforeach()

	# ---- CPack Package Version ----

	set(bPkgVerUndefined ON)
	unset(nVersionMajor)
	unset(nVersionMinor)
	unset(nVersionPatch)
	unset(nVersionTweak)

	if(DEFINED CPACK_PACKAGE_VERSION)
		string(REPLACE "." ";" lsVersions "${CPACK_PACKAGE_VERSION}")
		list(LENGTH lsVersions nVersions)
		if(nVersions GREATER 0)
			list(GET lsVersions 0 nVersionMajor)
		endif()
		if(nVersions GREATER 1)
			list(GET lsVersions 1 nVersionMinor)
		endif()
		if(nVersions GREATER 2)
			list(GET lsVersions 2 nVersionPatch)
		endif()
		if(nVersions GREATER 3)
			list(GET lsVersions 3 nVersionTweak)
		endif()
		set(bPkgVerUndefined OFF)
	endif()

	if(DEFINED CPACK_PACKAGE_VERSION_TWEAK)
		set(nVersionTweak ${CPACK_PACKAGE_VERSION_TWEAK})
		set(bPkgVerUndefined OFF)
	endif()
	if(DEFINED CPACK_PACKAGE_VERSION_PATCH)
		set(nVersionPatch ${CPACK_PACKAGE_VERSION_PATCH})
		set(bPkgVerUndefined OFF)
	elseif(NOT DEFINED nVersionPatch AND DEFINED nVersionTweak)
		set(nVersionPatch 0)
	endif()
	if(DEFINED CPACK_PACKAGE_VERSION_MINOR)
		set(nVersionMinor ${CPACK_PACKAGE_VERSION_MINOR})
		set(bPkgVerUndefined OFF)
	elseif(NOT DEFINED nVersionMinor AND DEFINED nVersionPatch)
		set(nVersionMinor 0)
	endif()
	if(DEFINED CPACK_PACKAGE_VERSION_MAJOR)
		set(nVersionMajor ${CPACK_PACKAGE_VERSION_MAJOR})
		set(bPkgVerUndefined OFF)
	elseif(NOT DEFINED nVersionMajor AND DEFINED nVersionMinor)
		set(nVersionMajor 0)
	endif()

	if(DEFINED ${NX_PROJECT_NAME}_PROJECT_VERSION AND bPkgVerUndefined)
		string(REPLACE "." ";" lsVersions "${${NX_PROJECT_NAME}_PROJECT_VERSION}")
		list(LENGTH lsVersions nVersions)
		if(nVersions GREATER 0)
			list(GET lsVersions 0 nVersionMajor)
		endif()
		if(nVersions GREATER 1)
			list(GET lsVersions 1 nVersionMinor)
		endif()
		if(nVersions GREATER 2)
			list(GET lsVersions 2 nVersionPatch)
		endif()
		if(nVersions GREATER 3)
			list(GET lsVersions 3 nVersionTweak)
		endif()
	endif()

	if(DEFINED nVersionMajor AND NOT DEFINED CPACK_PACKAGE_VERSION_MAJOR)
		nx_set(CPACK_PACKAGE_VERSION_MAJOR ${nVersionMajor})
	endif()
	if(DEFINED nVersionMinor AND NOT DEFINED CPACK_PACKAGE_VERSION_MINOR)
		nx_set(CPACK_PACKAGE_VERSION_MINOR ${nVersionMinor})
	endif()
	if(DEFINED nVersionPatch AND NOT DEFINED CPACK_PACKAGE_VERSION_PATCH)
		nx_set(CPACK_PACKAGE_VERSION_PATCH ${nVersionPatch})
	endif()
	if(DEFINED nVersionTweak AND NOT DEFINED CPACK_PACKAGE_VERSION_TWEAK)
		nx_set(CPACK_PACKAGE_VERSION_TWEAK ${nVersionTweak})
	endif()

	if(DEFINED nVersionMajor AND NOT DEFINED CPACK_PACKAGE_VERSION)
		unset(lsVersions)
		list(APPEND lsVersions ${nVersionMajor} ${nVersionMinor} ${nVersionPatch} ${nVersionTweak})
		string(REPLACE ";" "." sVersion "${lsVersions}")
		nx_set(CPACK_PACKAGE_VERSION "${sVersion}")
	endif()

	if(NOT DEFINED CPACK_PACKAGE_VERSION_MAJOR)
		nx_set(CPACK_PACKAGE_VERSION_MAJOR 0)
	endif()
	if(NOT DEFINED CPACK_PACKAGE_VERSION_MINOR)
		nx_set(CPACK_PACKAGE_VERSION_MINOR 0)
	endif()
	if(NOT DEFINED CPACK_PACKAGE_VERSION_PATCH)
		nx_set(CPACK_PACKAGE_VERSION_PATCH 0)
	endif()
	if(NOT DEFINED CPACK_PACKAGE_VERSION_TWEAK)
		nx_set(CPACK_PACKAGE_VERSION_TWEAK 0)
	endif()

	unset(sPkgVerCompat)
	if(DEFINED ${NX_PROJECT_NAME}_PROJECT_VERSION_COMPAT AND bPkgVerUndefined)
		set(sPkgVerCompat "${${NX_PROJECT_NAME}_PROJECT_VERSION_COMPAT}")
	endif()

	if(DEFINED ${NX_PROJECT_NAME}_PROJECT_VERSION_EXTRA AND bPkgVerUndefined)
		nx_set(CPACK_PACKAGE_VERSION "${CPACK_PACKAGE_VERSION}-${${NX_PROJECT_NAME}_PROJECT_VERSION_EXTRA}")
	elseif(CPACK_PACKAGE_VERSION_MAJOR EQUAL 0 AND bPkgVerUndefined)
		nx_set(CPACK_PACKAGE_VERSION "${CPACK_PACKAGE_VERSION}-indev")
	endif()

	unset(sPkgVerSCM)
	if(DEFINED NX_GIT_RETRIEVED_STATE AND NX_GIT_RETRIEVED_STATE)
		# list(APPEND sPkgVerSCM "g${NX_GIT_COMMIT_SHORT}") string(SUBSTRING "${NX_GIT_COMMIT_DATE}${NX_GIT_COMMIT_TIME}" 2 10 sPkgVerSCM)

		string(SUBSTRING "${NX_GIT_COMMIT_TIME}" 2 2 nPkgVerMinutes)
		string(SUBSTRING "${NX_GIT_COMMIT_TIME}" 0 2 nPkgVerHours)
		string(SUBSTRING "${NX_GIT_COMMIT_DATE}" 0 4 nPkgVerYear)
		string(SUBSTRING "${NX_GIT_COMMIT_DATE}" 4 2 nPkgVerMonth)
		string(SUBSTRING "${NX_GIT_COMMIT_DATE}" 6 2 nPkgVerDay)

		# Normalize Date

		math(EXPR nPkgVerYear "${nPkgVerYear} - 2005")
		math(EXPR nPkgVerMonth "${nPkgVerMonth} - 1")
		math(EXPR nPkgVerDay "${nPkgVerDay} - 1")

		# Pack It In

		# 64, 2048, 65536, 1048576
		set(nTimestamp "${nPkgVerMinutes}")
		math(EXPR nTimestamp "${nTimestamp} + (${nPkgVerHours} * 60)")
		math(EXPR nTimestamp "${nTimestamp} + (${nPkgVerDay} * 1440)")
		math(EXPR nTimestamp "${nTimestamp} + (${nPkgVerMonth} * 44640)")
		math(EXPR sPkgVerSCM "${nTimestamp} + (${nPkgVerYear} * 535680)" OUTPUT_FORMAT HEXADECIMAL)
		string(REPLACE "0x" "" sPkgVerSCM "${sPkgVerSCM}")

		if(NOT NX_GIT_COMMIT_BRANCH MATCHES "master|main|trunk")
			list(APPEND sPkgVerSCM "${NX_GIT_COMMIT_BRANCH}")
		endif()
		if(NX_GIT_COMMIT_DIRTY)
			list(APPEND sPkgVerSCM "dirty")
		endif()
	endif()
	if(DEFINED sPkgVerSCM AND bPkgVerUndefined)
		string(REGEX REPLACE "[-+_ .]" "" sPkgVerSCM "${sPkgVerSCM}")
		string(REPLACE ";" "." sPkgVerSCM "${sPkgVerSCM}")
		nx_set(CPACK_PACKAGE_VERSION "${CPACK_PACKAGE_VERSION}+${sPkgVerSCM}")
	endif()

	if(NOT DEFINED CPACK_DEBIAN_PACKAGE_VERSION AND DEFINED CPACK_PACKAGE_VERSION)
		string(REPLACE "+" "~" sVersion "${CPACK_PACKAGE_VERSION}")
		string(REPLACE "-" "+" sVersion "${sVersion}")
		nx_set(CPACK_DEBIAN_PACKAGE_VERSION "${sVersion}")
	endif()
	if(NOT DEFINED CPACK_DEBIAN_PACKAGE_RELEASE)
		if(NOT NX_TARGET_ARCHITECTURE_GENERIC AND bPrimaryCompiled)
			if(DEFINED sDistroCodename)
				nx_set(CPACK_DEBIAN_PACKAGE_RELEASE "1${sDistroCodename}1")
			elseif(DEFINED sDistroId)
				nx_set(CPACK_DEBIAN_PACKAGE_RELEASE "1${sDistroId}1")
			else()
				nx_set(CPACK_DEBIAN_PACKAGE_RELEASE 1)
			endif()
		else()
			nx_set(CPACK_DEBIAN_PACKAGE_RELEASE 1)
		endif()
	endif()

	if(NOT DEFINED CPACK_PKGBUILD_PACKAGE_VERSION)
		string(REPLACE "-" "_" sVersion "${CPACK_PACKAGE_VERSION}")
		nx_set(CPACK_PKGBUILD_PACKAGE_VERSION "${sVersion}")
	endif()
	if(NOT DEFINED CPACK_PKGBUILD_PACKAGE_RELEASE)
		nx_set(CPACK_PKGBUILD_PACKAGE_RELEASE 1)
	endif()

	set(sReleaseSrcRPM "${CPACK_RPM_PACKAGE_RELEASE}")
	if(NOT DEFINED CPACK_RPM_PACKAGE_VERSION)
		string(REPLACE "+" "~" sVersion "${CPACK_PACKAGE_VERSION}")
		string(REPLACE "-" "+" sVersion "${sVersion}")
		nx_set(CPACK_RPM_PACKAGE_VERSION "${sVersion}")
	endif()
	if(NOT DEFINED CPACK_RPM_PACKAGE_RELEASE)
		if(NOT NX_TARGET_ARCHITECTURE_GENERIC AND bPrimaryCompiled)
			if(DEFINED sDistroPlatform)
				nx_set(CPACK_RPM_PACKAGE_RELEASE "1.${sDistroPlatform}")
			else()
				nx_set(CPACK_RPM_PACKAGE_RELEASE 1)
			endif()
		else()
			nx_set(CPACK_RPM_PACKAGE_RELEASE 1)
		endif()
		set(sReleaseSrcRPM 1)
	endif()
	if(NOT DEFINED CPACK_RPM_PACKAGE_RELEASE_DIST)
		nx_set(CPACK_RPM_PACKAGE_RELEASE_DIST OFF)
	endif()

	# ---- CPack Package Contact ----

	unset(sPkgContactName)
	if(DEFINED ${NX_PROJECT_NAME}_PROJECT_MAINTAINER)
		set(sPkgContactName "${${NX_PROJECT_NAME}_PROJECT_MAINTAINER}")
	endif()

	unset(sPkgContactMail)
	if(DEFINED ${NX_PROJECT_NAME}_PROJECT_CONTACT)
		set(sPkgContactMail "${${NX_PROJECT_NAME}_PROJECT_CONTACT}")
	endif()

	if(NOT DEFINED CPACK_PACKAGE_CONTACT)
		if(DEFINED sPkgContactName)
			if(DEFINED sPkgContactMail)
				if(sPkgContactName MATCHES "\\.")
					nx_set(CPACK_PACKAGE_CONTACT "<${sPkgContactMail}> (${sPkgContactName})")
				else()
					nx_set(CPACK_PACKAGE_CONTACT "${sPkgContactName} <${sPkgContactMail}>")
				endif()
			else()
				nx_set(CPACK_PACKAGE_CONTACT "${sPkgContactName}")
			endif()
		elseif(DEFINED sPkgContactMail)
			nx_set(CPACK_PACKAGE_CONTACT "${sPkgContactMail}")
		endif()
	endif()

	if(NOT DEFINED CPACK_PACKAGE_VENDOR AND DEFINED ${NX_PROJECT_NAME}_PROJECT_VENDOR)
		nx_set(CPACK_PACKAGE_VENDOR "${${NX_PROJECT_NAME}_PROJECT_VENDOR}")
	endif()

	if(NOT DEFINED CPACK_PACKAGE_HOMEPAGE_URL AND DEFINED ${NX_PROJECT_NAME}_PROJECT_HOMEPAGE)
		nx_set(CPACK_PACKAGE_HOMEPAGE_URL "${${NX_PROJECT_NAME}_PROJECT_HOMEPAGE}")
	endif()

	if(NOT DEFINED CPACK_DEBIAN_PACKAGE_MAINTAINER AND DEFINED CPACK_PACKAGE_CONTACT)
		nx_set(CPACK_DEBIAN_PACKAGE_MAINTAINER "${CPACK_PACKAGE_CONTACT}")
	endif()
	if(NOT DEFINED CPACK_DEBIAN_PACKAGE_HOMEPAGE AND DEFINED CPACK_PACKAGE_HOMEPAGE_URL)
		nx_set(CPACK_DEBIAN_PACKAGE_HOMEPAGE "${CPACK_PACKAGE_HOMEPAGE_URL}")
	endif()

	if(NOT DEFINED CPACK_NSIS_CONTACT AND DEFINED CPACK_PACKAGE_CONTACT)
		nx_set(CPACK_NSIS_CONTACT "${CPACK_PACKAGE_CONTACT}")
	endif()
	if(NOT DEFINED CPACK_NSIS_HELP_LINK AND DEFINED ${NX_PROJECT_NAME}_PROJECT_SUPPORT)
		nx_set(CPACK_NSIS_HELP_LINK "${${NX_PROJECT_NAME}_PROJECT_SUPPORT}")
	endif()
	if(NOT DEFINED CPACK_NSIS_URL_INFO_ABOUT AND DEFINED CPACK_PACKAGE_HOMEPAGE_URL)
		nx_set(CPACK_NSIS_URL_INFO_ABOUT "${CPACK_PACKAGE_HOMEPAGE_URL}")
	endif()

	if(NOT DEFINED CPACK_PKGBUILD_PACKAGE_HOMEPAGE AND DEFINED CPACK_PACKAGE_HOMEPAGE_URL)
		nx_set(CPACK_PKGBUILD_PACKAGE_HOMEPAGE "${CPACK_PACKAGE_HOMEPAGE_URL}")
	endif()
	if(NOT DEFINED CPACK_PKGBUILD_PACKAGE_MAINTAINER AND DEFINED CPACK_PACKAGE_CONTACT)
		nx_set(CPACK_PKGBUILD_PACKAGE_MAINTAINER "${CPACK_PACKAGE_CONTACT}")
	endif()

	if(NOT DEFINED CPACK_RPM_PACKAGE_URL AND DEFINED CPACK_PACKAGE_HOMEPAGE_URL)
		nx_set(CPACK_RPM_PACKAGE_URL "${CPACK_PACKAGE_HOMEPAGE_URL}")
	endif()
	if(NOT DEFINED CPACK_RPM_PACKAGE_VENDOR AND DEFINED CPACK_PACKAGE_VENDOR)
		nx_set(CPACK_RPM_PACKAGE_VENDOR "${CPACK_PACKAGE_VENDOR}")
	endif()

	# ---- CPack Package Description ----

	if(NOT DEFINED CPACK_PACKAGE_DESCRIPTION_SUMMARY AND DEFINED ${NX_PROJECT_NAME}_PROJECT_SUMMARY)
		nx_set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${${NX_PROJECT_NAME}_PROJECT_SUMMARY}")
	endif()

	if(NOT DEFINED CPACK_RESOURCE_FILE_README)
		if(DEFINED ${NX_PROJECT_NAME}_FILE_README)
			nx_set(CPACK_RESOURCE_FILE_README "${${NX_PROJECT_NAME}_FILE_README}")
		else()
			file(
				GLOB lsCandidates
				LIST_DIRECTORIES false
				"docs/README"
				"docs/README.*"
				"docs/README-*"
				"docs/ReadMe"
				"docs/ReadMe.*"
				"docs/ReadMe-*"
				"README"
				"README.*"
				"README-*"
				"ReadMe"
				"ReadMe.*"
				"ReadMe-*")
			if(DEFINED lsCandidates AND lsCandidates)
				list(GET lsCandidates 0 sCandidate)
				nx_set(CPACK_RESOURCE_FILE_README "${sCandidate}")
			endif()
		endif()
	endif()

	if(NOT DEFINED CPACK_DEBIAN_PACKAGE_DESCRIPTION AND DEFINED CPACK_PACKAGE_DESCRIPTION_SUMMARY)
		nx_set(CPACK_DEBIAN_PACKAGE_DESCRIPTION "${CPACK_PACKAGE_DESCRIPTION_SUMMARY}")
	endif()

	if(NOT DEFINED CPACK_RPM_PACKAGE_SUMMARY AND DEFINED CPACK_PACKAGE_DESCRIPTION_SUMMARY)
		nx_set(CPACK_RPM_PACKAGE_SUMMARY "${CPACK_PACKAGE_DESCRIPTION_SUMMARY}")
	endif()

	# ---- CPack Package License ----

	if(NOT DEFINED CPACK_RESOURCE_FILE_LICENSE)
		if(DEFINED ${NX_PROJECT_NAME}_FILE_LICENSE)
			nx_set(CPACK_RESOURCE_FILE_LICENSE "${${NX_PROJECT_NAME}_FILE_LICENSE}")
		else()
			file(
				GLOB lsCandidates
				LIST_DIRECTORIES false
				"docs/COPYING"
				"docs/COPYING.*"
				"docs/LICENSE"
				"docs/LICENSE.*"
				"docs/LICENSE-*"
				"COPYING"
				"COPYING.*"
				"LICENSE"
				"LICENSE.*"
				"LICENSE-*")
			if(DEFINED lsCandidates AND lsCandidates)
				list(GET lsCandidates 0 sCandidate)
				nx_set(CPACK_RESOURCE_FILE_LICENSE "${sCandidate}")
			endif()
		endif()
	endif()

	if(NOT DEFINED CPACK_PKGBUILD_PACKAGE_LICENSE)
		nx_set(CPACK_PKGBUILD_PACKAGE_LICENSE "unknown")
	endif()

	if(NOT DEFINED CPACK_RPM_PACKAGE_LICENSE)
		nx_set(CPACK_RPM_PACKAGE_LICENSE "unknown")
	endif()

	# ---- CPack Package Files ----

	if(NOT DEFINED CPACK_PACKAGE_CHECKSUM)
		nx_set(CPACK_PACKAGE_CHECKSUM "SHA256")
	endif()
	string(TOLOWER "${CPACK_PACKAGE_CHECKSUM}sum" sChecksumType)
	string(TOLOWER "${CPACK_PACKAGE_CHECKSUM}" sChecksumExt)

	if(NOT DEFINED CPACK_PACKAGE_FILE_NAME)
		if(DEFINED CPACK_PACKAGE_VERSION)
			nx_set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}_${CPACK_PACKAGE_VERSION}_${CPACK_SYSTEM_NAME}")
		else()
			nx_set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}_${CPACK_SYSTEM_NAME}")
		endif()
	endif()

	if(NOT DEFINED CPACK_ARCHIVE_FILE_NAME)
		nx_set(CPACK_ARCHIVE_FILE_NAME "${CPACK_PACKAGE_FILE_NAME}")
	endif()

	if(NOT DEFINED CPACK_DEBIAN_FILE_NAME)
		nx_set(
			CPACK_DEBIAN_FILE_NAME
			"${CPACK_DEBIAN_PACKAGE_NAME}_${CPACK_DEBIAN_PACKAGE_VERSION}-${CPACK_DEBIAN_PACKAGE_RELEASE}_${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}.deb"
		)
	endif()

	if(NOT DEFINED CPACK_NSIS_FILE_NAME)
		string(REPLACE "-unicode" "" sNSIS_Architecture "${CPACK_NSIS_PACKAGE_ARCHITECTURE}")
		if(DEFINED CPACK_PACKAGE_VERSION)
			nx_set(CPACK_NSIS_FILE_NAME "${CPACK_NSIS_PACKAGE_NAME}_${CPACK_PACKAGE_VERSION}_${sNSIS_Architecture}")
		else()
			nx_set(CPACK_NSIS_FILE_NAME "${CPACK_NSIS_PACKAGE_NAME}_${sNSIS_Architecture}")
		endif()
	endif()

	if(NOT DEFINED CPACK_PKGBUILD_FILE_NAME)
		nx_set(
			CPACK_PKGBUILD_FILE_NAME
			"${CPACK_PKGBUILD_PACKAGE_NAME}-${CPACK_PKGBUILD_PACKAGE_VERSION}-${CPACK_PKGBUILD_PACKAGE_RELEASE}-${CPACK_PKGBUILD_PACKAGE_ARCHITECTURE}.pkg.tar.zst"
		)
	endif()
	if(NOT DEFINED CPACK_MINGW_FILE_NAME)
		nx_set(
			CPACK_MINGW_FILE_NAME
			"${CPACK_MINGW_PACKAGE_NAME}-${CPACK_PKGBUILD_PACKAGE_VERSION}-${CPACK_PKGBUILD_PACKAGE_RELEASE}-${CPACK_MINGW_PACKAGE_ARCHITECTURE}.pkg.tar.zst"
		)
	endif()

	if(NOT DEFINED CPACK_RPM_FILE_NAME)
		nx_set(CPACK_RPM_FILE_NAME
				"${CPACK_RPM_PACKAGE_NAME}-${CPACK_RPM_PACKAGE_VERSION}-${CPACK_RPM_PACKAGE_RELEASE}.${CPACK_RPM_PACKAGE_ARCHITECTURE}.rpm")
	endif()

	foreach(sComponent ${lsProjectComponents})
		if(DEFINED CPACK_PACKAGE_VERSION)
			nx_set_global(
				CPACK_ARCHIVE_${NX_PROJECT_NAME}_${sComponent}_FILE_NAME
				"${CPACK_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME}_${CPACK_PACKAGE_VERSION}_${CPACK_${NX_PROJECT_NAME}_${sComponent}_SYSTEM_NAME}"
			)
		else()
			nx_set_global(CPACK_ARCHIVE_${NX_PROJECT_NAME}_${sComponent}_FILE_NAME
							"${CPACK_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME}_${CPACK_${NX_PROJECT_NAME}_${sComponent}_SYSTEM_NAME}")
		endif()
		nx_set_global(
			CPACK_DEBIAN_${NX_PROJECT_NAME}_${sComponent}_FILE_NAME
			"${CPACK_DEBIAN_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME}_${CPACK_DEBIAN_PACKAGE_VERSION}-${CPACK_DEBIAN_PACKAGE_RELEASE}_${CPACK_DEBIAN_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_ARCHITECTURE}.deb"
		)
		nx_set_global(
			CPACK_PKGBUILD_${NX_PROJECT_NAME}_${sComponent}_FILE_NAME
			"${CPACK_PKGBUILD_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME}-${CPACK_PKGBUILD_PACKAGE_VERSION}-${CPACK_PKGBUILD_PACKAGE_RELEASE}-${CPACK_PKGBUILD_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_ARCHITECTURE}.pkg.tar.zst"
		)
		nx_set_global(
			CPACK_RPM_${NX_PROJECT_NAME}_${sComponent}_FILE_NAME
			"${CPACK_RPM_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_NAME}-${CPACK_RPM_PACKAGE_VERSION}-${CPACK_RPM_PACKAGE_RELEASE}.${CPACK_RPM_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_ARCHITECTURE}.rpm"
		)
	endforeach()

	# ---- CPack Source Files ----

	list(
		APPEND
		CPACK_SOURCE_IGNORE_FILES
		"${CMAKE_CURRENT_BINARY_DIR}"
		"/build.*/"
		"/\\\\..*/"
		"/\\\\..drone.yml$"
		"/\\\\..git*"
		"~$"
		"\\\\.code-workspace$"
		"\\\\.kate-swp$"
		"\\\\.kdev4$"
		"\\\\.swp$")

	if(NOT DEFINED CPACK_SOURCE_PACKAGE_FILE_NAME)
		if(DEFINED CPACK_PACKAGE_VERSION)
			nx_set(CPACK_SOURCE_PACKAGE_FILE_NAME "${CPACK_SOURCE_PACKAGE_NAME}-source_${CPACK_PACKAGE_VERSION}_Generic")
		else()
			nx_set(CPACK_SOURCE_PACKAGE_FILE_NAME "${CPACK_SOURCE_PACKAGE_NAME}-source_Generic")
		endif()
	endif()

	if(NOT DEFINED CPACK_PKGBUILD_FILE_SOURCE)
		nx_set(CPACK_PKGBUILD_FILE_SOURCE
				"${CPACK_PKGBUILD_PACKAGE_SOURCE}-${CPACK_PKGBUILD_PACKAGE_VERSION}-${CPACK_PKGBUILD_PACKAGE_RELEASE}.src.tar.gz")
	endif()
	if(NOT DEFINED CPACK_MINGW_FILE_SOURCE)
		nx_set(CPACK_MINGW_FILE_SOURCE
				"${CPACK_MINGW_PACKAGE_SOURCE}-${CPACK_PKGBUILD_PACKAGE_VERSION}-${CPACK_PKGBUILD_PACKAGE_RELEASE}.src.tar.gz")
	endif()

	if(NOT DEFINED CPACK_RPM_FILE_SOURCE)
		nx_set(CPACK_RPM_FILE_SOURCE "${CPACK_RPM_PACKAGE_SOURCE}-${CPACK_RPM_PACKAGE_VERSION}-${sReleaseSrcRPM}.src.rpm")
	endif()

	# ---- Generator: External ----

	if(NOT DEFINED CPACK_EXTERNAL_ENABLE_STAGING)
		nx_set(CPACK_EXTERNAL_ENABLE_STAGING ON)
	endif()

	if(NOT DEFINED CPACK_EXTERNAL_REQUESTED_VERSIONS)
		nx_set(CPACK_EXTERNAL_REQUESTED_VERSIONS "1.0")
	endif()

	# ---- Generator: Archive ----

	if(NOT DEFINED CPACK_ARCHIVE_COMPONENT_INSTALL)
		nx_set(CPACK_ARCHIVE_COMPONENT_INSTALL OFF)
	endif()

	set(bGeneratorsRelease OFF)
	set(bGeneratorsSource OFF)

	if(NOT DEFINED CPACK_GENERATOR)
		if(NX_TARGET_PLATFORM_MSDOS)
			nx_set(CPACK_GENERATOR "ZIP")
		elseif(NX_TARGET_PLATFORM_WINDOWS_NATIVE)
			nx_set(CPACK_GENERATOR "7Z")
		else()
			nx_set(CPACK_GENERATOR "TXZ")
		endif()
		set(bGeneratorsRelease ON)
	endif()

	if(NOT DEFINED CPACK_SOURCE_GENERATOR)
		if(NX_TARGET_PLATFORM_MSDOS OR NX_TARGET_PLATFORM_WINDOWS_NATIVE)
			nx_set(CPACK_SOURCE_GENERATOR "ZIP")
		else()
			nx_set(CPACK_SOURCE_GENERATOR "TGZ")
		endif()
		set(bGeneratorsSource ON)
	endif()

	# ---- Generator: Debian ----

	if(NOT DEFINED CPACK_DEB_COMPONENT_INSTALL)
		nx_set(CPACK_DEB_COMPONENT_INSTALL ON)
	endif()

	if(DEFINED CPACK_DEBIAN_PACKAGE_ARCHITECTURE AND DEFINED CPACK_DEBIAN_PACKAGE_VERSION)
		if(NX_TARGET_PLATFORM_GENERIC OR NX_TARGET_PLATFORM_LINUX)
			find_program(DPKG_BUILDPACKAGE_EXECUTABLE NAMES "dpkg-buildpackage")
			if(bGeneratorsRelease AND DPKG_BUILDPACKAGE_EXECUTABLE)
				nx_append(CPACK_GENERATOR "DEB")
			endif()
		endif()
	endif()

	if("DEB" IN_LIST CPACK_GENERATOR)
		if(NOT DEFINED CPACK_DEBIAN_COMPRESSION_TYPE)
			nx_set(CPACK_DEBIAN_COMPRESSION_TYPE "xz")
		endif()

		if(NOT DEFINED CPACK_DEBIAN_ENABLE_COMPONENT_DEPENDS)
			nx_set(CPACK_DEBIAN_ENABLE_COMPONENT_DEPENDS OFF)
		endif()

		if(NOT DEFINED CPACK_DEBIAN_PACKAGE_GENERATE_SHLIBS)
			if("${NX_PROJECT_NAME}_LIB" IN_LIST NX_COMPONENT_LIST)
				nx_set(CPACK_DEBIAN_PACKAGE_GENERATE_SHLIBS ON)
			else()
				nx_set(CPACK_DEBIAN_PACKAGE_GENERATE_SHLIBS OFF)
			endif()
		endif()
		if(NOT DEFINED CPACK_DEBIAN_PACKAGE_GENERATE_SHLIBS_POLICY)
			nx_set(CPACK_DEBIAN_PACKAGE_GENERATE_SHLIBS_POLICY "=")
		endif()

		if(NOT DEFINED CPACK_DEBIAN_PACKAGE_SECTION)
			nx_set(CPACK_DEBIAN_PACKAGE_SECTION "devel")
		endif()

		if(NOT DEFINED CPACK_DEBIAN_PACKAGE_SHLIBDEPS)
			find_program(DPKG_SHLIBDEPS_EXECUTABLE NAMES "dpkg-shlibdeps")
			if(DPKG_SHLIBDEPS_EXECUTABLE AND bPrimaryBinary)
				nx_set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
			else()
				nx_set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS OFF)
			endif()
		endif()
	endif()

	# ---- Generator: NSIS ----

	if(DEFINED CPACK_NSIS_PACKAGE_ARCHITECTURE)
		if(NX_TARGET_PLATFORM_GENERIC OR NX_TARGET_PLATFORM_WINDOWS_NATIVE)
			find_program(
				MAKENSIS_EXECUTABLE
				NAMES "makensis"
				PATHS "$ENV{NSIS_DIR}" "$ENV{PROGRAMFILES}/NSIS" "$ENV{PROGRAMFILES\(x86\)}/NSIS")
			if(bGeneratorsRelease AND MAKENSIS_EXECUTABLE)
				if(CPACK_NSIS_PACKAGE_ARCHITECTURE MATCHES "amd64")
					nx_append(CPACK_GENERATOR "NSIS64")
				else()
					nx_append(CPACK_GENERATOR "NSIS")
				endif()
			endif()
		endif()
	endif()

	if("NSIS" IN_LIST CPACK_GENERATOR OR "NSIS64" IN_LIST CPACK_GENERATOR)
		if(NOT DEFINED CPACK_NSIS_COMPRESSOR)
			nx_set(CPACK_NSIS_COMPRESSOR "/SOLID lzma")
		endif()

		if(NOT DEFINED CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL)
			nx_set(CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL ON)
		endif()

		if(NOT DEFINED CPACK_NSIS_EXECUTABLES_DIRECTORY)
			nx_set(CPACK_NSIS_EXECUTABLES_DIRECTORY "${NX_INSTALL_PATH_APPLICATIONS}")
		endif()

		if(NOT DEFINED CPACK_NSIS_MODIFY_PATH)
			nx_set(CPACK_NSIS_MODIFY_PATH OFF)
		endif()

		if(NOT DEFINED CPACK_NSIS_MUI_HEADERIMAGE)
			file(
				GLOB lsCandidates
				LIST_DIRECTORIES false
				"tools/packaging/header-150x57.bmp" "tools/header-150x57.bmp" "data/packaging/header-150x57.bmp"
				"data/images/header-150x57.bmp" "data/header-150x57.bmp" "header-150x57.bmp")
			if(DEFINED lsCandidates AND lsCandidates)
				list(GET lsCandidates 0 sCandidate)
				nx_set(CPACK_NSIS_MUI_HEADERIMAGE "${sCandidate}")
			else()
				nx_set(CPACK_NSIS_MUI_HEADERIMAGE "${NXPACKAGE_DIRECTORY}/packaging/header-150x57.bmp")
			endif()
		endif()
		if(DEFINED CPACK_NSIS_MUI_HEADERIMAGE)
			file(TO_NATIVE_PATH "${CPACK_NSIS_MUI_HEADERIMAGE}" CPACK_NSIS_MUI_HEADERIMAGE)
		endif()

		if(NOT DEFINED CPACK_NSIS_MUI_ICON)
			file(
				GLOB lsCandidates
				LIST_DIRECTORIES false
				"tools/packaging/install.ico"
				"tools/install.ico"
				"data/packaging/install.ico"
				"data/icons/install.ico"
				"data/install.ico"
				"install.ico"
				"tools/packaging/${PROJECT_NAME}.ico"
				"tools/${PROJECT_NAME}.ico"
				"data/packaging/${PROJECT_NAME}.ico"
				"data/icons/${PROJECT_NAME}.ico"
				"data/${PROJECT_NAME}.ico"
				"${PROJECT_NAME}.ico")
			if(DEFINED lsCandidates AND lsCandidates)
				list(GET lsCandidates 0 sCandidate)
				nx_set(CPACK_NSIS_MUI_ICON "${sCandidate}")
			else()
				nx_set(CPACK_NSIS_MUI_ICON "${NXPACKAGE_DIRECTORY}/packaging/install.ico")
			endif()
		endif()

		if(NOT DEFINED CPACK_NSIS_MUI_UNIICON)
			file(
				GLOB lsCandidates
				LIST_DIRECTORIES false
				"tools/packaging/uninstall.ico"
				"tools/uninstall.ico"
				"data/packaging/uninstall.ico"
				"data/icons/uninstall.ico"
				"data/uninstall.ico"
				"uninstall.ico"
				"tools/packaging/${PROJECT_NAME}.ico"
				"tools/${PROJECT_NAME}.ico"
				"data/packaging/${PROJECT_NAME}.ico"
				"data/icons/${PROJECT_NAME}.ico"
				"data/${PROJECT_NAME}.ico"
				"${PROJECT_NAME}.ico")
			if(DEFINED lsCandidates AND lsCandidates)
				list(GET lsCandidates 0 sCandidate)
				nx_set(CPACK_NSIS_MUI_UNIICON "${sCandidate}")
			else()
				nx_set(CPACK_NSIS_MUI_UNIICON "${NXPACKAGE_DIRECTORY}/packaging/install.ico")
			endif()
		endif()

		if(NOT DEFINED CPACK_NSIS_MUI_WELCOMEFINISHPAGE_BITMAP)
			file(
				GLOB lsCandidates
				LIST_DIRECTORIES false
				"tools/packaging/page-164x314.bmp" "tools/page-164x314.bmp" "data/packaging/page-164x314.bmp"
				"data/images/page-164x314.bmp" "data/page-164x314.bmp" "page-164x314.bmp")
			if(DEFINED lsCandidates AND lsCandidates)
				list(GET lsCandidates 0 sCandidate)
				nx_set(CPACK_NSIS_MUI_WELCOMEFINISHPAGE_BITMAP "${sCandidate}")
			else()
				nx_set(CPACK_NSIS_MUI_WELCOMEFINISHPAGE_BITMAP "${NXPACKAGE_DIRECTORY}/packaging/page-164x314.bmp")
			endif()
		endif()
		if(NOT DEFINED CPACK_NSIS_MUI_UNWELCOMEFINISHPAGE_BITMAP)
			nx_set(CPACK_NSIS_MUI_UNWELCOMEFINISHPAGE_BITMAP "${CPACK_NSIS_MUI_WELCOMEFINISHPAGE_BITMAP}")
		endif()
		if(DEFINED CPACK_NSIS_MUI_WELCOMEFINISHPAGE_BITMAP)
			file(TO_NATIVE_PATH "${CPACK_NSIS_MUI_WELCOMEFINISHPAGE_BITMAP}" CPACK_NSIS_MUI_WELCOMEFINISHPAGE_BITMAP)
		endif()
		if(DEFINED CPACK_NSIS_MUI_UNWELCOMEFINISHPAGE_BITMAP)
			file(TO_NATIVE_PATH "${CPACK_NSIS_MUI_UNWELCOMEFINISHPAGE_BITMAP}" CPACK_NSIS_MUI_UNWELCOMEFINISHPAGE_BITMAP)
		endif()

		if(NOT DEFINED CPACK_NSIS_UNINSTALL_NAME)
			nx_set(CPACK_NSIS_UNINSTALL_NAME "${CPACK_NSIS_PACKAGE_NAME}-Uninstall")
		endif()

		unset(sNSIS_LaunchApplication)
		unset(sNSIS_MUI_FINISHPAGE_RUN)
		if(DEFINED CPACK_NSIS_MUI_FINISHPAGE_RUN)
			file(TO_NATIVE_PATH "${CPACK_NSIS_EXECUTABLES_DIRECTORY}/${CPACK_NSIS_MUI_FINISHPAGE_RUN}" sApplication)
			set(sNSIS_LaunchApplication "Function LaunchApplication\n  ExecShell \"\" \"\$INSTDIR\\${sApplication}\"\nFunctionEnd")
			set(sNSIS_MUI_FINISHPAGE_RUN
				[[
	!define MUI_FINISHPAGE_RUN
	!define MUI_FINISHPAGE_TEXT "Launch Application"
	!define MUI_FINISHPAGE_RUN_FUNCTION "LaunchApplication"
				]])
		endif()

		unset(sNSIS_CreateShortCut)
		unset(sNSIS_DeleteShortCut)
		unset(sMenuFile)
		foreach(sMenuLink ${CPACK_NSIS_MENU_LINKS})
			if(DEFINED sMenuFile)
				list(APPEND sNSIS_CreateShortCut
						"  CreateShortCut \"\$SMPROGRAMS\\\$STARTMENU_FOLDER\\${sMenuLink}.lnk\" \"\$INSTDIR\\${sMenuFile}\"")
				list(APPEND sNSIS_DeleteShortCut "  Delete \"\$SMPROGRAMS\\\$STARTMENU_FOLDER\\${sMenuLink}.lnk\"")
				unset(sMenuFile)
			else()
				if(sMenuLink MATCHES "://")
					set(sMenuFile "${sMenuLink}")
				else()
					file(TO_NATIVE_PATH "${sMenuLink}" sMenuFile)
				endif()
			endif()
		endforeach()
		if(DEFINED sNSIS_CreateShortCut)
			string(REPLACE ";" "\n" sNSIS_CreateShortCut "${sNSIS_CreateShortCut}")
		endif()
		if(DEFINED sNSIS_DeleteShortCut)
			string(REPLACE ";" "\n" sNSIS_DeleteShortCut "${sNSIS_DeleteShortCut}")
		endif()
	endif()

	# ---- Generator: PKGBUILD ----

	if(NOT DEFINED CPACK_PKG_COMPONENT_INSTALL)
		nx_set(CPACK_PKG_COMPONENT_INSTALL OFF)
	endif()

	if(DEFINED CPACK_PKGBUILD_PACKAGE_ARCHITECTURE AND DEFINED CPACK_PKGBUILD_PACKAGE_VERSION)
		if(NX_TARGET_PLATFORM_GENERIC
			OR NX_TARGET_PLATFORM_CYGWIN
			OR NX_TARGET_PLATFORM_LINUX)
			find_program(MAKEPKG_EXECUTABLE NAMES "makepkg")
			if(bGeneratorsRelease AND MAKEPKG_EXECUTABLE)
				nx_append(CPACK_GENERATOR "PKGBUILD")
			endif()
			if(bGeneratorsSource AND MAKEPKG_EXECUTABLE)
				nx_append(CPACK_SOURCE_GENERATOR "PKGBUILD")
			endif()
		endif()
	endif()
	if(DEFINED CPACK_MINGW_PACKAGE_ARCHITECTURE AND DEFINED CPACK_PKGBUILD_PACKAGE_VERSION)
		if(NX_TARGET_PLATFORM_GENERIC OR NX_TARGET_PLATFORM_WINDOWS_MINGW)
			find_program(MAKEPKG_MINGW_EXECUTABLE NAMES "makepkg-mingw")
			if(bGeneratorsRelease AND MAKEPKG_MINGW_EXECUTABLE)
				nx_append(CPACK_GENERATOR "MINGW")
			endif()
			if(bGeneratorsSource AND MAKEPKG_MINGW_EXECUTABLE)
				nx_append(CPACK_SOURCE_GENERATOR "MINGW")
			endif()
		endif()
		if(NX_TARGET_PLATFORM_CYGWIN AND NOT "x$ENV{MINGW_ARCH}" STREQUAL "x")
			find_program(MAKEPKG_MINGW_EXECUTABLE NAMES "makepkg-mingw")
			if(bGeneratorsRelease AND MAKEPKG_MINGW_EXECUTABLE)
				nx_append(CPACK_GENERATOR "MINGW")
			endif()
			if(bGeneratorsSource AND MAKEPKG_MINGW_EXECUTABLE)
				nx_append(CPACK_SOURCE_GENERATOR "MINGW")
			endif()
		endif()
	endif()

	if("PKGBUILD" IN_LIST CPACK_GENERATOR OR "PKGBUILD" IN_LIST CPACK_SOURCE_GENERATOR)
		if(CPACK_PKGBUILD_PACKAGE_LICENSE STREQUAL "unknown")
			message(AUTHOR_WARNING "nx_package: Please Configure 'CPACK_PKGBUILD_PACKAGE_LICENSE'")
		endif()
	endif()

	# ---- Generator: RPM ----

	if(NOT DEFINED CPACK_RPM_COMPONENT_INSTALL)
		nx_set(CPACK_RPM_COMPONENT_INSTALL ON)
	endif()

	if(DEFINED CPACK_RPM_PACKAGE_ARCHITECTURE AND DEFINED CPACK_RPM_PACKAGE_VERSION)
		if(NX_TARGET_PLATFORM_GENERIC OR NX_TARGET_PLATFORM_LINUX)
			find_program(RPMBUILD_EXECUTABLE NAMES "rpmbuild")
			if(bGeneratorsRelease AND RPMBUILD_EXECUTABLE)
				nx_append(CPACK_GENERATOR "RPM")
			endif()
			if(bGeneratorsSource AND RPMBUILD_EXECUTABLE)
				nx_append(CPACK_SOURCE_GENERATOR "RPM")
			endif()
		endif()
	endif()

	if("RPM" IN_LIST CPACK_GENERATOR OR "RPM" IN_LIST CPACK_SOURCE_GENERATOR)
		find_program(RPMBUILD_EXECUTABLE NAMES "rpmbuild")

		if(CPACK_RPM_PACKAGE_LICENSE STREQUAL "unknown")
			message(AUTHOR_WARNING "nx_package: Please Configure 'CPACK_RPM_PACKAGE_LICENSE'")
		endif()

		if(NOT DEFINED CPACK_RPM_COMPRESSION_TYPE)
			nx_set(CPACK_RPM_COMPRESSION_TYPE "xz")
		endif()

		if(NOT DEFINED CPACK_RPM_PACKAGE_AUTOPROV)
			if("LIB" IN_LIST lsProjectComponents)
				nx_set(CPACK_RPM_PACKAGE_AUTOPROV ON)
			else()
				nx_set(CPACK_RPM_PACKAGE_AUTOPROV OFF)
			endif()
		endif()

		if(NOT DEFINED CPACK_RPM_PACKAGE_AUTOREQ)
			if(bPrimaryBinary)
				nx_set(CPACK_RPM_PACKAGE_AUTOREQ ON)
			else()
				nx_set(CPACK_RPM_PACKAGE_AUTOREQ OFF)
			endif()
		endif()

		if(NOT DEFINED CPACK_RPM_PACKAGE_GROUP)
			nx_set(CPACK_RPM_PACKAGE_GROUP "Unspecified")
		endif()

		if(NOT DEFINED CPACK_RPM_PACKAGE_RELOCATABLE)
			nx_set(CPACK_RPM_PACKAGE_RELOCATABLE ON)
		endif()
	endif()

	# ---- CPack Component Options ----

	if(NOT DEFINED CPACK_COMPONENTS_GROUPING)
		nx_set(CPACK_COMPONENTS_GROUPING "IGNORE")
	endif()

	set(nComponentOrdinal 1)
	foreach(sComponent ${lsProjectComponents})
		nx_set_global(CPACK_COMPONENT_${NX_PROJECT_NAME}_${sComponent}_GROUP "${PROJECT_NAME}")

		if(sComponent MATCHES "^(APP|SRV|BIN|MOD)$")
			if("DBG" IN_LIST lsProjectComponents)
				nx_append_global(CPACK_COMPONENT_${NX_PROJECT_NAME}_DBG_DEPENDS "${NX_PROJECT_NAME}_${sComponent}")
			endif()
		elseif(sComponent STREQUAL "LIB")
			if("APP" IN_LIST lsProjectComponents)
				nx_append_global(CPACK_COMPONENT_${NX_PROJECT_NAME}_APP_DEPENDS "${NX_PROJECT_NAME}_${sComponent}")
			endif()
			if("SRV" IN_LIST lsProjectComponents)
				nx_append_global(CPACK_COMPONENT_${NX_PROJECT_NAME}_SRV_DEPENDS "${NX_PROJECT_NAME}_${sComponent}")
			endif()
			if("BIN" IN_LIST lsProjectComponents)
				nx_append_global(CPACK_COMPONENT_${NX_PROJECT_NAME}_BIN_DEPENDS "${NX_PROJECT_NAME}_${sComponent}")
			endif()
			if("MOD" IN_LIST lsProjectComponents)
				nx_append_global(CPACK_COMPONENT_${NX_PROJECT_NAME}_MOD_DEPENDS "${NX_PROJECT_NAME}_${sComponent}")
			endif()
			if("OBJ" IN_LIST lsProjectComponents)
				nx_append_global(CPACK_COMPONENT_${NX_PROJECT_NAME}_OBJ_DEPENDS "${NX_PROJECT_NAME}_${sComponent}")
			elseif("DEV" IN_LIST lsProjectComponents)
				nx_append_global(CPACK_COMPONENT_${NX_PROJECT_NAME}_DEV_DEPENDS "${NX_PROJECT_NAME}_${sComponent}")
			endif()
			if("DBG" IN_LIST lsProjectComponents)
				nx_append_global(CPACK_COMPONENT_${NX_PROJECT_NAME}_DBG_DEPENDS "${NX_PROJECT_NAME}_${sComponent}")
			endif()
		elseif(sComponent STREQUAL "DEV")
			if("OBJ" IN_LIST lsProjectComponents)
				nx_append_global(CPACK_COMPONENT_${NX_PROJECT_NAME}_OBJ_DEPENDS "${NX_PROJECT_NAME}_${sComponent}")
			endif()
		elseif(sComponent STREQUAL "DAT")
			if(bPrimaryBinary AND NOT bPrimaryLibrary)
				if("APP" IN_LIST lsProjectComponents)
					nx_append_global(CPACK_COMPONENT_${NX_PROJECT_NAME}_APP_DEPENDS "${NX_PROJECT_NAME}_${sComponent}")
				endif()
				if("SRV" IN_LIST lsProjectComponents)
					nx_append_global(CPACK_COMPONENT_${NX_PROJECT_NAME}_SRV_DEPENDS "${NX_PROJECT_NAME}_${sComponent}")
				endif()
				if("BIN" IN_LIST lsProjectComponents)
					nx_append_global(CPACK_COMPONENT_${NX_PROJECT_NAME}_BIN_DEPENDS "${NX_PROJECT_NAME}_${sComponent}")
				endif()
				if("MOD" IN_LIST lsProjectComponents)
					nx_append_global(CPACK_COMPONENT_${NX_PROJECT_NAME}_MOD_DEPENDS "${NX_PROJECT_NAME}_${sComponent}")
				endif()
			elseif("LIB" IN_LIST lsProjectComponents)
				nx_append_global(CPACK_COMPONENT_${NX_PROJECT_NAME}_LIB_DEPENDS "${NX_PROJECT_NAME}_${sComponent}")
			endif()
		endif()

		if(sComponent MATCHES "^(OBJ|DEV)$")
			if(bPrimaryBinary AND NOT bPrimaryLibrary)
				nx_set_global(CPACK_COMPONENT_${NX_PROJECT_NAME}_${sComponent}_DISABLED ON)
			endif()
		elseif(sComponent STREQUAL "DBG")
			nx_set_global(CPACK_COMPONENT_${NX_PROJECT_NAME}_DBG_DISABLED ON)
		endif()

		if(sComponent MATCHES "^(LIB|RTM)$")
			nx_set_global(CPACK_DEBIAN_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_SECTION "libs")
			nx_set_global(CPACK_RPM_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_GROUP "${CPACK_RPM_PACKAGE_GROUP}")
		elseif(sComponent MATCHES "^(OBJ|DEV)$")
			if(NX_TARGET_ARCHITECTURE_GENERIC)
				nx_set_global(CPACK_DEBIAN_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_SECTION "devel")
				nx_set_global(CPACK_RPM_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_GROUP "Development/Tools")
			elseif(NX_HOST_LANGUAGE_CXX)
				nx_set_global(CPACK_DEBIAN_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_SECTION "libdevel")
				nx_set_global(CPACK_RPM_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_GROUP "Development/C++")
			elseif(NX_HOST_LANGUAGE_C)
				nx_set_global(CPACK_DEBIAN_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_SECTION "libdevel")
				nx_set_global(CPACK_RPM_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_GROUP "Development/C")
			else()
				nx_set_global(CPACK_DEBIAN_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_SECTION "libdevel")
				nx_set_global(CPACK_RPM_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_GROUP "Development/Other")
			endif()
		elseif(sComponent STREQUAL "DOC")
			nx_set_global(CPACK_DEBIAN_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_SECTION "doc")
			nx_set_global(CPACK_RPM_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_GROUP "Documentation")
		elseif(sComponent STREQUAL "DBG")
			nx_set_global(CPACK_DEBIAN_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_SECTION "debug")
			nx_set_global(CPACK_RPM_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_GROUP "Development/Debug")
		else()
			nx_set_global(CPACK_DEBIAN_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_SECTION "${CPACK_DEBIAN_PACKAGE_SECTION}")
			nx_set_global(CPACK_RPM_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_GROUP "${CPACK_RPM_PACKAGE_GROUP}")
		endif()

		if(sComponent MATCHES "^(APP|SRV|BIN|MOD)$")
			nx_set_global(CPACK_DEBIAN_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_SHLIBDEPS ${CPACK_DEBIAN_PACKAGE_SHLIBDEPS})
			nx_set_global(CPACK_RPM_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_AUTOREQ ${CPACK_RPM_PACKAGE_AUTOREQ})
			nx_set_global(CPACK_RPM_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_AUTOPROV OFF)
		elseif(sComponent STREQUAL "LIB")
			nx_set_global(CPACK_DEBIAN_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_SHLIBDEPS ${CPACK_DEBIAN_PACKAGE_SHLIBDEPS})
			nx_set_global(CPACK_RPM_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_AUTOREQ ${CPACK_RPM_PACKAGE_AUTOREQ})
			nx_set_global(CPACK_RPM_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_AUTOPROV ${CPACK_RPM_PACKAGE_AUTOPROV})
		else()
			nx_set_global(CPACK_DEBIAN_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_SHLIBDEPS OFF)
			nx_set_global(CPACK_RPM_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_AUTOREQ OFF)
			nx_set_global(CPACK_RPM_${NX_PROJECT_NAME}_${sComponent}_PACKAGE_AUTOPROV OFF)
		endif()

		if(nComponentOrdinal GREATER 9)
			nx_set_global(CPACK_${NX_PROJECT_NAME}_${sComponent}_ORDINAL "${CPACK_SOURCE_PACKAGE_NAME}-${nComponentOrdinal}")
		else()
			nx_set_global(CPACK_${NX_PROJECT_NAME}_${sComponent}_ORDINAL "${CPACK_SOURCE_PACKAGE_NAME}-0${nComponentOrdinal}")
		endif()
		math(EXPR nComponentOrdinal "${nComponentOrdinal} + 1")
	endforeach()

	unset(lsComponentOrdinals)
	list(APPEND lsComponentOrdinals "${CPACK_SOURCE_PACKAGE_NAME}-00")
	foreach(sComponent ${NX_COMPONENT_UNSORTED})
		list(APPEND lsComponentOrdinals "${CPACK_${sComponent}_ORDINAL}")
	endforeach()
	list(APPEND lsComponentOrdinals "${CPACK_SOURCE_PACKAGE_NAME}-99")
	list(SORT lsComponentOrdinals)

	# ---- Dependency Parsing ----

	set(sDepCMakeDEBIAN "cmake (>= 3.14)")
	set(sDepCMakePKGBUILD "cmake>=3.14")
	set(sDepCMakeMINGW "\${MINGW_PACKAGE_PREFIX}-cmake>=3.14")
	set(sDepCMakeRPM "cmake >= 3.14")

	set(sDepVersionDEBIAN " (= ${CPACK_DEBIAN_PACKAGE_VERSION}-${CPACK_DEBIAN_PACKAGE_RELEASE})")
	set(sDepVersionPKGBUILD "=${CPACK_PKGBUILD_PACKAGE_VERSION}-${CPACK_PKGBUILD_PACKAGE_RELEASE}")
	set(sDepVersionMINGW "=${CPACK_PKGBUILD_PACKAGE_VERSION}-${CPACK_PKGBUILD_PACKAGE_RELEASE}")
	set(sDepVersionRPM " = ${CPACK_RPM_PACKAGE_VERSION}-${CPACK_RPM_PACKAGE_RELEASE}")

	set(sDepSeparatorDEBIAN ", ")
	set(sDepSeparatorPKGBUILD " ")
	set(sDepSeparatorMINGW " ")
	set(sDepSeparatorRPM ", ")

	unset(sDepQuoteDEBIAN)
	set(sDepQuotePKGBUILD "'")
	set(sDepQuoteMINGW "\"")
	unset(sDepQuoteRPM)

	nx_set(vDepProvidesDEBIAN "CPACK_DEBIAN_PACKAGE_PROVIDES")
	nx_set(vDepConflictsDEBIAN "CPACK_DEBIAN_PACKAGE_CONFLICTS")
	nx_set(vDepRequiresDEBIAN "CPACK_DEBIAN_PACKAGE_DEPENDS")
	nx_set(vDepRecommendsDEBIAN "CPACK_DEBIAN_PACKAGE_RECOMMENDS")
	nx_set(vDepSuggestsDEBIAN "CPACK_DEBIAN_PACKAGE_SUGGESTS")
	nx_set(vDepBuildReqsDEBIAN "CPACK_DEBIAN_PACKAGE_BUILDREQUIRES")

	nx_set(vDepProvidesPKGBUILD "CPACK_PKGBUILD_PACKAGE_PROVIDES")
	nx_set(vDepConflictsPKGBUILD "CPACK_PKGBUILD_PACKAGE_CONFLICTS")
	nx_set(vDepRequiresPKGBUILD "CPACK_PKGBUILD_PACKAGE_DEPENDS")
	nx_set(vDepRecommendsPKGBUILD "CPACK_PKGBUILD_PACKAGE_OPTIONAL")
	nx_set(vDepSuggestsPKGBUILD "CPACK_PKGBUILD_PACKAGE_OPTIONAL")
	nx_set(vDepBuildReqsPKGBUILD "CPACK_PKGBUILD_PACKAGE_BUILDREQUIRES")

	nx_set(vDepProvidesMINGW "CPACK_MINGW_PACKAGE_PROVIDES")
	nx_set(vDepConflictsMINGW "CPACK_MINGW_PACKAGE_CONFLICTS")
	nx_set(vDepRequiresMINGW "CPACK_MINGW_PACKAGE_DEPENDS")
	nx_set(vDepRecommendsMINGW "CPACK_MINGW_PACKAGE_OPTIONAL")
	nx_set(vDepSuggestsMINGW "CPACK_MINGW_PACKAGE_OPTIONAL")
	nx_set(vDepBuildReqsMINGW "CPACK_MINGW_PACKAGE_BUILDREQUIRES")

	nx_set(vDepProvidesRPM "CPACK_RPM_PACKAGE_PROVIDES")
	nx_set(vDepConflictsRPM "CPACK_RPM_PACKAGE_CONFLICTS")
	nx_set(vDepRequiresRPM "CPACK_RPM_PACKAGE_REQUIRES")
	nx_set(vDepRecommendsRPM "CPACK_RPM_PACKAGE_SUGGESTS")
	nx_set(vDepSuggestsRPM "CPACK_RPM_PACKAGE_SUGGESTS")
	nx_set(vDepBuildReqsRPM "CPACK_RPM_PACKAGE_BUILDREQUIRES")

	foreach(sGenerator "DEBIAN" "PKGBUILD" "MINGW" "RPM")
		if(NOT DEFINED sPkgVerCompat)
			nx_set(NX_${sGenerator}_VERSION_COMPAT)
		endif()

		if(DEFINED NX_${sGenerator}_DEVEL_REQUIRES)
			nx_append(NX_${sGenerator}_BUILD_REQUIRES ${NX_${sGenerator}_DEVEL_REQUIRES})
		endif()
		if(NOT DEFINED NX_${sGenerator}_BUILD_REQUIRES OR NOT NX_${sGenerator}_BUILD_REQUIRES MATCHES "cmake")
			nx_append(NX_${sGenerator}_BUILD_REQUIRES "${sDepCMake${sGenerator}}")
		endif()

		# Parse CPack Variables

		if(DEFINED ${vDepBuildReqs${sGenerator}}} AND NOT DEFINED NX_${sGenerator}_BUILD_REQUIRES)
			string(REPLACE "${sDepSeparator${sGenerator}}" ";" sDependency "${${vDepBuildReqs${sGenerator}}}")
			if(DEFINED sDepQuote${sGenerator})
				string(REPLACE "sDepQuote${sGenerator}" "" sDependency "${sDependency}")
			endif()
			nx_append(NX_${sGenerator}_BUILD_REQUIRES "${sDependency}")
		endif()
		if(DEFINED ${vDepProvides${sGenerator}}} AND NOT DEFINED NX_${sGenerator}_PACKAGE_PROVIDES)
			string(REPLACE "${sDepSeparator${sGenerator}}" ";" sDependency "${${vDepProvides${sGenerator}}}")
			if(DEFINED sDepQuote${sGenerator})
				string(REPLACE "sDepQuote${sGenerator}" "" sDependency "${sDependency}")
			endif()
			nx_append(NX_${sGenerator}_PACKAGE_PROVIDES "${sDependency}")
		endif()
		if(DEFINED ${vDepConflicts${sGenerator}}} AND NOT DEFINED NX_${sGenerator}_PACKAGE_CONFLICTS)
			string(REPLACE "${sDepSeparator${sGenerator}}" ";" sDependency "${${vDepConflicts${sGenerator}}}")
			if(DEFINED sDepQuote${sGenerator})
				string(REPLACE "sDepQuote${sGenerator}" "" sDependency "${sDependency}")
			endif()
			nx_append(NX_${sGenerator}_PACKAGE_CONFLICTS "${sDependency}")
		endif()
		if(DEFINED ${vDepRequires${sGenerator}}} AND NOT DEFINED NX_${sGenerator}_PACKAGE_REQUIRES)
			string(REPLACE "${sDepSeparator${sGenerator}}" ";" sDependency "${${vDepRequires${sGenerator}}}")
			if(DEFINED sDepQuote${sGenerator})
				string(REPLACE "sDepQuote${sGenerator}" "" sDependency "${sDependency}")
			endif()
			nx_append(NX_${sGenerator}_PACKAGE_REQUIRES "${sDependency}")
		endif()
		if(DEFINED ${vDepRecommends${sGenerator}}} AND NOT DEFINED NX_${sGenerator}_PACKAGE_RECOMMENDS)
			string(REPLACE "${sDepSeparator${sGenerator}}" ";" sDependency "${${vDepRecommends${sGenerator}}}")
			if(DEFINED sDepQuote${sGenerator})
				string(REPLACE "sDepQuote${sGenerator}" "" sDependency "${sDependency}")
			endif()
			nx_append(NX_${sGenerator}_PACKAGE_RECOMMENDS "${sDependency}")
		endif()
		if(DEFINED ${vDepSuggests${sGenerator}}} AND NOT DEFINED NX_${sGenerator}_PACKAGE_SUGGESTS)
			string(REPLACE "${sDepSeparator${sGenerator}}" ";" sDependency "${${vDepSuggests${sGenerator}}}")
			if(DEFINED sDepQuote${sGenerator})
				string(REPLACE "sDepQuote${sGenerator}" "" sDependency "${sDependency}")
			endif()
			nx_append(NX_${sGenerator}_PACKAGE_SUGGESTS "${sDependency}")
		endif()

		# Recreate CPack Variables

		if(DEFINED NX_${sGenerator}_BUILD_REQUIRES)
			string(REPLACE ";" "${sDepQuote${sGenerator}}${sDepSeparator${sGenerator}}${sDepQuote${sGenerator}}" sDependencies
							"${sDepQuote${sGenerator}}${NX_${sGenerator}_BUILD_REQUIRES}${sDepQuote${sGenerator}}")
			nx_set(${vDepBuildReqs${sGenerator}} "${sDependencies}")
		endif()
		if(DEFINED NX_${sGenerator}_PACKAGE_PROVIDES)
			string(REPLACE ";" "${sDepQuote${sGenerator}}${sDepSeparator${sGenerator}}${sDepQuote${sGenerator}}" sDependencies
							"${sDepQuote${sGenerator}}${NX_${sGenerator}_PACKAGE_PROVIDES}${sDepQuote${sGenerator}}")
			nx_set(${vDepProvides${sGenerator}} "${sDependencies}")
		endif()
		if(DEFINED NX_${sGenerator}_PACKAGE_CONFLICTS)
			string(REPLACE ";" "${sDepQuote${sGenerator}}${sDepSeparator${sGenerator}}${sDepQuote${sGenerator}}" sDependencies
							"${sDepQuote${sGenerator}}${NX_${sGenerator}_PACKAGE_CONFLICTS}${sDepQuote${sGenerator}}")
			nx_set(${vDepConflicts${sGenerator}} "${sDependencies}")
		endif()
		if(DEFINED NX_${sGenerator}_PACKAGE_REQUIRES)
			string(REPLACE ";" "${sDepQuote${sGenerator}}${sDepSeparator${sGenerator}}${sDepQuote${sGenerator}}" sDependencies
							"${sDepQuote${sGenerator}}${NX_${sGenerator}_PACKAGE_REQUIRES}${sDepQuote${sGenerator}}")
			nx_set(${vDepRequires${sGenerator}} "${sDependencies}")
		endif()
		if(DEFINED NX_${sGenerator}_PACKAGE_RECOMMENDS)
			string(REPLACE ";" "${sDepQuote${sGenerator}}${sDepSeparator${sGenerator}}${sDepQuote${sGenerator}}" sDependencies
							"${sDepQuote${sGenerator}}${NX_${sGenerator}_PACKAGE_RECOMMENDS}${sDepQuote${sGenerator}}")
			nx_set(${vDepRecommends${sGenerator}} "${sDependencies}")
		endif()
		if(DEFINED NX_${sGenerator}_PACKAGE_SUGGESTS)
			string(REPLACE ";" "${sDepQuote${sGenerator}}${sDepSeparator${sGenerator}}${sDepQuote${sGenerator}}" sDependencies
							"${sDepQuote${sGenerator}}${NX_${sGenerator}_PACKAGE_SUGGESTS}${sDepQuote${sGenerator}}")
			nx_set(${vDepSuggests${sGenerator}} "${sDependencies}")
		endif()

		# Build Component Dependencies

		set(bAddedBinaryDeps OFF)
		foreach(sComponent "LIB" "APP" "SRV" "BIN" "MOD")
			if("${sComponent}" IN_LIST lsProjectComponents)
				if(NOT DEFINED CPACK_COMPONENT_${NX_PROJECT_NAME}_${sComponent}_DEPENDS)
					if(DEFINED NX_${sGenerator}_PACKAGE_REQUIRES)
						nx_append_global(NX_${sGenerator}_${NX_PROJECT_NAME}_${sComponent}_REQUIRES ${NX_${sGenerator}_PACKAGE_REQUIRES})
					endif()
					if(DEFINED NX_${sGenerator}_PACKAGE_RECOMMENDS)
						nx_append_global(NX_${sGenerator}_${NX_PROJECT_NAME}_${sComponent}_RECOMMENDS
											${NX_${sGenerator}_PACKAGE_RECOMMENDS})
					endif()
					if(DEFINED NX_${sGenerator}_PACKAGE_SUGGESTS)
						nx_append_global(NX_${sGenerator}_${NX_PROJECT_NAME}_${sComponent}_SUGGESTS ${NX_${sGenerator}_PACKAGE_SUGGESTS})
					endif()
					set(bAddedBinaryDeps ON)
				endif()
			endif()
		endforeach()

		set(bAddedDevelopDeps OFF)
		set(bAddedCompiledDeps ${bAddedBinaryDeps})
		foreach(sComponent "DEV" "OBJ")
			if("${sComponent}" IN_LIST lsProjectComponents)
				if(NOT DEFINED CPACK_COMPONENT_${NX_PROJECT_NAME}_${sComponent}_DEPENDS AND NOT bAddedBinaryDeps)
					if(DEFINED NX_${sGenerator}_PACKAGE_REQUIRES)
						nx_append_global(NX_${sGenerator}_${NX_PROJECT_NAME}_${sComponent}_REQUIRES ${NX_${sGenerator}_PACKAGE_REQUIRES})
					endif()
					if(DEFINED NX_${sGenerator}_PACKAGE_RECOMMENDS)
						nx_append_global(NX_${sGenerator}_${NX_PROJECT_NAME}_${sComponent}_RECOMMENDS
											${NX_${sGenerator}_PACKAGE_RECOMMENDS})
					endif()
					if(DEFINED NX_${sGenerator}_PACKAGE_SUGGESTS)
						nx_append_global(NX_${sGenerator}_${NX_PROJECT_NAME}_${sComponent}_SUGGESTS ${NX_${sGenerator}_PACKAGE_SUGGESTS})
					endif()
					set(bAddedCompiledDeps ON)
				endif()
				if(NOT bAddedDevelopDeps)
					if(DEFINED NX_${sGenerator}_DEVEL_REQUIRES)
						nx_append_global(NX_${sGenerator}_${NX_PROJECT_NAME}_${sComponent}_REQUIRES ${NX_${sGenerator}_DEVEL_REQUIRES})
					endif()
					if(DEFINED NX_${sGenerator}_DEVEL_RECOMMENDS)
						nx_append_global(NX_${sGenerator}_${NX_PROJECT_NAME}_${sComponent}_RECOMMENDS ${NX_${sGenerator}_DEVEL_RECOMMENDS})
					endif()
					if(DEFINED NX_${sGenerator}_DEVEL_SUGGESTS)
						nx_append_global(NX_${sGenerator}_${NX_PROJECT_NAME}_${sComponent}_SUGGESTS ${NX_${sGenerator}_DEVEL_SUGGESTS})
					endif()
					set(bAddedDevelopDeps ON)
				endif()
			endif()
		endforeach()

		foreach(sComponent "DAT")
			if("${sComponent}" IN_LIST lsProjectComponents AND NOT bAddedCompiledDeps)
				if(NOT DEFINED CPACK_COMPONENT_${NX_PROJECT_NAME}_${sComponent}_DEPENDS)
					if(DEFINED NX_${sGenerator}_PACKAGE_REQUIRES)
						nx_append_global(NX_${sGenerator}_${NX_PROJECT_NAME}_${sComponent}_REQUIRES ${NX_${sGenerator}_PACKAGE_REQUIRES})
					endif()
					if(DEFINED NX_${sGenerator}_PACKAGE_RECOMMENDS)
						nx_append_global(NX_${sGenerator}_${NX_PROJECT_NAME}_${sComponent}_RECOMMENDS
											${NX_${sGenerator}_PACKAGE_RECOMMENDS})
					endif()
					if(DEFINED NX_${sGenerator}_PACKAGE_SUGGESTS)
						nx_append_global(NX_${sGenerator}_${NX_PROJECT_NAME}_${sComponent}_SUGGESTS ${NX_${sGenerator}_PACKAGE_SUGGESTS})
					endif()
				endif()
			endif()
		endforeach()

		# Add Generated Dependencies

		foreach(sComponent ${lsProjectComponents})
			foreach(sDependency ${CPACK_COMPONENT_${NX_PROJECT_NAME}_${sComponent}_DEPENDS})
				if(sDependency MATCHES "^${NX_PROJECT_NAME}")
					nx_append_global(NX_${sGenerator}_${NX_PROJECT_NAME}_${sComponent}_REQUIRES
										"${CPACK_${sGenerator}_${sDependency}_PACKAGE_NAME}${sDepVersion${sGenerator}}")
				else()
					nx_append_global(NX_${sGenerator}_${NX_PROJECT_NAME}_${sComponent}_REQUIRES
										"${CPACK_${sGenerator}_${sDependency}_PACKAGE_NAME}")
				endif()
			endforeach()
		endforeach()

		# Add CMake Development Dependency

		set(bAddedCMakeDep OFF)
		if("${NX_${sGenerator}_DEVEL_REQUIRES};${NX_${sGenerator}_DEVEL_RECOMMENDS};${NX_${sGenerator}_DEVEL_SUGGESTS}" MATCHES "cmake")
			set(bAddedCMakeDep ON)
		endif()
		if("${NX_${sGenerator}_PACKAGE_REQUIRES};${NX_${sGenerator}_PACKAGE_RECOMMENDS};${NX_${sGenerator}_PACKAGE_SUGGESTS}" MATCHES
			"cmake")
			set(bAddedCMakeDep ON)
		endif()
		if(NOT bAddedCMakeDep)
			nx_append(NX_${sGenerator}_DEVEL_SUGGESTS "${sDepCMake${sGenerator}}")
			if("OBJ" IN_LIST lsProjectComponents)
				nx_append_global(NX_${sGenerator}_${NX_PROJECT_NAME}_OBJ_SUGGESTS "${sDepCMake${sGenerator}}")
			endif()
		endif()

		# Global Development Depends

		if("DEV" IN_LIST lsProjectComponents OR "OBJ" IN_LIST lsProjectComponents)
			if(DEFINED NX_${sGenerator}_DEVEL_REQUIRES)
				string(REPLACE ";" "${sDepQuote${sGenerator}}${sDepSeparator${sGenerator}}${sDepQuote${sGenerator}}" sDependencies
								"${sDepQuote${sGenerator}}${NX_${sGenerator}_DEVEL_REQUIRES}${sDepQuote${sGenerator}}")
				if(DEFINED ${vDepRecommends${sGenerator}})
					nx_set(${vDepRecommends${sGenerator}} "${${vDepRecommends${sGenerator}}}${sDepSeparator${sGenerator}}${sDependencies}")
				else()
					nx_set(${vDepRecommends${sGenerator}} "${sDependencies}")
				endif()
			endif()
			if(DEFINED NX_${sGenerator}_DEVEL_RECOMMENDS)
				string(REPLACE ";" "${sDepQuote${sGenerator}}${sDepSeparator${sGenerator}}${sDepQuote${sGenerator}}" sDependencies
								"${sDepQuote${sGenerator}}${NX_${sGenerator}_DEVEL_RECOMMENDS}${sDepQuote${sGenerator}}")
				if(DEFINED ${vDepSuggests${sGenerator}})
					nx_set(${vDepSuggests${sGenerator}} "${${vDepSuggests${sGenerator}}}${sDepSeparator${sGenerator}}${sDependencies}")
				else()
					nx_set(${vDepSuggests${sGenerator}} "${sDependencies}")
				endif()
			endif()
			if(DEFINED NX_${sGenerator}_DEVEL_SUGGESTS)
				string(REPLACE ";" "${sDepQuote${sGenerator}}${sDepSeparator${sGenerator}}${sDepQuote${sGenerator}}" sDependencies
								"${sDepQuote${sGenerator}}${NX_${sGenerator}_DEVEL_SUGGESTS}${sDepQuote${sGenerator}}")
				if(DEFINED ${vDepSuggests${sGenerator}})
					nx_set(${vDepSuggests${sGenerator}} "${${vDepSuggests${sGenerator}}}${sDepSeparator${sGenerator}}${sDependencies}")
				else()
					nx_set(${vDepSuggests${sGenerator}} "${sDependencies}")
				endif()
			endif()
		endif()

		# Finalize Component Dependencies

		foreach(sComponent ${lsProjectComponents})
			string(REPLACE "${sGenerator}" "${sGenerator}_${NX_PROJECT_NAME}_${sComponent}" vDepRequiresCOMPONENT
							"${vDepRequires${sGenerator}}")
			nx_set_global(${vDepRequiresCOMPONENT})

			if(DEFINED NX_${sGenerator}_${NX_PROJECT_NAME}_${sComponent}_REQUIRES AND NOT sGenerator STREQUAL "MINGW")
				string(
					REPLACE
						";" "${sDepQuote${sGenerator}}${sDepSeparator${sGenerator}}${sDepQuote${sGenerator}}" sDependencies
						"${sDepQuote${sGenerator}}${NX_${sGenerator}_${NX_PROJECT_NAME}_${sComponent}_REQUIRES}${sDepQuote${sGenerator}}")
				if(DEFINED ${vDepRequiresCOMPONENT})
					nx_set_global(${vDepRequiresCOMPONENT} "${${vDepRequiresCOMPONENT}}${sDepSeparator${sGenerator}}${sDependencies}")
				else()
					nx_set_global(${vDepRequiresCOMPONENT} "${sDependencies}")
				endif()
			endif()

			string(REPLACE "${sGenerator}" "${sGenerator}_${NX_PROJECT_NAME}_${sComponent}" vDepRecommendsCOMPONENT
							"${vDepRecommends${sGenerator}}")
			nx_set_global(${vDepRecommendsCOMPONENT})

			if(DEFINED NX_${sGenerator}_${NX_PROJECT_NAME}_${sComponent}_RECOMMENDS AND NOT sGenerator STREQUAL "MINGW")
				string(
					REPLACE
						";" "${sDepQuote${sGenerator}}${sDepSeparator${sGenerator}}${sDepQuote${sGenerator}}" sDependencies
						"${sDepQuote${sGenerator}}${NX_${sGenerator}_${NX_PROJECT_NAME}_${sComponent}_RECOMMENDS}${sDepQuote${sGenerator}}")
				if(DEFINED ${vDepRecommendsCOMPONENT})
					nx_set_global(${vDepRecommendsCOMPONENT} "${${vDepRecommendsCOMPONENT}}${sDepSeparator${sGenerator}}${sDependencies}")
				else()
					nx_set_global(${vDepRecommendsCOMPONENT} "${sDependencies}")
				endif()
			endif()

			string(REPLACE "${sGenerator}" "${sGenerator}_${NX_PROJECT_NAME}_${sComponent}" vDepSuggestsCOMPONENT
							"${vDepSuggests${sGenerator}}")
			nx_set_global(${vDepSuggestsCOMPONENT})

			if(DEFINED NX_${sGenerator}_${NX_PROJECT_NAME}_${sComponent}_SUGGESTS AND NOT sGenerator STREQUAL "MINGW")
				string(
					REPLACE
						";" "${sDepQuote${sGenerator}}${sDepSeparator${sGenerator}}${sDepQuote${sGenerator}}" sDependencies
						"${sDepQuote${sGenerator}}${NX_${sGenerator}_${NX_PROJECT_NAME}_${sComponent}_SUGGESTS}${sDepQuote${sGenerator}}")
				if(DEFINED ${vDepSuggestsCOMPONENT})
					nx_set_global(${vDepSuggestsCOMPONENT} "${${vDepSuggestsCOMPONENT}}${sDepSeparator${sGenerator}}${sDependencies}")
				else()
					nx_set_global(${vDepSuggestsCOMPONENT} "${sDependencies}")
				endif()
			endif()
		endforeach()
	endforeach()

	if(CPACK_DEB_COMPONENT_INSTALL)
		nx_set(${vDepProvidesDEBIAN})
		nx_set(${vDepRequiresDEBIAN})
		nx_set(${vDepRecommendsDEBIAN})
		nx_set(${vDepSuggestsDEBIAN})
	endif()
	if(CPACK_PKG_COMPONENT_INSTALL)
		nx_set(${vDepProvidesPKGBUILD})
		nx_set(${vDepRequiresPKGBUILD})
		nx_set(${vDepRecommendsPKGBUILD})
		nx_set(${vDepSuggestsPKGBUILD})
	endif()
	if(CPACK_RPM_COMPONENT_INSTALL)
		nx_set(${vDepProvidesRPM})
		nx_set(${vDepRequiresRPM})
		nx_set(${vDepRecommendsRPM})
		nx_set(${vDepSuggestsRPM})
	endif()

	# -------- Custom Packaging -------- #

	unset(lsNeedPackageSource)
	unset(lsNeedPackageBinary)
	unset(lsIsExtraBinary)
	unset(lsIsExtraSource)

	if(NOT DEFINED _CURRENT_YEAR)
		string(TIMESTAMP _CURRENT_YEAR "%Y")
	endif()
	if(NOT DEFINED _CURRENT_DATE)
		string(TIMESTAMP _CURRENT_DATE "%Y%m%d")
	endif()

	unset(lsRMDirs)
	unset(lsRMDirsForce)
	if(DEFINED NX_CLEANUP_RMDIR AND NX_CLEANUP_RMDIR)
		list(APPEND lsRMDirs ${NX_CLEANUP_RMDIR})
	endif()
	if(DEFINED NX_CLEANUP_RMDIR_F AND NX_CLEANUP_RMDIR_F)
		list(APPEND lsRMDirs ${NX_CLEANUP_RMDIR_F})
		list(APPEND lsRMDirsForce ${NX_CLEANUP_RMDIR_F})
	endif()
	foreach(sRMPath ${NX_CLEANUP_DELETE} ${NX_CLEANUP_RMDIR} ${NX_CLEANUP_RMDIR_F})
		get_filename_component(sRMPath "${sRMPath}" DIRECTORY)
		while(sRMPath AND NOT sRMPath STREQUAL "/")
			list(APPEND lsRMDirs "${sRMPath}")
			get_filename_component(sRMPath "${sRMPath}" DIRECTORY)
		endwhile()
	endforeach()
	if(DEFINED lsRMDirs AND lsRMDirs)
		list(REMOVE_DUPLICATES lsRMDirs)
		list(SORT lsRMDirs)
		list(REVERSE lsRMDirs)
	endif()

	unset(sGPGKeyId)
	unset(sGPGPassword)
	unset(sGPGPassFile)

	if(DEFINED GPG_KEYID)
		set(sGPGKeyId "${GPG_KEYID}")
	elseif(NOT "x$ENV{GPG_KEYID}" STREQUAL "x")
		set(sGPGKeyId "$ENV{GPG_KEYID}")
	endif()
	if(DEFINED sGPGKeyId AND sGPGKeyId MATCHES "^(OFF|FALSE|0|DISABLED)$")
		unset(sGPGKeyId)
	endif()
	if(NOT DEFINED sGPGKeyId)
		if(EXISTS "$ENV{HOME}/.devscripts")
			file(STRINGS "$ENV{HOME}/.devscripts" lsDevStrings REGEX "^DEBSIGN_KEYID=")
			foreach(lsDevStrings ${lsDistroStrings})
				if(lsDevStrings MATCHES "^DEBSIGN_KEYID=(.*)$")
					set(sGPGKeyId "${CMAKE_MATCH_1}")
				endif()
			endforeach()
		endif()
	endif()
	if(NOT DEFINED sGPGKeyId)
		if(EXISTS "$ENV{HOME}/.rpmmacros")
			file(STRINGS "$ENV{HOME}/.rpmmacros" lsDevStrings REGEX "^%_gpg_name ")
			foreach(lsDevStrings ${lsDistroStrings})
				if(lsDevStrings MATCHES "^%_gpg_name[ ]+(.*)$")
					set(sGPGKeyId "${CMAKE_MATCH_1}")
				endif()
			endforeach()
		endif()
	endif()
	if(NOT DEFINED sGPGKeyId)
		if(EXISTS "/etc/devscripts.conf")
			file(STRINGS "/etc/devscripts.conf" lsDevStrings REGEX "^DEBSIGN_KEYID=")
			foreach(lsDevStrings ${lsDistroStrings})
				if(lsDevStrings MATCHES "^DEBSIGN_KEYID=(.*)$")
					set(sGPGKeyId "${CMAKE_MATCH_1}")
				endif()
			endforeach()
		endif()
	endif()

	if(DEFINED sGPGKeyId)
		if(DEFINED GPG_PASSFILE AND EXISTS "${GPG_PASSFILE}")
			set(sGPGPassFile "${GPG_PASSFILE}")
		elseif(DEFINED GPG_PASSWORD)
			set(sGPGPassword "${GPG_PASSWORD}")
		elseif(NOT "x$ENV{GPG_PASSFILE}" STREQUAL "x" AND EXISTS "$ENV{GPG_PASSFILE}")
			set(sGPGPassFile "$ENV{GPG_PASSFILE}")
		elseif(NOT "x$ENV{GPG_PASSWORD}" STREQUAL "x")
			set(sGPGPassword "$ENV{GPG_PASSWORD}")
		endif()
	endif()

	unset(sPFXCertificate)
	unset(sPFXPassword)
	unset(sPFXPassFile)

	if(DEFINED PKCS12_CERTIFICATE AND EXISTS "${PKCS12_CERTIFICATE}")
		set(sPFXCertificate "${PKCS12_CERTIFICATE}")
	elseif(NOT "x$ENV{PKCS12_CERTIFICATE}" STREQUAL "x" AND EXISTS "$ENV{PKCS12_CERTIFICATE}")
		set(sPFXCertificate "$ENV{PKCS12_CERTIFICATE}")
	endif()

	if(DEFINED sPFXCertificate)
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
	endif()

	# -------- Arch/MSYS2 Custom Packages -------- #

	unset(sPKGBuildInstaller)

	if("PKGBUILD" IN_LIST CPACK_GENERATOR OR "PKGBUILD" IN_LIST CPACK_SOURCE_GENERATOR)
		find_program(MAKEPKG_EXECUTABLE NAMES "makepkg")
		if(MAKEPKG_EXECUTABLE AND PACKAGE_TARGETS${NX_PROJECT_NAME})
			file(
				GLOB lsCandidates
				LIST_DIRECTORIES false
				"tools/packaging/PKGBUILD[-.]${sDistroId}" "tools/PKGBUILD[-.]${sDistroId}" "PKGBUILD[-.]${sDistroId}"
				"tools/packaging/PKGBUILD" "tools/PKGBUILD" "PKGBUILD")
			if(DEFINED lsCandidates AND lsCandidates)
				list(GET lsCandidates 0 sCandidate)
				set(sPKGBuildInstaller "${sCandidate}")
			endif()

			if(DEFINED sPKGBuildInstaller)
				get_filename_component(sDestination "${sPKGBuildInstaller}" NAME)
				set(sPKGBuildCombine "${CMAKE_CURRENT_BINARY_DIR}/${sDestination}")
			else()
				unset(sPKGBuildSource)
				file(
					GLOB lsCandidates
					LIST_DIRECTORIES false
					"tools/packaging/PKGBUILD[-.]${sDistroId}.in" "tools/PKGBUILD[-.]${sDistroId}.in" "PKGBUILD[-.]${sDistroId}.in"
					"tools/packaging/PKGBUILD.in" "tools/PKGBUILD.in" "PKGBUILD.in")
				if(DEFINED lsCandidates AND lsCandidates)
					list(GET lsCandidates 0 sCandidate)
					set(sPKGBuildSource "${sCandidate}")
				elseif(EXISTS "${NXPACKAGE_DIRECTORY}/packaging/PKGBUILD.${sDistroId}.in")
					set(sPKGBuildSource "${NXPACKAGE_DIRECTORY}/packaging/PKGBUILD.${sDistroId}.in")
				else()
					set(sPKGBuildSource "${NXPACKAGE_DIRECTORY}/packaging/PKGBUILD.in")
				endif()

				string(REGEX REPLACE ".in$" ".component" sCandidate "${sPKGBuildSource}")
				if(EXISTS "${sCandidate}" AND CPACK_PKG_COMPONENT_INSTALL)
					foreach(sComponent ${NX_COMPONENT_LIST})
						set(sPKGBuildComponent_Name "${CPACK_PKGBUILD_${sComponent}_PACKAGE_NAME}")
						set(sPKGBuildComponent_Architecture "${CPACK_PKGBUILD_${sComponent}_PACKAGE_ARCHITECTURE}")
						set(sPKGBuildComponent_Ordinal "${CPACK_${sComponent}_ORDINAL}")

						unset(sPKGBuildComponent_Depends)
						if(DEFINED CPACK_PKGBUILD_${sComponent}_PACKAGE_DEPENDS)
							set(sPKGBuildComponent_Depends "${CPACK_PKGBUILD_${sComponent}_PACKAGE_DEPENDS}")
						endif()

						unset(sPKGBuildComponent_Optional)
						if(DEFINED CPACK_PKGBUILD_${sComponent}_PACKAGE_OPTIONAL)
							set(sPKGBuildComponent_Optional "${CPACK_PKGBUILD_${sComponent}_PACKAGE_OPTIONAL}")
						endif()

						set(sPKGBuildComponent_SourceDir
							"_CPack_Packages/${CPACK_SYSTEM_NAME}/External/${CPACK_PACKAGE_FILE_NAME}/${sComponent}")

						get_filename_component(sDestination "${sCandidate}" NAME)
						string(REGEX REPLACE ".component$" ".${sPKGBuildComponent_Ordinal}" sDestination "${sDestination}")
						configure_file("${sCandidate}" "${CMAKE_CURRENT_BINARY_DIR}/_${sDestination}" @ONLY NEWLINE_STYLE UNIX)
					endforeach()

					set(sPKGBuild_PackageTag "ignored")
					unset(sPKGBuild_Packages)
					foreach(sComponent ${NX_COMPONENT_LIST})
						list(APPEND sPKGBuild_Packages "'${CPACK_PKGBUILD_${sComponent}_PACKAGE_NAME}'")
					endforeach()
					string(REPLACE ";" " " sPKGBuild_Packages "${sPKGBuild_Packages}")
				else()
					set(sPKGBuild_PackageTag "package")
					set(sPKGBuild_Packages "'${CPACK_PKGBUILD_PACKAGE_NAME}'")
				endif()

				get_filename_component(sDestination "${sPKGBuildSource}" NAME)
				string(REGEX REPLACE ".in$" "" sDestination "${sDestination}")
				configure_file("${sPKGBuildSource}" "${CMAKE_CURRENT_BINARY_DIR}/_${sDestination}" @ONLY NEWLINE_STYLE UNIX)
				set(sPKGBuildInstaller "${CMAKE_CURRENT_BINARY_DIR}/_${sDestination}")
				set(sPKGBuildCombine "${CMAKE_CURRENT_BINARY_DIR}/${sDestination}")
			endif()
		endif()
	endif()
	if("PKGBUILD" IN_LIST CPACK_GENERATOR AND PACKAGE_TARGETS${NX_PROJECT_NAME})
		if(MAKEPKG_EXECUTABLE)
			cmake_dependent_option(GPGSIGN_PKGBUILD${NX_PROJECT_NAME} "Digitally-Sign PKGBUILD Packages - ${PROJECT_NAME}" ON
									"NOT NX_TARGET_BUILD_DEBUG;DEFINED sGPGKeyId" OFF)
			unset(sSignArgs)
			if(GPGSIGN_PKGBUILD${NX_PROJECT_NAME})
				set(sSignArgs "--sign")
				if(DEFINED bHasGPGKeyId)
					list(APPEND sSignArgs "--key" "${sGPGKeyId}")
				endif()
			endif()

			unset(sCopyInstaller)
			list(APPEND sCopyInstaller COMMAND "${CMAKE_COMMAND};-E;copy_if_different;${sPKGBuildInstaller};${sPKGBuildCombine}")
			foreach(sOrdinal ${lsComponentOrdinals})
				if(EXISTS "${sPKGBuildInstaller}.${sOrdinal}" AND CPACK_PKG_COMPONENT_INSTALL)
					list(APPEND sCopyInstaller COMMAND "cat;${sPKGBuildInstaller}.${sOrdinal};>>;${sPKGBuildCombine}")
				endif()
			endforeach()
			get_filename_component(sDestination "${sPKGBuildCombine}" NAME)

			unset(sChecksumCommand)
			if(CPACK_PKG_COMPONENT_INSTALL)
				foreach(sComponent ${NX_COMPONENT_LIST})
					list(
						APPEND
						sChecksumCommand
						COMMAND
						"${CMAKE_COMMAND};-E;${sChecksumType};${CPACK_PKGBUILD_${sComponent}_FILE_NAME};>;${CPACK_PKGBUILD_${sComponent}_FILE_NAME}.${sChecksumExt}"
					)
				endforeach()
			else()
				list(APPEND sChecksumCommand COMMAND
						"${CMAKE_COMMAND};-E;${sChecksumType};${CPACK_PKGBUILD_FILE_NAME};>;${CPACK_PKGBUILD_FILE_NAME}.${sChecksumExt}")
			endif()

			add_custom_target(
				"pkgbuild${NX_PROJECT_NAME}"
				${sCopyInstaller}
				COMMAND "${MAKEPKG_EXECUTABLE}" -g -p "${sDestination}" >> ${sPKGBuildCombine}
				COMMAND "${MAKEPKG_EXECUTABLE}" -C -c -f -p "${sDestination}" ${sSignArgs} ${sChecksumCommand}
				DEPENDS "${sPKGBUILDInstaller}"
				WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
				COMMENT "[makepkg] Building Package: ${CPACK_PKGBUILD_FILE_NAME}"
				VERBATIM)
			list(APPEND lsIsExtraBinary "pkgbuild${NX_PROJECT_NAME}")
			list(APPEND lsNeedPackageSource "pkgbuild${NX_PROJECT_NAME}")
		endif()
		if("PKGBUILD" IN_LIST CPACK_GENERATOR)
			list(REMOVE_ITEM CPACK_GENERATOR "PKGBUILD")
		endif()
	endif()
	if("PKGBUILD" IN_LIST CPACK_SOURCE_GENERATOR AND PACKAGE_TARGETS${NX_PROJECT_NAME})
		if(MAKEPKG_EXECUTABLE)
			cmake_dependent_option(GPGSIGN_PKGBUILD_SRC${NX_PROJECT_NAME} "Digitally-Sign PKGBUILD Packages - ${PROJECT_NAME}" ON
									"NOT NX_TARGET_BUILD_DEBUG;DEFINED sGPGKeyId" OFF)
			unset(sSignArgs)
			if(GPGSIGN_PKGBUILD_SRC${NX_PROJECT_NAME})
				set(sSignArgs "--sign")
				if(DEFINED bHasGPGKeyId)
					list(APPEND sSignArgs "--key" "${sGPGKeyId}")
				endif()
			endif()

			unset(sCopyInstaller)
			list(APPEND sCopyInstaller COMMAND "${CMAKE_COMMAND};-E;copy_if_different;${sPKGBuildInstaller};${sPKGBuildCombine}")
			foreach(sOrdinal ${lsComponentOrdinals})
				if(EXISTS "${sPKGBuildInstaller}.${sOrdinal}" AND CPACK_PKG_COMPONENT_INSTALL)
					list(APPEND sCopyInstaller COMMAND "cat;${sPKGBuildInstaller}.${sOrdinal};>>;${sPKGBuildCombine}")
				endif()
			endforeach()
			get_filename_component(sDestination "${sPKGBuildCombine}" NAME)

			add_custom_target(
				"pkgbuild${NX_PROJECT_NAME}_SRC"
				${sCopyInstaller}
				COMMAND bash "${MAKEPKG_EXECUTABLE}" -g -p "${sDestination}" >> ${sPKGBuildCombine}
				COMMAND bash "${MAKEPKG_EXECUTABLE}" -f -o -p "${sDestination}" --allsource ${sSignArgs}
				COMMAND "${CMAKE_COMMAND}" -E "${sChecksumType}" "${CPACK_PKGBUILD_FILE_SOURCE}" >
						"${CPACK_PKGBUILD_FILE_SOURCE}.${sChecksumExt}"
				DEPENDS "${sPKGBUILDInstaller}"
				WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
				COMMENT "[makepkg] Building Package: ${CPACK_PKGBUILD_FILE_SOURCE}"
				VERBATIM)
			list(APPEND lsIsExtraSource "pkgbuild${NX_PROJECT_NAME}_SRC")
			list(APPEND lsNeedPackageSource "pkgbuild${NX_PROJECT_NAME}_SRC")
		endif()
		if("PKGBUILD" IN_LIST CPACK_SOURCE_GENERATOR)
			list(REMOVE_ITEM CPACK_SOURCE_GENERATOR "PKGBUILD")
		endif()
	endif()

	# -------- MSYS2 MinGW Custom Packages -------- #

	unset(sPKGBuildInstaller)

	if("MINGW" IN_LIST CPACK_GENERATOR OR "MINGW" IN_LIST CPACK_SOURCE_GENERATOR)
		find_program(MAKEPKG_MINGW_EXECUTABLE NAMES "makepkg-mingw")
		if(MAKEPKG_MINGW_EXECUTABLE AND PACKAGE_TARGETS${NX_PROJECT_NAME})
			file(
				GLOB lsCandidates
				LIST_DIRECTORIES false
				"tools/packaging/PKGBUILD[-.]mingw-w64" "tools/PKGBUILD[-.]mingw-w64" "PKGBUILD[-.]mingw-w64")
			if(DEFINED lsCandidates AND lsCandidates)
				list(GET lsCandidates 0 sCandidate)
				set(sPKGBuildInstaller "${sCandidate}")
			endif()

			if(DEFINED sPKGBuildInstaller)
				get_filename_component(sDestination "${sPKGBuildInstaller}" NAME)
				set(sPKGBuildCombine "${CMAKE_CURRENT_BINARY_DIR}/${sDestination}")
			else()
				unset(sPKGBuildSource)
				file(
					GLOB lsCandidates
					LIST_DIRECTORIES false
					"tools/packaging/PKGBUILD[-.]mingw-w64.in" "tools/PKGBUILD[-.]mingw-w64.in" "PKGBUILD[-.]mingw-w64.in")
				if(DEFINED lsCandidates AND lsCandidates)
					list(GET lsCandidates 0 sCandidate)
					set(sPKGBuildSource "${sCandidate}")
				else()
					set(sPKGBuildSource "${NXPACKAGE_DIRECTORY}/packaging/PKGBUILD.mingw-w64.in")
				endif()

				get_filename_component(sDestination "${sPKGBuildSource}" NAME)
				string(REGEX REPLACE ".in$" "" sDestination "${sDestination}")
				configure_file("${sPKGBuildSource}" "${CMAKE_CURRENT_BINARY_DIR}/_${sDestination}" @ONLY NEWLINE_STYLE UNIX)
				set(sPKGBuildInstaller "${CMAKE_CURRENT_BINARY_DIR}/_${sDestination}")
				set(sPKGBuildCombine "${CMAKE_CURRENT_BINARY_DIR}/${sDestination}")
			endif()
		endif()
	endif()
	if("MINGW" IN_LIST CPACK_GENERATOR AND PACKAGE_TARGETS${NX_PROJECT_NAME})
		if(MAKEPKG_MINGW_EXECUTABLE)
			cmake_dependent_option(GPGSIGN_MINGW${NX_PROJECT_NAME} "Digitally-Sign MinGW Packages - ${PROJECT_NAME}" ON
									"NOT NX_TARGET_BUILD_DEBUG;DEFINED sGPGKeyId" OFF)
			unset(sSignArgs)
			if(GPGSIGN_MINGW${NX_PROJECT_NAME})
				set(sSignArgs "--sign")
				if(DEFINED bHasGPGKeyId)
					list(APPEND sSignArgs "--key" "${sGPGKeyId}")
				endif()
			endif()

			unset(sCopyInstaller)
			list(APPEND sCopyInstaller COMMAND "${CMAKE_COMMAND};-E;copy_if_different;${sPKGBuildInstaller};${sPKGBuildCombine}")
			get_filename_component(sDestination "${sPKGBuildCombine}" NAME)

			unset(sChecksumCommand)
			if(NOT "x$ENV{MINGW_PACKAGE_PREFIX}" STREQUAL "x")
				list(APPEND sChecksumCommand COMMAND
						"${CMAKE_COMMAND};-E;${sChecksumType};${CPACK_MINGW_FILE_NAME};>;${CPACK_MINGW_FILE_NAME}.${sChecksumExt}")
				string(REPLACE "\${MINGW_PACKAGE_PREFIX}" "$ENV{MINGW_PACKAGE_PREFIX}" sChecksumCommand "${sChecksumCommand}")
			elseif(NOT "x$ENV{MINGW_ARCH}" STREQUAL "x")
				if("$ENV{MINGW_ARCH}" MATCHES "mingw32")
					list(APPEND sChecksumCommand COMMAND
							"${CMAKE_COMMAND};-E;${sChecksumType};${CPACK_MINGW_FILE_NAME};>;${CPACK_MINGW_FILE_NAME}.${sChecksumExt}")
					string(REPLACE "\${MINGW_PACKAGE_PREFIX}" "mingw-w64-i686" sChecksumCommand "${sChecksumCommand}")
				endif()
				if("$ENV{MINGW_ARCH}" MATCHES "mingw64")
					list(APPEND sChecksumCommand COMMAND
							"${CMAKE_COMMAND};-E;${sChecksumType};${CPACK_MINGW_FILE_NAME};>;${CPACK_MINGW_FILE_NAME}.${sChecksumExt}")
					string(REPLACE "\${MINGW_PACKAGE_PREFIX}" "mingw-w64-x86_64" sChecksumCommand "${sChecksumCommand}")
				endif()
				if("$ENV{MINGW_ARCH}" MATCHES "clang32")
					list(APPEND sChecksumCommand COMMAND
							"${CMAKE_COMMAND};-E;${sChecksumType};${CPACK_MINGW_FILE_NAME};>;${CPACK_MINGW_FILE_NAME}.${sChecksumExt}")
					string(REPLACE "\${MINGW_PACKAGE_PREFIX}" "mingw-w64-clang-i686" sChecksumCommand "${sChecksumCommand}")
				endif()
				if("$ENV{MINGW_ARCH}" MATCHES "clang64")
					list(APPEND sChecksumCommand COMMAND
							"${CMAKE_COMMAND};-E;${sChecksumType};${CPACK_MINGW_FILE_NAME};>;${CPACK_MINGW_FILE_NAME}.${sChecksumExt}")
					string(REPLACE "\${MINGW_PACKAGE_PREFIX}" "mingw-w64-clang-x86_64" sChecksumCommand "${sChecksumCommand}")
				endif()
				if("$ENV{MINGW_ARCH}" MATCHES "ucrt64")
					list(APPEND sChecksumCommand COMMAND
							"${CMAKE_COMMAND};-E;${sChecksumType};${CPACK_MINGW_FILE_NAME};>;${CPACK_MINGW_FILE_NAME}.${sChecksumExt}")
					string(REPLACE "\${MINGW_PACKAGE_PREFIX}" "mingw-w64-ucrt-x86_64" sChecksumCommand "${sChecksumCommand}")
				endif()
			else()
				list(APPEND sChecksumCommand COMMAND
						"${CMAKE_COMMAND};-E;${sChecksumType};${CPACK_MINGW_FILE_NAME};>;${CPACK_MINGW_FILE_NAME}.${sChecksumExt}")
				string(REPLACE "\${MINGW_PACKAGE_PREFIX}" "mingw-w64-x86_64" sChecksumCommand "${sChecksumCommand}")
			endif()

			add_custom_target(
				"mingw${NX_PROJECT_NAME}"
				${sCopyInstaller}
				COMMAND bash "${MAKEPKG_MINGW_EXECUTABLE}" -g -p "${sDestination}" >> ${sPKGBuildCombine}
				COMMAND bash "${MAKEPKG_MINGW_EXECUTABLE}" -C -c -f -p "${sDestination}" ${sSignArgs} ${sChecksumCommand}
				DEPENDS "${sPKGBUILDInstaller}"
				WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
				COMMENT "[makepkg-mingw] Building Package: ${CPACK_MINGW_FILE_NAME}"
				VERBATIM)
			list(APPEND lsIsExtraBinary "mingw${NX_PROJECT_NAME}")
			list(APPEND lsNeedPackageSource "mingw${NX_PROJECT_NAME}")
		endif()
		if("MINGW" IN_LIST CPACK_GENERATOR)
			list(REMOVE_ITEM CPACK_GENERATOR "MINGW")
		endif()
	endif()
	if("MINGW" IN_LIST CPACK_SOURCE_GENERATOR AND PACKAGE_TARGETS${NX_PROJECT_NAME})
		if(MAKEPKG_MINGW_EXECUTABLE)
			cmake_dependent_option(GPGSIGN_MINGW_SRC${NX_PROJECT_NAME} "Digitally-Sign MinGW Packages - ${PROJECT_NAME}" ON
									"NOT NX_TARGET_BUILD_DEBUG;DEFINED sGPGKeyId" OFF)
			unset(sSignArgs)
			if(GPGSIGN_MINGW_SRC${NX_PROJECT_NAME})
				set(sSignArgs "--sign")
				if(DEFINED bHasGPGKeyId)
					list(APPEND sSignArgs "--key" "${sGPGKeyId}")
				endif()
			endif()

			unset(sCopyInstaller)
			list(APPEND sCopyInstaller COMMAND "${CMAKE_COMMAND};-E;copy_if_different;${sPKGBuildInstaller};${sPKGBuildCombine}")
			get_filename_component(sDestination "${sPKGBuildCombine}" NAME)

			add_custom_target(
				"mingw${NX_PROJECT_NAME}_SRC"
				${sCopyInstaller}
				COMMAND bash "${MAKEPKG_MINGW_EXECUTABLE}" -g -p "${sDestination}" >> ${sPKGBuildCombine}
				COMMAND bash "${MAKEPKG_MINGW_EXECUTABLE}" -f -o -p "${sDestination}" --allsource ${sSignArgs}
				COMMAND "${CMAKE_COMMAND}" -E "${sChecksumType}" "${CPACK_MINGW_FILE_SOURCE}" > "${CPACK_MINGW_FILE_SOURCE}.${sChecksumExt}"
				DEPENDS "${sPKGBUILDInstaller}"
				WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
				COMMENT "[makepkg-mingw] Building Package: ${CPACK_MINGW_FILE_SOURCE}"
				VERBATIM)
			list(APPEND lsIsExtraSource "mingw${NX_PROJECT_NAME}_SRC")
			list(APPEND lsNeedPackageSource "mingw${NX_PROJECT_NAME}_SRC")
		endif()
		if("MINGW" IN_LIST CPACK_SOURCE_GENERATOR)
			list(REMOVE_ITEM CPACK_SOURCE_GENERATOR "MINGW")
		endif()
	endif()

	# -------- NSIS Custom Packages -------- #

	set(bHasNSIS OFF)
	set(bRequestNSIS OFF)
	if("NSIS" IN_LIST CPACK_GENERATOR OR "NSIS64" IN_LIST CPACK_GENERATOR)
		set(bRequestNSIS ON)
	endif()

	if(bRequestNSIS AND PACKAGE_TARGETS${NX_PROJECT_NAME})
		find_program(
			MAKENSIS_EXECUTABLE
			NAMES "makensis"
			PATHS "$ENV{NSIS_DIR}" "$ENV{PROGRAMFILES}/NSIS" "$ENV{PROGRAMFILES\(x86\)}/NSIS")
		if(MAKENSIS_EXECUTABLE)
			unset(sNSISInstaller)
			file(
				GLOB lsCandidates
				LIST_DIRECTORIES false
				"tools/packaging/*.nsi" "tools/*.nsi" "*.nsi")
			if(DEFINED lsCandidates AND lsCandidates)
				list(GET lsCandidates 0 sCandidate)
				set(sNSISInstaller "${sCandidate}")
			endif()

			if(DEFINED sNSISInstaller)
				get_filename_component(sDestination "${sNSISInstaller}" NAME)
				set(sNSISCombine "${CMAKE_CURRENT_BINARY_DIR}/${sDestination}")
			else()
				unset(sNSISSource)
				file(
					GLOB lsCandidates
					LIST_DIRECTORIES false
					"tools/packaging/*.nsi.in" "tools/*.nsi.in" "*.nsi.in")
				if(DEFINED lsCandidates AND lsCandidates)
					list(GET lsCandidates 0 sCandidate)
					set(sNSISSource "${sCandidate}")
				else()
					set(sNSISSource "${NXPACKAGE_DIRECTORY}/packaging/installer.nsi.in")
				endif()

				unset(sNSISRoutine_Install)
				string(REGEX REPLACE ".in$" ".component" sCandidate "${sNSISSource}")
				if(EXISTS "${sCandidate}")
					foreach(sComponent ${NX_COMPONENT_LIST})
						set(sNSISComponent_Name "${CPACK_COMPONENT_${sComponent}_DISPLAY_NAME}")
						set(sNSISComponent_Tag "${sComponent}")
						set(sNSISComponent_Ordinal "${CPACK_${sComponent}_ORDINAL}")

						unset(sNSISComponent_Disabled)
						if(CPACK_COMPONENT_${sComponent}_DISABLED)
							set(sNSISComponent_Disabled "/o")
						endif()

						unset(sNSISComponent_Required)
						if(CPACK_COMPONENT_${sComponent}_REQUIRED)
							set(sNSISComponent_Required "\n  SectionIn RO")
						endif()

						file(TO_NATIVE_PATH "_CPack_Packages/${CPACK_SYSTEM_NAME}/External/${CPACK_PACKAGE_FILE_NAME}/${sComponent}"
								sNSISComponent_SourceDir)

						get_filename_component(sDestination "${sCandidate}" NAME)
						string(REGEX REPLACE ".component$" ".${sNSISComponent_Ordinal}" sDestination "${sDestination}")
						configure_file("${sCandidate}" "${CMAKE_CURRENT_BINARY_DIR}/_${sDestination}" @ONLY NEWLINE_STYLE WIN32)
					endforeach()
				else()
					foreach(sComponent ${NX_COMPONENT_LIST})
						file(TO_NATIVE_PATH "_CPack_Packages/${CPACK_SYSTEM_NAME}/External/${CPACK_PACKAGE_FILE_NAME}/${sComponent}"
								sNSISComponent_SourceDir)
						list(APPEND sNSISRoutine_Install "  File /r \"${sNSISComponent_SourceDir}\\*.*\"")
					endforeach()
					string(REPLACE ";" "\n" sNSISRoutine_Install "${sNSISRoutine_Install}")
				endif()

				unset(sNSISRoutine_Uninstall)
				foreach(sCandidate ${NX_CLEANUP_DELETE})
					file(TO_NATIVE_PATH "${sCandidate}" sCandidate)
					list(APPEND sNSISRoutine_Uninstall "  Delete \"$INSTDIR\\${sCandidate}\"")
				endforeach()
				foreach(sCandidate ${lsRMDirs})
					if("${sCandidate}" IN_LIST lsRMDirsForce)
						file(TO_NATIVE_PATH "${sCandidate}" sCandidate)
						list(APPEND sNSISRoutine_Uninstall "  RMDir /r \"$INSTDIR\\${sCandidate}\"")
					else()
						file(TO_NATIVE_PATH "${sCandidate}" sCandidate)
						list(APPEND sNSISRoutine_Uninstall "  RMDir \"$INSTDIR\\${sCandidate}\"")
					endif()
				endforeach()
				if(DEFINED sNSISRoutine_Uninstall)
					list(APPEND sNSISRoutine_Uninstall "  RMDir \"$INSTDIR\"")
				else()
					list(APPEND sNSISRoutine_Uninstall "  RMDir /r \"$INSTDIR\"")
				endif()
				string(REPLACE ";" "\n" sNSISRoutine_Uninstall "${sNSISRoutine_Uninstall}")

				get_filename_component(sDestination "${sNSISSource}" NAME)
				string(REGEX REPLACE ".in$" "" sDestination "${sDestination}")
				configure_file("${sNSISSource}" "${CMAKE_CURRENT_BINARY_DIR}/_${sDestination}" @ONLY NEWLINE_STYLE WIN32)
				set(sNSISInstaller "${CMAKE_CURRENT_BINARY_DIR}/_${sDestination}")
				set(sNSISCombine "${CMAKE_CURRENT_BINARY_DIR}/${sDestination}")
			endif()

			if(NOT "External" IN_LIST CPACK_GENERATOR)
				nx_append(CPACK_GENERATOR "External")
			endif()
			if("NSIS" IN_LIST CPACK_GENERATOR)
				list(REMOVE_ITEM CPACK_GENERATOR "NSIS")
			endif()
			if("NSIS64" IN_LIST CPACK_GENERATOR)
				list(REMOVE_ITEM CPACK_GENERATOR "NSIS64")
			endif()
			set(bHasNSIS ON)

			unset(sCopyInstaller)
			list(APPEND sCopyInstaller COMMAND "${CMAKE_COMMAND};-E;copy_if_different;${sNSISInstaller};${sNSISCombine}")
			foreach(sOrdinal ${lsComponentOrdinals})
				if(EXISTS "${sNSISInstaller}.${sOrdinal}")
					list(APPEND sCopyInstaller COMMAND "cat;${sNSISInstaller}.${sOrdinal};>>;${sNSISCombine}")
				endif()
			endforeach()

			add_custom_target(
				"nsis${NX_PROJECT_NAME}"
				${sCopyInstaller}
				COMMAND "${MAKENSIS_EXECUTABLE}" /INPUTCHARSET UTF8 "${sNSISCombine}"
				COMMAND "${CMAKE_COMMAND}" -E "${sChecksumType}" "${CPACK_NSIS_FILE_NAME}.exe" >
						"${CPACK_NSIS_FILE_NAME}.exe.${sChecksumExt}"
				DEPENDS "${sNSISInstaller}"
				WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
				COMMENT "[makensis] Building Package: ${CPACK_NSIS_FILE_NAME}.exe"
				VERBATIM)
			list(APPEND lsIsExtraBinary "nsis${NX_PROJECT_NAME}")
			list(APPEND lsNeedPackageBinary "nsis${NX_PROJECT_NAME}")
		endif()
	endif()

	# -------- Debian Package Signing -------- #

	if("DEB" IN_LIST CPACK_GENERATOR
		AND PACKAGE_TARGETS${NX_PROJECT_NAME}
		AND NOT NX_TARGET_BUILD_DEBUG
		AND DEFINED sGPGKeyId)
		find_program(DPKG_SIG_EXECUTABLE NAMES "dpkg-sig")
		cmake_dependent_option(GPGSIGN_DEBIAN${NX_PROJECT_NAME} "Digitally-Sign Debian Packages - ${PROJECT_NAME}" ON "DPKG_SIG_EXECUTABLE"
								OFF)

		if(GPGSIGN_DEBIAN${NX_PROJECT_NAME})
			unset(sSignArgs)
			if(DEFINED sGPGKeyId AND NOT sGPGKeyId MATCHES "^(ON|TRUE|1|DEFAULT)$")
				list(APPEND sSignArgs "-k" "${sGPGKeyId}")
			endif()
			if(DEFINED sGPGPassFile)
				list(APPEND sSignArgs "-f" "${sPFXPassFile}")
			elseif(DEFINED sGPGPassword)
				file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/.gpgpass" "${sGPGPassword}")
				list(APPEND sSignArgs "-f" "${CMAKE_CURRENT_BINARY_DIR}/.gpgpass")
			endif()

			if(CPACK_DEB_COMPONENT_INSTALL)
				foreach(sComponent ${NX_COMPONENT_LIST})
					add_custom_target(
						"debsign${sComponent}"
						COMMAND "${DPKG_SIG_EXECUTABLE}" --sign builder ${sSignArgs} "${CPACK_DEBIAN_${sComponent}_FILE_NAME}"
						COMMAND "${CMAKE_COMMAND}" -E "${sChecksumType}" "${CPACK_DEBIAN_${sComponent}_FILE_NAME}" >
								"${CPACK_DEBIAN_${sComponent}_FILE_NAME}.${sChecksumExt}"
						WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
						COMMENT "[dpkg-sig] Signing Package: ${CPACK_DEBIAN_${sComponent}_FILE_NAME}"
						VERBATIM)
					list(APPEND lsIsExtraBinary "debsign${sComponent}")
					list(APPEND lsNeedPackageBinary "debsign${sComponent}")
				endforeach()
			else()
				add_custom_target(
					"debsign${NX_PROJECT_NAME}"
					COMMAND "${DPKG_SIG_EXECUTABLE}" --sign builder ${sSignArgs} "${CPACK_DEBIAN_FILE_NAME}"
					COMMAND "${CMAKE_COMMAND}" -E "${sChecksumType}" "${CPACK_DEBIAN_FILE_NAME}" >
							"${CPACK_DEBIAN_FILE_NAME}.${sChecksumExt}"
					WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
					COMMENT "[dpkg-sig] Signing Package: ${CPACK_DEBIAN_FILE_NAME}"
					VERBATIM)
				list(APPEND lsIsExtraBinary "debsign${NX_PROJECT_NAME}")
				list(APPEND lsNeedPackageBinary "debsign${NX_PROJECT_NAME}")
			endif()
		endif()
	endif()

	# -------- NSIS Package Signing -------- #

	if("NSIS" IN_LIST CPACK_GENERATOR OR "NSIS64" IN_LIST CPACK_GENERATOR)
		set(bHasNSIS ON)
	endif()

	if(bHasNSIS
		AND PACKAGE_TARGETS${NX_PROJECT_NAME}
		AND NOT NX_TARGET_BUILD_DEBUG
		AND DEFINED sPFXCertificate)
		find_program(OSSLSIGNCODE_EXECUTABLE NAMES "osslsigncode")
		cmake_dependent_option(DIGSIGN_NSIS${NX_PROJECT_NAME} "Digitally-Sign NSIS Packages - ${PROJECT_NAME}" ON "OSSLSIGNCODE_EXECUTABLE"
								OFF)

		if(DIGSIGN_NSIS${NX_PROJECT_NAME})
			unset(sSignArgs)
			if(DEFINED sPFXPassFile)
				list(APPEND sSignArgs "-readpass" "${sPFXPassFile}")
			elseif(DEFINED sPFXPassword)
				list(APPEND sSignArgs "-pass" "${sPFXPassword}")
			endif()

			add_custom_target(
				"exesign${NX_PROJECT_NAME}"
				COMMAND "${OSSLSIGNCODE_EXECUTABLE}" -pkcs12 "${sPFXCertificate}" ${sSignArgs} -ts "http://timestamp.digicert.com" -h sha1
						-in "${CPACK_NSIS_FILE_NAME}.exe" -out "${CPACK_NSIS_FILE_NAME}.tmp"
				COMMAND "${OSSLSIGNCODE_EXECUTABLE}" -pkcs12 "${sPFXCertificate}" ${sSignArgs} -ts "http://timestamp.digicert.com" -h sha256
						-in "${CPACK_NSIS_FILE_NAME}.tmp" -out "${CPACK_NSIS_FILE_NAME}.exe"
				COMMAND "${CMAKE_COMMAND}" -E remove "${CPACK_NSIS_FILE_NAME}.tmp"
				COMMAND "${CMAKE_COMMAND}" -E "${sChecksumType}" "${CPACK_NSIS_FILE_NAME}.exe" >
						"${CPACK_NSIS_FILE_NAME}.exe.${sChecksumExt}"
				WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
				COMMENT "[osslsigncode] Signing Package: ${CPACK_NSIS_FILE_NAME}.exe"
				VERBATIM)
			list(APPEND lsIsExtraBinary "exesign${NX_PROJECT_NAME}")
			if(TARGET "nsis${NX_PROJECT_NAME}")
				add_dependencies(${sTarget} "nsis${NX_PROJECT_NAME}")
			else()
				list(APPEND lsNeedPackageBinary "exesign${NX_PROJECT_NAME}")
			endif()
		endif()
	endif()

	# -------- RPM Package Signing -------- #

	if("RPM" IN_LIST CPACK_GENERATOR
		AND PACKAGE_TARGETS${NX_PROJECT_NAME}
		AND NOT NX_TARGET_BUILD_DEBUG
		AND DEFINED sGPGKeyId)
		find_program(RPMSIGN_EXECUTABLE NAMES "rpmsign")
		cmake_dependent_option(GPGSIGN_RPM${NX_PROJECT_NAME} "Digitally-Sign RPM Packages - ${PROJECT_NAME}" ON "RPMSIGN_EXECUTABLE" OFF)

		if(GPGSIGN_RPM${NX_PROJECT_NAME})
			unset(sSignArgs)
			if(DEFINED sGPGKeyId)
				list(APPEND sSignArgs "-D" "_gpg_name ${sGPGKeyId}")
			endif()
			if(DEFINED sGPGPassword)
				list(APPEND sSignArgs "-D" "_gpg_pass ${sGPGPassword}")
			endif()
			if(NOT EXISTS "$ENV{HOME}/.rpmmacros")
				list(APPEND sSignArgs "-D" "_binary_filedigest_algorithm 8")
				list(APPEND sSignArgs "-D" "_source_filedigest_algorithm 8")
			endif()

			if(CPACK_RPM_COMPONENT_INSTALL)
				foreach(sComponent ${NX_COMPONENT_LIST})
					add_custom_target(
						"rpmsign${sComponent}"
						COMMAND "${RPMSIGN_EXECUTABLE}" --addsign ${sSignArgs} "${CPACK_RPM_${sComponent}_FILE_NAME}"
						COMMAND "${CMAKE_COMMAND}" -E "${sChecksumType}" "${CPACK_RPM_${sComponent}_FILE_NAME}" >
								"${CPACK_RPM_${sComponent}_FILE_NAME}.${sChecksumExt}"
						WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
						COMMENT "[rpmsign] Signing Package: ${CPACK_RPM_${sComponent}_FILE_NAME}"
						VERBATIM)
					list(APPEND lsIsExtraBinary "rpmsign${sComponent}")
					list(APPEND lsNeedPackageBinary "rpmsign${sComponent}")
				endforeach()
			else()
				add_custom_target(
					"rpmsign${NX_PROJECT_NAME}"
					COMMAND "${RPMSIGN_EXECUTABLE}" --addsign ${sSignArgs} "${CPACK_RPM_FILE_NAME}"
					COMMAND "${CMAKE_COMMAND}" -E "${sChecksumType}" "${CPACK_RPM_FILE_NAME}" > "${CPACK_RPM_FILE_NAME}.${sChecksumExt}"
					WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
					COMMENT "[rpmsign] Signing Package: ${CPACK_RPM_FILE_NAME}"
					VERBATIM)
				list(APPEND lsIsExtraBinary "rpmsign${NX_PROJECT_NAME}")
				list(APPEND lsNeedPackageBinary "rpmsign${NX_PROJECT_NAME}")
			endif()
		endif()
	endif()

	if("RPM" IN_LIST CPACK_SOURCE_GENERATOR
		AND PACKAGE_TARGETS${NX_PROJECT_NAME}
		AND NOT NX_TARGET_BUILD_DEBUG
		AND DEFINED sGPGKeyId)
		find_program(RPMSIGN_EXECUTABLE NAMES "rpmsign")
		cmake_dependent_option(GPGSIGN_SRPM${NX_PROJECT_NAME} "Digitally-Sign SRPM Packages - ${PROJECT_NAME}" ON "RPMSIGN_EXECUTABLE" OFF)

		if(GPGSIGN_SRPM${NX_PROJECT_NAME})
			unset(sSignArgs)
			if(DEFINED sGPGKeyId)
				list(APPEND sSignArgs "-D" "_gpg_name ${sGPGKeyId}")
			endif()
			if(DEFINED sGPGPassword)
				list(APPEND sSignArgs "-D" "_gpg_pass ${sGPGPassword}")
			endif()
			if(NOT EXISTS "$ENV{HOME}/.rpmmacros")
				list(APPEND sSignArgs "-D" "_binary_filedigest_algorithm 8")
				list(APPEND sSignArgs "-D" "_source_filedigest_algorithm 8")
			endif()

			add_custom_target(
				"rpmsign${NX_PROJECT_NAME}_SRC"
				COMMAND "${RPMSIGN_EXECUTABLE}" --addsign ${sSignArgs} "${CPACK_RPM_FILE_SOURCE}"
				COMMAND "${CMAKE_COMMAND}" -E "${sChecksumType}" "${CPACK_RPM_FILE_SOURCE}" > "${CPACK_RPM_FILE_SOURCE}.${sChecksumExt}"
				WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
				COMMENT "[rpmsign] Signing Package: ${CPACK_RPM_FILE_SOURCE}"
				VERBATIM)
			list(APPEND lsIsExtraSource "rpmsign${NX_PROJECT_NAME}_SRC")
			list(APPEND lsNeedPackageSource "rpmsign${NX_PROJECT_NAME}_SRC")
		endif()
	endif()

	# -------- Include CPack -------- #

	foreach(
		vCleanseVars
		"CPACK_MINGW_FILE_NAME"
		"CPACK_MINGW_PACKAGE_NAME"
		"CPACK_MINGW_PACKAGE_PROVIDES"
		"CPACK_MINGW_PACKAGE_CONFLICTS"
		"CPACK_MINGW_PACKAGE_BUILDREQUIRES"
		"CPACK_MINGW_PACKAGE_DEPENDS"
		"CPACK_MINGW_PACKAGE_OPTIONAL")
		if(DEFINED ${vCleanseVars})
			string(REPLACE "\"" "\\\"" ${vCleanseVars} "${${vCleanseVars}}")
			string(REPLACE "\$" "\\\$" ${vCleanseVars} "${${vCleanseVars}}")
		endif()
	endforeach()
	foreach(
		vCleanseVars
		"CPACK_NSIS_EXTRA_INSTALL_COMMANDS"
		"CPACK_NSIS_EXTRA_PREINSTALL_COMMANDS"
		"CPACK_NSIS_EXTRA_UNINSTALL_COMMANDS"
		"CPACK_NSIS_INSTALL_ROOT"
		"CPACK_NSIS_MUI_HEADERIMAGE"
		"CPACK_NSIS_MUI_UNWELCOMEFINISHPAGE_BITMAP"
		"CPACK_NSIS_MUI_WELCOMEFINISHPAGE_BITMAP")
		if(DEFINED ${vCleanseVars})
			string(REPLACE "\\" "\\\\" ${vCleanseVars} "${${vCleanseVars}}")
		endif()
	endforeach()

	if(PACKAGE_TARGETS${NX_PROJECT_NAME})
		include(CPack)

		if(NOT TARGET package_extra)
			add_custom_target(package_extra COMMENT "== Building Binary Packaging ==")
		endif()
		if(NOT TARGET package_extra_source)
			add_custom_target(package_extra_source COMMENT "== Building Source Packaging ==")
		endif()
		if(NOT TARGET custom_package)
			add_custom_target(
				custom_package
				COMMAND "${CMAKE_COMMAND}" --build . --target package
				WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
				COMMENT "[cmake] Building Binary Package"
				VERBATIM)
		endif()
		if(NOT TARGET custom_package_source)
			unset(sByProducts)
			if("TGZ" IN_LIST CPACK_SOURCE_GENERATOR)
				list(APPEND sByProducts "${CMAKE_CURRENT_BINARY_DIR}/${CPACK_ARCHIVE_FILE_NAME}.tar.gz")
			endif()
			if("TXZ" IN_LIST CPACK_SOURCE_GENERATOR)
				list(APPEND sByProducts "${CMAKE_CURRENT_BINARY_DIR}/${CPACK_ARCHIVE_FILE_NAME}.tar.xz")
			endif()
			if("ZIP" IN_LIST CPACK_SOURCE_GENERATOR)
				list(APPEND sByProducts "${CMAKE_CURRENT_BINARY_DIR}/${CPACK_ARCHIVE_FILE_NAME}.zip")
			endif()
			if("7Z" IN_LIST CPACK_SOURCE_GENERATOR)
				list(APPEND sByProducts "${CMAKE_CURRENT_BINARY_DIR}/${CPACK_ARCHIVE_FILE_NAME}.7z")
			endif()
			unset(sMirrorCommand)
			if(DEFINED NX_GIT_RETRIEVED_STATE AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/tools")
				list(
					APPEND
					sMirrorCommand
					COMMAND
					"${CMAKE_COMMAND};-E;copy_if_different;${CMAKE_CURRENT_BINARY_DIR}/GitInfo.cmake;${CMAKE_CURRENT_SOURCE_DIR}/tools/GitInfo.cmake"
				)
			endif()
			add_custom_target(
				custom_package_source
				${sMirrorCommand}
				COMMAND "${CMAKE_COMMAND}" --build . --target package_source
				BYPRODUCTS ${sByProducts}
				WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
				COMMENT "[cmake] Building Source Package"
				VERBATIM)
		endif()

		foreach(sTarget ${lsNeedPackageBinary})
			add_dependencies(${sTarget} custom_package)
		endforeach()
		foreach(sTarget ${lsNeedPackageSource})
			add_dependencies(${sTarget} custom_package_source)
		endforeach()
		foreach(sTarget ${lsIsExtraBinary})
			add_dependencies(package_extra ${sTarget})
		endforeach()
		foreach(sTarget ${lsIsExtraSource})
			add_dependencies(package_extra_source ${sTarget})
		endforeach()
		if(NOT DEFINED lsIsExtraBinary)
			add_dependencies(package_extra custom_package)
		endif()
		if(NOT DEFINED lsIsExtraSource)
			add_dependencies(package_extra_source custom_package_source)
		endif()
	endif()

	_nx_function_end()
endfunction()

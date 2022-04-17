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

include(NXIdentify)

if(NOT NX_TARGET_ARCHITECTURE_GENERIC)
	if(NX_TARGET_PLATFORM_DARWIN)
		set(CMAKE_INSTALL_NAME_DIR "@rpath")
		set(CMAKE_INSTALL_RPATH "@loader_path")
	else()
		set(CMAKE_INSTALL_RPATH "$ORIGIN")
	endif()
	set(CMAKE_BUILD_RPATH_USE_ORIGIN ON)
	set(CMAKE_INSTALL_RPATH_USE_LINK_PATH ON)
endif()

_nx_guard_file()

nx_set(NXINSTALL_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}")

# ===================================================================

function(nx_install_set_subdir sSubDir)
	_nx_function_begin()

	if(NOT "x${sSubDir}" STREQUAL "x")
		if(NX_TARGET_PLATFORM_MSDOS)
			nx_string_limit(sSubDir "${sSubDir}" 8)
		endif()
		set(sSubDir "/${sSubDir}")
	endif()

	# -- Project Parent Tag --

	unset(sApplicationName)
	if(DEFINED ${NX_PROJECT_NAME}_PROJECT_PARENT)
		set(sApplicationName "${${NX_PROJECT_NAME}_PROJECT_PARENT}")
	elseif(DEFINED ${NX_PROJECT_NAME}_PROJECT_NAME)
		set(sApplicationName "${${NX_PROJECT_NAME}_PROJECT_NAME}")
	else()
		set(sApplicationName "${PROJECT_NAME}")
	endif()

	if(NX_TARGET_PLATFORM_MSDOS)
		nx_string_limit(sApplicationName "${sApplicationName}" 8)
		string(TOUPPER "${sApplicationName}" sApplicationName)
	elseif(NOT NX_TARGET_PLATFORM_HAIKU AND NOT NX_TARGET_PLATFORM_WINDOWS_NATIVE)
		string(TOLOWER "${sApplicationName}" sApplicationName)
	endif()

	# -- Project Architecture Tags --

	unset(sLibraryPath)
	unset(sLibrarySuffix)

	if(NX_TARGET_PLATFORM_ANDROID)
		if(DEFINED ANDROID_ABI)
			set(sLibraryPath "${ANDROID_ABI}")
		endif()
	elseif(NX_TARGET_PLATFORM_MSDOS)
		if(NX_TARGET_ARCHITECTURE_IA32)
			set(sLibrarySuffix "32")
		endif()
	elseif(NX_TARGET_PLATFORM_WINDOWS_NATIVE)
		set(sLibraryPath "${NX_TARGET_ARCHITECTURE_STRING}")
	elseif(DEFINED NX_INSTALL_OPT AND NX_INSTALL_OPT)
		set(sLibraryPath "${NX_TARGET_ARCHITECTURE_STRING}")
	elseif(DEFINED CMAKE_LIBRARY_ARCHITECTURE)
		set(sLibraryPath "${CMAKE_LIBRARY_ARCHITECTURE}")
	elseif(NX_TARGET_ARCHITECTURE_AMD64 AND NX_TARGET_PLATFORM_LINUX)
		set(sLibrarySuffix "64")
	elseif(NX_TARGET_ARCHITECTURE_IA32 AND NX_TARGET_PLATFORM_FREEBSD)
		set(sLibrarySuffix "32")
	endif()

	if(DEFINED sLibraryPath)
		if(NX_TARGET_PLATFORM_MSDOS)
			nx_string_limit(sLibraryPath "${sLibraryPath}" 8)
			string(TOUPPER "${sLibraryPath}" sLibraryPath)
		elseif(NX_TARGET_PLATFORM_POSIX OR NX_TARGET_PLATFORM_WINDOWS_MINGW)
			string(TOLOWER "${sLibraryPath}" sLibraryPath)
		endif()
		set(sLibraryPath "/${sLibraryPath}")
	endif()

	# -- The Install Paths --

	foreach(sPathType "PATH_DATA" "PATH_MODULES" "PATH_CONFIGURATION" "DPATH_MODULES" "RPATH_MODULES")
		nx_set(NX_INSTALL_${sPathType})
	endforeach()

	if(NX_TARGET_PLATFORM_HAIKU)
		# <root>/data/myApplication/Addon1
		nx_set(NX_INSTALL_PATH_DATA "data/${sApplicationName}${sSubDir}")
		# <root>/lib##/myApplication/<arch>/Addon1
		nx_set(NX_INSTALL_PATH_MODULES "lib${sLibrarySuffix}/${sApplicationName}${sLibraryPath}${sSubDir}")
		# <root>/settings/myApplication/Addon1
		nx_set(NX_INSTALL_PATH_CONFIGURATION "settings/${sApplicationName}${sSubDir}")
	elseif(NX_TARGET_PLATFORM_MSDOS)
		# installdir>/DATA/ADDON1
		nx_set(NX_INSTALL_PATH_DATA "DATA${sSubDir}")
		# <installdir>/LIB##/<arch>/ADDON1
		nx_set(NX_INSTALL_PATH_MODULES "LIB${sLibrarySuffix}${sLibraryPath}${sSubDir}")
		# <installdir>/ETC/ADDON1
		nx_set(NX_INSTALL_PATH_CONFIGURATION "ETC${sSubDir}")
	elseif(NX_TARGET_PLATFORM_WINDOWS_NATIVE)
		# <installdir>/Data/Addon1
		nx_set(NX_INSTALL_PATH_DATA "Data${sSubDir}")
		# <installdir>/Modules##/<arch>/Addon1
		nx_set(NX_INSTALL_PATH_MODULES "Modules${sLibrarySuffix}${sLibraryPath}${sSubDir}")
		# <installdir>/Settings/Addon1
		nx_set(NX_INSTALL_PATH_CONFIGURATION "Settings${sSubDir}")
	else()
		# <root>/share/myapplication/addon1
		nx_set(NX_INSTALL_PATH_DATA "share/${sApplicationName}${sSubDir}")
		# <root>/lib##/myapplication/<arch>/addon1
		nx_set(NX_INSTALL_PATH_MODULES "lib${sLibrarySuffix}/${sApplicationName}${sLibraryPath}${sSubDir}")
		# <root>/etc/myapplication/addon1
		nx_set(NX_INSTALL_PATH_CONFIGURATION "etc/${sApplicationName}${sSubDir}")
	endif()

	if(NOT DEFINED NX_INSTALL_PATH_MODULES)
		nx_set(NX_INSTALL_PATH_MODULES "${NX_INSTALL_PATH_LIBRARIES}${sSubDir}")
	endif()

	if(DEFINED CMAKE_OBJCOPY AND EXISTS "${CMAKE_OBJCOPY}")
		nx_set(NX_INSTALL_DPATH_MODULES "${NX_INSTALL_DPATH_MODULES}/.debug")
	else()
		nx_set(NX_INSTALL_DPATH_MODULES "${NX_INSTALL_PATH_MODULES}")
	endif()

	file(RELATIVE_PATH NX_INSTALL_RPATH_MODULES "/${NX_INSTALL_PATH_MODULES}" "/${NX_INSTALL_PATH_LIBRARIES}")

	foreach(sPathType "PATH_DATA" "PATH_MODULES" "PATH_CONFIGURATION" "DPATH_MODULES" "RPATH_MODULES")
		nx_set(${NX_PROJECT_NAME}_${sPathType} "${NX_INSTALL_${sPathType}}")
	endforeach()

	_nx_function_end()
endfunction()

# ===================================================================

function(nx_install_initialize)
	_nx_function_begin()

	# -- Project Version Tag --

	unset(sVersionCompat)
	if(DEFINED ${NX_PROJECT_NAME}_PROJECT_VERSION_COMPAT)
		set(sVersionCompat "${${NX_PROJECT_NAME}_PROJECT_VERSION_COMPAT}")
	elseif(DEFINED ${NX_PROJECT_NAME}_PROJECT_SOVERSION_COMPAT)
		set(sVersionCompat "${${NX_PROJECT_NAME}_PROJECT_SOVERSION_COMPAT}")
	endif()

	# -- Project Parent Tag --

	unset(sApplicationName)
	if(DEFINED ${NX_PROJECT_NAME}_PROJECT_PARENT)
		set(sApplicationName "${${NX_PROJECT_NAME}_PROJECT_PARENT}")
	elseif(DEFINED ${NX_PROJECT_NAME}_PROJECT_NAME)
		set(sApplicationName "${${NX_PROJECT_NAME}_PROJECT_NAME}")
	else()
		set(sApplicationName "${PROJECT_NAME}")
	endif()

	if(NX_TARGET_PLATFORM_MSDOS)
		nx_string_limit(sApplicationName "${sApplicationName}" 8)
		string(TOUPPER "${sApplicationName}" sApplicationName)
	elseif(NOT NX_TARGET_PLATFORM_HAIKU AND NOT NX_TARGET_PLATFORM_WINDOWS_NATIVE)
		string(TOLOWER "${sApplicationName}" sApplicationName)
	endif()

	# -- Project Child Tag --

	unset(sProjectName)
	if(DEFINED ${NX_PROJECT_NAME}_PROJECT_NAME)
		set(sProjectName "${${NX_PROJECT_NAME}_PROJECT_NAME}")
	else()
		set(sProjectName "${PROJECT_NAME}")
	endif()

	if(NX_TARGET_PLATFORM_MSDOS)
		nx_string_limit(sProjectName "${sProjectName}" 8)
		string(TOUPPER "${sProjectName}" sProjectName)
	elseif(NOT NX_TARGET_PLATFORM_HAIKU AND NOT NX_TARGET_PLATFORM_WINDOWS_NATIVE)
		string(TOLOWER "${sProjectName}" sProjectName)
	endif()

	if(NOT sApplicationName STREQUAL sProjectName)
		unset(sProjectName)
	endif()

	# -- Project Architecture Tags --

	unset(sBinaryPath)
	unset(sBinarySuffix)

	unset(sLibraryPath)
	unset(sLibrarySuffix)

	if(NX_TARGET_PLATFORM_ANDROID)
		if(DEFINED ANDROID_ABI)
			set(sBinaryPath "${ANDROID_ABI}")
			set(sLibraryPath "${ANDROID_ABI}")
		endif()
	elseif(NX_TARGET_PLATFORM_MSDOS)
		if(NX_TARGET_ARCHITECTURE_IA32)
			set(sBinarySuffix "32")
			set(sLibrarySuffix "32")
		endif()
	elseif(NX_TARGET_PLATFORM_WINDOWS_NATIVE)
		set(sBinaryPath "${NX_TARGET_ARCHITECTURE_STRING}")
		set(sLibraryPath "${NX_TARGET_ARCHITECTURE_STRING}")
	elseif(DEFINED NX_INSTALL_OPT AND NX_INSTALL_OPT)
		set(sBinaryPath "${NX_TARGET_ARCHITECTURE_STRING}")
		set(sLibraryPath "${NX_TARGET_ARCHITECTURE_STRING}")
	elseif(DEFINED CMAKE_LIBRARY_ARCHITECTURE)
		set(sLibraryPath "${CMAKE_LIBRARY_ARCHITECTURE}")
	elseif(NX_TARGET_ARCHITECTURE_AMD64 AND NX_TARGET_PLATFORM_LINUX)
		set(sLibrarySuffix "64")
	elseif(NX_TARGET_ARCHITECTURE_IA32 AND NX_TARGET_PLATFORM_FREEBSD)
		set(sLibrarySuffix "32")
	endif()

	if(DEFINED sBinaryPath)
		if(NX_TARGET_PLATFORM_MSDOS)
			nx_string_limit(sBinaryPath "${sBinaryPath}" 8)
			string(TOUPPER "${sBinaryPath}" sBinaryPath)
		elseif(NX_TARGET_PLATFORM_POSIX OR NX_TARGET_PLATFORM_WINDOWS_MINGW)
			string(TOLOWER "${sBinaryPath}" sBinaryPath)
		endif()
		set(sBinaryPath "/${sBinaryPath}")
	endif()
	if(DEFINED sLibraryPath)
		if(NX_TARGET_PLATFORM_MSDOS)
			nx_string_limit(sLibraryPath "${sLibraryPath}" 8)
			string(TOUPPER "${sLibraryPath}" sLibraryPath)
		elseif(NX_TARGET_PLATFORM_POSIX OR NX_TARGET_PLATFORM_WINDOWS_MINGW)
			string(TOLOWER "${sLibraryPath}" sLibraryPath)
		endif()
		set(sLibraryPath "/${sLibraryPath}")
	endif()

	# -- Project Directories --

	unset(sProjectDir)
	unset(sDevelopDir)

	if(NX_TARGET_PLATFORM_MSDOS OR NX_TARGET_PLATFORM_WINDOWS_NATIVE)
		if(DEFINED sProjectName)
			set(sProjectDir "${sProjectName}")
			set(sDevelopDir "${sProjectName}")
		else()
			set(sProjectDir "${sApplicationName}")
			set(sDevelopDir "${sApplicationName}")
		endif()
		if(DEFINED sVersionCompat)
			set(sDevelopDir "${sDevelopDir}-v${sVersionCompat}")
		endif()
	else()
		set(sProjectDir "${sApplicationName}")
		set(sDevelopDir "${sApplicationName}")
		if(DEFINED sProjectName)
			set(sProjectDir "${sProjectDir}-${sProjectName}")
			set(sDevelopDir "${sDevelopDir}-${sProjectName}")
		endif()
		if(DEFINED sVersionCompat)
			if(NX_TARGET_PLATFORM_HAIKU)
				set(sDevelopDir "${sDevelopDir}-v${sVersionCompat}")
			else()
				set(sDevelopDir "${sDevelopDir}-${sVersionCompat}")
			endif()
		endif()
	endif()

	if(DEFINED sProjectDir)
		if(NX_TARGET_PLATFORM_MSDOS)
			nx_string_limit(sLibraryPath "${sProjectDir}" 8)
			string(TOUPPER "${sProjectDir}" sProjectDir)
		elseif(NOT NX_TARGET_PLATFORM_HAIKU AND NOT NX_TARGET_PLATFORM_WINDOWS_NATIVE)
			string(TOLOWER "${sProjectDir}" sProjectDir)
		endif()
		set(sProjectDir "/${sProjectDir}")
	endif()
	if(DEFINED sDevelopDir)
		if(NX_TARGET_PLATFORM_MSDOS)
			string(TOUPPER "${sDevelopDir}" sDevelopDir)
		elseif(NOT NX_TARGET_PLATFORM_HAIKU AND NOT NX_TARGET_PLATFORM_WINDOWS_NATIVE)
			string(TOLOWER "${sDevelopDir}" sDevelopDir)
		endif()
		set(sDevelopDir "/${sDevelopDir}")
	endif()

	# -- Installation Root --

	unset(sRootPath)
	unset(sLocalPath)
	unset(sStagingPath)

	if(NX_TARGET_PLATFORM_HAIKU)
		if(NX_TARGET_PLATFORM_NATIVE AND NOT "x$ENV{HOME}" STREQUAL "x")
			set(sRootPath "$ENV{HOME}/config")
		else()
			set(sRootPath "/boot/home/config")
		endif()
		if(NOT DEFINED NX_INSTALL_SYSTEM OR NOT NX_INSTALL_SYSTEM)
			set(sLocalPath "${sRootPath}/non-packaged")
		endif()

		set(sStagingPath "${sRootPath}")
	elseif(NX_TARGET_PLATFORM_MSDOS)
		if(DEFINED ${NX_PROJECT_NAME}_FOLDER_NAME)
			set(sRootPath "/${${NX_PROJECT_NAME}_FOLDER_NAME}")
		else()
			set(sRootPath "/${sApplicationName}")
		endif()
	elseif(NX_TARGET_PLATFORM_WINDOWS_NATIVE)
		if(DEFINED ${NX_PROJECT_NAME}_FOLDER_NAME)
			set(sRootPath "/${${NX_PROJECT_NAME}_FOLDER_NAME}")
		elseif(DEFINED ${NX_PROJECT_NAME}_PROJECT_VENDOR)
			set(sRootPath "/${${NX_PROJECT_NAME}_PROJECT_VENDOR}/${sApplicationName}")
		else()
			set(sRootPath "/Applications/${sApplicationName}")
		endif()
		if(DEFINED ${NX_PROJECT_NAME}_PROJECT_VENDOR)
			set(sStagingPath "/${${NX_PROJECT_NAME}_PROJECT_VENDOR}")
		else()
			set(sStagingPath "/Applications")
		endif()
	else()
		set(sRootPath "/usr")
		set(sStagingPath "${sRootPath}/opt")

		if(NOT DEFINED NX_INSTALL_SYSTEM OR NOT NX_INSTALL_SYSTEM)
			set(sLocalPath "${sRootPath}/local")
		endif()
	endif()

	if(NOT DEFINED sLocalPath)
		set(sLocalPath "${sRootPath}")
	endif()

	# -- Installation Drive --

	unset(sInstallDrive)
	unset(sPackageDrive)

	if(NX_TARGET_PLATFORM_MSDOS OR NX_TARGET_PLATFORM_WINDOWS)
		if(NX_TARGET_PLATFORM_NATIVE AND NOT "x$ENV{SystemDrive}" STREQUAL "x")
			nx_set(sInstallDrive "$ENV{SystemDrive}")
		else()
			nx_set(sInstallDrive "C:")
		endif()
		nx_set(sPackageDrive "C:")
	endif()

	# -- The Prefix Paths --

	if(NOT DEFINED NX_INITIALIZED_INSTALL)
		if(DEFINED NXINSTALL_CMAKE_INSTALL_PREFIX AND "x${CMAKE_INSTALL_PREFIX}" STREQUAL "x${NXINSTALL_CMAKE_INSTALL_PREFIX}")
			nx_set_global(NX_INITIALIZED_INSTALL ON)
		else()
			nx_set_global(NX_INITIALIZED_INSTALL OFF)
		endif()
	endif()
	if(NOT DEFINED NX_INITIALIZED_PACKAGE)
		if(DEFINED NXINSTALL_CPACK_INSTALL_PREFIX AND "x${CPACK_INSTALL_PREFIX}" STREQUAL "x${NXINSTALL_CPACK_INSTALL_PREFIX}")
			nx_set_global(NX_INITIALIZED_PACKAGE ON)
		else()
			nx_set_global(NX_INITIALIZED_PACKAGE OFF)
		endif()
	endif()
	if(NOT DEFINED NX_INITIALIZED_STAGING)
		if(DEFINED NXINSTALL_CMAKE_STAGING_PREFIX AND "x${CMAKE_STAGING_PREFIX}" STREQUAL "x${NXINSTALL_CMAKE_STAGING_PREFIX}")
			nx_set_global(NX_INITIALIZED_STAGING ON)
		else()
			nx_set_global(NX_INITIALIZED_STAGING OFF)
		endif()
	endif()

	if(DEFINED ${NX_PROJECT_NAME}_IS_EXTERNAL AND NOT ${NX_PROJECT_NAME}_IS_EXTERNAL)
		if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT OR NX_INITIALIZED_INSTALL)
			nx_set_global(NX_INITIALIZED_INSTALL ON)
			nx_set_cache(CMAKE_INSTALL_PREFIX "${sInstallDrive}${sLocalPath}" PATH "Install Prefix")
			nx_set_cache(NXINSTALL_CMAKE_INSTALL_PREFIX "${sInstallDrive}${sLocalPath}" INTERNAL "")

			if(NOT DEFINED CPACK_INSTALL_PREFIX OR NX_INITIALIZED_PACKAGE)
				nx_set_global(NX_INITIALIZED_PACKAGE ON)
				nx_set_cache(CPACK_INSTALL_PREFIX "${sPackageDrive}${sRootPath}" PATH "Package Prefix")
				nx_set_cache(NXINSTALL_CPACK_INSTALL_PREFIX "${sPackageDrive}${sRootPath}" INTERNAL "")
			endif()
		elseif(NOT DEFINED CPACK_INSTALL_PREFIX)
			nx_set_global(NX_INITIALIZED_PACKAGE ON)
			nx_set_cache(CPACK_INSTALL_PREFIX "${sPackageDrive}${sRootPath}" PATH "Package Prefix")
			nx_set_cache(NXINSTALL_CPACK_INSTALL_PREFIX "${sPackageDrive}${sRootPath}" INTERNAL "")
			# nx_set_global(CPACK_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")
		endif()

		if(NOT DEFINED CMAKE_STAGING_PREFIX OR NX_INITIALIZED_STAGING)
			if(DEFINED CMAKE_SYSROOT)
				nx_set_global(NX_INITIALIZED_STAGING ON)
				nx_set_cache(CMAKE_STAGING_PREFIX "${CMAKE_SYSROOT}${NX_INSTALL_PATH_BASE}" PATH "Staging Prefix")
				nx_set_cache(NXINSTALL_CMAKE_STAGING_PREFIX "${CMAKE_SYSROOT}${NX_INSTALL_PATH_BASE}" INTERNAL "")
			elseif(DEFINED CMAKE_OSX_SYSROOT)
				nx_set_global(NX_INITIALIZED_STAGING ON)
				nx_set_cache(CMAKE_STAGING_PREFIX "${CMAKE_OSX_SYSROOT}${NX_INSTALL_PATH_BASE}" PATH "Staging Prefix")
				nx_set_cache(NXINSTALL_CMAKE_STAGING_PREFIX "${CMAKE_OSX_SYSROOT}${NX_INSTALL_PATH_BASE}" INTERNAL "")
			elseif(NOT NX_TARGET_PLATFORM_NATIVE OR NOT NX_TARGET_ARCHITECTURE_NATIVE)
				string(TOLOWER "${NX_TARGET_PLATFORM_STRING}-${NX_TARGET_ARCHITECTURE_STRING}" sSysrootName)
				set(sSysrootPath "${sStagingPath}/sysroots/${sSysrootName}")

				nx_set_global(NX_INITIALIZED_STAGING ON)
				nx_set_cache(CMAKE_STAGING_PREFIX "${sInstallDrive}${sSysrootPath}" PATH "Staging Prefix")
				nx_set_cache(NXINSTALL_CMAKE_STAGING_PREFIX "${sInstallDrive}${sSysrootPath}" INTERNAL "")
			endif()
		endif()
	endif()

	# -- The Install Paths --

	foreach(
		sPathType
		"PATH_APPLICATIONS"
		"PATH_BINARIES"
		"PATH_LIBRARIES"
		"PATH_DAEMONS"
		"PATH_MODULES"
		"PATH_CONFIGURATION"
		"PATH_DATA"
		"PATH_LOCALDATA"
		"PATH_DOCUMENTATION"
		"PATH_LICENSES"
		"PATH_DEVELOP"
		"PATH_EXPORT"
		"PATH_INCLUDE"
		"PATH_STATIC"
		"PATH_SOURCE"
		"PATH_PKGSRC"
		"DPATH_APPLICATIONS"
		"DPATH_BINARIES"
		"DPATH_LIBRARIES"
		"DPATH_DAEMONS"
		"DPATH_MODULES"
		"RPATH_APPLICATIONS"
		"RPATH_BINARIES"
		"RPATH_DAEMONS"
		"RPATH_MODULES")
		nx_set(NX_INSTALL_${sPathType})
	endforeach()

	if(NX_TARGET_PLATFORM_HAIKU)
		# <root>/apps##/<arch>/myApplication
		nx_set(NX_INSTALL_PATH_APPLICATIONS "apps${sBinarySuffix}${sBinaryPath}/${sApplicationName}")
		# <root>/bin##/<arch>
		nx_set(NX_INSTALL_PATH_BINARIES "bin${sBinarySuffix}${sBinaryPath}")
		# <root>/lib##/<arch>
		nx_set(NX_INSTALL_PATH_LIBRARIES "lib${sLibrarySuffix}${sLibraryPath}")
		# <root>/servers##/<arch>
		nx_set(NX_INSTALL_PATH_DAEMONS "servers${sBinarySuffix}${sBinaryPath}")

		# <root>/data/myApplication
		nx_set(NX_INSTALL_PATH_DATA "data/${sApplicationName}")
		# <root>/lib##/myApplication/<arch>
		nx_set(NX_INSTALL_PATH_MODULES "lib${sLibrarySuffix}/${sApplicationName}${sLibraryPath}")
		# <root>/settings/myApplication
		nx_set(NX_INSTALL_PATH_CONFIGURATION "settings/${sApplicationName}")

		# <root>/data/myApplication-Addon1
		nx_set(NX_INSTALL_PATH_LOCALDATA "data${sProjectDir}")
		# <root>/documentation/packages/myApplication-Addon1
		nx_set(NX_INSTALL_PATH_DOCUMENTATION "documentation/packages${sProjectDir}")

		# <root>/develop/documenation/packages/myApplication-Addon1-v3
		nx_set(NX_INSTALL_PATH_DEVELOP "develop/documentation/packages${sDevelopDir}")
		# <root>/develop/lib/cmake
		nx_set(NX_INSTALL_PATH_EXPORT "develop/lib${sLibrarySuffix}/cmake${sLibraryPath}")
		# <root>/develop/headers/myApplication-Addon1-v3
		nx_set(NX_INSTALL_PATH_INCLUDE "develop/headers${sDevelopDir}")
		# <root>/develop/lib##/<arch>
		nx_set(NX_INSTALL_PATH_STATIC "develop/lib${sLibrarySuffix}${sLibraryPath}")
		# <root>/develop/sources/myApplication-Addon1-v3
		nx_set(NX_INSTALL_PATH_SOURCE "develop/sources${sDevelopDir}")
		# <root>/develop/sources
		nx_set(NX_INSTALL_PATH_PKGSRC "develop/sources")
	elseif(NX_TARGET_PLATFORM_MSDOS)
		# <installdir>/BIN##/<arch>
		nx_set(NX_INSTALL_PATH_BINARIES "BIN${sBinarySuffix}${sBinaryPath}")

		# installdir>/DATA
		nx_set(NX_INSTALL_PATH_DATA "DATA")
		# <installdir>/LIB##/<arch>
		nx_set(NX_INSTALL_PATH_MODULES "LIB${sLibrarySuffix}${sLibraryPath}")
		# <installdir>/ETC
		nx_set(NX_INSTALL_PATH_CONFIGURATION "ETC")

		# <installdir>/LOCAL/ADDON1
		nx_set(NX_INSTALL_PATH_LOCALDATA "LOCAL${sProjectDir}")
		# <installdir>/DOCS/ADDON1
		nx_set(NX_INSTALL_PATH_DOCUMENTATION "DOCS${sProjectDir}")

		# <installdir>/SDK/ADDON1-V3/DOCS
		nx_set(NX_INSTALL_PATH_DEVELOP "SDK${sDevelopDir}/DOCS")
		# <installdir>/SDK/CMAKE##/<arch>
		nx_set(NX_INSTALL_PATH_EXPORT "SDK/CMAKE${sLibrarySuffix}${sLibraryPath}")
		# <installdir>/SDK/ADDON1-V3/INCLUDE
		nx_set(NX_INSTALL_PATH_INCLUDE "SDK${sDevelopDir}/INCLUDE")
		# <installdir>/SDK/ADDON1-V3/LIB##/<arch>
		nx_set(NX_INSTALL_PATH_STATIC "SDK${sDevelopDir}/LIB${sLibrarySuffix}${sLibraryPath}")
		# <installdir>/SDK/ADDON1-V3/SRC
		nx_set(NX_INSTALL_PATH_SOURCE "SDK${sDevelopDir}/SRC")
		# <installdir>/SRC
		nx_set(NX_INSTALL_PATH_PKGSRC "SRC")
	elseif(NX_TARGET_PLATFORM_WINDOWS_NATIVE)
		# <installdir>/Binaries##/<arch>
		nx_set(NX_INSTALL_PATH_BINARIES "Binaries${sBinarySuffix}${sBinaryPath}")

		# <installdir>/Data
		nx_set(NX_INSTALL_PATH_DATA "Data")
		# <installdir>/Modules##/<arch>
		nx_set(NX_INSTALL_PATH_MODULES "Modules${sLibrarySuffix}${sLibraryPath}")
		# <installdir>/Settings
		nx_set(NX_INSTALL_PATH_CONFIGURATION "Settings")

		# <installdir>/LocalData/Addon1
		nx_set(NX_INSTALL_PATH_LOCALDATA "LocalData${sProjectDir}")
		# <installdir>/Documentation/Addon1
		nx_set(NX_INSTALL_PATH_DOCUMENTATION "Documentation${sProjectDir}")

		# <installdir>/SDK/Addon1-v3/Documentation
		nx_set(NX_INSTALL_PATH_DEVELOP "SDK${sDevelopDir}/Documentation")
		# <installdir>/SDK/CMake##/<arch>
		nx_set(NX_INSTALL_PATH_EXPORT "SDK/CMake${sLibrarySuffix}${sLibraryPath}")
		# <installdir>/SDK/Addon1-v3/Headers
		nx_set(NX_INSTALL_PATH_INCLUDE "SDK${sDevelopDir}/Headers")
		# <installdir>/SDK/Addon1-v3/Libraries
		nx_set(NX_INSTALL_PATH_STATIC "SDK${sDevelopDir}/Libraries${sLibrarySuffix}${sLibraryPath}")
		# <installdir>/SDK/Addon1-v3/Sources
		nx_set(NX_INSTALL_PATH_SOURCE "SDK${sDevelopDir}/Sources")
		# <installdir>/Sources
		nx_set(NX_INSTALL_PATH_PKGSRC "Sources")
	else()
		# <root>/bin##/<arch>
		nx_set(NX_INSTALL_PATH_BINARIES "bin${sBinarySuffix}${sBinaryPath}")

		# <root>/lib##/<arch>
		if(NX_TARGET_PLATFORM_CYGWIN OR NX_TARGET_PLATFORM_WINDOWS_MINGW)
			nx_set(NX_INSTALL_PATH_STATIC "lib${sLibrarySuffix}${sLibraryPath}")
		else()
			nx_set(NX_INSTALL_PATH_LIBRARIES "lib${sLibrarySuffix}${sLibraryPath}")
		endif()

		# <root>/share/myapplication
		nx_set(NX_INSTALL_PATH_DATA "share/${sApplicationName}")
		# <root>/lib##/myapplication/<arch>
		nx_set(NX_INSTALL_PATH_MODULES "lib${sLibrarySuffix}/${sApplicationName}${sLibraryPath}")
		# <root>/etc/myapplication
		nx_set(NX_INSTALL_PATH_CONFIGURATION "etc/${sApplicationName}")

		# <root>/share/myapplication-addon1
		nx_set(NX_INSTALL_PATH_LOCALDATA "share${sProjectDir}")
		# <root>/share/doc/myapplication-addon1
		nx_set(NX_INSTALL_PATH_DOCUMENTATION "share/doc${sProjectDir}")
		# <root>/share/licenses/myapplication-addon1
		nx_set(NX_INSTALL_PATH_LICENSES "share/licenses${sProjectDir}")

		# <root>/lib/cmake##/<arch>
		nx_set(NX_INSTALL_PATH_EXPORT "lib${sLibrarySuffix}/cmake${sLibraryPath}")
		# <root>/include/myapplication-addon1-3
		nx_set(NX_INSTALL_PATH_INCLUDE "include${sDevelopDir}")
		# <root>/src/myapplication-addon1-3
		nx_set(NX_INSTALL_PATH_SOURCE "src${sDevelopDir}")
		# <root>/src
		nx_set(NX_INSTALL_PATH_PKGSRC "src")
	endif()

	if(NOT DEFINED NX_INSTALL_PATH_APPLICATIONS)
		nx_set(NX_INSTALL_PATH_APPLICATIONS "${NX_INSTALL_PATH_BINARIES}")
	endif()
	if(NOT DEFINED NX_INSTALL_PATH_DAEMONS)
		nx_set(NX_INSTALL_PATH_DAEMONS "${NX_INSTALL_PATH_BINARIES}")
	endif()
	if(NOT DEFINED NX_INSTALL_PATH_LIBRARIES)
		nx_set(NX_INSTALL_PATH_LIBRARIES "${NX_INSTALL_PATH_BINARIES}")
	endif()

	if(NOT DEFINED NX_INSTALL_PATH_LICENSES)
		nx_set(NX_INSTALL_PATH_LICENSES "${NX_INSTALL_PATH_DOCUMENTATION}")
	endif()
	if(NOT DEFINED NX_INSTALL_PATH_DEVELOP)
		nx_set(NX_INSTALL_PATH_DEVELOP "${NX_INSTALL_PATH_DOCUMENTATION}")
	endif()

	if(NOT DEFINED NX_INSTALL_PATH_STATIC)
		nx_set(NX_INSTALL_PATH_STATIC "${NX_INSTALL_PATH_LIBRARIES}")
	endif()

	if(DEFINED CMAKE_OBJCOPY AND EXISTS "${CMAKE_OBJCOPY}")
		nx_set(NX_INSTALL_DPATH_APPLICATIONS "${NX_INSTALL_PATH_APPLICATIONS}/.debug")
		nx_set(NX_INSTALL_DPATH_BINARIES "${NX_INSTALL_PATH_BINARIES}/.debug")
		nx_set(NX_INSTALL_DPATH_LIBRARIES "${NX_INSTALL_PATH_LIBRARIES}/.debug")
		nx_set(NX_INSTALL_DPATH_DAEMONS "${NX_INSTALL_PATH_DAEMONS}/.debug")
	else()
		nx_set(NX_INSTALL_DPATH_APPLICATIONS "${NX_INSTALL_PATH_APPLICATIONS}")
		nx_set(NX_INSTALL_DPATH_BINARIES "${NX_INSTALL_PATH_BINARIES}")
		nx_set(NX_INSTALL_DPATH_LIBRARIES "${NX_INSTALL_PATH_LIBRARIES}")
		nx_set(NX_INSTALL_DPATH_DAEMONS "${NX_INSTALL_PATH_DAEMONS}")
	endif()

	file(RELATIVE_PATH NX_INSTALL_RPATH_APPLICATIONS "/${NX_INSTALL_PATH_APPLICATIONS}" "/${NX_INSTALL_PATH_LIBRARIES}")
	file(RELATIVE_PATH NX_INSTALL_RPATH_BINARIES "/${NX_INSTALL_PATH_BINARIES}" "/${NX_INSTALL_PATH_LIBRARIES}")
	file(RELATIVE_PATH NX_INSTALL_RPATH_DAEMONS "/${NX_INSTALL_PATH_DAEMONS}" "/${NX_INSTALL_PATH_LIBRARIES}")

	foreach(
		sPathType
		"PATH_APPLICATIONS"
		"PATH_BINARIES"
		"PATH_LIBRARIES"
		"PATH_DAEMONS"
		"PATH_MODULES"
		"PATH_CONFIGURATION"
		"PATH_DATA"
		"PATH_LOCALDATA"
		"PATH_DOCUMENTATION"
		"PATH_LICENSES"
		"PATH_DEVELOP"
		"PATH_EXPORT"
		"PATH_INCLUDE"
		"PATH_STATIC"
		"PATH_SOURCE"
		"PATH_PKGSRC"
		"DPATH_APPLICATIONS"
		"DPATH_BINARIES"
		"DPATH_LIBRARIES"
		"DPATH_DAEMONS"
		"DPATH_MODULES"
		"RPATH_APPLICATIONS"
		"RPATH_BINARIES"
		"RPATH_DAEMONS"
		"RPATH_MODULES")
		nx_set(${NX_PROJECT_NAME}_${sPathType} "${NX_INSTALL_${sPathType}}")
	endforeach()

	_nx_function_end()
endfunction()

nx_install_initialize()

# ===================================================================

function(nx_install_custom)
	_nx_function_begin()

	if(NOT DEFINED INSTALL_TARGETS${NX_PROJECT_NAME})
		set(bDefaultInstall OFF)
		if(NOT DEFINED ${NX_PROJECT_NAME}_IS_EXTERNAL OR NOT ${NX_PROJECT_NAME}_IS_EXTERNAL)
			set(bDefaultInstall ON)
		endif()

		option(INSTALL_TARGETS${NX_PROJECT_NAME} "Install Targets - ${PROJECT_NAME}" ${bDefaultInstall})
	endif()

	# PARSER START ====

	_nx_parser_initialize()

	set(lsKeywordSingle "COMPONENT" "DESTINATION")
	set(lsKeywordMultiple "FILES" "DIRECTORIES" "CONTENTS")

	set(sParseMode "FILES")

	_nx_parser_clear()
	_nx_parser_run(${ARGN})

	# ==== PARSER END

	if(NOT DEFINED sArgCOMPONENT)
		set(sArgCOMPONENT "DAT")
	endif()

	if(NOT DEFINED sArgDESTINATION)
		if(sArgCOMPONENT STREQUAL "DOC")
			set(sArgDESTINATION "${NX_INSTALL_PATH_DOCUMENTATION}")
		else()
			set(sArgDESTINATION "${NX_INSTALL_PATH_DATA}")
		endif()
	endif()

	if(INSTALL_TARGETS${NX_PROJECT_NAME})
		if(DEFINED lsArgFILES)
			nx_set(${NX_PROJECT_NAME}_COMPONENT_${sArgCOMPONENT} ON)
			install(
				FILES ${lsArgFILES}
				COMPONENT "${NX_PROJECT_NAME}_${sArgCOMPONENT}"
				DESTINATION "${sArgDESTINATION}")
			foreach(sFileName ${lsArgFILES})
				get_filename_component(sFileName "${sFileName}" NAME)
				nx_append_global(NX_CLEANUP_DELETE "${sArgDESTINATION}/${sFileName}")
			endforeach()
			nx_append_global(NX_CLEANUP_RMDIR "${sArgDESTINATION}")
		endif()
		foreach(sDirectory ${lsArgCONTENTS})
			nx_set(${NX_PROJECT_NAME}_COMPONENT_${sArgCOMPONENT} ON)
			install(
				DIRECTORY "${sDirectory}/"
				COMPONENT "${NX_PROJECT_NAME}_${sArgCOMPONENT}"
				DESTINATION "${sArgDESTINATION}")
			nx_append_global(NX_CLEANUP_RMDIR_F "${sArgDESTINATION}")
		endforeach()
		foreach(sDirectory ${lsArgDIRECTORIES})
			nx_set(${NX_PROJECT_NAME}_COMPONENT_${sArgCOMPONENT} ON)
			install(
				DIRECTORY "${sDirectory}"
				COMPONENT "${NX_PROJECT_NAME}_${sArgCOMPONENT}"
				DESTINATION "${sArgDESTINATION}")
			get_filename_component(sDirectory "${sDirectory}" NAME)
			nx_append_global(NX_CLEANUP_RMDIR_F "${sArgDESTINATION}/${sDirectory}")
		endforeach()
	endif()

	_nx_function_end()
endfunction()

# ===================================================================

function(nx_install_docs)
	_nx_guard_function(nx_install_docs)
	_nx_function_begin()

	# PARSER START ====

	_nx_parser_initialize()

	set(lsKeywordSingle "COMPONENT" "DESTINATION")
	set(lsKeywordMultiple "FILES" "DIRECTORIES" "CONTENTS" "READMES" "LICENSES" "DEVELOP")

	set(sParseMode "FILES")

	_nx_parser_clear()
	_nx_parser_run(${ARGN})

	# ==== PARSER END

	if(NOT DEFINED sArgCOMPONENT)
		set(sArgCOMPONENT "DAT")
	endif()

	if(NOT DEFINED sArgDESTINATION)
		set(sArgDESTINATION "${NX_INSTALL_PATH_DATA}")
	endif()

	if(NOT DEFINED lsArgLICENSES)
		file(
			GLOB lsArgLICENSES
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
		if(DEFINED lsArgLICENSES AND NOT lsArgLICENSES)
			unset(lsArgLICENSES)
		endif()
	endif()
	if(DEFINED lsArgLICENSES)
		list(GET lsArgLICENSES 0 sLicenseFile)
		nx_set(${NX_PROJECT_NAME}_FILE_LICENSE "${sLicenseFile}")
	endif()

	if(NOT DEFINED lsArgREADMES)
		file(
			GLOB lsArgREADMES
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
		if(DEFINED lsArgREADMES AND NOT lsArgREADMES)
			unset(lsArgREADMES)
		endif()
	endif()
	if(DEFINED lsArgREADMES)
		list(GET lsArgREADMES 0 sReadmeFile)
		nx_set(${NX_PROJECT_NAME}_FILE_README "${sReadmeFile}")
	endif()

	if(NOT DEFINED lsArgDEVELOP)
		file(
			GLOB lsArgDEVELOP
			LIST_DIRECTORIES false
			"docs/BUILDING"
			"docs/BUILDING.*"
			"docs/CONTRIBUTING"
			"docs/CONTRIBUTING.*"
			"docs/HACKING"
			"docs/HACKING.*"
			"BUILDING"
			"BUILDING.*"
			"CONTRIBUTING"
			"CONTRIBUTING.*"
			"HACKING"
			"HACKING.*")
	endif()

	if(NOT DEFINED lsArgFILES
		AND NOT DEFINED lsArgCONTENTS
		AND NOT DEFINED lsArgDIRECTORIES)
		if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/docs" AND IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/docs")
			list(APPEND lsArgCONTENTS "${CMAKE_CURRENT_SOURCE_DIR}/docs")
		endif()

		file(
			GLOB lsArgDIRECTORIES
			LIST_DIRECTORIES true
			"docs/*")
		if(DEFINED lsArgDIRECTORIES AND NOT lsArgDIRECTORIES)
			unset(lsArgDIRECTORIES)
		endif()

		file(
			GLOB lsArgFILES
			LIST_DIRECTORIES true
			"docs/*"
			"AUTHORS"
			"BUGS"
			"CHANGELOG"
			"ChangeLog"
			"FAQ"
			"INSTALL"
			"NEWS"
			"THANKS"
			"TODO"
			"*.md"
			"*.txt")
		if(DEFINED lsArgFILES AND NOT lsArgFILES)
			unset(lsArgFILES)
		endif()

		if(DEFINED lsArgDIRECTORIES)
			foreach(sDocument ${lsArgFILES})
				if(sDocument IN_LIST lsArgDIRECTORIES)
					list(REMOVE_ITEM lsArgDIRECTORIES "${sDocument}")
				endif()
			endforeach()
		endif()

		if(DEFINED lsArgFILES)
			foreach(sDocument "${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt" ${lsArgREADMES} ${lsArgLICENSES} ${lsArgDEVELOP})
				if(sDocument IN_LIST lsArgFILES)
					list(REMOVE_ITEM lsArgFILES "${sDocument}")
				endif()
			endforeach()
		endif()
	endif()

	nx_install_custom(
		FILES ${lsArgREADMES} ${lsArgFILES}
		CONTENTS ${lsArgCONTENTS}
		DIRECTORIES ${lsArgDIRECTORIES}
		COMPONENT "DOC"
		DESTINATION "${NX_INSTALL_PATH_DOCUMENTATION}")
	nx_install_custom(
		FILES ${lsArgLICENSES}
		COMPONENT "DOC"
		DESTINATION "${NX_INSTALL_PATH_LICENSES}")
	nx_install_custom(
		FILES ${lsArgDEVELOP}
		COMPONENT "DEV"
		DESTINATION "${NX_INSTALL_PATH_DEVELOP}")

	_nx_function_end()
endfunction()

# ===================================================================

function(nx_install_source)
	_nx_guard_function(nx_install_source)
	_nx_function_begin()

	# PARSER START ====

	_nx_parser_initialize()

	set(lsKeywordMultiple "FILES" "DIRECTORIES" "INCLUDES")

	set(sParseMode "FILES")

	_nx_parser_clear()
	_nx_parser_run(${ARGN})

	# ==== PARSER END

	nx_install_custom(
		CONTENTS ${${NX_PROJECT_NAME}_DIRS_INCLUDE} ${lsArgINCLUDES}
		COMPONENT "DEV"
		DESTINATION "${NX_INSTALL_PATH_INCLUDE}")

	foreach(sSourcePair ${${NX_PROJECT_NAME}_FILES_INTERFACE})
		string(REPLACE "::" ";" sSourcePair "${sSourcePair}")
		list(GET sSourcePair 1 sRelSource)
		list(GET sSourcePair 0 sFile)
		get_filename_component(sDestination "${NX_INSTALL_PATH_SOURCE}/${sRelSource}" DIRECTORY)
		nx_install_custom(
			FILES "${sFile}"
			COMPONENT "DEV"
			DESTINATION "${sDestination}")
	endforeach()

	foreach(sCandidate ${lsArgFILES})
		unset(sRelSource)
		foreach(sCandidatePath "${CMAKE_CURRENT_SOURCE_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}/src" "${CMAKE_CURRENT_BINARY_DIR}"
								${${NX_PROJECT_NAME}_DIRS_SOURCE})
			file(RELATIVE_PATH sTestPath "${sCandidatePath}" "${sCandidate}")
			string(SUBSTRING "${sTestPath}" 0 2 sTest)
			if(NOT sTest STREQUAL ".." AND NOT sTest MATCHES ":$")
				set(sRelSource "${sTestPath}")
			endif()
		endforeach()
		if(DEFINED sRelSource)
			get_filename_component(sDestination "${NX_INSTALL_PATH_SOURCE}/${sRelSource}" DIRECTORY)
			nx_install_custom(
				FILES "${sCandidate}"
				COMPONENT "DEV"
				DESTINATION "${sDestination}")
		endif()
	endforeach()

	foreach(sCandidate ${lsArgDIRECTORIES})
		unset(sRelSource)
		foreach(sCandidatePath "${CMAKE_CURRENT_SOURCE_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}/src" "${CMAKE_CURRENT_BINARY_DIR}"
								${${NX_PROJECT_NAME}_DIRS_SOURCE})
			file(RELATIVE_PATH sTestPath "${sCandidatePath}" "${sCandidate}")
			string(SUBSTRING "${sTestPath}" 0 2 sTest)
			if(NOT sTest STREQUAL ".." AND NOT sTest MATCHES ":$")
				set(sRelSource "${sTestPath}")
			endif()
		endforeach()
		if(DEFINED sRelSource)
			get_filename_component(sDestination "${NX_INSTALL_PATH_SOURCE}/${sRelSource}" DIRECTORY)
			nx_install_custom(
				DIRECTORIES "${sCandidate}"
				COMPONENT "DEV"
				DESTINATION "${sDestination}")
		endif()
	endforeach()

	_nx_function_end()
endfunction()

# ===================================================================

function(nx_install_runtime_dependencies)
	_nx_guard_function(nx_install_runtime_dependencies)
	_nx_function_begin()

	if(NX_TARGET_PLATFORM_WINDOWS
		AND CMAKE_VERSION VERSION_GREATER_EQUAL 3.16
		AND DEFINED INSTALL_TARGETS${NX_PROJECT_NAME})
		set(bCanDepend OFF)
		if(DEFINED ${NX_PROJECT_NAME}_TARGETS_EXECUTABLE
			OR DEFINED ${NX_PROJECT_NAME}_TARGETS_SHARED
			OR DEFINED ${NX_PROJECT_NAME}_TARGETS_MODULE)
			set(bCanDepend ON)
		endif()

		cmake_dependent_option(INSTALL_DEPENDENCIES${NX_PROJECT_NAME} "Install Runtime Dependencies - ${PROJECT_NAME}" ON
								"INSTALL_TARGETS${NX_PROJECT_NAME};bCanDepend" OFF)

		if(INSTALL_DEPENDENCIES${NX_PROJECT_NAME})
			unset(sTargetList)
			unset(sSystemDirectories)

			if(DEFINED ${NX_PROJECT_NAME}_TARGETS_EXECUTABLE)
				set(sTargetList "${sTargetList}EXECUTABLES ")
				foreach(sTargetName ${${NX_PROJECT_NAME}_TARGETS_EXECUTABLE})
					set(sTargetList "${sTargetList}$<TARGET_FILE:${sTargetName}> ")
				endforeach()
			endif()
			if(DEFINED ${NX_PROJECT_NAME}_TARGETS_SHARED OR DEFINED ${NX_PROJECT_NAME}_TARGETS_MODULE)
				set(sTargetList "${sTargetList}LIBRARIES ")
				foreach(sTargetName ${${NX_PROJECT_NAME}_TARGETS_SHARED} ${${NX_PROJECT_NAME}_TARGETS_MODULE})
					set(sTargetList "${sTargetList}$<TARGET_FILE:${sTargetName}> ")
				endforeach()
			endif()

			foreach(sPathName ${CMAKE_SYSTEM_LIBRARY_PATH} ${CMAKE_MINGW_SYSTEM_LIBRARY_PATH})
				set(sSystemDirectories "${sSystemDirectories}\"${sPathName}\" ")
			endforeach()

			if(NOT DEFINED _CURRENT_YEAR)
				string(TIMESTAMP _CURRENT_YEAR "%Y")
			endif()
			if(NOT DEFINED _CURRENT_DATE)
				string(TIMESTAMP _CURRENT_DATE "%Y%m%d")
			endif()

			configure_file("${NXINSTALL_DIRECTORY}/NXInstallRuntimeDependencies.cmake.in"
							"${CMAKE_CURRENT_BINARY_DIR}/NXInstall${PROJECT_NAME}Dependencies.cmake" @ONLY)
			list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_BINARY_DIR}")
			include(NXInstall${PROJECT_NAME}Dependencies)
		endif()
	endif()

	_nx_function_end()
endfunction()

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

_nx_guard_file()

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.git")
	include(GitWatch)
	nx_git_check()
elseif(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/GitInfo.cmake")
	list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}")
	include(GitInfo)
	set(NX_GIT_WATCH_VARS ON)
endif()

# ===================================================================

function(nx_project_begin)
	_nx_function_begin()

	# === Add To Project List ===

	if(DEFINED NX_PROJECT_LIST)
		if("${NX_PROJECT_NAME}" IN_LIST NX_PROJECT_LIST)
			foreach(vCheck "${NX_VARLISTS_GLOBAL}" "${NX_VARLISTS_SET}")
				if(vCheck MATCHES "^${NX_PROJECT_NAME}_")
					message(AUTHOR_WARNING "nx_project_begin: Project Setting ${vCheck} Already Set ('${${vCheck}}')")
					unset(${vCheck})
				endif()
			endforeach()
		endif()
	endif()
	nx_append_global(NX_PROJECT_LIST "${NX_PROJECT_NAME}")

	# PARSER START ====

	_nx_parser_initialize("ABI" "API" "LIBTOOL" "OSX")

	set(lsKeywordSingle
		"NAME"
		"PARENT"
		"SUMMARY"
		"HOMEPAGE"
		"SUPPORT"
		"MAINTAINER"
		"CONTACT"
		"VENDOR"
		"PRERELEASE")

	set(lsKeywordSingleABI "VERSION" "MAJOR" "MINOR" "PATCH" "TWEAK" "COMPATIBILITY")
	set(lsKeywordSingleAPI "VERSION" "MAJOR" "MINOR" "PATCH" "TWEAK" "COMPATIBILITY")
	set(lsKeywordSingleLIBTOOL "VERSION" "CURRENT" "AGE" "REVISION")
	set(lsKeywordSingleOSX "VERSION" "MAJOR" "MINOR" "COMPATIBILITY")

	set(sComboMode "API")
	set(sParseMode "NAME")

	_nx_parser_clear()

	set(sDefaultABI "VERSION")
	set(sDefaultAPI "VERSION")
	set(sDefaultLIBTOOL "VERSION")
	set(sDefaultOSX "VERSION")

	set(sNextMAINTAINER "CONTACT")
	set(sNextCONTACT "MAINTAINER")
	set(sNextVERSION_API "COMPATIBILITY")
	set(sNextVERSION_ABI "COMPATIBILITY")
	set(sNextVERSION_OSX "COMPATIBILITY")

	_nx_parser_run(${ARGN})

	# ==== PARSER END

	if(NOT DEFINED sArgCONTACT)
		set(sArgCONTACT "nobody@example.com")
	endif()

	if(NOT DEFINED sArgNAME)
		set(sArgNAME "${PROJECT_NAME}")
	endif()

	if(NOT DEFINED sArgHOMEPAGE)
		if(DEFINED PROJECT_HOMEPAGE_URL AND PROJECT_HOMEPAGE_URL)
			set(sArgHOMEPAGE "${PROJECT_HOMEPAGE_URL}")
		endif()
	endif()
	if(NOT DEFINED sArgSUPPORT AND DEFINED sArgHOMEPAGE)
		set(sArgSUPPORT "${sArgHOMEPAGE}")
	endif()

	if(NOT DEFINED sArgPARENT)
		string(REPLACE "-" ";" lsArgNAME "${sArgNAME}")
		list(GET lsArgNAME 0 sArgPARENT)
	endif()

	if(NOT DEFINED sArgSUMMARY)
		if(DEFINED PROJECT_DESCRIPTION AND PROJECT_DESCRIPTION)
			set(sArgSUMMARY "${PROJECT_DESCRIPTION}")
		else()
			set(sArgSUMMARY "No Description Provided")
		endif()
	endif()

	if(NOT DEFINED sArgVENDOR)
		if(DEFINED sArgMAINTAINER)
			set(sArgVENDOR "${sArgMAINTAINER}")
		else()
			set(sArgVENDOR "Orphaned Packages")
		endif()
	endif()
	if(NOT DEFINED sArgMAINTAINER AND DEFINED sArgVENDOR)
		set(sArgMAINTAINER "${sArgVENDOR}")
	endif()

	if(NOT DEFINED sArgVERSION_API)
		if(DEFINED PROJECT_VERSION AND PROJECT_VERSION)
			set(sArgVERSION_API "${PROJECT_VERSION}")
		endif()
	endif()
	if(NOT DEFINED sArgCOMPATIBILITY_API)
		set(sArgCOMPATIBILITY_API "SameMajorVersion")
	endif()
	if(NOT DEFINED sArgCOMPATIBILITY_ABI)
		set(sArgCOMPATIBILITY_ABI "SameMajorVersion")
	endif()
	if(NOT DEFINED sArgCOMPATIBILITY_OSX)
		set(sArgCOMPATIBILITY_OSX "${sArgCOMPATIBILITY_ABI}")
	endif()

	if(NOT sArgCOMPATIBILITY_API MATCHES "AnyNewerVersion|SameMajorVersion|SameMinorVersion|ExactVersion")
		message(AUTHOR_WARNING "nx_project_begin: API Compatibility '${sArgCOMPATIBILITY_API}' Unknown")
	endif()
	if(NOT sArgCOMPATIBILITY_ABI MATCHES "AnyNewerVersion|SameMajorVersion|SameMinorVersion|ExactVersion")
		message(AUTHOR_WARNING "nx_project_begin: ABI Compatibility '${sArgCOMPATIBILITY_ABI}' Unknown")
	endif()
	if(NOT sArgCOMPATIBILITY_OSX MATCHES "AnyNewerVersion|SameMajorVersion|SameMinorVersion|ExactVersion")
		message(AUTHOR_WARNING "nx_project_begin: OSX Compatibility '${sArgCOMPATIBILITY_OSX}' Unknown")
	endif()

	if(NOT DEFINED NX_PROJECT_PARENT)
		nx_set_global(NX_PROJECT_PARENT "${sArgPARENT}")
	endif()
	if(NOT "${sArgNAME}" STREQUAL "${sArgPARENT}")
		string(REPLACE "${sArgPARENT}-" "" sArgNAME "${sArgNAME}")
	endif()

	nx_set(${NX_PROJECT_NAME}_PROJECT_PARENT "${sArgPARENT}")
	nx_set(${NX_PROJECT_NAME}_PROJECT_NAME "${sArgNAME}")

	nx_set(${NX_PROJECT_NAME}_PROJECT_MAINTAINER "${sArgMAINTAINER}")
	nx_set(${NX_PROJECT_NAME}_PROJECT_CONTACT "${sArgCONTACT}")
	nx_set(${NX_PROJECT_NAME}_PROJECT_VENDOR "${sArgVENDOR}")

	nx_set(${NX_PROJECT_NAME}_PROJECT_SUMMARY "${sArgSUMMARY}")

	if(DEFINED sArgHOMEPAGE)
		nx_set(${NX_PROJECT_NAME}_PROJECT_HOMEPAGE "${sArgHOMEPAGE}")
	endif()
	if(DEFINED sArgSUPPORT)
		nx_set(${NX_PROJECT_NAME}_PROJECT_SUPPORT "${sArgSUPPORT}")
	endif()
	if(DEFINED sArgPRERELEASE)
		nx_set(${NX_PROJECT_NAME}_PROJECT_PRERELEASE "${sArgPRERELEASE}")
	endif()

	nx_set(${NX_PROJECT_NAME}_IS_EXTERNAL ON)
	if(NX_PROJECT_PARENT STREQUAL "${sArgPARENT}")
		nx_set(${NX_PROJECT_NAME}_IS_EXTERNAL OFF)
	endif()

	# === Convenience Folder Name ===

	set(sFolderName "${sArgPARENT}")
	if(NX_TARGET_PLATFORM_DARWIN)
		if(DEFINED sArgHOMEPAGE)
			# TODO: This is probably not super robust.
			string(REGEX REPLACE "^.+://|/.+" "" sBaseURL "${sArgHOMEPAGE}")
			string(REGEX REPLACE "[.]" ";" sBaseURL "${sBaseURL}")
			list(REVERSE sBaseURL)
			list(GET sBaseURL 0 1 sBaseURL)
			string(REGEX REPLACE ";" "." sBaseURL "${sBaseURL}")
			string(TOLOWER "${sBaseURL}.${sFolderName}" sFolderName)
		elseif(DEFINED sArgVENDOR)
			string(MAKE_C_IDENTIFIER "${sArgVENDOR}" sVendorName)
			string(TOLOWER "net.${sVendorName}.${sFolderName}" sFolderName)
		endif()
	elseif(NX_TARGET_PLATFORM_MSDOS)
		nx_string_limit(sFolderName "${sFolderName}" 8)
		string(TOUPPER "${sFolderName}" sFolderName)
	elseif(NX_TARGET_PLATFORM_WINDOWS_NATIVE)
		set(sFolderName "${sArgVENDOR}/${sFolderName}")
	elseif(NOT NX_TARGET_PLATFORM_HAIKU)
		string(TOLOWER "${sFolderName}" sFolderName)
	endif()
	nx_set(${NX_PROJECT_NAME}_FOLDER_NAME "${sFolderName}")

	# === Parse Full Versions ===

	if(DEFINED sArgVERSION_API)
		string(REPLACE "." ";" lsVersion "${sArgVERSION_API}")
		list(LENGTH lsVersion nVersion)
		if(nVersion GREATER 0)
			list(GET lsVersion 0 sArgMAJOR_API)
		endif()
		if(nVersion GREATER 1)
			list(GET lsVersion 1 sArgMINOR_API)
		endif()
		if(nVersion GREATER 2)
			list(GET lsVersion 2 sArgPATCH_API)
		endif()
		if(nVersion GREATER 3)
			list(GET lsVersion 3 sArgTWEAK_API)
		endif()
	endif()
	if(NOT DEFINED sArgPATCH_API)
		if(DEFINED sArgTWEAK_API)
			set(sArgPATCH_API 0)
		endif()
	endif()
	if(NOT DEFINED sArgMINOR_API)
		if(DEFINED sArgPATCH_API)
			set(sArgMINOR_API 0)
		endif()
	endif()
	if(NOT DEFINED sArgMAJOR_API)
		if(DEFINED sArgMINOR_API)
			set(sArgMAJOR_API 0)
		endif()
	endif()

	if(DEFINED sArgVERSION_ABI)
		string(REPLACE "." ";" lsVersion "${sArgVERSION_ABI}")
		list(LENGTH lsVersion nVersion)
		if(nVersion GREATER 0)
			list(GET lsVersion 0 sArgMAJOR_ABI)
		endif()
		if(nVersion GREATER 1)
			list(GET lsVersion 1 sArgMINOR_ABI)
		endif()
		if(nVersion GREATER 2)
			list(GET lsVersion 2 sArgPATCH_ABI)
		endif()
		if(nVersion GREATER 3)
			list(GET lsVersion 3 sArgTWEAK_ABI)
		endif()
	endif()
	if(NOT DEFINED sArgPATCH_ABI)
		if(DEFINED sArgTWEAK_ABI)
			set(sArgPATCH_ABI 0)
		endif()
	endif()
	if(NOT DEFINED sArgMINOR_ABI)
		if(DEFINED sArgPATCH_ABI)
			set(sArgMINOR_ABI 0)
		endif()
	endif()
	if(NOT DEFINED sArgMAJOR_ABI)
		if(DEFINED sArgMINOR_ABI)
			set(sArgMAJOR_ABI 0)
		endif()
	endif()

	if(DEFINED sArgVERSION_LIBTOOL)
		string(REPLACE ":" ";" lsVersion "${sArgVERSION_LIBTOOL}")
		list(LENGTH lsVersion nVersion)
		if(nVersion GREATER 0)
			list(GET lsVersion 0 sArgCURRENT_LIBTOOL)
		endif()
		if(nVersion GREATER 1)
			list(GET lsVersion 1 sArgREVISION_LIBTOOL)
		endif()
		if(nVersion GREATER 2)
			list(GET lsVersion 2 sArgAGE_LIBTOOL)
		endif()
	endif()
	if(NOT DEFINED sArgREVISION_LIBTOOL)
		if(DEFINED sArgAGE_LIBTOOL)
			set(sArgREVISION_LIBTOOL 0)
		endif()
	endif()
	if(NOT DEFINED sArgCURRENT_LIBTOOL)
		if(DEFINED sArgREVISION_LIBTOOL)
			set(sArgCURRENT_LIBTOOL 0)
		endif()
	endif()

	if(DEFINED sArgVERSION_OSX)
		string(REPLACE "." ";" lsVersion "${sArgVERSION_OSX}")
		list(LENGTH lsVersion nVersion)
		if(nVersion GREATER 0)
			list(GET lsVersion 0 sArgMAJOR_OSX)
		endif()
		if(nVersion GREATER 1)
			list(GET lsVersion 1 sArgMINOR_OSX)
		endif()
	endif()
	if(NOT DEFINED sArgMAJOR_OSX)
		if(DEFINED sArgMINOR_OSX)
			set(sArgMAJOR_OSX 0)
		endif()
	endif()

	# === Rebuild Full Versions ===

	if(DEFINED sArgMAJOR_API)
		unset(sArgVERSION_API)
		list(APPEND sArgVERSION_API ${sArgMAJOR_API} ${sArgMINOR_API} ${sArgPATCH_API} ${sArgTWEAK_API})
		string(REPLACE ";" "." sArgVERSION_API "${sArgVERSION_API}")

		nx_set(${NX_PROJECT_NAME}_PROJECT_VERSION "${sArgVERSION_API}")
		nx_set(${NX_PROJECT_NAME}_PROJECT_VERSION_MAJOR "${sArgMAJOR_API}")

		if(DEFINED sArgMINOR_API)
			nx_set(${NX_PROJECT_NAME}_PROJECT_VERSION_MINOR "${sArgMINOR_API}")
		endif()
		if(DEFINED sArgPATCH_API)
			nx_set(${NX_PROJECT_NAME}_PROJECT_VERSION_PATCH "${sArgPATCH_API}")
		endif()
		if(DEFINED sArgTWEAK_API)
			nx_set(${NX_PROJECT_NAME}_PROJECT_VERSION_TWEAK "${sArgTWEAK_API}")
		endif()

		if(NOT sArgCOMPATIBILITY_API MATCHES "^AnyNewer")
			set(sArgVERSION_API ${sArgMAJOR_API})
			if(NOT sArgCOMPATIBILITY_API MATCHES "^SameMajor")
				list(APPEND sArgVERSION_API ${sArgMINOR_API})
				if(NOT sArgCOMPATIBILITY_API MATCHES "^SameMinor")
					list(APPEND sArgVERSION_API ${sArgPATCH_API})
				endif()
			endif()
			string(REPLACE ";" "." sArgVERSION_API "${sArgVERSION_API}")
			nx_set(${NX_PROJECT_NAME}_PROJECT_VERSION_COMPAT "${sArgVERSION_API}")
		endif()
	endif()

	if(DEFINED sArgCURRENT_LIBTOOL)
		unset(sArgVERSION_LIBTOOL)
		list(APPEND sArgVERSION_LIBTOOL ${sArgCURRENT_LIBTOOL} ${sArgREVISION_LIBTOOL} ${sArgAGE_LIBTOOL})
		string(REPLACE ";" ":" sArgVERSION_LIBTOOL "${sArgVERSION_LIBTOOL}")

		nx_set(${NX_PROJECT_NAME}_PROJECT_LIBTOOL "${sArgVERSION_LIBTOOL}")
		nx_set(${NX_PROJECT_NAME}_PROJECT_LIBTOOL_CURRENT "${sArgCURRENT_LIBTOOL}")

		if(DEFINED sArgREVISION_LIBTOOL)
			nx_set(${NX_PROJECT_NAME}_PROJECT_LIBTOOL_REVISION "${sArgREVISION_LIBTOOL}")
		else()
			set(sArgREVISION_LIBTOOL 0)
		endif()
		if(DEFINED sArgAGE_LIBTOOL)
			nx_set(${NX_PROJECT_NAME}_PROJECT_LIBTOOL_AGE "${sArgAGE_LIBTOOL}")
		else()
			set(sArgAGE_LIBTOOL 0)
		endif()

		if(NOT DEFINED sArgMAJOR_ABI)
			if(NX_TARGET_PLATFORM_FREEBSD)
				set(sArgMAJOR_ABI "${sArgCURRENT_LIBTOOL}")
				set(sArgMINOR_ABI "${sArgREVISION_LIBTOOL}")
			else()
				math(EXPR sArgMAJOR_ABI "${sArgCURRENT_LIBTOOL} - ${sArgAGE_LIBTOOL}")
				set(sArgMINOR_ABI "${sArgAGE_LIBTOOL}")
				set(sArgPATCH_ABI "${sArgREVISION_LIBTOOL}")
			endif()
		endif()

		if(NOT DEFINED sArgMAJOR_OSX AND NX_TARGET_PLATFORM_DARWIN)
			math(EXPR sArgMAJOR_OSX "${sArgCURRENT_LIBTOOL} + 1")
			set(sArgMINOR_OSX "${sArgREVISION_LIBTOOL}")
		endif()
	endif()

	# === ABI Version ===

	if(DEFINED sArgMAJOR_ABI)
		unset(sArgVERSION_ABI)
		list(APPEND sArgVERSION_ABI ${sArgMAJOR_ABI} ${sArgMINOR_ABI} ${sArgPATCH_ABI} ${sArgTWEAK_ABI})
		string(REPLACE ";" "." sArgVERSION_ABI "${sArgVERSION_ABI}")

		nx_set(${NX_PROJECT_NAME}_PROJECT_SOVERSION "${sArgVERSION_ABI}")
		nx_set(${NX_PROJECT_NAME}_PROJECT_SOVERSION_MAJOR "${sArgMAJOR_ABI}")

		if(DEFINED sArgMINOR_ABI)
			nx_set(${NX_PROJECT_NAME}_PROJECT_SOVERSION_MINOR "${sArgMINOR_ABI}")
		endif()
		if(DEFINED sArgPATCH_ABI)
			nx_set(${NX_PROJECT_NAME}_PROJECT_SOVERSION_PATCH "${sArgPATCH_ABI}")
		endif()
		if(DEFINED sArgTWEAK_ABI)
			nx_set(${NX_PROJECT_NAME}_PROJECT_SOVERSION_TWEAK "${sArgTWEAK_ABI}")
		endif()

		if(NOT sArgCOMPATIBILITY_ABI MATCHES "^AnyNewer")
			set(sArgVERSION_ABI ${sArgMAJOR_ABI})
			if(NOT sArgCOMPATIBILITY_ABI MATCHES "^SameMajor")
				list(APPEND sArgVERSION_ABI ${sArgMINOR_ABI})
				if(NOT sArgCOMPATIBILITY_ABI MATCHES "^SameMinor")
					list(APPEND sArgVERSION_ABI ${sArgPATCH_ABI})
				endif()
			endif()
			string(REPLACE ";" "." sArgVERSION_API "${sArgVERSION_ABI}")
			nx_set(${NX_PROJECT_NAME}_PROJECT_SOVERSION_COMPAT "${sArgVERSION_ABI}")
		endif()

		if(NOT DEFINED sArgMAJOR_OSX AND NX_TARGET_PLATFORM_DARWIN)
			set(sArgMAJOR_OSX "${sArgMAJOR_ABI}")
			if(DEFINED sArgMINOR_ABI)
				set(sArgMINOR_OSX "${sArgMINOR_ABI}")
			endif()
		endif()
	endif()

	if(DEFINED sArgMAJOR_OSX AND NX_TARGET_PLATFORM_DARWIN)
		unset(sArgVERSION_OSX)
		list(APPEND sArgVERSION_OSX ${sArgMAJOR_OSX} ${sArgMINOR_OSX})
		string(REPLACE ";" "." sArgVERSION_OSX "${sArgVERSION_OSX}")

		nx_set(${NX_PROJECT_NAME}_PROJECT_OSX "${sArgVERSION_OSX}")
		nx_set(${NX_PROJECT_NAME}_PROJECT_OSX_MAJOR "${sArgMAJOR_OSX}")

		if(DEFINED sArgMINOR_OSX)
			nx_set(${NX_PROJECT_NAME}_PROJECT_OSX_MINOR "${sArgMINOR_OSX}")
		endif()

		if(NOT sArgCOMPATIBILITY_OSX MATCHES "^AnyNewer")
			set(sArgVERSION_OSX ${sArgMAJOR_OSX})
			if(NOT sArgCOMPATIBILITY_OSX MATCHES "^SameMajor")
				list(APPEND sArgVERSION_OSX ${sArgMINOR_OSX})
			endif()
			string(REPLACE ";" "." sArgVERSION_OSX "${sArgVERSION_OSX}")
			nx_set(${NX_PROJECT_NAME}_PROJECT_OSX_COMPAT "${sArgVERSION_OSX}")
		endif()
	endif()

	# === Update Install Paths ===

	if(COMMAND nx_install_initialize)
		nx_install_initialize()
	endif()

	_nx_function_end()
endfunction()

# ===================================================================

macro(_nx_require_project)
	if(NOT DEFINED ${NX_PROJECT_NAME}_IS_EXTERNAL)
		message(AUTHOR_WARNING "Did you forget to call nx_project_begin?")
		return()
	endif()
endmacro()

macro(nx_project_end)
	_nx_require_project()

	# === Internal Projects Always Call These ===

	if(NOT ${NX_PROJECT_NAME}_IS_EXTERNAL)
		if(COMMAND nx_format_clang AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.clang-format")
			nx_format_clang(FILES ${${NX_PROJECT_NAME}_FILES_SOURCE})
		endif()

		if(COMMAND nx_format_cmake)
			file(
				GLOB lsCMakeFiles
				LIST_DIRECTORIES false
				"tools/*.cmake" "CMakeLists.txt")
			nx_format_cmake(FILES ${lsCMakeFiles})
		endif()

		if(COMMAND nx_target_export)
			nx_target_export()
		endif()
	endif()

	# === Make Sure Files Are Properly Installed ===

	if(COMMAND nx_install_runtime_dependencies AND DEFINED ${NX_PROJECT_NAME}_TARGETS_EXECUTABLE)
		nx_install_runtime_dependencies()
	endif()

	if(COMMAND nx_install_docs)
		nx_install_docs()
	endif()

	if(COMMAND nx_install_source)
		nx_install_source()
	endif()

	# === Set Package Component Variables ===

	if(COMMAND nx_package)
		nx_package()
	endif()

	# === Propagate Variables To Parent Projects ===

	if(NOT CMAKE_CURRENT_SOURCE_DIR STREQUAL "${CMAKE_SOURCE_DIR}")
		if(DEFINED NX_VARLISTS_SORTED AND NX_VARLISTS_SORTED)
			list(REMOVE_DUPLICATES NX_VARLISTS_SORTED)
		endif()

		foreach(vSortedList "NX_VARLISTS_RESET" "NX_VARLISTS_GLOBAL" ${NX_VARLISTS_SORTED})
			if(DEFINED ${vSortedList} AND ${vSortedList})
				list(SORT ${vSortedList})
				list(REMOVE_DUPLICATES ${vSortedList})
			endif()
		endforeach()

		foreach(vReset ${_NX_VARLISTS_RESET})
			if(DEFINED ${vReset})
				unset(${vReset})
			endif()
		endforeach()

		foreach(vPropagate "NX_VARLISTS_RESET" "NX_VARLISTS_GLOBAL" "NX_VARLISTS_SORTED" ${NX_VARLISTS_GLOBAL})
			if(DEFINED ${vPropagate})
				set(${vPropagate}
					"${${vPropagate}}"
					PARENT_SCOPE)
			else()
				unset(${vPropagate} PARENT_SCOPE)
			endif()
		endforeach()
	endif()
endmacro()

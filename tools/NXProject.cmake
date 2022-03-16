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

# cmake-lint: disable=C0301,C0307,R0912,R0915

include(NXIdentify)

nx_guard_file()

# ===================================================================

#
# Open Project Scope
#
function(nx_project_begin)
	nx_function_begin()

	# === Add To Project List ===

	if(DEFINED NX_PROJECT_LIST)
		if("${NX_PROJECT_NAME}" IN_LIST NX_PROJECT_LIST)
			foreach(tmp_variable "${_NX_VARLISTS_GLOBAL}" "${_NX_VARLISTS_SET}")
				if(tmp_variable MATCHES "^${NX_PROJECT_NAME}_")
					message(AUTHOR_WARNING "nx_project_begin: Project Setting ${tmp_variable} Already Set ('${${tmp_variable}}')")
					unset(${tmp_variable})
				endif()
			endforeach()
		endif()
	endif()
	nx_append_global(NX_PROJECT_LIST "${NX_PROJECT_NAME}")

	# === Available Parsing Modes ===

	set(lst_pmode_version "ABI" "API" "LIBTOOL" "OSX")
	set(lst_pmode_single
		"NAME"
		"PARENT"
		"SUMMARY"
		"HOMEPAGE"
		"SUPPORT"
		"MAINTAINER"
		"CONTACT"
		"VENDOR"
		"PRERELEASE")
	set(lst_pmode_single_abi "VERSION" "MAJOR" "MINOR" "PATCH" "TWEAK" "COMPATIBILITY")
	set(lst_pmode_single_api "VERSION" "MAJOR" "MINOR" "PATCH" "TWEAK" "COMPATIBILITY")
	set(lst_pmode_single_libtool "VERSION" "CURRENT" "AGE" "REVISION")
	set(lst_pmode_single_osx "VERSION" "MAJOR" "MINOR" "COMPATIBILITY")

	foreach(tmp_pmode ${lst_pmode_single})
		string(TOLOWER "${tmp_pmode}" tmp_pmode)
		unset(arg_project_${tmp_pmode})
	endforeach()

	foreach(tmp_vmode ${lst_pmode_version})
		string(TOLOWER "${tmp_vmode}" tmp_vmode)
		foreach(tmp_pmode ${lst_pmode_single_${tmp_vmode}})
			string(TOLOWER "${tmp_pmode}_${tmp_vmode}" tmp_pmode)
			unset(arg_project_${tmp_pmode})
		endforeach()
	endforeach()

	set(str_pmode_cur "NAME")
	set(str_vmode_cur "API")

	# === Parse Arguments ===

	foreach(tmp_argv ${ARGN})
		string(TOLOWER "${str_vmode_cur}" tmp_vmode)
		if("${tmp_argv}" IN_LIST lst_pmode_version)
			set(str_vmode_cur "${tmp_argv}")
			set(str_pmode_cur "VERSION")
		elseif("${tmp_argv}" IN_LIST lst_pmode_single OR "${tmp_argv}" IN_LIST lst_pmode_single_${tmp_vmode})
			set(str_pmode_cur "${tmp_argv}")
		elseif("${str_pmode_cur}" IN_LIST lst_pmode_single_${tmp_vmode})
			string(TOLOWER "${str_pmode_cur}_${tmp_vmode}" tmp_pmode)
			if(DEFINED arg_project_${tmp_pmode})
				message(AUTHOR_WARNING "nx_project_begin: Option ${str_vmode_cur} ${str_pmode_cur} Already Set")
			elseif(str_pmode_cur STREQUAL "COMPATIBILITY" AND NOT tmp_argv MATCHES
																"^AnyNewerVersion$|^SameMajorVersion$|^SameMinorVersion$|^ExactVersion$")
				message(AUTHOR_WARNING "nx_project_begin: Option ${str_vmode_cur} ${str_pmode_cur} Invalid ('${tmp_argv}')")
			else()
				set(arg_project_${tmp_pmode} "${tmp_argv}")
			endif()
			if(str_vmode_cur STREQUAL "API" AND str_pmode_cur STREQUAL "VERSION")
				set(str_pmode_cur "PRERELEASE")
			endif()
		elseif("${str_pmode_cur}" IN_LIST lst_pmode_single)
			string(TOLOWER "${str_pmode_cur}" tmp_pmode)
			if(DEFINED arg_project_${tmp_pmode})
				message(AUTHOR_WARNING "nx_project_begin: Option ${str_pmode_cur} Already Set")
			else()
				set(arg_project_${tmp_pmode} "${tmp_argv}")
			endif()
			if(str_pmode_cur STREQUAL "MAINTAINER")
				set(str_pmode_cur "CONTACT")
			endif()
		else()
			message(AUTHOR_WARNING "nx_project_begin: Parse Mode ${str_pmode_cur} Unknown")
		endif()
	endforeach()

	# === Project Name ===

	if(DEFINED arg_project_name)
		nx_set(${NX_PROJECT_NAME}_PROJECT_NAME "${arg_project_name}")
	elseif(NOT DEFINED ${NX_PROJECT_NAME}_PROJECT_NAME)
		nx_set(${NX_PROJECT_NAME}_PROJECT_NAME "${PROJECT_NAME}")
	endif()

	if(DEFINED arg_project_parent)
		nx_set(${NX_PROJECT_NAME}_PROJECT_PARENT "${arg_project_parent}")
	elseif(NOT DEFINED ${NX_PROJECT_NAME}_PROJECT_PARENT)
		string(REPLACE "-" ";" ${NX_PROJECT_NAME}_PROJECT_NAME "${${NX_PROJECT_NAME}_PROJECT_NAME}")
		list(GET ${NX_PROJECT_NAME}_PROJECT_NAME 0 arg_project_parent)
		string(REPLACE ";" "-" ${NX_PROJECT_NAME}_PROJECT_NAME "${${NX_PROJECT_NAME}_PROJECT_NAME}")
		nx_set(${NX_PROJECT_NAME}_PROJECT_PARENT "${arg_project_parent}")
	endif()

	if(NOT "${${NX_PROJECT_NAME}_PROJECT_NAME}" STREQUAL "${${NX_PROJECT_NAME}_PROJECT_PARENT}")
		string(REPLACE "${${NX_PROJECT_NAME}_PROJECT_PARENT}-" "" ${NX_PROJECT_NAME}_PROJECT_NAME "${${NX_PROJECT_NAME}_PROJECT_NAME}")
	endif()

	# === Is This An External Project? ===

	nx_set(${NX_PROJECT_NAME}_IS_EXTERNAL ON)

	if(NOT DEFINED NX_PROJECT_PARENT OR NX_PROJECT_PARENT STREQUAL "${${NX_PROJECT_NAME}_PROJECT_NAME}")
		nx_set_global(NX_PROJECT_PARENT "${${NX_PROJECT_NAME}_PROJECT_PARENT}")
	endif()

	set(opt_initialize_prefix OFF)
	if(NX_PROJECT_PARENT STREQUAL "${${NX_PROJECT_NAME}_PROJECT_PARENT}")
		set(opt_initialize_prefix ON)
		nx_set(${NX_PROJECT_NAME}_IS_EXTERNAL OFF)
	endif()

	# === Project Vendor ===

	if(DEFINED arg_project_vendor)
		nx_set(${NX_PROJECT_NAME}_PROJECT_VENDOR "${arg_project_vendor}")
	elseif(NOT DEFINED ${NX_PROJECT_NAME}_PROJECT_VENDOR)
		nx_set(${NX_PROJECT_NAME}_PROJECT_VENDOR "Orphaned Packages")
	endif()

	# === Project Maintainer ===

	if(DEFINED arg_project_maintainer)
		nx_set(${NX_PROJECT_NAME}_PROJECT_MAINTAINER "${arg_project_maintainer}")
	elseif(NOT DEFINED ${NX_PROJECT_NAME}_PROJECT_MAINTAINER)
		nx_set(${NX_PROJECT_NAME}_PROJECT_MAINTAINER "${NX_PROJECT_NAME}_PROJECT_VENDOR")
	endif()

	if(DEFINED arg_project_contact)
		nx_set(${NX_PROJECT_NAME}_PROJECT_CONTACT "${arg_project_contact}")
	elseif(NOT DEFINED ${NX_PROJECT_NAME}_PROJECT_CONTACT)
		nx_set(${NX_PROJECT_NAME}_PROJECT_CONTACT "nobody@example.com")
	endif()

	# === Project Summary ===

	if(DEFINED arg_project_summary)
		nx_set(${NX_PROJECT_NAME}_PROJECT_SUMMARY "${arg_project_summary}")
	elseif(NOT DEFINED ${NX_PROJECT_NAME}_PROJECT_SUMMARY)
		if(DEFINED PROJECT_DESCRIPTION AND PROJECT_DESCRIPTION)
			nx_set(${NX_PROJECT_NAME}_PROJECT_SUMMARY "${PROJECT_DESCRIPTION}")
		endif()
	endif()

	# === Project URLs ===

	if(DEFINED arg_project_homepage)
		nx_set(${NX_PROJECT_NAME}_PROJECT_HOMEPAGE "${arg_project_homepage}")
	elseif(NOT DEFINED ${NX_PROJECT_NAME}_PROJECT_HOMEPAGE)
		if(DEFINED PROJECT_HOMEPAGE_URL AND PROJECT_HOMEPAGE_URL)
			nx_set(${NX_PROJECT_NAME}_PROJECT_HOMEPAGE "${PROJECT_HOMEPAGE_URL}")
		endif()
	endif()

	if(DEFINED arg_project_support)
		nx_set(${NX_PROJECT_NAME}_PROJECT_SUPPORT "${arg_project_support}")
	endif()

	# === Parse Full Versions ===

	if(NOT DEFINED arg_project_version_api AND NOT DEFINED ${NX_PROJECT_NAME}_PROJECT_VERSION)
		if(DEFINED PROJECT_VERSION AND PROJECT_VERSION)
			set(arg_project_version_api "${PROJECT_VERSION}")
		endif()
	endif()
	if(DEFINED arg_project_version_api)
		string(REPLACE "." ";" lst_version "${arg_project_version_api}")
		list(LENGTH lst_version num_version)
		if(num_version GREATER 0)
			list(GET lst_version 0 arg_project_major_api)
		endif()
		if(num_version GREATER 1)
			list(GET lst_version 1 arg_project_minor_api)
		endif()
		if(num_version GREATER 2)
			list(GET lst_version 2 arg_project_patch_api)
		endif()
		if(num_version GREATER 3)
			list(GET lst_version 3 arg_project_tweak_api)
		endif()
		if(NOT DEFINED arg_project_compatibility_api)
			set(arg_project_compatibility_api "SameMajorVersion")
		endif()
	endif()

	if(DEFINED arg_project_version_abi)
		string(REPLACE "." ";" lst_version "${arg_project_version_abi}")
		list(LENGTH lst_version num_version)
		if(num_version GREATER 0)
			list(GET lst_version 0 arg_project_major_abi)
		endif()
		if(num_version GREATER 1)
			list(GET lst_version 1 arg_project_minor_abi)
		endif()
		if(num_version GREATER 2)
			list(GET lst_version 2 arg_project_patch_abi)
		endif()
		if(NOT DEFINED arg_project_compatibility_abi)
			set(arg_project_compatibility_abi "SameMajorVersion")
		endif()
	endif()

	if(DEFINED arg_project_version_libtool)
		string(REPLACE ":" ";" lst_version "${arg_project_version_libtool}")
		list(LENGTH lst_version num_version)
		if(num_version GREATER 0)
			list(GET lst_version 0 arg_project_current_libtool)
		endif()
		if(num_version GREATER 1)
			list(GET lst_version 1 arg_project_revision_libtool)
		endif()
		if(num_version GREATER 2)
			list(GET lst_version 2 arg_project_age_libtool)
		endif()
	endif()

	if(DEFINED arg_project_version_osx)
		string(REPLACE "." ";" lst_version "${arg_project_version_osx}")
		list(LENGTH lst_version num_version)
		if(num_version GREATER 0)
			list(GET lst_version 0 arg_project_major_osx)
		endif()
		if(num_version GREATER 1)
			list(GET lst_version 1 arg_project_minor_osx)
		endif()
		if(NOT DEFINED arg_project_compatibility_osx)
			if(DEFINED arg_project_compatibility_abi)
				set(arg_project_compatibility_osx "${arg_project_compatibility_abi}")
			else()
				set(arg_project_compatibility_osx "SameMajorVersion")
			endif()
		endif()
	endif()

	# === API Version ===

	if(NOT DEFINED arg_project_tweak_api)
		if(DEFINED ${NX_PROJECT_NAME}_PROJECT_VERSION_TWEAK)
			set(arg_project_tweak_api "${${NX_PROJECT_NAME}_PROJECT_VERSION_TWEAK}")
		elseif(DEFINED PROJECT_VERSION_TWEAK)
			set(arg_project_tweak_api "${PROJECT_VERSION_TWEAK}")
		endif()
	endif()

	if(NOT DEFINED arg_project_patch_api)
		if(DEFINED ${NX_PROJECT_NAME}_PROJECT_VERSION_PATCH)
			set(arg_project_patch_api "${${NX_PROJECT_NAME}_PROJECT_VERSION_PATCH}")
		elseif(DEFINED PROJECT_VERSION_PATCH)
			set(arg_project_patch_api "${PROJECT_VERSION_PATCH}")
		elseif(DEFINED arg_project_tweak_api)
			set(arg_project_patch_api 0)
		endif()
	endif()

	if(NOT DEFINED arg_project_minor_api)
		if(DEFINED ${NX_PROJECT_NAME}_PROJECT_VERSION_MINOR)
			set(arg_project_minor_api "${${NX_PROJECT_NAME}_PROJECT_VERSION_MINOR}")
		elseif(DEFINED PROJECT_VERSION_MINOR)
			set(arg_project_minor_api "${PROJECT_VERSION_MINOR}")
		elseif(DEFINED arg_project_patch_api)
			set(arg_project_minor_api 0)
		endif()
	endif()

	if(NOT DEFINED arg_project_major_api)
		if(DEFINED ${NX_PROJECT_NAME}_PROJECT_VERSION_MAJOR)
			set(arg_project_major_api "${${NX_PROJECT_NAME}_PROJECT_VERSION_MAJOR}")
		elseif(DEFINED PROJECT_VERSION_MAJOR)
			set(arg_project_major_api "${PROJECT_VERSION_MAJOR}")
		elseif(DEFINED arg_project_minor_api)
			set(arg_project_major_api 0)
		endif()
	endif()

	if(DEFINED arg_project_major_api)
		unset(arg_project_version_api)
		list(APPEND arg_project_version_api ${arg_project_major_api} ${arg_project_minor_api} ${arg_project_patch_api}
				${arg_project_tweak_api})
		string(REPLACE ";" "." arg_project_version_api "${arg_project_version_api}")

		nx_set(${NX_PROJECT_NAME}_PROJECT_VERSION "${arg_project_version_api}")
		nx_set(${NX_PROJECT_NAME}_PROJECT_VERSION_MAJOR "${arg_project_major_api}")
		if(DEFINED arg_project_minor_api)
			nx_set(${NX_PROJECT_NAME}_PROJECT_VERSION_MINOR "${arg_project_minor_api}")
		endif()
		if(DEFINED arg_project_patch_api)
			nx_set(${NX_PROJECT_NAME}_PROJECT_VERSION_PATCH "${arg_project_patch_api}")
		endif()
		if(DEFINED arg_project_tweak_api)
			nx_set(${NX_PROJECT_NAME}_PROJECT_VERSION_TWEAK "${arg_project_tweak_api}")
		endif()

		if(DEFINED arg_project_compatibility_api)
			set(arg_project_version_api ${arg_project_major_api})
			if(NOT arg_project_compatibility_api STREQUAL "SameMajorVersion")
				list(APPEND arg_project_version_api ${arg_project_minor_api})
				if(NOT arg_project_compatibility_api STREQUAL "SameMinorVersion")
					list(APPEND arg_project_version_api ${arg_project_patch_api})
				endif()
			endif()
			string(REPLACE ";" "." arg_project_version_api "${arg_project_version_api}")
			nx_set(${NX_PROJECT_NAME}_PROJECT_VERSION_COMPAT "${arg_project_version_api}")
		endif()
	endif()

	if(DEFINED arg_project_prerelease)
		nx_set(${NX_PROJECT_NAME}_PROJECT_VERSION_EXTRA "${arg_project_prerelease}")
	endif()

	# === LibTool Version ===

	if(NOT DEFINED arg_project_age_libtool)
		if(DEFINED ${NX_PROJECT_NAME}_PROJECT_LIBTOOL_AGE)
			set(arg_project_age_libtool "${${NX_PROJECT_NAME}_PROJECT_LIBTOOL_AGE}")
		endif()
	endif()

	if(NOT DEFINED arg_project_revision_libtool)
		if(DEFINED ${NX_PROJECT_NAME}_PROJECT_LIBTOOL_REVISION)
			set(arg_project_revision_libtool "${${NX_PROJECT_NAME}_PROJECT_LIBTOOL_REVISION}")
		elseif(DEFINED arg_project_age_libtool)
			set(arg_project_revision_libtool 0)
		endif()
	endif()

	if(NOT DEFINED arg_project_current_libtool)
		if(DEFINED ${NX_PROJECT_NAME}_PROJECT_LIBTOOL_CURRENT)
			set(arg_project_current_libtool "${${NX_PROJECT_NAME}_PROJECT_LIBTOOL_CURRENT}")
		elseif(DEFINED arg_project_revision_libtool)
			set(arg_project_current_libtool 0)
		endif()
	endif()

	if(DEFINED arg_project_current_libtool)
		unset(arg_project_version_libtool)
		list(APPEND arg_project_version_libtool ${arg_project_current_libtool} ${arg_project_revision_libtool} ${arg_project_age_libtool})
		string(REPLACE ";" ":" arg_project_version_libtool "${arg_project_version_libtool}")

		nx_set(${NX_PROJECT_NAME}_PROJECT_LIBTOOL "${arg_project_version_libtool}")
		nx_set(${NX_PROJECT_NAME}_PROJECT_LIBTOOL_CURRENT "${arg_project_current_libtool}")
		if(DEFINED arg_project_revision_libtool)
			nx_set(${NX_PROJECT_NAME}_PROJECT_LIBTOOL_REVISION "${arg_project_revision_libtool}")
		else()
			set(arg_project_revision_libtool 0)
		endif()
		if(DEFINED arg_project_age_libtool)
			nx_set(${NX_PROJECT_NAME}_PROJECT_LIBTOOL_AGE "${arg_project_age_libtool}")
		else()
			set(arg_project_age_libtool 0)
		endif()

		if(NOT DEFINED arg_project_major_abi)
			if(NX_TARGET_PLATFORM_FREEBSD)
				set(arg_project_major_abi "${arg_project_current_libtool}")
				set(arg_project_minor_abi "${arg_project_revision_libtool}")
			else()
				math(EXPR arg_project_major_abi "${arg_project_current_libtool} - ${arg_project_age_libtool}")
				set(arg_project_minor_abi "${arg_project_age_libtool}")
				set(arg_project_patch_abi "${arg_project_revision_libtool}")
			endif()
			if(NOT DEFINED arg_project_compatibility_abi)
				set(arg_project_compatibility_abi "SameMajorVersion")
			endif()
		endif()

		if(NOT DEFINED arg_project_major_osx)
			if(NX_TARGET_PLATFORM_DARWIN)
				math(EXPR arg_project_major_osx "${arg_project_current_libtool} + 1")
				set(arg_project_minor_osx "${arg_project_revision_libtool}")
			endif()
			if(NOT DEFINED arg_project_compatibility_osx)
				set(arg_project_compatibility_osx "SameMajorVersion")
			endif()
		endif()
	endif()

	# === ABI Version ===

	if(NOT DEFINED arg_project_patch_abi)
		if(DEFINED ${NX_PROJECT_NAME}_PROJECT_SOVERSION_PATCH)
			set(arg_project_patch_abi "${${NX_PROJECT_NAME}_PROJECT_SOVERSION_PATCH}")
		endif()
	endif()

	if(NOT DEFINED arg_project_minor_abi)
		if(DEFINED ${NX_PROJECT_NAME}_PROJECT_SOVERSION_MINOR)
			set(arg_project_minor_abi "${${NX_PROJECT_NAME}_PROJECT_SOVERSION_MINOR}")
		elseif(DEFINED arg_project_patch_abi)
			set(arg_project_minor_abi 0)
		endif()
	endif()

	if(NOT DEFINED arg_project_major_abi)
		if(DEFINED ${NX_PROJECT_NAME}_PROJECT_SOVERSION_MAJOR)
			set(arg_project_major_abi "${${NX_PROJECT_NAME}_PROJECT_SOVERSION_MAJOR}")
		elseif(DEFINED arg_project_minor_abi)
			set(arg_project_major_abi 0)
		endif()
	endif()

	if(DEFINED arg_project_major_abi)
		unset(arg_project_version_abi)
		list(APPEND arg_project_version_abi ${arg_project_major_abi} ${arg_project_minor_abi} ${arg_project_patch_abi})
		string(REPLACE ";" "." arg_project_version_abi "${arg_project_version_abi}")

		nx_set(${NX_PROJECT_NAME}_PROJECT_SOVERSION "${arg_project_version_abi}")
		nx_set(${NX_PROJECT_NAME}_PROJECT_SOVERSION_MAJOR "${arg_project_major_abi}")
		if(DEFINED arg_project_minor_abi)
			nx_set(${NX_PROJECT_NAME}_PROJECT_SOVERSION_MINOR "${arg_project_minor_abi}")
		endif()
		if(DEFINED arg_project_patch_abi)
			nx_set(${NX_PROJECT_NAME}_PROJECT_SOVERSION_PATCH "${arg_project_patch_abi}")
		endif()

		if(DEFINED arg_project_compatibility_abi)
			set(arg_project_version_abi ${arg_project_major_abi})
			if(NOT arg_project_compatibility_abi STREQUAL "SameMajorVersion")
				list(APPEND arg_project_version_abi ${arg_project_minor_abi})
				if(NOT arg_project_compatibility_abi STREQUAL "SameMinorVersion")
					list(APPEND arg_project_version_abi ${arg_project_patch_abi})
				endif()
			endif()
			string(REPLACE ";" "." arg_project_version_api "${arg_project_version_abi}")
			nx_set(${NX_PROJECT_NAME}_PROJECT_SOVERSION_COMPAT "${arg_project_version_abi}")
		endif()
	endif()

	# === Mach-O Version ===

	if(NOT DEFINED arg_project_minor_osx)
		if(DEFINED ${NX_PROJECT_NAME}_PROJECT_MACHO_MINOR)
			set(arg_project_minor_osx "${${NX_PROJECT_NAME}_PROJECT_MACHO_MINOR}")
		endif()
	endif()

	if(NOT DEFINED arg_project_major_osx)
		if(DEFINED ${NX_PROJECT_NAME}_PROJECT_MACHO_MAJOR)
			set(arg_project_major_osx "${${NX_PROJECT_NAME}_PROJECT_MACHO_MAJOR}")
		elseif(DEFINED arg_project_minor_osx)
			set(arg_project_major_osx 0)
		endif()
	endif()

	if(DEFINED arg_project_major_osx)
		unset(arg_project_version_osx)
		list(APPEND arg_project_version_osx ${arg_project_major_osx} ${arg_project_minor_osx})
		string(REPLACE ";" "." arg_project_version_osx "${arg_project_version_osx}")

		nx_set(${NX_PROJECT_NAME}_PROJECT_MACHO "${arg_project_version_osx}")
		nx_set(${NX_PROJECT_NAME}_PROJECT_MACHO_MAJOR "${arg_project_major_osx}")
		if(DEFINED arg_project_minor_osx)
			nx_set(${NX_PROJECT_NAME}_PROJECT_MACHO_MINOR "${arg_project_minor_osx}")
		endif()

		if(DEFINED arg_project_compatibility_osx)
			set(arg_project_version_osx ${arg_project_major_osx})
			if(NOT arg_project_compatibility_osx STREQUAL "SameMajorVersion")
				list(APPEND arg_project_version_osx ${arg_project_minor_osx})
			endif()
			string(REPLACE ";" "." arg_project_version_osx "${arg_project_version_osx}")
			nx_set(${NX_PROJECT_NAME}_PROJECT_MACHO_COMPAT "${arg_project_version_osx}")
		endif()
	endif()

	# === Update Install Paths ===

	if(COMMAND nx_install_initialize)
		nx_install_initialize()
		if(opt_initialize_prefix)
			nx_install_prefixes()
		endif()
	endif()

	nx_function_end()
endfunction()

#
# Terminate Project Scope
#
macro(nx_project_end)

	# === Internal Projects Always Call These ===

	if(NOT ${NX_PROJECT_NAME}_IS_EXTERNAL)
		if(COMMAND nx_format_clang AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.clang-format")
			nx_format_clang()
		endif()

		if(COMMAND nx_format_cmake AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.cmake-format")
			nx_format_cmake(${${NX_PROJECT_NAME}_FILES_CMAKE})
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

	# === Print Feature Summary ===

	if(COMMAND feature_summary)
		feature_summary(WHAT ENABLED_FEATURES DISABLED_FEATURES PACKAGES_FOUND)
		feature_summary(FILENAME "${CMAKE_CURRENT_BINARY_DIR}/FEATURES.md" WHAT ALL)
	endif()

	# === Propagate Variables To Parent Projects ===

	if(NOT CMAKE_CURRENT_SOURCE_DIR STREQUAL "${CMAKE_SOURCE_DIR}")
		if(DEFINED _NX_VARLISTS_SORTED AND _NX_VARLISTS_SORTED)
			list(REMOVE_DUPLICATES _NX_VARLISTS_SORTED)
		endif()

		foreach(tmp_sort "_NX_VARLISTS_RESET" "_NX_VARLISTS_GLOBAL" ${_NX_VARLISTS_SORTED})
			if(DEFINED ${tmp_sort} AND ${tmp_sort})
				list(SORT ${tmp_sort})
				list(REMOVE_DUPLICATES ${tmp_sort})
			endif()
		endforeach()

		foreach(_NX_TEMP ${_NX_VARLISTS_RESET})
			if(DEFINED ${_NX_TEMP})
				unset(${_NX_TEMP})
			endif()
		endforeach()

		foreach(tmp_propagate "_NX_VARLISTS_RESET" "_NX_VARLISTS_GLOBAL" "_NX_VARLISTS_SORTED" ${_NX_VARLISTS_GLOBAL})
			if(DEFINED ${tmp_propagate})
				set(${tmp_propagate}
					"${${tmp_propagate}}"
					PARENT_SCOPE)
			else()
				unset(${tmp_propagate} PARENT_SCOPE)
			endif()
		endforeach()
	endif()
endmacro()

# === Get VCS Information ===

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.git")
	include(GitWatch)
	nx_git_check()
elseif(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/GitInfo.cmake")
	list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}")
	include(GitInfo)
	set(NX_GIT_WATCH_VARS ON)
endif()

# === Set Default Project Variables ===

nx_project_begin()

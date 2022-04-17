# -------------------------------
# SPDX-License-Identifier: MIT
#
# Copyright © 2020 Andrew Hardin
# Copyright © 2022 Daniel Wolf <<nephatrine@gmail.com>>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the “Software”), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# -------------------------------

# -------------------------------
# Adapted from Andrew Hardin's cmake-git-version-tracking script. https://github.com/andrew-hardin/cmake-git-version-tracking
# -------------------------------

# cmake-lint: disable=C0111,R0912,R0915

if(NOT DEFINED NX_GITWATCH_RUN)
	include(_NXInternals)
	_nx_guard_file()
else()
	macro(_nx_function_begin)
		# intentionally empty
	endmacro()
	macro(_nx_function_end)
		if(DEFINED NX_VARLISTS_SET AND NX_VARLISTS_SETNX_VARLISTS_SET)
			list(SORT NX_VARLISTS_SET)
			list(REMOVE_DUPLICATES NX_VARLISTS_SET)
		endif()
		foreach(vPropagate "NX_VARLISTS_SET" ${NX_VARLISTS_SET})
			if(DEFINED ${vPropagate})
				set(${vPropagate}
					"${${vPropagate}}"
					PARENT_SCOPE)
			else()
				unset(${vPropagate} PARENT_SCOPE)
			endif()
		endforeach()
	endmacro()
	function(nx_set vName)
		_nx_function_begin()
		list(APPEND NX_VARLISTS_SET "${vName}")
		if(ARGC GREATER 1)
			list(APPEND ${vName} ${ARGN})
		endif()
		_nx_function_end()
	endfunction()
endif()

set(NX_GITWATCH_FILE "${CMAKE_CURRENT_LIST_FILE}")
set(NX_GITWATCH_VARS
	"GIT_RETRIEVED_STATE"
	"GIT_COMMIT_DIRTY"
	"GIT_COMMIT_HASH"
	"GIT_COMMIT_SHORT"
	"GIT_COMMIT_ISO8601"
	"GIT_COMMIT_DATE"
	"GIT_COMMIT_TIME"
	"GIT_COMMIT_TAG"
	"GIT_COMMIT_BRANCH")

macro(_nx_git_command)
	if(NOT DEFINED GIT_EXECUTABLE)
		find_package(Git QUIET REQUIRED)
	endif()

	set(nGitResult 255)
	set(sGitOutput "")
	set(sGitError "Unknown")

	if(GIT_EXECUTABLE)
		execute_process(
			COMMAND "${GIT_EXECUTABLE}" ${ARGV}
			WORKING_DIRECTORY "${sWorkingDirectory}"
			RESULT_VARIABLE nGitResult
			OUTPUT_VARIABLE sGitOutput
			ERROR_VARIABLE sGitError
			OUTPUT_STRIP_TRAILING_WHITESPACE)
	endif()

	if(NOT nGitResult EQUAL 0)
		nx_set(NX_GIT_RETRIEVED_STATE "0")
		# set(ENV{GIT_RETRIEVED_STATE} "0")
		if(GIT_EXECUTABLE)
			string(REPLACE ";" " " sGitArgs "${ARGV}")
			message(FATAL_ERROR "${sGitError} (${GIT_EXECUTABLE} ${sGitArgs})")
		endif()
	endif()
endmacro()

function(nx_git_update sWorkingDirectory)
	_nx_function_begin()

	nx_set(NX_GIT_RETRIEVED_STATE "1")
	# set(ENV{GIT_RETRIEVED_STATE} "1")

	_nx_git_command(status --porcelain -uno)
	if(NOT nGitResult EQUAL 0)
		nx_set(NX_GIT_COMMIT_DIRTY "1")
		# set(ENV{GIT_COMMIT_DIRTY} "1")
	elseif(sGitOutput STREQUAL "")
		nx_set(NX_GIT_COMMIT_DIRTY "0")
		# set(ENV{GIT_COMMIT_DIRTY} "0")
	else()
		nx_set(NX_GIT_COMMIT_DIRTY "1")
		# set(ENV{GIT_COMMIT_DIRTY} "1")
	endif()

	_nx_git_command(log -1 --format=%H)
	if(NOT nGitResult EQUAL 0 OR sGitOutput STREQUAL "")
		nx_set(NX_GIT_COMMIT_HASH "unknown")
		# set(ENV{GIT_COMMIT_HASH} "unknown")
	else()
		nx_set(NX_GIT_COMMIT_HASH "${sGitOutput}")
		# set(ENV{GIT_COMMIT_HASH} "${sGitOutput}")
	endif()

	_nx_git_command(log -1 --format=%h)
	if(NOT nGitResult EQUAL 0 OR sGitOutput STREQUAL "")
		nx_set(NX_GIT_COMMIT_SHORT "unknown")
		# set(ENV{GIT_COMMIT_SHORT} "unknown")
	else()
		nx_set(NX_GIT_COMMIT_SHORT "${sGitOutput}")
		# set(ENV{GIT_COMMIT_SHORT} "${sGitOutput}")
	endif()

	_nx_git_command(log -1 --format=%ci)
	if(NOT nGitResult EQUAL 0 OR sGitOutput STREQUAL "")
		nx_set(NX_GIT_COMMIT_ISO8601 "unknown")
		# set(ENV{GIT_COMMIT_ISO8601} "unknown")
	else()
		nx_set(NX_GIT_COMMIT_ISO8601 "${sGitOutput}")
		# set(ENV{GIT_COMMIT_ISO8601} "${sGitOutput}")
	endif()

	_nx_git_command(log -1 --format=%cd --date=format:%Y%m%d)
	if(NOT nGitResult EQUAL 0 OR sGitOutput STREQUAL "")
		nx_set(NX_GIT_COMMIT_DATE "unknown")
		# set(ENV{GIT_COMMIT_DATE} "unknown")
	else()
		nx_set(NX_GIT_COMMIT_DATE "${sGitOutput}")
		# set(ENV{GIT_COMMIT_DATE} "${sGitOutput}")
	endif()

	_nx_git_command(log -1 --format=%cd --date=format:%H%M%S)
	if(NOT nGitResult EQUAL 0 OR sGitOutput STREQUAL "")
		nx_set(NX_GIT_COMMIT_TIME "unknown")
		# set(ENV{GIT_COMMIT_TIME} "unknown")
	else()
		nx_set(NX_GIT_COMMIT_TIME "${sGitOutput}")
		# set(ENV{GIT_COMMIT_TIME} "${sGitOutput}")
	endif()

	_nx_git_command(describe --always --dirty --broken)
	if(NOT nGitResult EQUAL 0 OR sGitOutput STREQUAL "")
		nx_set(NX_GIT_COMMIT_TAG "unknown")
		# set(ENV{GIT_COMMIT_TAG} "unknown")
	else()
		nx_set(NX_GIT_COMMIT_TAG "${sGitOutput}")
		# set(ENV{GIT_COMMIT_TAG} "${sGitOutput}")
	endif()

	_nx_git_command(rev-parse --abbrev-ref HEAD)
	if(NOT nGitResult EQUAL 0 OR sGitOutput STREQUAL "")
		nx_set(NX_GIT_COMMIT_BRANCH "unknown")
		# set(ENV{GIT_COMMIT_BRANCH} "unknown")
	else()
		nx_set(NX_GIT_COMMIT_BRANCH "${sGitOutput}")
		# set(ENV{GIT_COMMIT_BRANCH} "${sGitOutput}")
	endif()

	_nx_function_end()
endfunction()

function(nx_git_watcher)
	if(NOT DEFINED NX_GITWATCH_RUN)
		return()
	endif()

	_nx_function_begin()

	nx_git_update("${NX_GITWATCH_SOURCE_DIR}")

	unset(sStateString)
	if(EXISTS "${NX_GITWATCH_CONF_IN}")
		file(READ "${NX_GITWATCH_CONF_IN}" sStateString)
	endif()
	foreach(vGitWatch ${NX_GITWATCH_VARS})
		set(sStateString "${NX_${vGitWatch}}${sStateString}")
		# set(sStateString "$ENV{${vGitWatch}}${sStateString}")
	endforeach()
	string(SHA256 sStateHash "${sStateString}")

	set(bStateChanged ON)
	if(EXISTS "${NX_GITWATCH_STATE}")
		file(READ "${NX_GITWATCH_STATE}" sStatePrevious)
		if(sStatePrevious STREQUAL "${sStateHash}")
			set(bStateChanged OFF)
		endif()
	endif()

	if(bStateChanged AND "x${NX_GIT_RETRIEVED_STATE}" STREQUAL "x1")
		# if(bStateChanged AND "x$ENV{GIT_RETRIEVED_STATE}" STREQUAL "x1")
		file(WRITE "${NX_GITWATCH_STATE}" "${sStateHash}")
	endif()
	if(bStateChanged OR NOT EXISTS "${NX_GITWATCH_CONF_OUT}")
		foreach(vGitWatch ${NX_GITWATCH_VARS})
			# nx_set(NX_${vGitWatch} $ENV{${vGitWatch}})
		endforeach()
		configure_file("${NX_GITWATCH_CONF_IN}" "${NX_GITWATCH_CONF_OUT}")
	endif()

	_nx_function_end()
endfunction()

function(nx_git_check)
	_nx_function_begin()
	nx_git_update("${CMAKE_CURRENT_SOURCE_DIR}")

	if("x${NX_GIT_RETRIEVED_STATE}" STREQUAL "x1")
		# if("x$ENV{GIT_RETRIEVED_STATE}" STREQUAL "x1")
		if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/tools")
			set(sGitInfo "${CMAKE_CURRENT_SOURCE_DIR}/tools/GitInfo.cmake")
		else()
			set(sGitInfo "${CMAKE_CURRENT_SOURCE_DIR}/GitInfo.cmake")
		endif()

		string(TIMESTAMP sTimeStamp "%Y-%m-%d %H:%M" UTC)
		file(WRITE "${sGitInfo}" "# Last Updated ${sTimeStamp}\n\n")

		foreach(vGitWatch ${NX_GITWATCH_VARS})
			set(sInfoContent "${NX_${vGitWatch}}")
			# set(sInfoContent "$ENV{${vGitWatch}}")
			file(APPEND "${sGitInfo}" "nx_set(NX_${vGitWatch} \"${sInfoContent}\")\n")
			# nx_set(NX_${vGitWatch} $ENV{${vGitWatch}})
		endforeach()
	endif()

	_nx_function_end()
endfunction()

function(nx_git_configure sGitInput sGitOutput)
	_nx_function_begin()

	get_filename_component(sGitTarget "${sGitInput}" NAME)
	string(MAKE_C_IDENTIFIER "${sGitTarget}" sGitTarget)
	add_custom_target(
		${sGitTarget} ALL
		BYPRODUCTS "${sGitOutput}"
		DEPENDS "${sGitInput}"
		COMMENT "[GitWatcher] Retrieving Git State"
		COMMAND
			${CMAKE_COMMAND} -DNX_GITWATCH_RUN=ON -DGIT_EXECUTABLE="${GIT_EXECUTABLE}"
			-DNX_GITWATCH_STATE="${CMAKE_CURRENT_BINARY_DIR}/git.state" -DNX_GITWATCH_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}"
			-DNX_GITWATCH_CONF_IN="${sGitInput}" -DNX_GITWATCH_CONF_OUT="${sGitOutput}" -P "${NX_GITWATCH_FILE}")

	configure_file("${sGitInput}" "${sGitOutput}")

	_nx_function_end()
endfunction()

if(DEFINED NX_GITWATCH_RUN)
	nx_git_watcher()
endif()

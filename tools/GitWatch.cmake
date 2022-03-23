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

if(NOT DEFINED GIT_EXECUTABLE)
	find_package(Git QUIET REQUIRED)
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
		set(ENV{GIT_RETRIEVED_STATE} "0")
		if(GIT_EXECUTABLE)
			string(REPLACE ";" " " sGitArgs "${ARGV}")
			message(FATAL_ERROR "${sGitError} (${GIT_EXECUTABLE} ${sGitArgs})")
		endif()
	endif()
endmacro()

function(nx_git_update sWorkingDirectory)
	set(ENV{GIT_RETRIEVED_STATE} "1")

	_nx_git_command(status --porcelain -uno)
	if(NOT nGitResult EQUAL 0)
		set(ENV{GIT_COMMIT_DIRTY} "1")
	elseif(sGitOutput STREQUAL "")
		set(ENV{GIT_COMMIT_DIRTY} "0")
	else()
		set(ENV{GIT_COMMIT_DIRTY} "1")
	endif()

	_nx_git_command(log -1 --format=%H)
	if(NOT nGitResult EQUAL 0 OR sGitOutput STREQUAL "")
		set(ENV{GIT_COMMIT_HASH} "unknown")
	else()
		set(ENV{GIT_COMMIT_HASH} "${sGitOutput}")
	endif()

	_nx_git_command(log -1 --format=%h)
	if(NOT nGitResult EQUAL 0 OR sGitOutput STREQUAL "")
		set(ENV{GIT_COMMIT_SHORT} "unknown")
	else()
		set(ENV{GIT_COMMIT_SHORT} "${sGitOutput}")
	endif()

	_nx_git_command(log -1 --format=%ci)
	if(NOT nGitResult EQUAL 0 OR sGitOutput STREQUAL "")
		set(ENV{GIT_COMMIT_ISO8601} "unknown")
	else()
		set(ENV{GIT_COMMIT_ISO8601} "${sGitOutput}")
	endif()

	_nx_git_command(log -1 --format=%cd --date=format:%Y%m%d)
	if(NOT nGitResult EQUAL 0 OR sGitOutput STREQUAL "")
		set(ENV{GIT_COMMIT_DATE} "unknown")
	else()
		set(ENV{GIT_COMMIT_DATE} "${sGitOutput}")
	endif()

	_nx_git_command(log -1 --format=%cd --date=format:%H%M%S)
	if(NOT nGitResult EQUAL 0 OR sGitOutput STREQUAL "")
		set(ENV{GIT_COMMIT_TIME} "unknown")
	else()
		set(ENV{GIT_COMMIT_TIME} "${sGitOutput}")
	endif()

	_nx_git_command(describe --always --dirty --broken)
	if(NOT nGitResult EQUAL 0 OR sGitOutput STREQUAL "")
		set(ENV{GIT_COMMIT_TAG} "unknown")
	else()
		set(ENV{GIT_COMMIT_TAG} "${sGitOutput}")
	endif()

	_nx_git_command(rev-parse --abbrev-ref HEAD)
	if(NOT nGitResult EQUAL 0 OR sGitOutput STREQUAL "")
		set(ENV{GIT_COMMIT_BRANCH} "unknown")
	else()
		set(ENV{GIT_COMMIT_BRANCH} "${sGitOutput}")
	endif()
endfunction()

function(nx_git_watcher)
	if(NOT DEFINED _NX_GIT_INTERNAL)
		return()
	endif()

	nx_git_update("${NX_GIT_SOURCE_DIR}")

	unset(sGitInput)
	if(EXISTS "${NX_GIT_FILE_INPUT}")
		file(READ "${NX_GIT_FILE_INPUT}" sGitInput)
	endif()
	foreach(vGitWatch ${NX_GITWATCH_VARS})
		set(sGitInput "$ENV{${vGitWatch}}${sGitInput}")
	endforeach()
	string(SHA256 sGitState "${sGitInput}")

	set(bGitChanged ON)
	if(EXISTS "${NX_GIT_FILE_STATE}")
		file(READ "${NX_GIT_FILE_STATE}" sGitPrevious)
		if(sGitPrevious STREQUAL "${sGitState}")
			set(bGitChanged OFF)
		endif()
	endif()

	if(bGitChanged AND "x$ENV{GIT_RETRIEVED_STATE}" STREQUAL "x1")
		file(WRITE "${NX_GIT_FILE_STATE}" "${sGitState}")
	endif()
	if(bGitChanged OR NOT EXISTS "${NX_GIT_FILE_OUTPUT}")
		foreach(vGitWatch ${NX_GITWATCH_VARS})
			set(NX_${vGitWatch} $ENV{${vGitWatch}})
		endforeach()
		configure_file("${NX_GIT_FILE_INPUT}" "${NX_GIT_FILE_OUTPUT}")
	endif()
endfunction()

function(nx_git_check)
	nx_git_update("${CMAKE_CURRENT_SOURCE_DIR}")
	string(TIMESTAMP thisTime "%Y-%m-%d %H:%M" UTC)

	if("x$ENV{GIT_RETRIEVED_STATE}" STREQUAL "x1")
		file(WRITE "${CMAKE_CURRENT_SOURCE_DIR}/GitInfo.cmake" "# Last Updated ${thisTime}\n\n")
	endif()
	foreach(vGitWatch ${NX_GITWATCH_VARS})
		if("x$ENV{GIT_RETRIEVED_STATE}" STREQUAL "x1")
			set(thisWalrus "$ENV{${vGitWatch}}")
			file(APPEND "${CMAKE_CURRENT_SOURCE_DIR}/GitInfo.cmake" "nx_set(NX_${vGitWatch} \"${thisWalrus}\")\n")
		endif()
		set(NX_${vGitWatch}
			$ENV{${vGitWatch}}
			PARENT_SCOPE)
	endforeach()
endfunction()

function(nx_git_configure sGitInput sGitOutput)
	get_filename_component(sGitTarget "${sGitInput}" NAME)
	string(MAKE_C_IDENTIFIER "${sGitTarget}" sGitTarget)
	add_custom_target(
		${sGitTarget} ALL
		BYPRODUCTS "${sGitOutput}"
		DEPENDS "${sGitInput}"
		COMMENT "[GitWatcher] Retrieving Git State"
		COMMAND
			${CMAKE_COMMAND} -D_NX_GIT_INTERNAL=ON -DGIT_EXECUTABLE=${GIT_EXECUTABLE} -DNX_GIT_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}"
			-DNX_GIT_FILE_INPUT=${sGitInput} -DNX_GIT_FILE_OUTPUT="${sGitOutput}"
			-DNX_GIT_FILE_STATE="${CMAKE_CURRENT_BINARY_DIR}/git.state" -P "${NX_GITWATCH_FILE}")
	configure_file("${sGitInput}" "${sGitOutput}")
endfunction()

nx_git_watcher()

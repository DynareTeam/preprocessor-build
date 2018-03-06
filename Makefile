# Copyright © 2018 Stéphane Adjemian <stepan@dynare.org>
#
# This file is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This file is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# GPLv3 license is available at <http://www.gnu.org/licenses/>.

OSX_SDK_VERSION=10.11

ifeq ($(wildcard configure.inc),)
CONFIGURATION_FILE=0
PREPROCESSOR_GIT_REMOTE=https://github.com/DynareTeam/dynare-preprocessor
PREPROCESSOR_GIT_BRANCH=master
PREPROCESSOR_GIT_COMMIT=$(git ls-remote $PREPROCESSOR_REMOTE $PREPROCESSOR_BRANCH | sed "s/refs\/heads\/master//")
else
include ./configure.inc
CONFIGURATION_FILE=1
endif

ifeq ($(wildcard remote.inc),)
REMOTE_FILE=0
else
include ./remote.inc
REMOTE_FILE=1
endif

ROOT_PATH := ${CURDIR}

.PHONY: osxcross-init osxcross clean-osxcross preprocessor-init preprocessor-fetch

osxcross: modules/osxcross/target/bin/x86_64-apple-darwin15-g++

osxcross-init:
	git submodule update --init

modules/osxcross/target/bin/x86_64-apple-darwin15-g++: osxcross-init modules/osxcross/tarballs/MacOSX$(OSX_SDK_VERSION).sdk.tar.xz
	cd modules/osxcross; UNATTENDED=1 ./build.sh
	cd modules/osxcross; GCC_VERSION=6.4.0 ./build_gcc.sh

modules/osxcross/tarballs/MacOSX$(OSX_SDK_VERSION).sdk.tar.xz:
	wget https://dynare.adjemian.eu/osx/$(OSX_SDK_VERSION)/sdk.tar.xz -O sdk.tar.xz
	mv sdk.tar.xz $@

preprocessor-init:
	git submodule update --init

preprocessor-fetch: preprocessor-init
	cd modules/preprocessor && git fetch --all

preprocessor-set: preprocessor-fetch
	cd modules/preprocessor && git reset --hard $(PREPROCESSOR_GIT_COMMIT)


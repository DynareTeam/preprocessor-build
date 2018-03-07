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

include versions/boost.version
include versions/osx-sdk.version

ifeq ($(wildcard configure.inc),)
CONFIGURATION_FILE=0
PREPROCESSOR_GIT_REMOTE=https://github.com/DynareTeam/dynare-preprocessor
PREPROCESSOR_GIT_BRANCH=master
PREPROCESSOR_GIT_COMMIT=$(shell git ls-remote $(PREPROCESSOR_GIT_REMOTE) $(PREPROCESSOR_GIT_BRANCH) | sed "s/[[:space:]]*refs\/heads\/$(PREPROCESSOR_GIT_BRANCH)//")
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

.PHONY: osxcross-init osxcross-build clean-osxcross preprocessor-init preprocessor-fetch preprocessor-set boost-clean boost-tar-clean boost-clean-all

all: preprocessor-set osxcross-build Boost

osxcross-init:
	@git submodule update --init

osxcross-build: osxcross-init modules/osxcross/target/bin/x86_64-apple-darwin15-base-g++

modules/osxcross/target/bin/x86_64-apple-darwin15-base-g++: modules/osxcross/tarballs/MacOSX$(OSX_SDK_VERSION).sdk.tar.xz
	cd modules/osxcross; UNATTENDED=1 ./build.sh
	cd modules/osxcross; GCC_VERSION=6.4.0 ./build_gcc.sh
	touch modules/osxcross/target/bin/x86_64-apple-darwin15-base-g++

modules/osxcross/tarballs/MacOSX$(OSX_SDK_VERSION).sdk.tar.xz: versions/osx-sdk.version
	wget https://dynare.adjemian.eu/osx/$(OSX_SDK_VERSION)/sdk.tar.xz -O sdk.tar.xz
	mv sdk.tar.xz $@
	touch modules/osxcross/tarballs/MacOSX$(OSX_SDK_VERSION).sdk.tar.xz

osxcross-clean:
	rm -rf modules/osxcross

preprocessor-init:
	@git submodule update --init

preprocessor-fetch: preprocessor-init
	@cd modules/preprocessor && git fetch --all

preprocessor-set: preprocessor-fetch
	cd modules/preprocessor && git reset --hard $(PREPROCESSOR_GIT_COMMIT)

Boost: boost_${BOOST_VERSION}.tar.bz2
	tar xjf boost_${BOOST_VERSION}.tar.bz2
	mkdir -p Boost
	mv boost_${BOOST_VERSION}/* Boost
	rm -r boost_${BOOST_VERSION}

boost_${BOOST_VERSION}.tar.bz2: versions/boost.version
	rm -f boost_${BOOST_VERSION}.tar.bz2
	wget https://sourceforge.net/projects/boost/files/boost/`echo "${BOOST_VERSION}" | sed -e 's/_/./g'`/boost_${BOOST_VERSION}.tar.bz2/download -O boost_${BOOST_VERSION}.tar.bz2
	touch boost_${BOOST_VERSION}.tar.bz2
	rm -rf ${ROOT_PATH}/sources/Boost

boost-clean:
	rm -rf Boost

boost-tar-clean:
	rm -f boost_*.tar.bz2

boost-clean-all: boost-clean boost-tar-clean

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

# Decide if there is something to do
ifneq ($(wildcard builds/linux/$(PREPROCESSOR_GIT_COMMIT)/.),)
  ifneq ($(wildcard builds/windows/$(PREPROCESSOR_GIT_COMMIT)/.),)
    ifneq ($(wildcard builds/osx/$(PREPROCESSOR_GIT_COMMIT)/.),)
      DONE=1
    else
      DONE=0
    endif
  else
    DONE=0
  endif
else
  DONE=0
endif

.PHONY: osxcross-init osxcross-build osxcross-clean boost-clean boost-tar-clean boost-clean-all install
.PHONY: preprocessor-sources
.PHONY: all distribution dist linux-dist windows-dist osx-dist

all:
	@if [ $(DONE) -eq 0 ] ; then \
          rm -rf builds/windows/$(PREPROCESSOR_GIT_COMMIT) ; \
          rm -rf builds/linux/$(PREPROCESSOR_GIT_COMMIT) ; \
          rm -rf builds/osx/$(PREPROCESSOR_GIT_COMMIT) ; \
          $(MAKE) -j distribution ; \
        fi

distribution: preprocessor-sources
	$(MAKE) dist
	@if [ $(REMOTE_FILE) -eq 1 ]; then\
	  scp -r builds/$(PREPROCESSOR_GIT_COMMIT) $(REMOTE_SERVER):$(REMOTE_PATH) ;\
	fi

dist: linux-dist windows-dist osx-dist

install: osxcross-build Boost

#
# OSXCROSS
#

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

#
# PREPROCESSOR SOURCES
#

preprocessor-sources:
	rm -rf sources
	git clone $(PREPROCESSOR_GIT_REMOTE) sources
	cd sources && git reset --hard $(PREPROCESSOR_GIT_COMMIT)
	cd sources && cat configure.ac | sed "s/AC_INIT(\[dynare-preprocessor\], \[.*\])/AC_INIT([dynare-preprocessor],\ [$(PREPROCESSOR_GIT_COMMIT)])/" > configure.ac.new
	mv sources/configure.ac.new sources/configure.ac
#
# BOOST HEADERS
#

Boost: Boost/include/boost

Boost/include/boost: boost_${BOOST_VERSION}.tar.bz2
	tar xjf boost_${BOOST_VERSION}.tar.bz2
	mkdir -p Boost/include/boost
	mv boost_${BOOST_VERSION}/boost/* Boost/include/boost
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

#
# BUILD PREPROCESSOR (LINUX TARGET)
#

linux-dist: builds/$(PREPROCESSOR_GIT_COMMIT)/linux/32/preprocessor.tar.gz builds/$(PREPROCESSOR_GIT_COMMIT)/linux/64/preprocessor.tar.gz
	rm -rf tmp/binaries/linux

builds/$(PREPROCESSOR_GIT_COMMIT)/linux/32/preprocessor.tar.gz: tmp/binaries/linux/32/dynare_m
	mkdir -p builds/$(PREPROCESSOR_GIT_COMMIT)/linux/32
	cd tmp/binaries/linux/32 && mkdir -p bin && mv dynare_m bin && tar cfz preprocessor.tar.gz bin
	mv tmp/binaries/linux/32/preprocessor.tar.gz builds/$(PREPROCESSOR_GIT_COMMIT)/linux/32
	cd builds/$(PREPROCESSOR_GIT_COMMIT)/linux/32 && sha256sum preprocessor.tar.gz > sha256sum && gpg --clearsign sha256sum

builds/$(PREPROCESSOR_GIT_COMMIT)/linux/64/preprocessor.tar.gz: tmp/binaries/linux/64/dynare_m
	mkdir -p builds/$(PREPROCESSOR_GIT_COMMIT)/linux/64
	cd tmp/binaries/linux/64 && mkdir -p bin && mv dynare_m bin && tar cfz preprocessor.tar.gz bin
	mv tmp/binaries/linux/64/preprocessor.tar.gz builds/$(PREPROCESSOR_GIT_COMMIT)/linux/64
	cd builds/$(PREPROCESSOR_GIT_COMMIT)/linux/64 && sha256sum preprocessor.tar.gz > sha256sum && gpg --clearsign sha256sum

tmp/binaries/linux/32/dynare_m:
	mkdir -p tmp/linux/32
	cp -r sources/* tmp/linux/32
	cd tmp/linux/32 && autoreconf -si
	cd tmp/linux/32 && ./configure --with-boost=$(ROOT_PATH)/Boost CXX=g++-6  LDFLAGS='-m32 -static -static-libgcc -static-libstdc++' CXXFLAGS='-m32'
	cd tmp/linux/32 && make
	mkdir -p tmp/binaries/linux/32
	mv tmp/linux/32/src/dynare_m tmp/binaries/linux/32
	cd tmp/binaries/linux/32 && strip dynare_m
	rm -rf tmp/linux/32

tmp/binaries/linux/64/dynare_m:
	mkdir -p tmp/linux/64
	cp -r sources/* tmp/linux/64
	cd tmp/linux/64 && autoreconf -si
	cd tmp/linux/64 && ./configure --with-boost=$(ROOT_PATH)/Boost CXX=g++-6 LDFLAGS='-static -static-libgcc -static-libstdc++'
	cd tmp/linux/64 && make
	mkdir -p tmp/binaries/linux/64
	mv tmp/linux/64/src/dynare_m tmp/binaries/linux/64
	cd tmp/binaries/linux/64 && strip dynare_m
	rm -rf tmp/linux/64

#
# BUILD PREPROCESSOR (WINDOWS TARGET)
#

windows-dist: builds/$(PREPROCESSOR_GIT_COMMIT)/windows/32/preprocessor.tar.gz builds/$(PREPROCESSOR_GIT_COMMIT)/windows/64/preprocessor.tar.gz
	rm -rf tmp/binaries/windows

builds/$(PREPROCESSOR_GIT_COMMIT)/windows/32/preprocessor.tar.gz: tmp/binaries/windows/32/dynare_m.exe
	mkdir -p builds/$(PREPROCESSOR_GIT_COMMIT)/windows/32
	cd tmp/binaries/windows/32 && mkdir -p bin && mv dynare_m.exe bin && tar cfz preprocessor.tar.gz bin
	mv tmp/binaries/windows/32/preprocessor.tar.gz builds/$(PREPROCESSOR_GIT_COMMIT)/windows/32
	cd builds/$(PREPROCESSOR_GIT_COMMIT)/windows/32 && sha256sum preprocessor.tar.gz > sha256sum && gpg --clearsign sha256sum

builds/$(PREPROCESSOR_GIT_COMMIT)/windows/64/preprocessor.tar.gz: tmp/binaries/windows/64/dynare_m.exe
	mkdir -p builds/$(PREPROCESSOR_GIT_COMMIT)/windows/64
	cd tmp/binaries/windows/64 && mkdir -p bin && mv dynare_m.exe bin && tar cfz preprocessor.tar.gz bin
	mv tmp/binaries/windows/64/preprocessor.tar.gz builds/$(PREPROCESSOR_GIT_COMMIT)/windows/64
	cd builds/$(PREPROCESSOR_GIT_COMMIT)/windows/64 && sha256sum preprocessor.tar.gz > sha256sum && gpg --clearsign sha256sum

tmp/binaries/windows/32/dynare_m.exe:
	mkdir -p tmp/windows/32
	cp -r sources/* tmp/windows/32
	cd tmp/windows/32 && autoreconf -si
	cd tmp/windows/32 && ./configure --host=i686-w64-mingw32 --with-boost=$(ROOT_PATH)/Boost LDFLAGS='-static -static-libgcc -static-libstdc++'
	cd tmp/windows/32 && make
	mkdir -p tmp/binaries/windows/32
	mv tmp/windows/32/src/dynare_m.exe tmp/binaries/windows/32
	cd tmp/binaries/windows/32 && i686-w64-mingw32-strip dynare_m.exe
	rm -rf tmp/windows/32

tmp/binaries/windows/64/dynare_m.exe:
	mkdir -p tmp/windows/64
	cp -r sources/* tmp/windows/64
	cd tmp/windows/64 && autoreconf -si
	cd tmp/windows/64 && ./configure --host=x86_64-w64-mingw32 --with-boost=$(ROOT_PATH)/Boost LDFLAGS='-static -static-libgcc -static-libstdc++'
	cd tmp/windows/64 && make
	mkdir -p tmp/binaries/windows/64
	mv tmp/windows/64/src/dynare_m.exe tmp/binaries/windows/64
	cd tmp/binaries/windows/64 && x86_64-w64-mingw32-strip dynare_m.exe
	rm -rf tmp/windows/64

#
# BUILD PREPROCESSOR (OSX TARGET)
#

osx-dist: builds/$(PREPROCESSOR_GIT_COMMIT)/osx/32/preprocessor.tar.gz builds/$(PREPROCESSOR_GIT_COMMIT)/osx/64/preprocessor.tar.gz
	rm -rf tmp/binaries/osx

builds/$(PREPROCESSOR_GIT_COMMIT)/osx/32/preprocessor.tar.gz: tmp/binaries/osx/32/dynare_m
	mkdir -p builds/$(PREPROCESSOR_GIT_COMMIT)/osx/32
	cd tmp/binaries/osx/32 && mkdir -p bin && mv dynare_m bin && tar cfz preprocessor.tar.gz bin
	mv tmp/binaries/osx/32/preprocessor.tar.gz builds/$(PREPROCESSOR_GIT_COMMIT)/osx/32
	cd builds/$(PREPROCESSOR_GIT_COMMIT)/osx/32 && sha256sum preprocessor.tar.gz > sha256sum && gpg --clearsign sha256sum

builds/$(PREPROCESSOR_GIT_COMMIT)/osx/64/preprocessor.tar.gz: tmp/binaries/osx/64/dynare_m
	mkdir -p builds/$(PREPROCESSOR_GIT_COMMIT)/osx/64
	cd tmp/binaries/osx/64 && mkdir -p bin && mv dynare_m bin && tar cfz preprocessor.tar.gz bin
	mv tmp/binaries/osx/64/preprocessor.tar.gz builds/$(PREPROCESSOR_GIT_COMMIT)/osx/64
	cd builds/$(PREPROCESSOR_GIT_COMMIT)/osx/64 && sha256sum preprocessor.tar.gz > sha256sum && gpg --clearsign sha256sum

tmp/binaries/osx/32/dynare_m:
	mkdir -p tmp/osx/32
	cp -r sources/* tmp/osx/32
	cd tmp/osx/32 && autoreconf -si
	cd tmp/osx/32 && export PATH=$(ROOT_PATH)/modules/osxcross/target/bin:$(PATH) && ./configure --host=i386-apple-darwin15 CXX=o32-clang++ --with-boost=$(ROOT_PATH)/Boost CXXFLAGS='-stdlib=libc++' AR=i386-apple-darwin15-ar
	cd tmp/osx/32 && export PATH=$(ROOT_PATH)/modules/osxcross/target/bin:$(PATH) && make
	mkdir -p tmp/binaries/osx/32
	mv tmp/osx/32/src/dynare_m tmp/binaries/osx/32
	rm -rf tmp/osx/32

tmp/binaries/osx/64/dynare_m:
	mkdir -p tmp/osx/64
	cp -r sources/* tmp/osx/64
	cd tmp/osx/64 && autoreconf -si
	cd tmp/osx/64 && export PATH=$(ROOT_PATH)/modules/osxcross/target/bin:$(PATH) && ./configure --host=x86_64-apple-darwin15 CXX=o64-clang++ --with-boost=$(ROOT_PATH)/Boost  CXXFLAGS='-stdlib=libc++' AR=x86_64-apple-darwin15-ar
	cd tmp/osx/64 && export PATH=$(ROOT_PATH)/modules/osxcross/target/bin:$(PATH) && make
	mkdir -p tmp/binaries/osx/64
	mv tmp/osx/64/src/dynare_m tmp/binaries/osx/64
	rm -rf tmp/osx/64

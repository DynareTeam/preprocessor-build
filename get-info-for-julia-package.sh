#!/bin/sh

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

PREPROCESSOR_GIT_COMMIT=$1

linux32sha=`cat builds/$PREPROCESSOR_GIT_COMMIT/linux/32/sha256sum | sed "s/[[:space:]]*preprocessor.tar.gz//"`
linux64sha=`cat builds/$PREPROCESSOR_GIT_COMMIT/linux/64/sha256sum | sed "s/[[:space:]]*preprocessor.tar.gz//"`
windows32sha=`cat builds/$PREPROCESSOR_GIT_COMMIT/windows/32/sha256sum | sed "s/[[:space:]]*preprocessor.tar.gz//"`
windows64sha=`cat builds/$PREPROCESSOR_GIT_COMMIT/windows/64/sha256sum | sed "s/[[:space:]]*preprocessor.tar.gz//"`
osx64sha=`cat builds/$PREPROCESSOR_GIT_COMMIT/osx/64/sha256sum | sed "s/[[:space:]]*preprocessor.tar.gz//"`

echo " "
echo "Copy/paste the following in Dynare.jl/deps/build.jl if this preprocessor build is to be used in the Julia package:"
echo " "
echo "PREPROCESSOR_VERSION = $PREPROCESSOR_GIT_COMMIT"
echo " "
echo "download_info = Dict("
echo "    Linux(:i686, :glibc)    => ("\$REMOTE_PATH/linux/32/preprocessor.tar.gz", "$linux32sha"),"
echo "    Linux(:x86_64, :glibc)  => ("\$REMOTE_PATH/linux/64/preprocessor.tar.gz", "$linux64sha"),"
echo "    MacOS()                 => ("\$REMOTE_PATH/osx/64/preprocessor.tar.gz", "$osx64sha"),"
echo "    Windows(:i686)          => ("\$REMOTE_PATH/windows/32/preprocessor.tar.gz", "$windows32sha"),"
echo "    Windows(:x86_64)        => ("\$REMOTE_PATH/windows/64/preprocessor.tar.gz", "$windows64sha"),"
echo ")"
echo " "

#!/bin/bash
set -e

cd "$(dirname ${BASH_SOURCE[0]})"
source config.sh

cd "$JDKDIR"

# refresh patched build system
bash ./common/autoconf/autogen.sh

## Description ##
# Use the downloaded JDK:      --with-boot-jdk=/opt/jdkcross/jdk-9.0.1
# Cross-compiling for ARM:     --openjdk-target=arm-linux-gnueabi
# Tune for ARM926EJ-S softfp:  --with-abi-profile=arm-ev3
# Disable GUI:                 --enable-headless-only
# Help to find freetype:       --with-freetype-lib=/usr/lib/arm-linux-gnueabi
#                              --with-freetype-include=/usr/include
# Build only the Client VM:    --with-jvm-variants=client
# Add extra build flags:       --with-extra-cflags="-Wno-maybe-uninitialized -D__SOFTFP__"
#   - Fix the build on new GCC: -Wno-maybe-uninitialized
#   - Force softfloat runtime:  -D__SOFTFP__
# Fix the "internal" string:   --with-version-string="9.0.1+11"
# Fix for GCC and LTO objects: AR="arm-linux-gnueabi-gcc-ar"
#                              NM="arm-linux-gnueabi-gcc-nm"
#                              BUILD_AR="gcc-ar"
#                              BUILD_NM="gcc-nm"

# configure the build
bash ./configure --with-boot-jdk="$SCRIPTDIR/jdk-9.0.4" \
                 --openjdk-target=arm-linux-gnueabi \
                 --with-abi-profile=arm-ev3 \
                 --enable-headless-only \
                 --with-freetype-lib=/usr/lib/arm-linux-gnueabi \
                 --with-freetype-include=/usr/include \
                 --with-jvm-variants=client \
                 --with-extra-cflags="-w -Wno-error -D__SOFTFP__" \
                 --with-extra-cxxflags="-w -Wno-error -D__SOFTFP__" \
                 --with-version-string="$JAVA_VERSION" \
                 AR="arm-linux-gnueabi-gcc-ar" \
                 NM="arm-linux-gnueabi-gcc-nm" \
                 BUILD_AR="gcc-ar" \
                 BUILD_NM="gcc-nm"

# start the build
make clean images

#!/bin/bash
set -e

cd "$(dirname ${BASH_SOURCE[0]})"
source config.sh
source "$BUILDDIR/metadata"

cd "$JDKDIR"

# refresh patched build system
echo "[BUILD] Regenerating autoconf"
if   [ "$AUTOGEN_STYLE" == "v1" ]; then
  bash "$AUTOGEN_PATH"
elif [ "$AUTOGEN_STYLE" == "v2" ]; then
  bash ./configure autogen || true
fi

## Description ##
# Use the downloaded JDK:      --with-boot-jdk=<dir>
# Cross-compiling:             --openjdk-target=<triplet>
# Pick the correct ABI:        --with-abi-profile=<profile>
# Build only the right VM:     --with-jvm-variants=<VM>
# Disable GUI:                 --enable-headless-only
# Add extra build flags:       --with-extra-cflags="-w -Wno-error -D__SOFTFP__"
#                              --with-extra-cxxflags="-w -Wno-error -D__SOFTFP__"
#   - Fix the build on new GCC: -w -Wno-error
#   - Force softfloat runtime:  -D__SOFTFP__
# Fix the "internal" string:   --with-version-string="<version>"
# Use correct JNI path:        --with-jni-libpath=<dir1>:<dir2>...
# Use correct debug level      --with-debug-level=<level>
# Help to find freetype:       --with-freetype-lib=/usr/lib/arm-linux-gnueabi
#                              --with-freetype-include=/usr/include
# Use system libraries:        --with-libjpeg=system
#                              --with-giflib=system
#                              --with-libpng=system
#                              --with-zlib=system
#                              --with-lcms=system
# Fix for GCC and LTO objects: AR="arm-linux-gnueabi-gcc-ar"
#                              NM="arm-linux-gnueabi-gcc-nm"
#                              BUILD_AR="gcc-ar"
#                              BUILD_NM="gcc-nm"

# configure the build
echo "[BUILD] Configuring Java for target '$JDKPLATFORM'"

if [ "$JDKPLATFORM" == "ev3" ]; then
  LIBFFI_LIBS=-lffi_pic \
  bash ./configure --with-boot-jdk="$HOSTJDK" \
                   $TARGET_FLAGS \
                   --with-abi-profile="$HOTSPOT_ABI" \
                   --enable-headless-only \
                   --with-freetype-lib=/usr/lib/arm-linux-gnueabi \
                   --with-freetype-include=/usr/include \
                   --with-jtreg="$JTREG" \
                   $HOTSPOT_VARIANT \
                   --disable-warnings-as-errors \
                   --with-version-string="$JAVA_VERSION" \
                   $JNI_PATH_FLAGS \
                   $VENDOR_FLAGS \
                   --with-debug-level=$HOTSPOT_DEBUG \
                   --with-native-debug-symbols=internal \
                   --with-stdc++lib=dynamic \
                   --with-libjpeg=system \
                   --with-giflib=system \
                   --with-libpng=system \
                   --with-zlib=system \
                   --with-lcms=system \
                   --with-extra-cflags="-fno-tree-pre" \
                   --with-extra-cxxflags="-fno-tree-pre" \
                   AR="$AR" \
                   NM="$NM" \
                   BUILD_AR="gcc-ar" \
                   BUILD_NM="gcc-nm"
fi

# start the build
echo "[BUILD] Building Java"
make clean
if [ "$BOOTCYCLE" = "yes" ]; then
  make bootcycle-images
else
  make images
fi

#!/bin/bash

# scripts root directory
SCRIPTDIR="$( cd "$(dirname "$0")" ; pwd -P )"
# output directory
BUILDDIR="/build"
# jdk repository directory
JDKDIR="$BUILDDIR/jdk"
# softfloat repository directory
SFLTDIR="$BUILDDIR/sflt"
# softfloat repository
SFLTREPO="https://github.com/ev3dev-lang-java/softfloat-openjdk.git"
# softfloat build directory
SFLTBUILD="$SFLTDIR/build/Linux-ARM-VFPv2-GCC-OpenJDK"
# softfloat license
SFLTPFX="$SFLTDIR/output"
# openjdk-build repo dir
ABLDDIR="$BUILDDIR/openjdk-build"
# openjdk-build repo
ABLDREPO="https://github.com/AdoptOpenJDK/openjdk-build.git"
# cacertfile
CACERTFILE="$ABLDDIR/security/cacerts"
# hg tarball
JAVA_TMP="$BUILDDIR/jdk_tmp"
TARBALL_MAX_DOWNLOADS=10

JRI_MODULES="java.se,jdk.jdwp.agent,jdk.unsupported,jdk.management.agent,jdk.jartool"

JTREG="$BUILDDIR/jtreg"
JTREG_URL="https://ci.adoptopenjdk.net/view/Dependencies/job/jtreg/lastSuccessfulBuild/artifact/jtreg-4.2.0-tip.tar.gz"
JTREG_FILE="$BUILDDIR/jtreg.tar.gz"

###############################################################################
# Set the debug level
#    release: no debug information, all optimizations, no asserts.
#    optimized: no debug information, all optimizations, no asserts, HotSpot target is 'optimized'.
#    fastdebug: debug information (-g), all optimizations, all asserts
#    slowdebug: debug information (-g), no optimizations, all asserts
if [ "$JDKDEBUG" == "release" ] ||
   [ "$JDKDEBUG" == "optimized" ] ||
   [ "$JDKDEBUG" == "fastdebug" ] ||
   [ "$JDKDEBUG" == "slowdebug" ]; then
  HOTSPOT_DEBUG="$JDKDEBUG"
elif [ -z "$JDKDEBUG" ]; then
  HOTSPOT_DEBUG="release"
else
  echo "Error! Please specify a valid JVM debug level via the JDKDEBUG environment variable." >&2
  echo "Acceptable values:" >&2
  echo "JDKDEBUG=release" >&2
  echo "JDKDEBUG=optimized" >&2
  echo "JDKDEBUG=fastdebug" >&2
  echo "JDKDEBUG=slowdebug" >&2
  exit 1
fi


# EV3
if [ "$JDKPLATFORM" == "ev3" ]; then
  eval "$(dpkg-architecture -s -a armel -A armel)"

# invalid or unset platform
else
  echo "Error! Please specify JDK platform to compile via the JDKPLATFORM environment variable." >&2
  echo "Acceptable values:" >&2
  echo "JDKPLATFORM=ev3" >&2
  exit 1
fi

##
## Version-specific configuration
##

# invalid or unset VM
if [ "$JDKVM" != "zero" ] && [ "$JDKVM" != "client" ] && [ "$JDKVM" != "minimal" ]; then
  echo "Error! Please specify JDK VM to compile via the JDKVM environment variable." >&2
  echo "Acceptable values:" >&2
  echo "JDKVM=client" >&2
  echo "JDKVM=minimal" >&2
  echo "JDKVM=zero" >&2
  exit 1
fi

HOTSPOT_VARIANT="$JDKVM"
VENDOR_FLAGS="              --with-vendor-name=\"ev3dev-lang-java\" "
VENDOR_FLAGS="$VENDOR_FLAGS --with-vendor-url=\"https://github.com/ev3dev-lang-java/ev3dev-lang-java/\" "
VENDOR_FLAGS="$VENDOR_FLAGS --with-vendor-bug-url=\"https://github.com/ev3dev-lang-java/ev3dev-lang-java/issues/new\" "
VENDOR_FLAGS="$VENDOR_FLAGS --with-vendor-vm-bug-url=\"https://github.com/ev3dev-lang-java/ev3dev-lang-java/issues/new\" "

# output images directory
#IMAGEDIR="/build/jdk/build/linux-arm-normal-client-release/images"

# mercurial repository
#JAVA_REPO="http://hg.openjdk.java.net/jdk-updates/jdkXu/"

# patch to apply
#PATCHVER="jdkX"

# path to autogen.sh to regenerate the build system
#AUTOGEN_PATH="./common/autoconf/autogen.sh"

# hotspot variant to use
#HOTSPOT_VARIANT=client
# A comment from OpenJDK build system sums it up pretty well:
##   server: normal interpreter, and a tiered C1/C2 compiler
##   client: normal interpreter, and C1 (no C2 compiler)
##   minimal: reduced form of client with optional features stripped out
##   core: normal interpreter only, no compiler
##   zero: C++ based interpreter only, no compiler
##   custom: baseline JVM with no default features
# 'client' JVM starts fast enough and provides the best performance.
# 'zero' JVM provides us with a fallback when ARMv5 sflt JIT stops working completely.

## Boot JDK configs

# Destination Boot JDK directory
#HOSTJDK="$BUILDDIR/jdk-9.0.4"

# Cached archive
#HOSTJDK_FILE="$BUILDDIR/openjdk-9.0.4.tar.gz"

# Download URL
#HOSTJDK_URL="https://download.java.net/java/GA/jdk9/9.0.4/binaries/openjdk-9.0.4_linux-x64_bin.tar.gz"

# OpenJDK 11
if [ "$JDKVER" == "11" ]; then
  # download latest tag
  HG_BASE_URL="https://hg.openjdk.java.net/jdk-updates/jdk11u"
  JAVA_SCM="hg_zip"
  PATCHVER="jdk11"
  AUTOGEN_STYLE="v2"
  # yaay, tested sflt JDK11
  HOSTJDK="$BUILDDIR/zulu11.31.16-ca-jdk11.0.3-linux_aarch32sf"
  HOSTJDK_FILE="$BUILDDIR/zulu11.31.16-ca-jdk11.0.3-linux_aarch32sf.tar.gz"
  HOSTJDK_URL="http://cdn.azul.com/zulu-embedded/bin/zulu11.31.16-ca-jdk11.0.3-linux_aarch32sf.tar.gz"
  IMAGEDIR="$JDKDIR/build/linux-arm-normal-${JDKVM}-${HOTSPOT_DEBUG}/images"
  HOTSPOT_ABI=arm926ejs
  JNI_PATH_FLAGS=
  SOFTFLOAT_FLAGS=
  GA_REPLACE="+9"

# OpenJDK 12/Master+dev
elif [ "$JDKVER" == "12" ]; then
  # download latest tag
  HG_BASE_URL="https://hg.openjdk.java.net/jdk-updates/jdk12u"
  JAVA_SCM="hg_zip"
  PATCHVER="jdk12"
  AUTOGEN_STYLE="v2"
  # yaay, tested sflt JDK11
  HOSTJDK="$BUILDDIR/zulu11.31.16-ca-jdk11.0.3-linux_aarch32sf"
  HOSTJDK_FILE="$BUILDDIR/zulu11.31.16-ca-jdk11.0.3-linux_aarch32sf.tar.gz"
  HOSTJDK_URL="http://cdn.azul.com/zulu-embedded/bin/zulu11.31.16-ca-jdk11.0.3-linux_aarch32sf.tar.gz"
  IMAGEDIR="$JDKDIR/build/linux-arm-${JDKVM}-${HOTSPOT_DEBUG}/images"
  HOTSPOT_ABI=arm-sflt
  JNI_PATH_FLAGS="--with-jni-libpath=/usr/lib/$DEB_HOST_MULTIARCH/jni:/lib/$DEB_HOST_MULTIARCH:/usr/lib/$DEB_HOST_MULTIARCH:/usr/lib/jni:/lib:/usr/lib"
  SOFTFLOAT_FLAGS="--with-sflt=$SFLTPFX"
  if [ "$JDKPLATFORM" == "ev3" ]; then
    SFLT_NEEDED=true
  fi
  GA_REPLACE="+0"

# OpenJDK 13/Master+dev
elif [ "$JDKVER" == "13" ] || [ "$JDKVER" == "tip" ]; then
  # download tip or latest tag
  HG_BASE_URL="https://hg.openjdk.java.net/jdk/jdk"
  JAVA_SCM="hg_zip"
  PATCHVER="jdk13"
  AUTOGEN_STYLE="v2"
  # dogfooding; I'm not entirely happy with it, but I don't know of other sflt JDK12
  HOSTJDK="$BUILDDIR/jdk"
  HOSTJDK_FILE="$BUILDDIR/jdk-ev3.tar.gz"
  HOSTJDK_URL="https://ci.adoptopenjdk.net/view/ev3dev/job/openjdk12_build_ev3_linux/lastSuccessfulBuild/artifact/build/jdk-ev3.tar.gz"
  IMAGEDIR="$JDKDIR/build/linux-arm-${JDKVM}-${HOTSPOT_DEBUG}/images"
  HOTSPOT_ABI=arm-sflt
  JNI_PATH_FLAGS="--with-jni-libpath=/usr/lib/$DEB_HOST_MULTIARCH/jni:/lib/$DEB_HOST_MULTIARCH:/usr/lib/$DEB_HOST_MULTIARCH:/usr/lib/jni:/lib:/usr/lib"
  SOFTFLOAT_FLAGS="--with-sflt=$SFLTPFX"
  if [ "$JDKPLATFORM" == "ev3" ]; then
    SFLT_NEEDED=true
  fi
  GA_REPLACE="+0"

# invalid or unset version
else
  echo "Error! Please specify JDK version to compile via the JDKVER environment variable." >&2
  echo "Acceptable values:" >&2
  echo "JDKVER=11" >&2
  echo "JDKVER=12" >&2
  echo "JDKVER=13" >&2
  echo "JDKVER=tip" >&2
  exit 1
fi
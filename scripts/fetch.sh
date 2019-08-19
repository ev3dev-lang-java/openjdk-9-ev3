#!/bin/bash
set -e

cd "$(dirname ${BASH_SOURCE[0]})"
source config.sh

if [ ! -d "$JDKDIR" ]; then

  #####################
  # Git mirror method #
  #####################
  if [ "$JAVA_SCM" == "git" ]; then
    cd "$BUILDDIR"

    # Identify latest Git tag
    # select git clone target
    if [ "$JDKVER" == "tip" ]; then
      JAVA_TAG="$(git ls-remote --ref "$JAVA_REPO" | cut -f2 | grep 'refs/tags/' | sed 's|refs/tags/||' | \
                      sort -V | grep -v -- '-ga' | tail -n1)"
      JAVA_TARGET="master"
      SUFFIX="ev3-unstable"
    else
      JAVA_TAG="$(git ls-remote --ref "$JAVA_REPO" | cut -f2 | grep 'refs/tags/' | sed 's|refs/tags/||' | \
                      sort -V | grep -B1 -- '-ga' | tail -n2 | head -n1)"
      JAVA_TARGET="$JAVA_TAG"
      SUFFIX="ev3"
    fi

    # download it
    echo "[FETCH] Cloning Java repo from Git"
    git clone --depth "1" --branch "$JAVA_TARGET" "$JAVA_REPO" "$JDKDIR"

    # no get_source.sh is necessary

    # enter the jdk repo
    cd "$JDKDIR"
    JAVA_VERSION="$(echo "$JAVA_TAG" | sed -E "s/^.*jdk-//")-$SUFFIX"
    JAVA_COMMIT="$(git rev-parse HEAD)"
  fi

  # build metadata
  echo "# ev3dev-lang-java openjdk build metadata"  >"$BUILDDIR/metadata"
  echo "JAVA_ORIGIN=\"$JAVA_SCM\""                 >>"$BUILDDIR/metadata"
  echo "JAVA_COMMIT=\"$JAVA_COMMIT\""              >>"$BUILDDIR/metadata"
  echo "JAVA_VERSION=\"$JAVA_VERSION\""            >>"$BUILDDIR/metadata"
  echo "CONFIG_VM=\"$JDKVM\""                      >>"$BUILDDIR/metadata"
  echo "CONFIG_DEBUG=\"$HOTSPOT_DEBUG\""           >>"$BUILDDIR/metadata"
  echo "CONFIG_VERSION=\"$JDKVER\""                >>"$BUILDDIR/metadata"
  echo "CONFIG_PLATFORM=\"$JDKPLATFORM\""          >>"$BUILDDIR/metadata"
  echo "CONFIG_MODULES=\"$JRI_MODULES\""           >>"$BUILDDIR/metadata"
  echo "BUILDER_COMMIT=\"$BUILDER_COMMIT\""        >>"$BUILDDIR/metadata"
  echo "BUILDER_EXTRA=\"$BUILDER_EXTRA\""          >>"$BUILDDIR/metadata"


  echo "[FETCH] Build metadata: "
  cat "$BUILDDIR/metadata"
  echo

  # apply the EV3-specific patches
  echo "[FETCH] Patching the source tree"
  if [ -f "$SCRIPTDIR/${PATCHVER}.patch" ]; then
    patch -p1 -i "$SCRIPTDIR/${PATCHVER}.patch"
  fi

  # debian library path
  if [ -f "$SCRIPTDIR/${PATCHVER}_lib.patch" ]; then
    patch -p1 -i "$SCRIPTDIR/${PATCHVER}_lib.patch"
  fi

  # new patches from building openjdk 12
  if [ -f "$SCRIPTDIR/${PATCHVER}_new.patch" ]; then
    patch -p1 -i "$SCRIPTDIR/${PATCHVER}_new.patch"
  fi

  # use standard breakpoint functionality on ARM
  if [ -f "$SCRIPTDIR/${PATCHVER}_bkpt.patch" ]; then
    patch -p1 -i "$SCRIPTDIR/${PATCHVER}_bkpt.patch"
  fi

  # invalid written JFR files
  if [ -f "$SCRIPTDIR/${PATCHVER}_jfr.patch" ]; then
    patch -p1 -i "$SCRIPTDIR/${PATCHVER}_jfr.patch"
  fi

  # unaligned atomic read causes segfault in test/hotspot/jtreg/vmTestbase/nsk/jvmti/CompiledMethodUnload/compmethunload001/TestDescription.java
  if [ -f "$SCRIPTDIR/${PATCHVER}_cds.patch" ]; then
    patch -p1 -i "$SCRIPTDIR/${PATCHVER}_cds.patch"
  fi

  # store mercurial revision
  echo "$JAVA_COMMIT" > "$JDKDIR/.src-rev"

else
  echo "[FETCH] Directory for JDK repository exists, assuming everything has been done already." 2>&1
fi


if [ ! -d "$SFLTDIR" ] && [ "$SFLT_NEEDED" == "true" ]; then
  # clone the root project
  echo "[FETCH] Cloning SoftFloat repo"
  git clone --depth 1 "$SFLTREPO" "$SFLTDIR"
fi


if [ -d "$ABLDDIR" ]; then
  rm -rf "$ABLDDIR"
fi

# clone the root project
echo "[FETCH] Cloning openjdk-build repo"
git clone --depth 1 "$ABLDREPO" "$ABLDDIR"

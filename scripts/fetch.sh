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

    # Identify latest Git target:

    # * GA model: use latest -ga tag (proper release)
    if [ "$VERSION_POLICY" == "latest_general_availability" ]; then
      JAVA_TAG="$( git ls-remote --ref "$JAVA_REPO" | \
                   cut --fields=2                   | \
                   grep 'refs/tags/'                | \
                   sed 's|refs/tags/||'             | \
                   sort --version-sort              | \
                   grep --before-context=1 -- '-ga' | \
                   tail --lines=2                   | \
                   head --lines=1                       )"
      JAVA_TARGET="$JAVA_TAG"
      SUFFIX="ev3"

    # * Tag model:    use latest tag (mini-release)
    # * Commit model: use latest commit (no guarantee about anything); however use latest tag as the version
    elif [ "$VERSION_POLICY" == "latest_tag" ] || [ "$VERSION_POLICY" == "latest_commit" ]; then
      JAVA_TAG="$( git ls-remote --ref "$JAVA_REPO" | \
                   cut --fields=2                   | \
                   grep 'refs/tags/'                | \
                   sed 's|refs/tags/||'             | \
                   sort --version-sort              | \
                   grep --invert-match -- '-ga'     | \
                   tail --lines=1                       )"

      if [ "$VERSION_POLICY" == "latest_tag" ]; then
        JAVA_TARGET="$JAVA_TAG"
        SUFFIX="ev3-unreleased"
      else
        JAVA_TARGET="master"
        SUFFIX="ev3-dirty"
      fi

    else
    # * Direct model: for JDK9/JDK10; specify the revision directly
      JAVA_TAG="$VERSION_POLICY"
      JAVA_TARGET="$JAVA_TAG"
      SUFFIX="ev3"
    fi

    # override version suffix
    if [ ! -z "$VERSION_SUFFIX" ]; then
      SUFFIX="$VERSION_SUFFIX"
    fi

    # override branch
    if [ ! -z "$JAVA_BRANCH" ]; then
      JAVA_TARGET="$JAVA_BRANCH"
    fi

    # download it
    echo "[FETCH] Cloning Java repo from Git"
    echo "[FETCH] - repo url:   $JAVA_REPO"
    echo "[FETCH] - branch/tag: $JAVA_TARGET"
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
  echo "JAVA_REPO=\"$JAVA_REPO\""                  >>"$BUILDDIR/metadata"
  echo "JAVA_BRANCH=\"$JAVA_TARGET\""              >>"$BUILDDIR/metadata"
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

  PATCHES=""

  # apply the EV3-specific patches
  echo "[FETCH] Patching the source tree"
  if [ -f "$SCRIPTDIR/${PATCHVER}.patch" ]; then
    patch -p1 -i "$SCRIPTDIR/${PATCHVER}.patch"
    PATCHES="$PATCHES main"
  fi

  # replacement for softfloat patch
  if [ -f "$SCRIPTDIR/${PATCHVER}_nosflt.patch" ]; then
    patch -p1 -i "$SCRIPTDIR/${PATCHVER}_nosflt.patch"
    PATCHES="$PATCHES nosflt"
  fi

  # debian library path
  if [ -f "$SCRIPTDIR/${PATCHVER}_lib.patch" ]; then
    patch -p1 -i "$SCRIPTDIR/${PATCHVER}_lib.patch"
    PATCHES="$PATCHES lib"
  fi

  # new patches from building openjdk 12
  if [ -f "$SCRIPTDIR/${PATCHVER}_new.patch" ]; then
    patch -p1 -i "$SCRIPTDIR/${PATCHVER}_new.patch"
    PATCHES="$PATCHES new"
  fi

  # use standard breakpoint functionality on ARM
  if [ -f "$SCRIPTDIR/${PATCHVER}_bkpt.patch" ]; then
    patch -p1 -i "$SCRIPTDIR/${PATCHVER}_bkpt.patch"
    PATCHES="$PATCHES bkpt"
  fi

  # invalid written JFR files
  if [ -f "$SCRIPTDIR/${PATCHVER}_jfr.patch" ]; then
    patch -p1 -i "$SCRIPTDIR/${PATCHVER}_jfr.patch"
    PATCHES="$PATCHES jfr"
  fi

  # unaligned atomic read causes segfault in test/hotspot/jtreg/vmTestbase/nsk/jvmti/CompiledMethodUnload/compmethunload001/TestDescription.java
  if [ -f "$SCRIPTDIR/${PATCHVER}_cds.patch" ]; then
    patch -p1 -i "$SCRIPTDIR/${PATCHVER}_cds.patch"
    PATCHES="$PATCHES cds"
  fi

  # generic broken build
  if [ -f "$SCRIPTDIR/${PATCHVER}_klassinline.patch" ]; then
    patch -p1 -i "$SCRIPTDIR/${PATCHVER}_klassinline.patch"
    PATCHES="$PATCHES klassinline"
  fi

  # write patches to metadata
  echo "[FETCH] Patches applied: $PATCHES"
  echo "JAVA_PATCHES=\"$PATCHES\"" >>"$BUILDDIR/metadata"

  # store mercurial revision
  echo "$JAVA_COMMIT" > "$JDKDIR/.src-rev"

else
  echo "[FETCH] Directory for JDK repository exists, assuming everything has been done already." 2>&1
fi

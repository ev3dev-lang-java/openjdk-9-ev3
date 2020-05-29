#!/bin/bash

set -x
set -e

source /build/metadata

# 11.0.1+13-ev3

if [ -z "$JAVA_PACKAGE_REVISION" ]; then
    JAVA_PACKAGE_REVISION="-1"
fi

DEB_JRI_PREFIX=$(echo "$JAVA_VERSION" | cut -d + -f 1)
NUM_OF_FIELDS=$(echo "$DEB_JRI_PREFIX" | awk -F. "{print NF-1}")
if [ "$NUM_OF_FIELDS" -eq 0 ]; then
    export DEB_JRI_MAJOR=$DEB_JRI_PREFIX
    export DEB_JRI_MINOR=0
    export DEB_JRI_PATCH=0
elif [ "$NUM_OF_FIELDS" -eq 2 ]; then
    export DEB_JRI_MAJOR=$(echo "$DEB_JRI_PREFIX" | cut -d . -f 1)
    export DEB_JRI_MINOR=$(echo "$DEB_JRI_PREFIX" | cut -d . -f 2)
    export DEB_JRI_PATCH=$(echo "$DEB_JRI_PREFIX" | cut -d . -f 3)
else
    echo "Unsupported version string: $JAVA_VERSION" 1>&2
    exit 1
fi
export DEB_JRI_BUILD=$(echo "$JAVA_VERSION" | cut -d + -f 2 | cut -d - -f 1)
export DEB_JRI_PLATFORM=$(echo "$JAVA_VERSION" | cut -d - -f 2)
export DEB_JRI_OLD=$(expr $DEB_JRI_MAJOR - 1)99

if [ -z "$DEB_JRI_MINOR" ]; then
    DEB_JRI_MINOR="0"
fi

if [ -z "$DEB_JRI_PATCH" ]; then
    DEB_JRI_PATCH="0"
fi

PKG="jri-${DEB_JRI_MAJOR}-${DEB_JRI_PLATFORM}"
PKGVER="${DEB_JRI_MAJOR}.${DEB_JRI_MINOR}.${DEB_JRI_PATCH}~${DEB_JRI_BUILD}"
PKGNAME="${PKG}_${PKGVER}"
DATE=$(LC_ALL=C date -R)
if [ -z "$DISTRO" ]; then
    echo "Please choose a target distro." >&2
    exit 1
else
    echo "Building for ev3dev-$DISTRO"
fi

PKGDIR="/build/pkg/$PKGNAME"

rm -rf "/build/pkg"
mkdir "/build/pkg"
cd "/build/pkg"
tar -x -I 'pigz' -f "/build/jri-${DEB_JRI_PLATFORM}.tar.gz" -C "/build/pkg"
mv "/build/pkg/jri" "$PKGDIR"
tar -c -I 'xz -T0 -1' -f "$PKGDIR.orig.tar.xz" "$PKGNAME"
cp -rf /opt/jdkpkg/debian "$PKGDIR"
cd "$PKGDIR"

sed -i -e "s/@@package@@/$PKG/g;s/@@version@@/$PKGVER$JAVA_PACKAGE_REVISION/g;s/@@distro@@/$DISTRO/g;s/@@date@@/$DATE/g" "$PKGDIR/debian/changelog"
sed -i -e "s/@@package@@/$PKG/g;s/@@version@@/$PKGVER$JAVA_PACKAGE_REVISION/g;s/@@distro@@/$DISTRO/g;s/@@date@@/$DATE/g" "$PKGDIR/debian/control"
cd "$PKGDIR"
debuild -b -us -uc --no-sign --buildinfo-option="-O"
cd /build
rm -rf "$PKGDIR"
rm -rf "$PKGDIR.orig.tar.xz"

ln -s "pkg/${PKGNAME}${JAVA_PACKAGE_REVISION}_armel.deb" "/build/jri-for-test.deb"

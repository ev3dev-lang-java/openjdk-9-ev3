#!/bin/bash
set -e

cd "$(dirname ${BASH_SOURCE[0]})"
source config.sh

# enter images directory
cd "$IMAGEDIR"

# clean destinations
echo "[ZIP] Cleaning JRI images"
rm -rf ./jri

# build ev3 runtime image
echo "[ZIP] Building JRI"
if [ "$BOOTCYCLE" = yes ] && [ -f "$IMAGEDIR/jdk/bin/jlink" ]; then
  echo "[ZIP]  using bootcycle'd jlink"
  JLINK_EXE="$IMAGEDIR/jdk/bin/jlink"
elif [ -f "../buildjdk/jdk/bin/jlink" ]; then
  echo "[ZIP]  using bundled jlink"
  JLINK_EXE="../buildjdk/jdk/bin/jlink"
else
  echo "[ZIP]  using external jlink"
  JLINK_EXE="$HOSTJDK/bin/jlink"
fi

"$JLINK_EXE" \
   --module-path ./jmods/ \
   --endian little \
   --compress 0 \
   --no-header-files \
   --no-man-pages \
   --add-modules "$JRI_MODULES" \
   --output ./jri

cp "$BUILDDIR/metadata" "jri/metadata";   echo "TYPE=\"jri\""   >>"jri/metadata"
cp "$BUILDDIR/metadata" "jdk/metadata";   echo "TYPE=\"jdk\""   >>"jdk/metadata"
cp "$BUILDDIR/metadata" "jmods/metadata"; echo "TYPE=\"jmods\"" >>"jmods/metadata"

# remove jmods from jdk
rm -rf jdk/jmods

# create zip files
echo "[ZIP] Creating JRI archive"
tar -cf - jri   | pigz -9 > "$BUILDDIR/jri-$JDKPLATFORM.tar.gz"
echo "[ZIP] Creating JDK archive"
tar -cf - jdk   | pigz -9 > "$BUILDDIR/jdk-$JDKPLATFORM.tar.gz"
echo "[ZIP] Cleaning jmods archive"
tar -cf - jmods | pigz -9 > "$BUILDDIR/jmods-$JDKPLATFORM.tar.gz"

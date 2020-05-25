#!/bin/bash
set -e

cd "$(dirname ${BASH_SOURCE[0]})"
source config.sh

if [ ! -d "$HOSTJDK" ]; then
  if [ ! -e "$HOSTJDK_FILE" ]; then
    echo "[PREPARE] Downloading host JDK"
    wget -nv "$HOSTJDK_URL" -O "$HOSTJDK_FILE"
  else
    echo "[PREPARE] Using cached host JDK archive"
  fi
  echo "[PREPARE] Unpacking host JDK"
  mkdir -p "$(dirname "$HOSTJDK")"
  tar -xf "$HOSTJDK_FILE" -C "$(dirname "$HOSTJDK")"
  if [ ! -z "$HOSTJDK_RENAME_FROM" ]; then
    mv "$HOSTJDK_RENAME_FROM" "$HOSTJDK"
  fi
else
  echo "[PREPARE] Using cached host JDK directory"
fi

if [ ! -d "$JTREG" ]; then
  if [ ! -e "$JTREG_FILE" ]; then
    echo "[PREPARE] Downloading jtreg"
    wget -nv "$JTREG_URL" -O "$JTREG_FILE"
  else
    echo "[PREPARE] Using cached jtreg archive"
  fi
  echo "[PREPARE] Unpacking jtreg"
  tar -xf "$JTREG_FILE" -C "$(dirname "$JTREG")"
else
  echo "[PREPARE] Using cached jtreg directory"
fi

if [ ! -f "$CACERTFILE" ]; then
  echo "[PREPARE] Generating CA certificate database"
  cd "$BUILDDIR"
  wget -nv -N https://github.com/use-sparingly/keyutil/releases/download/0.4.0/keyutil-0.4.0.jar
  wget -nv -N https://raw.githubusercontent.com/curl/curl/master/lib/mk-ca-bundle.pl
  perl mk-ca-bundle.pl ca-bundle.crt
  "$HOSTJDK/bin/java" -jar keyutil-0.4.0.jar --import --new-keystore "$CACERTFILE" --password changeit --force-new-overwrite --import-pem-file ca-bundle.crt
fi

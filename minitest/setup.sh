#!/bin/bash

set -xe
export DEBIAN_FRONTEND=noninteractive
apt-get -qq update
apt-get -qq install --yes --no-install-recommends  /build/jri-for-test.deb

#!/bin/bash

set -e

cd "$( dirname "${BASH_SOURCE[0]}" )"
./setup.sh
./runner.sh

#!/bin/bash

function run_test {
    local TEST="$1"

    echo
    echo "Running test $TEST..."
    pushd "$TEST" >/dev/null 2>&1
    bash run.sh
    RETVAL=$?
    popd >/dev/null 2>&1

    TESTS=$((TESTS+1))
    if [ "$RETVAL" -eq 0 ]; then
        echo "=> SUCCESS"
        SUCCESS=$((SUCCESS+1))
    else
        echo "=> FAILURE"
        FAILURE=$((FAILURE+1))
    fi
}

SUCCESS=0
FAILURE=0
TESTS=0

echo "Mini test suite"

run_test basicStartup
run_test tlsClient

if [ "$FAILURE" -eq 0 ]; then
    echo "All $TESTS tests were successful."
    exit 0
else
    echo "Error: $FAILURE tests out of $TESTS failed."
    exit 1
fi

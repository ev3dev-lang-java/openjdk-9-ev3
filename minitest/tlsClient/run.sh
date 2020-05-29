#!/bin/bash

java -jar ssltest.jar -enabledprotocols TLSv1.3 -check-certificate -verify-hostname github.com | tee /dev/stderr | grep Accepted >/tmp/accepted-ciphers.txt
ACCEPTED="$(wc -l /tmp/accepted-ciphers.txt | cut -d ' ' -f 1)"

if [ "$ACCEPTED" -gt 0 ]; then
    echo "OK: at least one TLSv1.3 cipher passes"
    exit 0
else
    echo "KO: no TLSv1.3 cipher passes"
    exit 1
fi

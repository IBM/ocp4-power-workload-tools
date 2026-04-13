#!/bin/bash

mkdir -p tmp/spicedb
cd tmp/spicedb

curl -O -L https://github.com/authzed/spicedb/archive/refs/tags/v1.51.0.zip

if [[ "$OSTYPE" == "darwin"* ]]
then
    echo "Skipping on Mac (it exists)"
else
    echo "This is not a Mac. Proceeding..."
    dnf install unzip -y
fi

unzip v1.51.0.zip
cd spicedb-1.51.0

go clean -modcache

CGO_ENABLED=0 GOOS=linux GOARCH=ppc64le go build \
    -tags memoryprotection \
    -ldflags="-checklinkname=0 -w -s" \
    -o spicedb-ppc64le \
    ./cmd/spicedb

CGO_ENABLED=0 GOOS=linux GOARCH=s390x go build \
    -tags memoryprotection \
    -ldflags="-checklinkname=0 -w -s" \
    -o spicedb-s390x \
    ./cmd/spicedb

cd ../../..

mkdir -p tmp/grpc-health-probe
cd tmp/grpc-health-probe

curl -O -L https://github.com/authzed/grpc-health-probe/archive/refs/heads/main.zip
unzip main.zip
cd grpc-health-probe-main

CGO_ENABLED=0 GOOS=linux GOARCH=ppc64le go build -o grpc_health_probe-ppc64le -a -tags netgo -ldflags="-w" .
CGO_ENABLED=0 GOOS=linux GOARCH=s390x go build -o grpc_health_probe-s390x -a -tags netgo -ldflags="-w" .
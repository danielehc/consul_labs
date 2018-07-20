#!/usr/bin/env bash

set -x

echo "Running the build script"

if [[ ! $BUILD_DIR ]]; then
		SRC_DIR=consul_dev_cluster4
fi

# go get ./...
go build -o modern_app_web ${SRC_DIR}/src/modern_app_web.go 

find . -name modern_app_web

set +x

exit 0

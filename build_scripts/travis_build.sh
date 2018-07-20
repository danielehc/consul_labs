#!/usr/bin/env bash

set -x

echo "Running the build script"

if [[ ! $BUILD_DIR ]]; then
		SRC_DIR=consul_dev_cluster4
fi

# go get ./...
go build ${SRC_DIR}/src/modern_app_web.go -O modern_app_web

find . -name modern_app_web

set +x

exit 0

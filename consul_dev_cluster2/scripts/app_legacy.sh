#!/usr/bin/env bash

set -x

# Batch Application to Increment key on Redis

LEGACY_COUNTER=`redis-cli -h redis.service.consul INCR legacy_counter`
echo "Legacy counter is now $LEGACY_COUNTER"

set +x

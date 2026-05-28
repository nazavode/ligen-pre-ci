#!/usr/bin/env bash

# Beware: setvars.sh uses global $@ when sourced without arguments;
# make sure to pass at least an argument to avoid forwarding
# docker run args to it:
source /opt/intel/mkl/setvars.sh --force > /dev/null

exec "$@"

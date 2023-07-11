#!/usr/bin/env bash
CPUS=$(getconf _NPROCESSORS_ONLN)
cd ${HOME}/build/openssl
./config --prefix=${HOME}/local --openssldir=${HOME}/local/ssl
make -j${CPUS}
make test
make install
test -x ${HOME}/local/bin/openssl || echo FAIL

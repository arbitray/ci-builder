#!/usr/bin/env bash
set -x

ARCH=$(uname -m)

echo $ARCH

# GOLANG
if [[ ${ARCH} == 'x86_64' ]]; then
  curl -f -L https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz|tar -C /usr/local -xz
elif [[ ${ARCH} == 'aarch64' ]]
then
  curl -f -L https://golang.org/dl/go$GOLANG_VERSION.linux-arm64.tar.gz|tar -C /usr/local -xz
else
  echo "do not support this arch"
  exit 1
fi

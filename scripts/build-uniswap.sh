#!/bin/sh
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
pushd $SCRIPTPATH
cp truffle-config.js $SCRIPTPATH/../node_modules/@uniswap/v2-core/
pushd $SCRIPTPATH/../node_modules/@uniswap/v2-core/
mv build build-tmp
truffle build
rm -rf build
mv build-tmp build
popd
popd

#!/bin/sh
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
pushd $SCRIPTPATH
cp truffle-config.js $SCRIPTPATH/../node_modules/@uniswap/v2-core/
pushd $SCRIPTPATH/../node_modules/@uniswap/v2-core/
rm -rf build
truffle build
popd
popd

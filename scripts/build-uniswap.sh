#!/bin/sh
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd $SCRIPTPATH
cp truffle-config.js $SCRIPTPATH/../node_modules/@uniswap/v2-core/
cd $SCRIPTPATH/../node_modules/@uniswap/v2-core/
rm -rf build
truffle build

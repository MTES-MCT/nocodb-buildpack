#!/bin/bash
# usage: /app/nocodb/run /build/nocodb /build/nodejs

NC_DIR="$1"
NODE_DIR="$2"
cd "$NC_DIR" || return
DEBUG=xc* "$NODE_DIR/bin/node" main.js
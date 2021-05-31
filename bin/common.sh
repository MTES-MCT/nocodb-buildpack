#!/bin/bash

steptxt="----->"
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'                              # No Color
CURL="curl -L --retry 15 --retry-delay 2" # retry for up to 30 seconds

info() {
  echo -e "${GREEN}       $*${NC}"
}

warn() {
  echo -e "${YELLOW} !!    $*${NC}"
}

err() {
  echo -e "${RED} !!    $*${NC}" >&2
}

step() {
  echo "$steptxt $*"
}

start() {
  echo -n "$steptxt $*... "
}

finished() {
  echo "done"
}

function indent() {
  c='s/^/       /'
  case $(uname) in
  Darwin) sed -l "$c" ;; # mac/bsd sed: -l buffers on line boundaries
  *) sed -u "$c" ;;      # unix/gnu sed: -u unbuffered (arbitrary) chunks of data
  esac
}

function install_nodejs() {
  NODEJS_VERSION="$1"
  step "Fetching nodejs $NODEJS_VERSION"
  if [ -f "${CACHE_DIR}/dist/nodejs-$NODEJS_VERSION-linux-x64" ]; then
    info "File already downloaded"
  else
    ${CURL} -o "${CACHE_DIR}/dist/node-v$NODEJS_VERSION-linux-x64.tar.xz" "https://nodejs.org/dist/v$NODEJS_VERSION/node-v$NODEJS_VERSION-linux-x64.tar.xz"
  fi
  if [ -f "${CACHE_DIR}/dist/$NODEJS_VERSION-SHASUMS256.txt" ]; then
    info "Nodejs sha256 sum already checked"
  else
    ${CURL} -o "${CACHE_DIR}/dist/$NODEJS_VERSION-SHASUMS256.txt" "https://nodejs.org/dist/v$NODEJS_VERSION/SHASUMS256.txt"
    cd "${CACHE_DIR}/dist" || return
    grep "node-v$NODEJS_VERSION-linux-x64.tar.xz" "$NODEJS_VERSION-SHASUMS256.txt" | sha256sum -c --strict --status
    info "Nodejs v$NODEJS_VERSION sha256 checksum valid"
  fi
  tar -xJvf "${CACHE_DIR}/dist/node-v$NODEJS_VERSION-linux-x64.tar.xz" -C "${CACHE_DIR}/dist"
  cp -r "${CACHE_DIR}/dist/node-v$NODEJS_VERSION-linux-x64" "${BUILD_DIR}"
  mv "${BUILD_DIR}/node-v$NODEJS_VERSION-linux-x64" "${BUILD_DIR}/nodejs"
  finished
}

function install_nocodb() {
  export "PATH=${BUILD_DIR}/nodejs/bin:$PATH"
  mkdir -p "${CACHE_DIR}/nocodb"
  cd "${CACHE_DIR}/nocodb" || return 
  git clone https://github.com/nocodb/nocodb
  cd "${CACHE_DIR}/nocodb/nocodb/packages/nocodb" || return
  mkdir -p "${CACHE_DIR}/nocodb/cache"
  npm install --cache="${CACHE_DIR}/nocodb/cache" --production
  npm audit fix
  npm run build && npm run docker:build
  npx modclean --patterns="default:*" --ignore="nc-lib-gui/**,dayjs/**,express-status-monitor/**" --run
  rm -rf ./node_modules/sqlite3/deps
  mkdir -p "${NOCODB_PATH}"
  mv "${CACHE_DIR}/nocodb/nocodb/static" "${NOCODB_PATH}"
  mv "${CACHE_DIR}/nocodb/nocodb/packages/nocodb/build" "${NOCODB_PATH}"
  mv "${CACHE_DIR}/nocodb/nocodb/packages/nocodb/dist" "${NOCODB_PATH}"
  mv "${CACHE_DIR}/nocodb/nocodb/packages/nocodb/node_modules" "${NOCODB_PATH}"
  mv "${CACHE_DIR}/nocodb/nocodb/packages/nocodb/package.json" "${NOCODB_PATH}"
  mv "${CACHE_DIR}/nocodb/nocodb/packages/nocodb/package-lock.json" "${NOCODB_PATH}"
  mv "${CACHE_DIR}/nocodb/nocodb/packages/nocodb/docker/main.js" "${NOCODB_PATH}"
}

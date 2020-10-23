#!/bin/bash

set -e

export NWJS_BRANCH="$1"
export WORKDIR="/usr/docker"
export NWJSDIR="${WORKDIR}/nwjs"
export DEPOT_TOOLS_DIRECTORY="${WORKDIR}/depot_tools"
export PATH=${PATH}:${DEPOT_TOOLS_DIRECTORY}

function getGitRepository {
  REPO_URL="$1"
  REPO_DIR="$2"
  rm -rf "$REPO_DIR"
  git clone --depth 1 --branch "${NWJS_BRANCH}" "$REPO_URL" "$REPO_DIR"
}

function getNwjsRepository {
  cd $NWJSDIR/src
  gclient sync --reset --with_branch_heads --nohooks -D
  sh -c 'echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections'
  $NWJSDIR/src/build/install-build-deps.sh --arm --no-prompt --no-backwards-compatible
  $NWJSDIR/src/build/linux/sysroot_scripts/install-sysroot.py --arch=arm
  getGitRepository "https://github.com/nwjs/nw.js" "$NWJSDIR/src/content/nw"
  getGitRepository "https://github.com/nwjs/node" "$NWJSDIR/src/third_party/node-nw"
  getGitRepository "https://github.com/nwjs/v8" "$NWJSDIR/src/v8"
  gclient runhooks
}

getNwjsRepository

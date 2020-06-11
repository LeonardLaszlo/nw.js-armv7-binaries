#!/bin/bash

set -e

export NWJS_BRANCH="nw44"
export WORKDIR="/usr/docker"
export NWJSDIR="${WORKDIR}/nwjs"
export DEPOT_TOOLS_DIRECTORY="${WORKDIR}/depot_tools"
export PATH=${PATH}:${DEPOT_TOOLS_DIRECTORY}

function configureGclientForNwjs {
  mkdir -p "$NWJSDIR" && cd "$NWJSDIR"
  cat <<CONFIG > ".gclient"
solutions = [
  { "name"        : 'src',
    "url"         : 'https://github.com/nwjs/chromium.src.git@origin/${NWJS_BRANCH}',
    "deps_file"   : 'DEPS',
    "managed"     : True,
    "custom_deps" : {
        "src/third_party/WebKit/LayoutTests": None,
        "src/chrome_frame/tools/test/reference_build/chrome": None,
        "src/chrome_frame/tools/test/reference_build/chrome_win": None,
        "src/chrome/tools/test/reference_build/chrome": None,
        "src/chrome/tools/test/reference_build/chrome_linux": None,
        "src/chrome/tools/test/reference_build/chrome_mac": None,
        "src/chrome/tools/test/reference_build/chrome_win": None,
    },
    "custom_vars": {},
  },
]
CONFIG
}

function getGitRepository {
  REPO_URL="$1"
  REPO_DIR="$2"
  rm -rf "$REPO_DIR"
  git clone --depth 1 --branch "${NWJS_BRANCH}" "$REPO_URL" "$REPO_DIR"
}

function getNwjsRepository {
  cd $NWJSDIR/src
  gclient sync --reset --with_branch_heads --nohooks
  sh -c 'echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections'
  $NWJSDIR/src/build/install-build-deps.sh --arm --no-prompt --no-backwards-compatible
  $NWJSDIR/src/build/linux/sysroot_scripts/install-sysroot.py --arch=arm
  gclient runhooks
}

configureGclientForNwjs
getGitRepository "https://github.com/nwjs/nw.js" "$NWJSDIR/src/content/nw"
getGitRepository "https://github.com/nwjs/node" "$NWJSDIR/src/third_party/node-nw"
getGitRepository "https://github.com/nwjs/v8" "$NWJSDIR/src/v8"
getNwjsRepository

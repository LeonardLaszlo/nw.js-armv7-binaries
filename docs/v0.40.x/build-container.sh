#!/bin/bash

set -e

export NWJS_BRANCH="nw40"
export WORKDIR="/usr/docker"
export NWJSDIR="${WORKDIR}/nwjs"
export DEPOT_TOOLS_DIRECTORY="${WORKDIR}/depot_tools"
export PATH=${PATH}:${DEPOT_TOOLS_DIRECTORY}

export DEPOT_TOOLS_REPO="https://chromium.googlesource.com/chromium/tools/depot_tools.git"

function getNecessaryUbuntuPackages {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get -y upgrade
  apt-get -y install apt-utils git curl lsb-release sudo tzdata
  echo "Europe/Zurich" > /etc/timezone
  dpkg-reconfigure -f noninteractive tzdata
  apt-get -y install python
  apt-get autoclean
  apt-get autoremove
  git config --global user.email "you@example.com"
  git config --global user.name "Your Name"
}

function getDepotTools {
  git clone --depth 1 "$DEPOT_TOOLS_REPO" "$DEPOT_TOOLS_DIRECTORY"
}

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
  mkdir -p "$REPO_DIR"
  git clone --depth 1 --branch "${NWJS_BRANCH}" "$REPO_URL" "$REPO_DIR"
}

function getNwjsRepository {
  cd $NWJSDIR/src
  gclient sync --with_branch_heads --nohooks
  sh -c 'echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections'
  $NWJSDIR/src/build/install-build-deps.sh --arm --no-prompt --no-backwards-compatible
  $NWJSDIR/src/build/linux/sysroot_scripts/install-sysroot.py --arch=arm
  gclient runhooks
}

getNecessaryUbuntuPackages
getDepotTools
configureGclientForNwjs
getNwjsRepository
getGitRepository "https://github.com/nwjs/nw.js" "$NWJSDIR/src/content/nw"
getGitRepository "https://github.com/nwjs/node" "$NWJSDIR/src/third_party/node-nw"
getGitRepository "https://github.com/nwjs/v8" "$NWJSDIR/src/v8"

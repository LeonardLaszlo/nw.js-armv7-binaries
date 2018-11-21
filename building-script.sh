#!/bin/bash

# scp -P 3022 ~/Documents/github/nw.js-armv7-binaries/scripts/building-script.sh ubuntu@127.0.0.1:
# export NWJS_BRANCH="$(curl https://api.github.com/repos/nwjs/nw.js | grep -Po '(?<="default_branch": ")[^"]*')"

set -e

export NWJS_BRANCH=nw32

CHROMIUM_PATCHES=(
deee0544bf6a380aefc414622186e2c0c2d4077a
ef3b888560bce97a4120ac4771454b43f1216bfe
)

NODE_WEBKIT_PATCHES=(
84e6d0be845dbd92cb9ac3b885f1e5c711da0548
f593ab464481b0ba246ebc330c7f5d21622eb879
)

export GYP_CROSSCOMPILE="1"
export GYP_DEFINES="is_debug=false is_component_ffmpeg=true target_arch=arm target_cpu=\"arm\" arm_float_abi=hard"
export GN_ARGS="nwjs_sdk=false enable_nacl=false ffmpeg_branding=\"Chrome\""
export GYP_CHROMIUM_NO_ACTION=1

export DEPOT_TOOLS_DIRECTORY=$HOME/depot_tools
export NWJS=$HOME/nwjs
export PATH=$PATH:$DEPOT_TOOLS_DIRECTORY

export LANGUAGE="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_TIME="en_US.UTF-8"
export LC_MONETARY="en_US.UTF-8"
export LC_ADDRESS="en_US.UTF-8"
export LC_TELEPHONE="en_US.UTF-8"
export LC_NAME="en_US.UTF-8"
export LC_MEASUREMENT="en_US.UTF-8"
export LC_IDENTIFICATION="en_US.UTF-8"
export LC_NUMERIC="en_US.UTF-8"
export LC_PAPER="en_US.UTF-8"
export LANG="en_US.UTF-8"

export RED='\033[0;31m'
export NC='\033[0m'

function updateAndInstallMissingUbuntuPackages {
  sudo apt-get update
  sudo apt-get upgrade
  sudo apt-get install git htop sysstat openssh-server python
  sudo apt-get autoclean
  sudo apt-get autoremove
}

function configureGit {
  git config --global user.name "Leonard Laszlo"
  git config --global user.email "laslaul@yahoo.com"
  git config --global core.autocrlf false
  git config --global core.filemode false
  git config --global color.ui true
}

function getOrUpdateDepotTools {
  if [ -d "$DEPOT_TOOLS_DIRECTORY" ]; then
    echo -e "${RED}Update depot tools${NC}"
    cd $DEPOT_TOOLS_DIRECTORY
    git pull
  else
    echo -e "${RED}Clone depot tools${NC}"
    cd $HOME
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
  fi
}

function createGclientConfig {
  echo -e "${RED}Create gclient config${NC}"
  mkdir -p $NWJS
  cd $NWJS
  gclient config --name=src https://github.com/nwjs/chromium.src.git@origin/$NWJS_BRANCH
}

function updateCustomDependencies {
  echo -e "${RED}Update gclient config custom dependencies${NC}"
  cp .gclient .gclient.bak
  CUSTOM_DEPS='        "src/third_party/WebKit/LayoutTests": None,
          "src/chrome_frame/tools/test/reference_build/chrome": None,
          "src/chrome_frame/tools/test/reference_build/chrome_win": None,
          "src/chrome/tools/test/reference_build/chrome": None,
          "src/chrome/tools/test/reference_build/chrome_linux": None,
          "src/chrome/tools/test/reference_build/chrome_mac": None,
          "src/chrome/tools/test/reference_build/chrome_win": None,'
  awk -v values="${CUSTOM_DEPS}" '/custom_deps/ { print; print values; next }1' .gclient | cat > .gclient.temp
  mv .gclient.temp .gclient
}

function getOrUpdateGitRepository {
  REPO_URL=$1
  REPO_DIR=$2
  echo -e "${RED}Get or update $REPO_DIR${NC}"
  if [ -d $REPO_DIR ]; then
    echo -e "${RED}Update $REPO_DIR${NC}"
    cd $REPO_DIR
    git fetch --tags --prune
    git reset --hard HEAD
    # git am --abort || true
    git checkout $NWJS_BRANCH
    git reset --hard origin/$NWJS_BRANCH
    # git clean -fdx
    git status
  else
    echo -e "${RED}Clone $REPO_DIR${NC}"
    mkdir -p $REPO_DIR
    git clone $REPO_URL $REPO_DIR
    cd $REPO_DIR
    git checkout $NWJS_BRANCH
  fi
}

function updateNwjsRepository {
  echo -e "${RED}Update NWJS repository${NC}"
  cd $NWJS/src
  # git clean -fdx
  gclient sync --reset --with_branch_heads --nohooks
  sudo sh -c 'echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections'
  ./build/install-build-deps.sh --arm --no-prompt
}

function getAndApplyPatches {
  echo -e "${RED}Get and apply patches from @jtg-gg${NC}"
  cd $NWJS/src
  for COMMIT in ${CHROMIUM_PATCHES[@]}; do
    curl -s https://github.com/jtg-gg/chromium.src/commit/$COMMIT.patch | git am
  done

  cd $NWJS/src/content/nw/
  for COMMIT in ${NODE_WEBKIT_PATCHES[@]}; do
    curl -s https://github.com/jtg-gg/node-webkit/commit/$COMMIT.patch | git am
  done
}

function runHooks {
  echo -e "${RED}Run hooks${NC}"
  cd $NWJS/src
  gclient runhooks
  gn gen out_gn_arm/nw --args="$GN_ARGS"
  export GYP_CHROMIUM_NO_ACTION=0
  python build/gyp_chromium -Goutput_dir=out_gn_arm -I third_party/node-nw/build/common.gypi third_party/node-nw/node.gyp
}

function build {
  echo -e "${RED}Build${NC}"
  ninja -C out_gn_arm/nw nwjs
  ninja -C out_gn_arm/nw v8_libplatform
  ninja -C out_gn_arm/Release node
  ninja -C out_gn_arm/nw copy_node
  ninja -C out_gn_arm/nw dump
  ninja -C out_gn_arm/nw dist
}

# updateAndInstallMissingUbuntuPackages
# configureGit
# getOrUpdateDepotTools
createGclientConfig
updateCustomDependencies
getOrUpdateGitRepository "https://github.com/nwjs/nw.js" "$NWJS/src/content/nw"
getOrUpdateGitRepository "https://github.com/nwjs/node" "$NWJS/src/third_party/node"
getOrUpdateGitRepository "https://github.com/nwjs/v8" "$NWJS/src/v8"
updateNwjsRepository
getAndApplyPatches
runHooks
build

mkdir -p $NWJS/$NWJS_BRANCH

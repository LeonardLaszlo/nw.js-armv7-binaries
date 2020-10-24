#!/bin/bash

# scp -P 3022 ~/Documents/github/nw.js-armv7-binaries/building-script.sh ubuntu@127.0.0.1:
# export NWJS_BRANCH="$(curl https://api.github.com/repos/nwjs/nw.js | grep -Po '(?<="default_branch": ")[^"]*')"

# sudo visudo
# ubuntu ALL=(ALL) NOPASSWD:ALL

set -e

export NWJS_BRANCH=nw28
# 8c13d9d6de27201ed71529f77f38b39e0aafc184
CHROMIUM_PATCHES=(
65f2215706692e438ca3570be640ed724ae37eaf
2a3ca533a4dd2552889bd18cd4343809f13876c4
8c13d9d6de27201ed71529f77f38b39e0aafc184
5e4bd4d9d03f81623074334bf030d13fce968c1b
58c7eb31c1e9390325da21ccc7f718f1b1b019d2
cdc6ede7e5e4979ebbcc58492c7b576a07350152
97bd5cac6682dbf1e23bdf276257043bc2d7d533
)

NODE_WEBKIT_PATCHES=(
76770752e362b83b127ac4bf3aacc0c9a81bd590
a59ff4c4f7ede3b47411719e41c59332b25b7259
11dcb9c775e43c78eb8136148e23ffe3b15d737e
c87b16766cda3f0af1ffa76b2b24390d77a005e0
d480e6dcf6e49fd64200fd347d406554e76ef72e
42e15aeaf9b47447023d866fd94c82774327c49b
)

export GYP_CROSSCOMPILE="1"
export GYP_DEFINES="is_debug=false is_component_ffmpeg=true target_arch=arm target_cpu=\"arm\" arm_float_abi=hard"
export GN_ARGS="nwjs_sdk=false enable_nacl=false" #  ffmpeg_branding=\"Chrome\"
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
  sudo apt-get -y upgrade
  sudo apt-get -y install git htop sysstat openssh-server python curl
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
    cd "$DEPOT_TOOLS_DIRECTORY"
    git pull
  else
    echo -e "${RED}Clone depot tools${NC}"
    cd "$HOME"
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
  fi
}

function createGclientConfig {
  echo -e "${RED}Create gclient config${NC}"
  mkdir -p "$NWJS"
  cd "$NWJS"
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
  if [ -d "$REPO_DIR" ]; then
    echo -e "${RED}Update $REPO_DIR${NC}"
    cd "$REPO_DIR"
    git fetch --tags --prune
    git reset --hard HEAD
    # git am --abort || true
    git checkout $NWJS_BRANCH
    git reset --hard origin/$NWJS_BRANCH
    # git clean -fdx
    git status
  else
    echo -e "${RED}Clone $REPO_DIR${NC}"
    mkdir -p "$REPO_DIR"
    git clone "$REPO_URL" "$REPO_DIR"
    cd "$REPO_DIR"
    git checkout "$NWJS_BRANCH"
  fi
}

function updateNwjsRepository {
  echo -e "${RED}Update NWJS repository${NC}"
  cd "$NWJS"/src
  gclient sync --reset --with_branch_heads --nohooks
  cd "$NWJS"/src
  sudo sh -c 'echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections'
  "$NWJS"/src/build/install-build-deps.sh --arm --no-prompt
}

function getAndApplyPatches {
  echo -e "${RED}Get and apply patches from @jtg-gg${NC}"
  cd "$NWJS"/src
  for COMMIT in "${CHROMIUM_PATCHES[@]}"; do
    curl -s https://github.com/jtg-gg/chromium.src/commit/"$COMMIT".patch | git am
  done

  cd "$NWJS"/src/content/nw/
  for COMMIT in "${NODE_WEBKIT_PATCHES[@]}"; do
    curl -s https://github.com/jtg-gg/node-webkit/commit/"$COMMIT".patch | git am
  done
}

function runHooks {
  echo -e "${RED}Run hooks${NC}"
  cd "$NWJS"/src
  gclient runhooks
  gn gen out_gn_arm/nw --args="$GN_ARGS"
  export GYP_CHROMIUM_NO_ACTION=0
  python build/gyp_chromium -Goutput_dir=out_gn_arm -I third_party/node-nw/common.gypi third_party/node-nw/node.gyp
}

function build {
  echo -e "${RED}Build${NC}"
  cd "$NWJS"/src
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
# createGclientConfig
# updateCustomDependencies
# getOrUpdateGitRepository "https://github.com/nwjs/nw.js" "$NWJS/src/content/nw"
# getOrUpdateGitRepository "https://github.com/nwjs/node" "$NWJS/src/third_party/node-nw"
# getOrUpdateGitRepository "https://github.com/nwjs/v8" "$NWJS/src/v8"
# updateNwjsRepository
# getAndApplyPatches

# remove manually the following line:
# +            '../nw/obj/buildtools/third_party/libunwind/libunwind/*.o'
# from nwjs/src/content/nw/patch/patches/node.patch

runHooks
build

mkdir -p "$NWJS"/"$NWJS_BRANCH"

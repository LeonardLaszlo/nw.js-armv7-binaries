#!/bin/bash

# scp -P 3022 ~/Documents/github/nw.js-armv7-binaries/scripts/building-script.sh ubuntu@127.0.0.1:
# export NWJS_BRANCH="$(curl https://api.github.com/repos/nwjs/nw.js | grep -Po '(?<="default_branch": ")[^"]*')"

set -e

export NWJS_BRANCH=nw33

CHROMIUM_PATCHES=(
fe84048a681bf82b6d0b5dcb106047416f637e80
0ae6c0ea6a3dd41137e4c79fdd76782b494d902f
86fd0cc5bba9d5a29200939c0ce51e3d7a88e1e8
03439d024a0e0710f1aa643cf306ecef7a99851e
38d223bee64d375736f7239475a6c348bc083ddd
4a01e095065f92c658882e3ca7167013336a1eaf
e9de7508498657b3c9d86deb25a9470b8b8165b1
d0d1fa043be6afde8b54951d2a31d78991f18650
aaeb74aff7786a514ebaf3e1bccf3bd660efcff1
5924b1f519f966c5659b4988c2e7512a128c6a9a
cd2c081ee4048e21a35cca16eb8d44f9d66bd81a
5955bdba71efe837b9e72dd4794f95e1124ab8a7
82d53126cf86d64dbfab71591660ec49616b5282
16219181323d41817b3bc1291a5c2d01768daf45
36c907888d4da3c27c77ce17eba1132b7994637b
3805a44f70ca50e80af9464e99a3e1ff2bc99d42
c8706c0fd2eeb5782efcf1eb3b62108b9cc4408c
765aff9833cd34faedc45abdefa01e8584072458
f5966f10581982fb3ff116b61f42c670267c00fa
d8db2d35aea619ff66c8d29091fa642854a17fb1
80e563a1e68fab5d497dcb552e2bafed8d217f56
003022eebb659b1f571b3df0e97bcf503d844bd1
)

NODE_WEBKIT_PATCHES=(
62e89c34ecdaca4fdacb878ebc5e511669052c2c
71c87ea8fb0e64173b9be7d655e0666083f55d33
4c66c33cdbf1432e5a3798f37bb5f775c2d22981
2ada203f329342c18676cfa79d27dc093d354288
9ade4e7493a24b91ff350ae39c32ca936b91d028
dfc7e972155f8f4f9122250f2af78b904cfdaafb
993ec4bb279bd5fc2c0c9e3e11a521f8dda8f215
694c9f08c0772e0f132ce37dae92c69ab3022dd8
790e284e078e5f4342e05957b3bb89379fbe185e
2139b3efb04288b3532d09038e9f3080109b2a8f
191e94a54e8b553b256dd26be1030e4810aaf16a
73a41445fa00251b348820a8b7d305574d9c73ec
2ff95c4e1e8ea3a31137257b12c25eee1293e699
2d58167de97b8ffd2aaa8847cda523b1258c11d5
f518df35066e5d75000fa2b4bb9bcf3183a3ac7c
c4def3785d9a9b5cb028648f71ddd3612ac257fd
56cc85ea956ad2a42f3115be4955a10469ed36a6
7c2c0c2d6b43590d71bc1f1cc07566ab36ca8eba
b85dd85158e9efdca7db1d1b582535800d37a701
9d7b042cb041e28b0b886e80a239b64926f8591e
644cbfafd6f04e438b64c23c9c545e229b0b3ca5
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
  cd $NWJS/src
  sudo sh -c 'echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections'
  $NWJS/src/build/install-build-deps.sh --arm --no-prompt
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
# createGclientConfig
# updateCustomDependencies
getOrUpdateGitRepository "https://github.com/nwjs/nw.js" "$NWJS/src/content/nw"
getOrUpdateGitRepository "https://github.com/nwjs/node" "$NWJS/src/third_party/node"
getOrUpdateGitRepository "https://github.com/nwjs/v8" "$NWJS/src/v8"
updateNwjsRepository
getAndApplyPatches
runHooks
build

mkdir -p $NWJS/$NWJS_BRANCH

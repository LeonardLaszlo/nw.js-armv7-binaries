#!/bin/bash

set -e

# scp -P 3022 ~/Documents/github/nw.js-armv7-binaries/scripts/building-script.sh ubuntu@127.0.0.1:

# export NWJS_BRANCH="$(curl https://api.github.com/repos/nwjs/nw.js | grep -Po '(?<="default_branch": ")[^"]*')"
export NWJS_BRANCH=nw29

CHROMIUM_PATCHES=(
d14865047a33d7dc5a01cf4de08619af5326006d
3ebdc70e5ddd3028f6aa64675392d6c807dd61d5
35b7888c5bc1986a5cba3ac3f2acbfe3f47aa7b0
31ff74c3a5dd014320381119d1737dc9e1552304
762792453232268a3f1d2b9f8c5ea57cfc9044dd
70c3ecd89b8547485eba91c4ac4ec460882d2e0b
)

NODE_WEBKIT_PATCHES=(
7abc0c02717924d6afc8c065f1891fcdcaafcd3a
0eac6226bc0e8981e680812aecb87408f69f8aa1
b4c10577b99a647d940d07b3fca9ed263dc8ab42
bf588661ac2553227c755f40af711f913bb984bd
270e1cd7f6245b70482bf7404e9e9e5d9aef39cb
65db488b030c661c075cc140b91c3b6e3a4d9d06
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


sudo apt-get update &&
sudo apt-get upgrade --yes --force-yes &&
sudo apt-get install git htop sysstat openssh-server python --yes --force-yes &&
sudo apt-get autoclean --yes --force-yes &&
sudo apt-get autoremove --yes --force-yes &&

if [ -d "$DEPOT_TOOLS_DIRECTORY" ]; then
  cd $DEPOT_TOOLS_DIRECTORY
  git pull
else
  cd $HOME
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
fi

git config --global user.name "Leonard Laszlo"
git config --global user.email "laslaul@yahoo.com"
git config --global core.autocrlf false
git config --global core.filemode false
git config --global color.ui true

mkdir -p $NWJS
cd $NWJS
gclient config --name=src https://github.com/nwjs/chromium.src.git@origin/$NWJS_BRANCH

cp .gclient .gclient.old

# replace custom_deps with:
# "custom_deps" : {
#     "src/third_party/WebKit/LayoutTests": None,
#     "src/chrome_frame/tools/test/reference_build/chrome": None,
#     "src/chrome_frame/tools/test/reference_build/chrome_win": None,
#     "src/chrome/tools/test/reference_build/chrome": None,
#     "src/chrome/tools/test/reference_build/chrome_linux": None,
#     "src/chrome/tools/test/reference_build/chrome_mac": None,
#     "src/chrome/tools/test/reference_build/chrome_win": None,
# }
export CUSTOM_DEPS='        "src/third_party/WebKit/LayoutTests": None,
        "src/chrome_frame/tools/test/reference_build/chrome": None,
        "src/chrome_frame/tools/test/reference_build/chrome_win": None,
        "src/chrome/tools/test/reference_build/chrome": None,
        "src/chrome/tools/test/reference_build/chrome_linux": None,
        "src/chrome/tools/test/reference_build/chrome_mac": None,
        "src/chrome/tools/test/reference_build/chrome_win": None,'

awk -v values="${CUSTOM_DEPS}" '/custom_deps/ { print; print values; next }1' .gclient | cat > .gclient.temp
cp .gclient.temp .gclient

if [ -d "$NWJS/src/content/nw" ]; then
  cd $NWJS/src/content/nw
  git fetch --tags --prune
  git am --abort || true
  git checkout $NWJS_BRANCH
  git reset --hard origin/$NWJS_BRANCH
else
  mkdir -p $NWJS/src/content/nw
  git clone https://github.com/nwjs/nw.js $NWJS/src/content/nw
  cd $NWJS/src/content/nw
  git checkout "${DEFAULT_BRANCH}"
fi

if [ -d "$NWJS/src/third_party/node" ]; then
  cd $NWJS/src/third_party/node
  git fetch --tags --prune
  git am --abort || true
  git checkout $NWJS_BRANCH
  git reset --hard origin/$NWJS_BRANCH
else
  mkdir -p $NWJS/src/third_party/node
  git clone https://github.com/nwjs/node $NWJS/src/third_party/node
  cd $NWJS/src/third_party/node
  git checkout $NWJS_BRANCH
fi

if [ -d "$NWJS/src/v8" ]; then
  cd $NWJS/src/v8
  git fetch --tags --prune
  git am --abort || true
  git checkout $NWJS_BRANCH
  git reset --hard origin/$NWJS_BRANCH
else
  mkdir -p $NWJS/src/v8
  git clone https://github.com/nwjs/v8 $NWJS/src/v8
  cd $NWJS/src/v8
  git checkout $NWJS_BRANCH
fi

cd $NWJS/src
gclient sync --reset --with_branch_heads --nohooks
sudo sh -c 'echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections'
./build/install-build-deps.sh --arm --no-prompt

# ---------------------------------------
# Get and apply patches from @jtg-gg
# ---------------------------------------

for COMMIT in ${CHROMIUM_PATCHES[@]}; do
  curl -s https://github.com/jtg-gg/chromium.src/commit/$COMMIT.patch | git am
done

cd $NWJS/src/content/nw/

for COMMIT in ${NODE_WEBKIT_PATCHES[@]}; do
  curl -s https://github.com/jtg-gg/node-webkit/commit/$COMMIT.patch | git am
done

cd $NWJS/src
gclient runhooks
gn gen out_gn_arm/nw --args="$GN_ARGS"
export GYP_CHROMIUM_NO_ACTION=0
python build/gyp_chromium -Goutput_dir=out_gn_arm -I third_party/node-nw/build/common.gypi third_party/node-nw/node.gyp

# Build
ninja -C out_gn_arm/nw nwjs
ninja -C out_gn_arm/nw v8_libplatform
ninja -C out_gn_arm/Release node
ninja -C out_gn_arm/nw copy_node
ninja -C out_gn_arm/nw dump
ninja -C out_gn_arm/nw dist

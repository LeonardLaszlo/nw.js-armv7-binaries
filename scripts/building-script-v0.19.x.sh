#!/bin/sh

sudo apt-get update -qq
sudo apt-get upgrade -qq
sudo apt-get install git curl -qq

git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH=$PATH:"$(pwd)"/depot_tools

mkdir -p "$(pwd)"/nwjs
export NWJS="$(pwd)"/nwjs
cd $NWJS

# get default branch of NW.js
# export DEFAULT_BRANCH="$(curl https://api.github.com/repos/nwjs/nw.js | grep -Po '(?<="default_branch": ")[^"]*')"

DEFAULT_BRANCH=nw19

gclient config --name=src https://github.com/nwjs/chromium.src.git@origin/"${DEFAULT_BRANCH}"

# export MAGIC='"src/third_party/WebKit/LayoutTests": None, "src/chrome_frame/tools/test/reference_build/chrome": None, "src/chrome_frame/tools/test/reference_build/chrome_win": None, "src/chrome/tools/test/reference_build/chrome": None, "src/chrome/tools/test/reference_build/chrome_linux": None, "src/chrome/tools/test/reference_build/chrome_mac": None, "src/chrome/tools/test/reference_build/chrome_win": None,'

# awk -v values="${MAGIC}" '/custom_deps/ { print; print values; next }1' .gclient | cat > .gclient.temp
# mv .gclient.temp .gclient

# replace custom_deps manually with:

# "custom_deps" : {
#     "src/third_party/WebKit/LayoutTests": None,
#     "src/chrome_frame/tools/test/reference_build/chrome": None,
#     "src/chrome_frame/tools/test/reference_build/chrome_win": None,
#     "src/chrome/tools/test/reference_build/chrome": None,
#     "src/chrome/tools/test/reference_build/chrome_linux": None,
#     "src/chrome/tools/test/reference_build/chrome_mac": None,
#     "src/chrome/tools/test/reference_build/chrome_win": None,
# }

# clone some stuff
mkdir -p $NWJS/src/content/nw
mkdir -p $NWJS/src/third_party/node
mkdir -p $NWJS/src/v8
git clone https://github.com/nwjs/nw.js $NWJS/src/content/nw
git clone https://github.com/nwjs/node $NWJS/src/third_party/node
git clone https://github.com/nwjs/v8 $NWJS/src/v8
cd $NWJS/src/content/nw
git checkout "${DEFAULT_BRANCH}"
cd $NWJS/src/third_party/node
git checkout "${DEFAULT_BRANCH}"
cd $NWJS/src/v8
git checkout "${DEFAULT_BRANCH}"
cd $NWJS

export GYP_CROSSCOMPILE="1"
export GYP_DEFINES="target_arch=arm arm_float_abi=hard nwjs_sdk=1 disable_nacl=0 buildtype=Official"
export GN_ARGS="is_debug=false is_component_ffmpeg=true enable_nacl=true is_official_build=true target_cpu=\"arm\" ffmpeg_branding=\"Chrome\""

export GYP_CHROMIUM_NO_ACTION=1
gclient sync --reset --with_branch_heads

cd $NWJS/src
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
./build/install-build-deps.sh --arm --no-prompt
./build/linux/sysroot_scripts/install-sysroot.py --arch=arm

# ---------------------------------------
# Get and apply patches from @jtg-gg
# ---------------------------------------

# [Build] add node build tools for linux arm
curl https://github.com/jtg-gg/chromium.src/commit/5ecee7af1d0beee617f28306101329a3b300face.patch | git am
# [PATCH] [Build][gn] add support for linux arm binary strip
curl https://github.com/jtg-gg/chromium.src/commit/c270ee74e80bb993df00f0d929a00fce137a2cb4.patch | git am
# [Linux][arm] disable the runtime check
curl https://github.com/jtg-gg/chromium.src/commit/25bc987de045616ca04d2c4d2c0d502b06907dd4.patch | git am
# [PATCH] Update DEPS
# This one might be unnecessary
# curl https://github.com/jtg-gg/chromium.src/commit/887854c0698e3a655f589b190143d65b9e89a9c2.patch | git am

cd $NWJS/src/content/nw/

# [Build] add patches for Linux arm build
curl https://github.com/jtg-gg/node-webkit/commit/a06a37ce92545aecab5f10dd6a743c08e916d1ac.patch | git am
# [Build][Linux] add support for linux arm binary strip
curl https://github.com/jtg-gg/node-webkit/commit/7dbcd433cf5ecca238c9fc1e3d6f095716328b7c.patch | git am

cd $NWJS/src

gclient runhooks
gn gen out_gn_arm/nw --args="$GN_ARGS"
export GYP_CHROMIUM_NO_ACTION=0
python build/gyp_chromium -Goutput_dir=out_gn_arm -I third_party/node/build/common.gypi third_party/node/node.gyp

# Build
ninja -C out_gn_arm/nw nwjs
ninja -C out_gn_arm/nw v8_libplatform
ninja -C out_gn_arm/Release node
ninja -C out_gn_arm/nw copy_node
ninja -C out_gn_arm/nw dist

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
export DEFAULT_BRANCH="$(curl https://api.github.com/repos/nwjs/nw.js | grep -Po '(?<="default_branch": ")[^"]*')"

gclient config --name=src https://github.com/nwjs/chromium.src.git@origin/"${DEFAULT_BRANCH}"

export MAGIC='"src/third_party/WebKit/LayoutTests": None, "src/chrome_frame/tools/test/reference_build/chrome": None, "src/chrome_frame/tools/test/reference_build/chrome_win": None, "src/chrome/tools/test/reference_build/chrome": None, "src/chrome/tools/test/reference_build/chrome_linux": None, "src/chrome/tools/test/reference_build/chrome_mac": None, "src/chrome/tools/test/reference_build/chrome_win": None,'

awk -v values="${MAGIC}" '/custom_deps/ { print; print values; next }1' .gclient | cat > .gclient.temp
mv .gclient.temp .gclient

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

cd $NWJS/src
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
curl https://github.com/jtg-gg/chromium.src/commit/72b35ecdf9c9f5724435acb75d07c934d5537578.patch | git am
# [PATCH] [Build][gn] add support for linux arm binary strip
curl https://github.com/jtg-gg/chromium.src/commit/76d20e9dac4a76df2d0547a805a4d477830376cc.patch | git am
# [PATCH] Update DEPS
curl https://github.com/jtg-gg/chromium.src/commit/78a4f0d694df747a1a230f73937b70e817b72930.patch | git am
# [PATCH] [Build] add cherry-pick tool
curl https://github.com/jtg-gg/chromium.src/commit/ea9cb4fc33e136560142ac79e0172b44fe6e8d4c.patch | git am
# [PATCH] [Build][OSX] suppress dump sym log
curl https://github.com/jtg-gg/chromium.src/commit/b031d5d0bd752fe90727e9c7921bfd1081c1e375.patch | git am
# [PATCH] [Media Recorder] fix windows compile error for chrome 53 (+1 squashed commits)
curl https://github.com/jtg-gg/chromium.src/commit/674e77d54c847959fa02387f42f6d2f649510e98.patch | git am
# [Screen Selection] add optional constraint "windowToFront"
curl https://github.com/jtg-gg/chromium.src/commit/13e7970a6d5599302d86298a5eca554de136e695.patch | git am
# [SQLite] add encryption
curl https://github.com/jtg-gg/chromium.src/commit/168ffaf189aa1500cef259ab1f37e9af0428d4b1.patch | git am
# [SQLite] add "immediateCommand" to WebDatabase parameter
curl https://github.com/jtg-gg/chromium.src/commit/c386623ca29395a34c566b12e4909b5d5388af18.patch | git am
# [Drag Region] all platform, manifest / window creation param
curl https://github.com/jtg-gg/chromium.src/commit/958b5bbbce832a0befe445cfce3a5291f28faa18.patch | git am
# [Drag Region][OSX] force_enable_drag_region implementation
curl https://github.com/jtg-gg/chromium.src/commit/5be9c1a6b20e1e8a8d89cb3ae783a8686734c140.patch | git am
# [Drag Region][WIN] force_enable_drag_region implementation
curl https://github.com/jtg-gg/chromium.src/commit/2969c51ad9d6d700b30ae58171c0705110d0dcb8.patch | git am
# [GeoLocation][OSX][WIN] location provider implementation
curl https://github.com/jtg-gg/chromium.src/commit/bf38e1d45a5a02fded954ff150bb91876d13657e.patch | git am
# [AutoUpdater][OSX] add squirrel auto updater frameworks
curl https://github.com/jtg-gg/chromium.src/commit/165d9807da4565c6ab41c3a2ba4141e9b4ce9601.patch | git am

cd $NWJS/src/content/nw/

# [Build] add patches for Linux arm build
curl https://github.com/jtg-gg/node-webkit/commit/0798be55e1ae4953cabaaed109e6f4d419b2fb63.patch | git am
# [Build][Linux] add support for linux arm binary strip
curl https://github.com/jtg-gg/node-webkit/commit/11b133231d0b5ea10570ee492402587928ac3a09.patch | git am
# [Build][OSX] only add //chrome:nw_sym_archive if enable_dsyms is true
curl https://github.com/jtg-gg/node-webkit/commit/7e5886a344fbfbcb4a882b2b994ed8d1a74f91ca.patch | git am
# [Build][OSX] suppress dump sym log
curl https://github.com/jtg-gg/node-webkit/commit/234f19da9a0db3700e005b4ccae698fa554dbfb9.patch | git am
# fix crash on windows
curl https://github.com/jtg-gg/node-webkit/commit/bcba0a9a8ccf2c2ec8f553c67e04973906e6d5a9.patch | git am
# [Media Recorder] add manual test
curl https://github.com/jtg-gg/node-webkit/commit/86425b30f82cac625552aca603d946ffc5fe03fd.patch | git am
# [Media Recorder] rebase for chrome 55 (+1 squashed commit)
curl https://github.com/jtg-gg/node-webkit/commit/ead66b31ce32c0ba0314520c0a61e05a55869a8a.patch | git am
# [Emoji] add manual test
curl https://github.com/jtg-gg/node-webkit/commit/3d60e60a5e27ad31bbe0af7953d01d326d317369.patch | git am
# [SQLite] encryption auto test
curl https://github.com/jtg-gg/node-webkit/commit/eaa3b0a20fd753b91312371677df94e8a951fb09.patch | git am
# [Drag Region] all platform, window creation param, add automated test
curl https://github.com/jtg-gg/node-webkit/commit/10898d7da8e7456a7088a768260f0a60d8ee61c7.patch | git am
# [GeoLocation] automated test
curl https://github.com/jtg-gg/node-webkit/commit/90e3933166a754bc62c7fcd844d9b812433ac1c2.patch | git am
# [Proxy] getHttpProxy chrome 55 fixes (+1 squashed commit)
curl https://github.com/jtg-gg/node-webkit/commit/d6489489ec5dc15e0f71fa3a23f26ddb2b0e81f9.patch | git am
# [Proxy] implement getHttpAuth
curl https://github.com/jtg-gg/node-webkit/commit/5d1c3d2756c2f26bc3901f862eeebb0d34375054.patch | git am
# [Crash fix] on Heap Profiler object hover
curl https://github.com/jtg-gg/node-webkit/commit/31808014595411f86666e29436de8675dd7a462f.patch | git am
# [AutoUpdater][OSX] add squirrel auto updater
curl https://github.com/jtg-gg/node-webkit/commit/a0fdaf96fe19a76262a89c4f4b59c6fa63d589bc.patch | git am

gclient runhooks
gn gen out_gn_arm/nw --args="$GN_ARGS"
export GYP_CHROMIUM_NO_ACTION=0
python build/gyp_chromium -Goutput_dir=out_gn_arm third_party/node/node.gyp

# Build
ninja -C out_gn_arm/nw nwjs
ninja -C out_gn_arm/nw v8_libplatform
ninja -C out_gn_arm/Release node
ninja -C out_gn_arm/nw copy_node
ninja -C out_gn_arm/nw dist

#!/bin/bash

set -e

export WORKDIR="/usr/docker"

export GYP_CROSSCOMPILE="1"
export GYP_DEFINES="OS=linux building_nw=1 buildtype=Official clang=1 is_debug=false is_component_ffmpeg=true target_arch=arm target_cpu=\"arm\" arm_float_abi=hard"
export GYP_CHROMIUM_NO_ACTION=0

export DEPOT_TOOLS_DIRECTORY=$WORKDIR/depot_tools
export NWJSDIR=$WORKDIR/nwjs
export PATH=$PATH:$DEPOT_TOOLS_DIRECTORY
export LC_ALL=C.UTF-8

export RED='\033[0;31m'
export NC='\033[0m'

read -p "Build nwjs sdk (y/n)?" choice
case "$choice" in
  y|Y ) export NWJS_SDK="true";;
  n|N ) export NWJS_SDK="false";;
  * ) exit 128;;
esac

read -p "Enable NaCl (y/n)?" choice
case "$choice" in
  y|Y ) export ENABLE_NACL="true";;
  n|N ) export ENABLE_NACL="false";;
  * ) exit 128;;
esac

read -p "Enable FFmpeg branding (y/n)?" choice
case "$choice" in
  y|Y ) export FFMPEG_BRANDING="ffmpeg_branding=\"Chrome\"";;
  n|N ) export FFMPEG_BRANDING="";;
  * ) exit 128;;
esac

export GN_ARGS="nwjs_sdk=$NWJS_SDK enable_nacl=$ENABLE_NACL $FFMPEG_BRANDING"

echo Please type the nwjs git branch you wish to build. For example: nw28
read branchName
export NWJS_BRANCH="$branchName"
echo Start building branch $NWJS_BRANCH

function configureGclientForNwjs {
  cd "$NWJSDIR"
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

function updateNwjsRepository {
  cd $NWJSDIR/src
  gclient sync --reset --with_branch_heads
  sh -c 'echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections'
  $NWJSDIR/src/build/install-build-deps.sh --arm --no-prompt --no-backwards-compatible
  $NWJSDIR/src/build/linux/sysroot_scripts/install-sysroot.py --arch=arm
}

function build {
  cd $NWJSDIR/src
  gn gen out/nw --args="${GN_ARGS}"
  $NWJSDIR/src/build/gyp_chromium -I third_party/node-nw/common.gypi third_party/node-nw/node.gyp
  ninja -C out/nw nwjs
  ninja -C out/Release node
  ninja -C out/nw copy_node
  temp_dir=$(mktemp -d)
  OLD_PATH="${PATH}"
  export PATH="${temp_dir}:${PATH}"

  # Typically under `third_party/llvm-build/Release+Asserts/bin`, but search for it just in case.
  objcopy=$(find . -type f -name "llvm-objcopy" | head -1 | xargs -n 1 realpath)
  cat > "${temp_dir}/strip" <<STRIP_SCRIPT
#!/bin/sh
"${objcopy}" --strip-unneeded "\$@"
STRIP_SCRIPT
  chmod +x "${temp_dir}/strip"

  ninja -C out/nw dump

  export PATH="${OLD_PATH}"
  rm -rf "${temp_dir}"

  ninja -C out/nw dist
}

configureGclientForNwjs
getGitRepository "https://github.com/nwjs/nw.js" "$NWJSDIR/src/content/nw"
getGitRepository "https://github.com/nwjs/node" "$NWJSDIR/src/third_party/node-nw"
getGitRepository "https://github.com/nwjs/v8" "$NWJSDIR/src/v8"
updateNwjsRepository
build
cd $WORKDIR

# tar -zcvf nwjs-sdk-nacl-ffmpeg-branding-v0.44.2.tar.gz $NWJSDIR/src/out/nw/dist

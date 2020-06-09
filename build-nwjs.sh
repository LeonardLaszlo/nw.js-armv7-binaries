#!/bin/bash

set -e

export WORKDIR="/usr/docker"
export DEPOT_TOOLS_DIRECTORY=$WORKDIR/depot_tools
export NWJSDIR=$WORKDIR/nwjs
export PATH=$PATH:$DEPOT_TOOLS_DIRECTORY
export LC_ALL=C.UTF-8
export NWJS_BRANCH="nw45"

export GYP_CHROMIUM_NO_ACTION=0
export GYP_DEFINES="nwjs_sdk=0 disable_nacl=1 building_nw=1 buildtype=Official clang=1 OS=linux target_arch=arm target_cpu=arm arm_float_abi=hard"
export GN_ARGS="nwjs_sdk=false enable_nacl=false ffmpeg_branding=\"Chrome\" is_component_ffmpeg=true is_debug=false symbol_level=1 target_os=\"linux\" target_cpu=\"arm\" arm_float_abi=\"hard\""

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

build
cd $WORKDIR

# tar -zcvf nwjs-sdk-nacl-ffmpeg-branding-v0.44.3.tar.gz /usr/docker/nwjs/src/out/nw/dist

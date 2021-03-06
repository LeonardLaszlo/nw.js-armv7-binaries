#!/bin/bash

set -e

export WORKDIR="/usr/docker"
export NWJSDIR=${WORKDIR}/nwjs
export DEPOT_TOOLS_DIRECTORY=${WORKDIR}/depot_tools
export PATH=${PATH}:${DEPOT_TOOLS_DIRECTORY}
export LC_ALL=C.UTF-8
export GYP_CHROMIUM_NO_ACTION=0

function applyPatch {
  cd $NWJSDIR/src
  # See https://github.com/nwjs/nw.js/issues/1151
  patch -p0 --ignore-whitespace << 'PATCH'
--- content/nw/tools/package_binaries.py
+++ content/nw/tools/package_binaries.py
@@ -30,7 +30,7 @@
 # Init variables.
 binaries_location = None        # .../out/Release
 platform_name = None            # win/linux/osx
-arch = None                     # ia32/x64
+arch = None                     # ia32/x64/arm
 step = None                     # nw/chromedriver/symbol
 skip = None
 nw_ver = None                   # x.xx
@@ -153,7 +153,6 @@
                            'nw',
                            'icudtl.dat',
                            'locales',
-                           'natives_blob.bin',
                            'v8_context_snapshot.bin',
                            'lib/libnw.so',
                            'lib/libnode.so',
@@ -172,12 +171,12 @@
             target['input'] += ['nacl_helper', 'nacl_helper_bootstrap', 'pnacl']
             if arch == 'x64':
                 target['input'].append('nacl_irt_x86_64.nexe')
-            else:
+            elif arch == 'ia32':
                 target['input'].append('nacl_irt_x86_32.nexe')
-
+            else:
+                target['input'].append('nacl_irt_{}.nexe'.format(arch))
     elif platform_name == 'win':
         target['input'] = [
-                           'natives_blob.bin',
                            'v8_context_snapshot.bin',
                            'd3dcompiler_47.dll',
                            'libEGL.dll',
@@ -219,7 +218,6 @@
             target['input'].append('chromedriver')
             target['input'].append('libffmpeg.dylib')
             target['input'].append('minidump_stackwalk')
-            target['input'].append('natives_blob.bin')
             target['input'].append('v8_context_snapshot.bin')
     else:
         print 'Unsupported platform: ' + platform_name
PATCH

  # See https://gist.github.com/llamasoft/33af03b73945a84d7624460d67b922ab
  # For nwjs_sdk=false builds, some required(?) files never get built.
  # As a workaround, always use the SDK's GRIT input regardless of the flag.
  # See: https://github.com/nwjs/chromium.src/issues/145
  patch -p0 --ignore-whitespace << 'PATCH'
--- chrome/browser/BUILD.gn
+++ chrome/browser/BUILD.gn
@@ -5238,11 +5238,7 @@ proto_library("resource_prefetch_predictor_proto") {
 }

 grit("resources") {
-  if (nwjs_sdk) {
-    source = "browser_resources.grd"
-  } else {
-    source = "nwjs_resources.grd"
-  }
+  source = "browser_resources.grd"

   # The .grd contains references to generated files.
   source_is_generated = true
PATCH
  cd $NWJSDIR/src/third_party/node-nw
  patch -p0 --ignore-whitespace << 'PATCH'
--- common.gypi
+++ common.gypi
@@ -118,6 +118,9 @@
      ['OS=="linux" and target_arch=="x64" and <(building_nw)==1', {
        'sysroot': '<!(cd <(DEPTH) && pwd -P)/build/linux/debian_sid_amd64-sysroot',
      }],
+      ['OS=="linux" and target_arch=="arm" and <(building_nw)==1', {
+        'sysroot': '<!(cd <(DEPTH) && pwd -P)/build/linux/debian_sid_arm-sysroot',
+      }],
      ['OS== "mac"', {
        'obj_dir': '<(PRODUCT_DIR)/obj.target',
        #'v8_base': '<(PRODUCT_DIR)/libv8_base.a',
@@ -515,6 +518,10 @@
            'cflags': [ '--sysroot=<(sysroot)', '-nostdinc++', '-isystem<(DEPTH)/buildtools/third_party/libc++/trunk/include', '-isystem<(DEPTH)/buil$
            'ldflags': [ '--sysroot=<(sysroot)','<!(<(DEPTH)/content/nw/tools/sysroot_ld_path.sh <(sysroot))', '-nostdlib++' ],
          }],
+          [ 'OS=="linux" and target_arch=="arm"', {
+            'cflags': [ '--target=arm-linux-gnueabihf' ],
+            'ldflags': [ '--target=arm-linux-gnueabihf' ],
+          }],
          [ 'target_arch=="ppc" and OS!="aix"', {
            'cflags': [ '-m32' ],
            'ldflags': [ '-m32' ],
PATCH
}

function build {
  cd $NWJSDIR/src
  gn gen out/nw --args="${1}"
  $NWJSDIR/src/build/gyp_chromium -I third_party/node-nw/common.gypi third_party/node-nw/node.gyp
  ninja -C out/nw nwjs
  ninja -C out/Release node
  ninja -C out/nw copy_node
  temp_dir=$(mktemp -d)
  OLD_PATH="${PATH}"
  export PATH="${temp_dir}:${PATH}"

  # Typically under `third_party/llvm-build/Release+Asserts/bin`, but search for it just in case.
  objcopy=$(find $WORKDIR/clang+llvm* -type f -name "llvm-objcopy" | head -1 | xargs -n 1 realpath)
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

applyPatch

if [ -d "${WORKDIR}/dist" ]; then rm -r ${WORKDIR}/dist; fi

if [ ! -d "${WORKDIR}/clang+llvm-10.0.0-x86_64-linux-gnu-ubuntu-18.04" ]; then
  cd ${WORKDIR}
  curl -sOL https://github.com/llvm/llvm-project/releases/download/llvmorg-10.0.0/clang+llvm-10.0.0-x86_64-linux-gnu-ubuntu-18.04.tar.xz
  tar -xvf clang+llvm*
fi

export GYP_DEFINES="nwjs_sdk=0 disable_nacl=1 building_nw=1 buildtype=Official clang=1 OS=linux target_arch=arm target_cpu=arm arm_float_abi=hard"
build "nwjs_sdk=false enable_nacl=false is_component_ffmpeg=true is_debug=false symbol_level=1 target_os=\"linux\" target_cpu=\"arm\" arm_float_abi=\"hard\""
mkdir -p ${WORKDIR}/dist/nwjs-chromium-ffmpeg-branding
cp ${NWJSDIR}/src/out/nw/dist/** ${WORKDIR}/dist/nwjs-chromium-ffmpeg-branding

export GYP_DEFINES="nwjs_sdk=0 disable_nacl=1 building_nw=1 buildtype=Official clang=1 OS=linux target_arch=arm target_cpu=arm arm_float_abi=hard"
build "nwjs_sdk=false enable_nacl=false ffmpeg_branding=\"Chrome\" is_component_ffmpeg=true is_debug=false symbol_level=1 target_os=\"linux\" target_cpu=\"arm\" arm_float_abi=\"hard\""
mkdir -p ${WORKDIR}/dist/nwjs-chrome-ffmpeg-branding
cp ${NWJSDIR}/src/out/nw/dist/** ${WORKDIR}/dist/nwjs-chrome-ffmpeg-branding

export GYP_DEFINES="nwjs_sdk=1 disable_nacl=0 building_nw=1 buildtype=Official clang=1 OS=linux target_arch=arm target_cpu=arm arm_float_abi=hard"
build "nwjs_sdk=true enable_nacl=true is_component_ffmpeg=true is_debug=false symbol_level=1 target_os=\"linux\" target_cpu=\"arm\" arm_float_abi=\"hard\""
mkdir -p ${WORKDIR}/dist/nwjs-sdk-chromium-ffmpeg-branding
cp ${NWJSDIR}/src/out/nw/dist/** ${WORKDIR}/dist/nwjs-sdk-chromium-ffmpeg-branding

export GYP_DEFINES="nwjs_sdk=1 disable_nacl=0 building_nw=1 buildtype=Official clang=1 OS=linux target_arch=arm target_cpu=arm arm_float_abi=hard"
build "nwjs_sdk=true enable_nacl=true ffmpeg_branding=\"Chrome\" is_component_ffmpeg=true is_debug=false symbol_level=1 target_os=\"linux\" target_cpu=\"arm\" arm_float_abi=\"hard\""
mkdir -p ${WORKDIR}/dist/nwjs-sdk-chrome-ffmpeg-branding
cp ${NWJSDIR}/src/out/nw/dist/** ${WORKDIR}/dist/nwjs-sdk-chrome-ffmpeg-branding

# tar -zcvf v0.37.5.tar.gz dist/*
# docker cp 3f4cdbf38dc2:/usr/docker/v0.37.5.tar.gz .

FROM ubuntu:18.04

# Adapted from https://github.com/LeonardLaszlo/nw.js-armv7-binaries

# Install core packages.
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "America/New_York" > /etc/timezone
RUN apt-get update && apt-get install -y \
  apt-utils \
  curl \
  git \
  lsb-release \
  nano \
  python \
  python-setuptools \
  sudo \
  tzdata
RUN dpkg-reconfigure -f noninteractive tzdata

# Create working directory.
RUN mkdir /nwjs
WORKDIR /nwjs

# Install depot tools (gclient) and add gclient to path.
RUN git clone \
  --depth 1 \
  https://chromium.googlesource.com/chromium/tools/depot_tools.git \
  /nwjs/depot_tools
ENV PATH=${PATH}:/nwjs/depot_tools

ARG BRANCH=nw51

# Create gclient config pointing to target NWJS branch.
RUN echo "\n\
#!bin/bash
solutions=[\n\
  { \"name\":'src',\n\
    \"url\":'https://github.com/nwjs/chromium.src.git@origin/${BRANCH}',\n\
    \"deps_file\":'DEPS',\n\
    \"managed\": True,\n\
    \"custom_deps\":{\n\
        \"src/third_party/WebKit/LayoutTests\":None,\n\
        \"src/chrome_frame/tools/test/reference_build/chrome\":None,\n\
        \"src/chrome_frame/tools/test/reference_build/chrome_win\":None,\n\
        \"src/chrome/tools/test/reference_build/chrome\":None,\n\
        \"src/chrome/tools/test/reference_build/chrome_linux\":None,\n\
        \"src/chrome/tools/test/reference_build/chrome_mac\":None,\n\
        \"src/chrome/tools/test/reference_build/chrome_win\":None,\n\
    },\n\
    \"custom_vars\":{},\n\
  },\n\
]\n" > .gclient

# Download chromium source files.
RUN gclient sync --reset --with_branch_heads --nohooks -D

# Clone nwjs source code.
RUN git clone --depth 1 --branch ${BRANCH} \
  https://github.com/nwjs/nw.js \
  /nwjs/src/content/nw

# Clone nwjs fork of node.
RUN git clone --depth 1 --branch ${BRANCH} \
  https://github.com/nwjs/node \
  /nwjs/src/third_party/node-nw

# Clone nwjs fork of v8.
RUN git clone \
  --depth 1 \
  --branch ${BRANCH} \
  https://github.com/nwjs/v8 \
  /nwjs/src/v8

RUN /nwjs/src/build/install-build-deps.sh --no-prompt
RUN gclient runhooks
RUN /nwjs/src/build/linux/sysroot_scripts/install-sysroot.py --arch=arm64

# Use browser resources even without sdk build.
COPY patches/browser_build_gn.patch .
RUN patch -p0 -i browser_build_gn.patch

# Patch to avoid toolchain checking.
COPY patches/atk_build_gn.patch .
RUN patch -p0 -i atk_build_gn.patch

# Widevine patch.
COPY patches/nw_app_api.patch .
RUN patch -p0 -i nw_app_api.patch

WORKDIR /nwjs/src

# Configure nw build.
RUN gn gen out/nw --args="\
  enable_nacl=false \
  enable_widevine=false \
  ffmpeg_branding=\"Chrome\"\
  is_component_ffmpeg=true \
  is_debug=false \
  nwjs_sdk=false \
  symbol_level=1 \
  target_cpu=\"arm64\" \
  target_os=\"linux\" \
"

# Build nw.
RUN ninja -C out/nw nwjs

# Patch to enable arm64 node build.
WORKDIR /nwjs
COPY patches/node_common_gypi.patch .
RUN patch -p0 -i node_common_gypi.patch
WORKDIR /nwjs/src

# Node build.
ENV GYP_DEFINES=" \
  building_nw=1 \
  buildtype=Official \
  clang=1 \
  disable_nacl=1 \
  enable_widevine=0 \
  nwjs_sdk=0 \
  OS=linux \
  target_arch=arm64 \
"

RUN /nwjs/src/build/gyp_chromium \
  -I third_party/node-nw/common.gypi \
  third_party/node-nw/node.gyp

RUN ninja -C out/Release node
RUN ninja -C out/nw copy_node

# Strip
COPY strip.sh ./strip
RUN chmod +x ./strip
RUN PATH=${PWD}:${PATH} ninja -C out/nw dump

# Package
RUN ninja -C out/nw dist

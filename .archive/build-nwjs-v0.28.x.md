# Building NW.js for Linux ARMv7

## Environment setup

Download and install [Xubuntu 16.04.1 LTS (Xenial Xerus)] on [VirtualBox].

Host requirements:

-16 GB RAM
-60 GB empty disk space (SSD or high-speed HDD)
-fast internet connection

Guest requirements:

-8 GB RAM
-8 GB swap
-50 GB disk space.


Update and upgrade the packages on the guest OS by running:
```bash
sudo apt-get update
sudo apt-get upgrade
```

Install Git and monitoring tools:
```bash
sudo apt-get install git htop sysstat openssh-server python
```

## Prerequisites

Read [Building NW.js] tutorial before you go further.

Checkout and install the [depot_tools package]. This contains the custom tools necessary to checkout and build NW.js.

Clone the depot_tools repository:
```bash
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
```

Add depot_tools to the end of your PATH (you will probably want to put this in your ~/.bashrc or ~/.zshrc). Assuming you cloned depot_tools to /path/to/depot_tools:
```bash
export PATH=$PATH:/path/to/depot_tools
```

### Bootstrapping Configuration
If you have never used Git before, you’ll need to set some global git configurations; substitute your name and email address in the following commands:
```bash
git config --global user.name "John Doe"
git config --global user.email "jdoe@email.com"
git config --global core.autocrlf false
git config --global core.filemode false
# and for fun!
git config --global color.ui true
```

## Get the Code

**Step 1.** Create a folder for holding NW.js source code, export it to `NWJS` environment variable, and run following command in the folder to generate `.gclient` file:

```bash
mkdir -p $HOME/nwjs
export NWJS=$HOME/nwjs
cd $NWJS
gclient config --name=src https://github.com/nwjs/chromium.src.git@origin/nw28
```

Put `NWJS` environment variable in your ~/.bashrc or ~/.zshrc.

Generally if you are not interested in running Chromium tests, you don't have to sync the test cases and reference builds, which saves you lot of time. Open the `.gclient` file you just created and replace `custom_deps` section with followings:

```python
"custom_deps" : {
    "src/third_party/WebKit/LayoutTests": None,
    "src/chrome_frame/tools/test/reference_build/chrome": None,
    "src/chrome_frame/tools/test/reference_build/chrome_win": None,
    "src/chrome/tools/test/reference_build/chrome": None,
    "src/chrome/tools/test/reference_build/chrome_linux": None,
    "src/chrome/tools/test/reference_build/chrome_mac": None,
    "src/chrome/tools/test/reference_build/chrome_win": None,
}
```

**Step 2.** Manually clone and checkout correct branches for following repositories:

| path | repo |
|:---- |:---- |
| src/content/nw | <https://github.com/nwjs/nw.js> |
| src/third_party/node | <https://github.com/nwjs/node> |
| src/v8 | <https://github.com/nwjs/v8> |


```bash
mkdir -p $NWJS/src/content/nw
mkdir -p $NWJS/src/third_party/node-nw
mkdir -p $NWJS/src/v8
git clone https://github.com/nwjs/nw.js $NWJS/src/content/nw
git clone https://github.com/nwjs/node $NWJS/src/third_party/node-nw
git clone https://github.com/nwjs/v8 $NWJS/src/v8

git fetch --tags --prune
git reset --hard HEAD
git checkout nw28
# git checkout tags/nw-v0.28.2 -b nw-v0.28.2

cd $NWJS/src/content/nw
git fetch --tags --prune
git checkout nw28
cd $NWJS/src/third_party/node-nw
git fetch --tags --prune
git checkout nw28
cd $NWJS/src/v8
git fetch --tags --prune
git checkout nw28
```

**Step 3.** Export cross-compilation environment variables and synchronize the projects. To enable proprietary codecs set `ffmpeg_branding` to `Chrome` when you configure GN!

```bash
cd $NWJS/src
export GYP_CROSSCOMPILE="1"
export GYP_DEFINES="is_debug=false is_component_ffmpeg=true target_arch=arm target_cpu=\"arm\" arm_float_abi=hard"
export GN_ARGS="nwjs_sdk=false enable_nacl=false ffmpeg_branding=\"Chrome\"" #

export GYP_CHROMIUM_NO_ACTION=1
gclient sync --reset --with_branch_heads --nohooks
```

This usually downloads 20G+ from remote repositories.

**Step 4.** Install all the compiler and library dependencies:
```bash
./build/install-build-deps.sh --arm
```

**Step 5.** Get some ARMv7 specific patches:
```bash
# [Build] add node build tools for linux arm
curl -s https://github.com/jtg-gg/chromium.src/commit/65f2215706692e438ca3570be640ed724ae37eaf.patch | git am &&

# [Build][gn] add support for linux arm binary strip
curl -s https://github.com/jtg-gg/chromium.src/commit/2a3ca533a4dd2552889bd18cd4343809f13876c4.patch | git am &&

# Update DEPS
curl -s https://github.com/jtg-gg/chromium.src/commit/8c13d9d6de27201ed71529f77f38b39e0aafc184.patch | git am &&

# [Build] compile error fixes
curl -s https://github.com/jtg-gg/chromium.src/commit/5e4bd4d9d03f81623074334bf030d13fce968c1b.patch | git am &&

# [DCHECK] ignore always crashing dcheck
curl -s https://github.com/jtg-gg/chromium.src/commit/58c7eb31c1e9390325da21ccc7f718f1b1b019d2.patch | git am &&

# [Build] add cherry-pick tool
curl -s https://github.com/jtg-gg/chromium.src/commit/cdc6ede7e5e4979ebbcc58492c7b576a07350152.patch | git am &&

cd $NWJS/src/content/nw/ &&

# [Build] add patches for Linux arm build
curl -s https://github.com/jtg-gg/node-webkit/commit/76770752e362b83b127ac4bf3aacc0c9a81bd590.patch | git am &&

# [Build][Linux] add support for linux arm binary strip and packaging
curl -s https://github.com/jtg-gg/node-webkit/commit/a59ff4c4f7ede3b47411719e41c59332b25b7259.patch | git am &&

# [Build] remove ffmpeg patch
curl -s https://github.com/jtg-gg/node-webkit/commit/11dcb9c775e43c78eb8136148e23ffe3b15d737e.patch | git am &&

# [Build] fixes :
curl -s https://github.com/jtg-gg/node-webkit/commit/c87b16766cda3f0af1ffa76b2b24390d77a005e0.patch | git am &&

# [Build][Symbols] put nwjs version and commit-id into crash report, zi
curl -s https://github.com/jtg-gg/node-webkit/commit/d480e6dcf6e49fd64200fd347d406554e76ef72e.patch | git am &&

# [Build] debug runtime fixes
curl -s https://github.com/jtg-gg/node-webkit/commit/42e15aeaf9b47447023d866fd94c82774327c49b.patch | git am
```

**Step 6.** Setup environment variables and generate ninja build files with GN for Chromium:
```bash
cd $NWJS/src &&
gclient runhooks &&
gn gen out_gn_arm/nw --args="$GN_ARGS" &&
export GYP_CHROMIUM_NO_ACTION=0 &&
python build/gyp_chromium -Goutput_dir=out_gn_arm -I third_party/node-nw/build/common.gypi third_party/node-nw/node.gyp
```

## Build

Build NW.js and Node:
```bash
ninja -C out_gn_arm/nw nwjs &&
ninja -C out_gn_arm/nw v8_libplatform &&
ninja -C out_gn_arm/Release node &&
ninja -C out_gn_arm/nw copy_node &&
ninja -C out_gn_arm/nw dump &&
ninja -C out_gn_arm/nw dist
```

This process can take few hours depending on your system configuration.

When the compilation is done you should find your artifacts under `$NWJS/src/out_gn_arm/nw/dist/`.

[Xubuntu 16.04.1 LTS (Xenial Xerus)]: http://cdimage.ubuntu.com/xubuntu/releases/xenial/release/xubuntu-16.04.1-desktop-amd64.iso
[Ubuntu 14.04.5 LTS (Trusty Tahr)]: http://releases.ubuntu.com/14.04/ubuntu-14.04.5-desktop-amd64.iso
[VirtualBox]: https://www.virtualbox.org/wiki/Downloads
[Building NW.js]: http://docs.nwjs.io/en/latest/For%20Developers/Building%20NW.js/
[depot_tools package]: https://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up

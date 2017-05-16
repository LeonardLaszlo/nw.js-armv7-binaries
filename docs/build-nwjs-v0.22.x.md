# Building NW.js for Linux ARMv7

### Environment setup

Download and install [Xubuntu 16.04.1 LTS (Xenial Xerus)] on [VirtualBox].

Host requirements:

  - 16GB RAM
  - 60GB empty disk space (SSD or high-speed HDD)
  - fast internet connection

Guest requirements:

  - 10GB RAM
  - 10GB swap
  - 50GB disk space.


Update and upgrade the packages on the guest os by running:
```bash
sudo apt-get update
sudo apt-get upgrade
```

Install Git and monitoring tools:
```bash
sudo apt-get install git htop sysstat
```

### Prerequisites

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

###### Bootstrapping Configuration
If you have never used Git before, you’ll need to set some global git configurations; substitute your name and email address in the following commands:
```bash
git config --global user.name "John Doe"
git config --global user.email "jdoe@email.com"
git config --global core.autocrlf false
git config --global core.filemode false
# and for fun!
git config --global color.ui true
```

### Get the Code

**Step 1.** Create a folder for holding NW.js source code, export it to `NWJS` environment variable, and run following command in the folder to generate `.gclient` file:

```bash
mkdir -p $HOME/nwjs
export NWJS=$HOME/nwjs
cd $NWJS
gclient config --name=src https://github.com/nwjs/chromium.src.git@origin/nw22
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
| src/content/nw | https://github.com/nwjs/nw.js |
| src/third_party/node | https://github.com/nwjs/node |
| src/v8 | https://github.com/nwjs/v8 |


```bash
mkdir -p $NWJS/src/content/nw
mkdir -p $NWJS/src/third_party/node-nw
mkdir -p $NWJS/src/v8
git clone https://github.com/nwjs/nw.js $NWJS/src/content/nw
git clone https://github.com/nwjs/node $NWJS/src/third_party/node-nw
git clone https://github.com/nwjs/v8 $NWJS/src/v8
cd $NWJS/src/content/nw
git checkout nw22
cd $NWJS/src/third_party/node-nw
git checkout nw22
cd $NWJS/src/v8
git checkout nw22
```

**Step 3.** Export cross-compilation environment variables and synchronize the projects. To enable proprietary codecs set `ffmpeg_branding` to `Chrome` when you configure GN!

```bash
cd $NWJS/src
export GYP_CROSSCOMPILE="1"
export GYP_DEFINES="target_arch=arm arm_float_abi=hard nwjs_sdk=1 disable_nacl=0"
export GN_ARGS="is_debug=false is_component_ffmpeg=true enable_nacl=true target_cpu=\"arm\" ffmpeg_branding=\"Chrome\""

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
curl -s https://github.com/jtg-gg/chromium.src/commit/fd17b6a285fbbe9ed1e8cb8c845fdb1a0991d833.patch | git am

# [Build][gn] add support for linux arm binary strip
curl -s https://github.com/jtg-gg/chromium.src/commit/0ef94fad3d5f3901a999894ab1db7e6ae257b6c9.patch | git am

# [Linux][arm] disable the runtime check
curl -s https://github.com/jtg-gg/chromium.src/commit/bdc0dfaf23ac7db9e0d048d8bd0d716707136455.patch | git am

cd $NWJS/src/content/nw/

# [Build] add patches for Linux arm build
curl -s https://github.com/jtg-gg/node-webkit/commit/5e50b681d4fd185361f6ba8f379ae4ba20a3de19.patch | git am

# [Build][Linux] add support for linux arm binary strip
curl -s https://github.com/jtg-gg/node-webkit/commit/9305181849248e93fab56dc08c04465e9adbbb79.patch | git am
```

Check if added patches apply cleanly (optional step, but it helps debugging):
```bash
cd $NWJS/src/third_party/node-nw/deps/openssl/asm/arm-void-gas/modes/
git apply --check $NWJS/src/content/nw/patch/patches/node.patch
cd $NWJS/src/third_party/node-nw/deps/openssl/
git apply --check $NWJS/src/content/nw/patch/patches/node_openssl.patch
cd $NWJS/src/v8/src
git apply --check $NWJS/src/content/nw/patch/patches/v8.patch
cd $NWJS/src
```

**Step 6.** Setup environment variables and generate ninja build files with GN for Chromium:
```bash
gclient runhooks
gn gen out_gn_arm/nw --args="$GN_ARGS"
export GYP_CHROMIUM_NO_ACTION=0
python build/gyp_chromium -Goutput_dir=out_gn_arm -I third_party/node-nw/build/common.gypi third_party/node-nw/node.gyp
```

### Build

Build NW.js and Node:
```bash
ninja -C out_gn_arm/nw nwjs
ninja -C out_gn_arm/nw v8_libplatform
ninja -C out_gn_arm/Release node
ninja -C out_gn_arm/nw copy_node
ninja -C out_gn_arm/nw dump
ninja -C out_gn_arm/nw dist
```

This process can take few hours depending on your system configuration.

When the compilation is done you should find your artifacts under `$NWJS/src/out_gn_arm/nw/dist/`.

[Xubuntu 16.04.1 LTS (Xenial Xerus)]: http://cdimage.ubuntu.com/xubuntu/releases/xenial/release/xubuntu-16.04.1-desktop-amd64.iso
[Ubuntu 14.04.5 LTS (Trusty Tahr)]: http://releases.ubuntu.com/14.04/ubuntu-14.04.5-desktop-amd64.iso
[VirtualBox]: https://www.virtualbox.org/wiki/Downloads
[Building NW.js]: http://docs.nwjs.io/en/latest/For%20Developers/Building%20NW.js/
[depot_tools package]: https://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up

# Building NW.js for Linux ARMv7

### Environment setup

First thing to do is to download [Xubuntu 16.04.1 LTS (Xenial Xerus)] and install it onto your favorite virtual machine. For this tutorial [VirtualBox] was chosen.

The host computer needs to have at least 60GB empty disk space and 16GB RAM. The guest machine needs 10GB RAM, 4GB swap area and 50GB disk space. It is recommended to use a high-speed storage device such an SSD or high-speed HDD. A fast internet connection is also an advantage.

After the operating system installation is completed, in VirtualBox menu, click on Devices/Insert Guest Additions CD image. Next click on the CD icon in the Ubuntu menu bar, and run the auto-installer. When the installer is done, reboot the guest machine.

Next is recommended to update and upgrade the packages on the guest machine by running:
```bash
sudo apt-get update
sudo apt-get upgrade
```

Next install Git and some monitoring tools if not installed:
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
gclient config --name=src https://github.com/nwjs/chromium.src.git@origin/nw17
```

You will probably want to put `NWJS` environment variable in your ~/.bashrc or ~/.zshrc.

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
mkdir -p $NWJS/src/third_party/node
mkdir -p $NWJS/src/v8
git clone https://github.com/nwjs/nw.js $NWJS/src/content/nw
git clone https://github.com/nwjs/node $NWJS/src/third_party/node
git clone https://github.com/nwjs/v8 $NWJS/src/v8
cd $NWJS/src/content/nw
git checkout nw17
cd $NWJS/src/third_party/node
git checkout nw17
cd $NWJS/src/v8
git checkout nw17
cd $NWJS
```

**Step 3.** Export cross-compilation environment variables and synchronize the projects. To enable proprietary codecs set `ffmpeg_branding` to `Chrome` when you configure GN!

```bash
cd $NWJS/src
export GYP_CROSSCOMPILE="1"
export GYP_DEFINES="target_arch=arm arm_float_abi=hard nwjs_sdk=1 disable_nacl=0 buildtype=Official"
export GN_ARGS="is_debug=false is_component_ffmpeg=true enable_nacl=true is_official_build=true target_cpu=\"arm\" ffmpeg_branding=\"Chrome\""

export GYP_CHROMIUM_NO_ACTION=1
gclient sync --reset --with_branch_heads
```

This usually downloads 20G+ from GitHub and Google's Git repositories. Make sure you have a good network provider and be patient.

When finished, you will see a `src` folder in the same folder as `.gclient`.

**Step 4.** The `install-build-deps` script should be used to install all the compiler and library dependencies directly from Ubuntu repositories:
```bash
cd $NWJS/src
./build/install-build-deps.sh --arm
```

Install `sysroot` for ARM, might be automated by `gclient runhooks`:
```bash
./build/linux/sysroot_scripts/install-sysroot.py --arch=arm
```

**Step 5.** Get some ARMv7 specific patches:
```bash
wget https://raw.githubusercontent.com/LeonardLaszlo/nw.js-armv7-binaries/master/patches/0011.nwjs.v0.17.x.PATCH-Build-linux-arm-cross-compile-fix,-dump_syms-should-be-host.patch -P $NWJS/
wget https://raw.githubusercontent.com/LeonardLaszlo/nw.js-armv7-binaries/master/patches/0012.nwjs.v0.17.x.PATCH-Build-gn-add-support-for-linux-arm-binary-strip.patch -P $NWJS/
wget https://raw.githubusercontent.com/LeonardLaszlo/nw.js-armv7-binaries/master/patches/0013.nwjs.v0.17.x.PATCH-Build-add-patches-for-Linux-arm-build.patch -P $NWJS/
wget https://raw.githubusercontent.com/LeonardLaszlo/nw.js-armv7-binaries/master/patches/0014.nwjs.v0.17.x.PATCH-Build-Linux-add-support-for-linux-arm-binary-strip.patch -P $NWJS/
```

Check if patches apply cleanly and apply them:
```bash
# check
git apply --check $NWJS/0011.nwjs.v0.17.x.PATCH-Build-linux-arm-cross-compile-fix,-dump_syms-should-be-host.patch
git apply --check $NWJS/0012.nwjs.v0.17.x.PATCH-Build-gn-add-support-for-linux-arm-binary-strip.patch
# apply
git am $NWJS/0011.nwjs.v0.17.x.PATCH-Build-linux-arm-cross-compile-fix,-dump_syms-should-be-host.patch
git am $NWJS/0012.nwjs.v0.17.x.PATCH-Build-gn-add-support-for-linux-arm-binary-strip.patch
# check
cd $NWJS/src/content/nw/
git apply --check $NWJS/0013.nwjs.v0.17.x.PATCH-Build-add-patches-for-Linux-arm-build.patch
git apply --check $NWJS/0014.nwjs.v0.17.x.PATCH-Build-Linux-add-support-for-linux-arm-binary-strip.patch
# apply
git am $NWJS/0013.nwjs.v0.17.x.PATCH-Build-add-patches-for-Linux-arm-build.patch
git am $NWJS/0014.nwjs.v0.17.x.PATCH-Build-Linux-add-support-for-linux-arm-binary-strip.patch
cd $NWJS
```

Check if added patches apply cleanly (optional step, but it helps debugging):
```bash
cd $NWJS/src/third_party/node/deps/openssl/asm/arm-void-gas/modes/
git apply --check $NWJS/src/content/nw/patch/patches/node.patch
cd $NWJS/src/third_party/node/deps/openssl/
git apply --check $NWJS/src/content/nw/patch/patches/node_openssl.patch
cd $NWJS/src/v8/src
git apply --check $NWJS/src/content/nw/patch/patches/v8.patch
cd $NWJS/src
```

**Step 6.** Setup environment variables, synchronize projects and generate ninja build files with GN for Chromium:
```bash
gn gen out_gn_arm/nw --args="$GN_ARGS"
export GYP_CHROMIUM_NO_ACTION=0
python build/gyp_chromium -Goutput_dir=out_gn_arm third_party/node/node.gyp
```

### Build

Build NW.js and Node:
```bash
ninja -C out_gn_arm/nw nwjs
ninja -C out_gn_arm/nw v8_libplatform
ninja -C out_gn_arm/Release node
ninja -C out_gn_arm/nw copy_node
ninja -C out_gn_arm/nw dist
```

This process can take few hours depending on your system configuration. Be patient!

When the compilation is done you should find your artifacts under `$NWJS/src/out_arm/Release/dist/`.

[Xubuntu 16.04.1 LTS (Xenial Xerus)]: http://cdimage.ubuntu.com/xubuntu/releases/xenial/release/xubuntu-16.04.1-desktop-amd64.iso
[Ubuntu 14.04.5 LTS (Trusty Tahr)]: http://releases.ubuntu.com/14.04/ubuntu-14.04.5-desktop-amd64.iso
[VirtualBox]: https://www.virtualbox.org/wiki/Downloads
[Building NW.js]: http://docs.nwjs.io/en/latest/For%20Developers/Building%20NW.js/
[depot_tools package]: https://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up
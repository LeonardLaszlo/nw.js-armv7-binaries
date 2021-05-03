# Building NW.js for Linux ARMv7

### Environment setup

First thing to do is to download [Xubuntu 16.04.1 LTS (Xenial Xerus)] and install it onto your favorite virtual machine. For this tutorial [VirtualBox] was chosen.

The host computer needs to have at least 50GB empty disk space and 8GB RAM. The guest machine needs 6GB RAM, 6GB swap area and 44GB disk space. It is recommended to use a high-speed storage device such an SSD or high-speed HDD. A fast internet connection is also an advantage.

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
gclient config --name=src https://github.com/nwjs/chromium.src.git@origin/nw16
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
git checkout nw16
cd $NWJS/src/third_party/node
git checkout nw16
cd $NWJS/src/v8
git checkout nw16
cd $NWJS
```

**Step 3.** Run following command in your terminal:
```bash
gclient sync --with_branch_heads --nohooks
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
wget https://raw.githubusercontent.com/LeonardLaszlo/nw.js-armv7-binaries/master/patches/0007.nwjs.v0.16.x.[Build]-linux-arm-cross-compile-fix-dump_syms-should-be-host-only.patch -P $NWJS/
wget https://raw.githubusercontent.com/LeonardLaszlo/nw.js-armv7-binaries/master/patches/0008.nwjs.v0.16.x.[PATCH]-[Build][Linux]-add-support-for-linux-arm-binary-strip.patch -P $NWJS/
wget https://raw.githubusercontent.com/LeonardLaszlo/nw.js-armv7-binaries/master/patches/0009.nwjs.v0.16.x.[Build]-add-patches-for-Linux-arm-build.patch -P $NWJS/
```

Check if patches apply cleanly and apply them:
```bash
# check
git apply --check $NWJS/0007.nwjs.v0.16.x.[Build]-linux-arm-cross-compile-fix-dump_syms-should-be-host-only.patch
# apply
git am $NWJS/0007.nwjs.v0.16.x.[Build]-linux-arm-cross-compile-fix-dump_syms-should-be-host-only.patch
cd $NWJS/src/content/nw/
# check
git apply --check $NWJS/0008.nwjs.v0.16.x.[PATCH]-[Build][Linux]-add-support-for-linux-arm-binary-strip.patch
git apply --check $NWJS/0009.nwjs.v0.16.x.[Build]-add-patches-for-Linux-arm-build.patch
# apply
git am $NWJS/0008.nwjs.v0.16.x.[PATCH]-[Build][Linux]-add-support-for-linux-arm-binary-strip.patch
git am $NWJS/0009.nwjs.v0.16.x.[Build]-add-patches-for-Linux-arm-build.patch
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
cd $NWJS
```

**Step 6.** Setup environment variables and run hooks:
```bash
export GYP_CROSSCOMPILE=1
export GYP_DEFINES="target_arch=arm arm_float_abi=hard nwjs_sdk=1 disable_nacl=0"
export GYP_GENERATOR_FLAGS=output_dir=out_arm
gclient runhooks
```

**Step 7.** To enable proprietary codecs apply the patch bellow and run again the hooks:
```bash
wget https://raw.githubusercontent.com/LeonardLaszlo/nw.js-armv7-binaries/master/patches/0010.nwjs.v0.16.x.Chrome.branding.patch -P $NWJS/
cd $NWJS/src/third_party/ffmpeg/
git apply --check $NWJS/0010.nwjs.v0.16.x.Chrome.branding.patch
git apply $NWJS/0010.nwjs.v0.16.x.Chrome.branding.patch
cd $NWJS
gclient runhooks
```

### Build

Start the compilation:
```bash
cd $NWJS/src
ninja -C out_arm/Release dist
```

This process can take few hours depending on your system configuration. Be patient!

When the compilation is done you should find your artifacts under `$NWJS/src/out_arm/Release/dist/`.

[Xubuntu 16.04.1 LTS (Xenial Xerus)]: http://cdimage.ubuntu.com/xubuntu/releases/xenial/release/xubuntu-16.04.1-desktop-amd64.iso
[Ubuntu 14.04.5 LTS (Trusty Tahr)]: http://releases.ubuntu.com/14.04/ubuntu-14.04.5-desktop-amd64.iso
[VirtualBox]: https://www.virtualbox.org/wiki/Downloads
[Building NW.js]: http://docs.nwjs.io/en/latest/For%20Developers/Building%20NW.js/
[depot_tools package]: https://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up

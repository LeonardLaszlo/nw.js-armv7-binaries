# Building NW.js for ARMv7

## Environment setup

First thing to do is to download [Ubuntu 14.04.5 LTS (Trusty Tahr)] and install it onto your favorite virtual machine. For this tutorial [VirtualBox] was chosen.

The host computer needs to have at least 40 GB empty disk space and 8 GB RAM. The guest machine needs 4 GB RAM and 4 GB swap area.

After the installation is completed and Ubuntu is up, in VirtualBox menu, click on Devices/Insert Guest Additions CD image. Next click on the CD icon in the Ubuntu menu bar, and run the auto-installer. When the installer is done, reboot the guest machine.

Next is recommended to update and upgrade the packages on the guest machine by running:
```bash
sudo apt-get update
sudo apt-get upgrade
```

Next install Git if not installed:
```bash
sudo apt-get install git
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

**Step 1.** Create a folder for holding NW.js source code, like `$HOME/nwjs`, and run following command in the folder to generate `.gclient` file:

```bash
mkdir -p $HOME/nwjs
cd $HOME/nwjs
gclient config --name=src https://github.com/nwjs/chromium.src.git@origin/nw14
```

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
mkdir -p src/content/nw
mkdir -p src/third_party/node
mkdir -p src/v8
git clone https://github.com/nwjs/nw.js src/content/nw
git clone https://github.com/nwjs/node src/third_party/node
git clone https://github.com/nwjs/v8 src/v8
cd src/content/nw
git checkout nw14
cd $HOME/nwjs
cd src/third_party/node
git checkout nw14
cd $HOME/nwjs
cd src/v8
git checkout nw14
cd $HOME/nwjs
```

**Step 3.** Run following command in your terminal:
```bash
gclient sync --with_branch_heads --nohooks
```

This usually downloads 20G+ from GitHub and Google's Git repos. Make sure you have a good network provider and be patient.
When finished, you will see a `src` folder in the same folder as `.gclient`.

**Step 4.** The `install-build-deps` script should be used to install all the compiler and library dependencies directly from Ubuntu repositories:
```bash
cd src
./build/install-build-deps.sh --arm
```

Install sysroot for arm, might be automated by gclient runhooks:
```bash
./build/linux/sysroot_scripts/install-sysroot.py --arch=arm
```

**Step 5.** Get some ARMv7 specific patches:
```bash
wget https://raw.githubusercontent.com/LeonardLaszlo/nw.js-armv7-binaries/master/patches/0001.patch -P $HOME/nwjs/
wget https://raw.githubusercontent.com/LeonardLaszlo/nw.js-armv7-binaries/master/patches/0002.patch -P $HOME/nwjs/
wget https://raw.githubusercontent.com/LeonardLaszlo/nw.js-armv7-binaries/master/patches/0003.patch -P $HOME/nwjs/
```

Check if patches apply cleanly and apply them:
```bash
# check
git apply --check $HOME/nwjs/0001.patch
# apply
git am $HOME/nwjs/0001.patch
cd content/nw/
# check
git apply --check $HOME/nwjs/0002.patch
git apply --check $HOME/nwjs/0003.patch
# apply
git am $HOME/nwjs/0002.patch
git am $HOME/nwjs/0003.patch
cd $HOME/nwjs
```

**Step 6.** Setup environment variables and run hooks:
```bash
export GYP_CROSSCOMPILE=1
export GYP_DEFINES="target_arch=arm arm_float_abi=hard nwjs_sdk=1 disable_nacl=0"
export GYP_GENERATOR_FLAGS=output_dir=out_arm
gclient runhooks
```

**Step 7.** To enable proprietary codecs apply the following patch and run again the hooks:
```bash
wget https://raw.githubusercontent.com/LeonardLaszlo/nw.js-armv7-binaries/master/patches/0004.patch -P $HOME/nwjs/
cd src/third_party/ffmpeg/
git apply --check $HOME/nwjs/0004.patch
git apply $HOME/nwjs/0004.patch
cd $HOME/nwjs
gclient runhooks
cd $HOME/nwjs/src
```

## Build

Start the compilation:
```bash
ninja -C out_arm/Release dist
```

This process can take few hours depending on your system configuration. Be patient!
When the compilation is done you should find your artifacts under `src/out_arm/Release/dist/`.

[Ubuntu 14.04.5 LTS (Trusty Tahr)]: http://releases.ubuntu.com/14.04/ubuntu-14.04.5-desktop-amd64.iso
[VirtualBox]: https://www.virtualbox.org/wiki/Downloads
[Building NW.js]: http://docs.nwjs.io/en/latest/For%20Developers/Building%20NW.js/
[depot_tools package]: https://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up

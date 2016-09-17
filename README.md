# NW.js ARMv7 binaries

On versions v0.14.x and v0.15.x shared object files located in 'lib' directory need to be copied to '/usr/lib' directory.

If you don't want NW.js to store shared objects there, as an alternative, you can add the library where you store the shared objects to LD_LIBRARY_PATH environment variable, as shown below:
`export LD_LIBRARY_PATH=/path/to/nwjs/nwjs-v0.15.1-linux-arm/lib:$LD_LIBRARY_PATH`

Now if you run NW as shown below, it should work with no problems:
`./nw --use-gl=egl --ignore-gpu-blacklist --disable-accelerated-2d-canvas --num-raster-threads=2`

If you don't want to export the environment variable everytime you reboot you device you can add the export line to the end of `.bashrc` file.

You can find some step-by-step guides to build NW.js:
  - v0.15.x in file [docs/build-nwjs-v0.15.x.md],
  - v0.14.x in file [docs/build-nwjs-v0.14.x.md].

### Release log
  - [nwjs-sdk-v0.15.5-linux-arm.tar.gz] -- (Chrome branding)
  - [nwjs-sdk-v0.14.7-linux-arm.tar.gz] -- (Chrome branding)
  - [nwjs-v0.15.1-linux-armv7-chrome-branding.tar.gz] and [nwjs-symbol-v0.15.1-linux-armv7-chrome-branding.tar.gz]
  - [nwjs-v0.15.1-linux-armv7.tar.gz] and [nwjs-symbol-v0.15.1-linux-armv7.tar.gz]
  - [nwjs-sdk-v0.15.1-linux-armv7-chrome-branding.tar.gz] and [nwjs-sdk-symbol-v0.15.1-linux-armv7-chrome-branding.tar.gz]
  - [nwjs-sdk-v0.15.1-linux-armv7.tar.gz] and [nwjs-sdk-symbol-v0.15.1-linux-armv7.tar.gz]
  - [nwjs-sdk-v0.14.6-linux-armv7-chrome-branding.tar.gz] and [nwjs-sdk-symbol-v0.14.6-linux-armv7-chrome-branding.tar.gz]
  - [nwjs-sdk-v0.14.6-linux-armv7.tar.gz] and [nwjs-sdk-symbol-v0.14.6-linux-armv7.tar.gz]
  - [nwjs-v0.12.2-linux-arm.tar.gz]
  - [nwjs-v0.12.0-linux-arm.tar.gz]

### Tutorials

Cross compilation tutorial for v0.12.x:
- http://forum.odroid.com/viewtopic.php?f=52&t=16072

Cross compilation tutorial for v0.14.x:
- http://docs.nwjs.io/en/latest/For%20Developers/Building%20NW.js
- https://github.com/nwjs/nw.js/issues/1151#issuecomment-222101059

Chrome branding (enable proprietary codecs)
- http://docs.nwjs.io/en/latest/For%20Developers/Enable%20Proprietary%20Codecs

Thanks @gripped, @jtg-gg!

[docs/build-nwjs-v0.14.x.md]: https://github.com/LeonardLaszlo/nw.js-armv7-binaries/blob/master/docs/build-nwjs-v0.14.x.md
[docs/build-nwjs-v0.15.x.md]: https://github.com/LeonardLaszlo/nw.js-armv7-binaries/blob/master/docs/build-nwjs-v0.15.x.md

[nwjs-v0.12.0-linux-arm.tar.gz]: https://github.com/LeonardLaszlo/nw.js-armv7-binaries/releases/download/nwjs-v0.12.0-linux-ARMv7/nwjs-v0.12.0-linux-arm.tar.gz
[nwjs-v0.12.2-linux-arm.tar.gz]: https://github.com/LeonardLaszlo/nw.js-armv7-binaries/releases/download/nwjs-v0.12.2-linux-ARMv7.tar.gz/nwjs-v0.12.2-linux-arm.tar.gz
[nwjs-sdk-v0.14.6-linux-armv7.tar.gz]: https://github.com/LeonardLaszlo/nw.js-armv7-binaries/releases/download/nwjs-sdk-v0.14.6-linux-armv7/nwjs-sdk-v0.14.6-linux-armv7.tar.gz
[nwjs-sdk-symbol-v0.14.6-linux-armv7.tar.gz]: https://github.com/LeonardLaszlo/nw.js-armv7-binaries/releases/download/nwjs-sdk-v0.14.6-linux-armv7/nwjs-sdk-symbol-v0.14.6-linux-armv7.tar.gz
[nwjs-sdk-v0.14.6-linux-armv7-chrome-branding.tar.gz]: https://github.com/LeonardLaszlo/nw.js-armv7-binaries/releases/download/nwjs-sdk-v0.14.6-linux-armv7-chrome-branding/nwjs-sdk-v0.14.6-linux-armv7-chrome-branding.tar.gz
[nwjs-sdk-symbol-v0.14.6-linux-armv7-chrome-branding.tar.gz]: https://github.com/LeonardLaszlo/nw.js-armv7-binaries/releases/download/nwjs-sdk-v0.14.6-linux-armv7-chrome-branding/nwjs-sdk-symbol-v0.14.6-linux-armv7-chrome-branding.tar.gz
[nwjs-sdk-v0.15.1-linux-armv7.tar.gz]: https://github.com/LeonardLaszlo/nw.js-armv7-binaries/releases/download/nwjs-sdk-v0.15.1-linux-armv7/nwjs-sdk-v0.15.1-linux-armv7.tar.gz
[nwjs-sdk-symbol-v0.15.1-linux-armv7.tar.gz]: https://github.com/LeonardLaszlo/nw.js-armv7-binaries/releases/download/nwjs-sdk-v0.15.1-linux-armv7/nwjs-sdk-symbol-v0.15.1-linux-armv7.tar.gz
[nwjs-sdk-v0.15.1-linux-armv7-chrome-branding.tar.gz]: https://github.com/LeonardLaszlo/nw.js-armv7-binaries/releases/download/nwjs-sdk-v0.15.1-linux-armv7-chrome-branding/nwjs-sdk-v0.15.1-linux-armv7-chrome-branding.tar.gz
[nwjs-sdk-symbol-v0.15.1-linux-armv7-chrome-branding.tar.gz]: https://github.com/LeonardLaszlo/nw.js-armv7-binaries/releases/download/nwjs-sdk-v0.15.1-linux-armv7-chrome-branding/nwjs-sdk-symbol-v0.15.1-linux-armv7-chrome-branding.tar.gz
[nwjs-v0.15.1-linux-armv7.tar.gz]:https://github.com/LeonardLaszlo/nw.js-armv7-binaries/releases/download/nwjs-v0.15.1-linux-armv7/nwjs-v0.15.1-linux-armv7.tar.gz
[nwjs-symbol-v0.15.1-linux-armv7.tar.gz]: https://github.com/LeonardLaszlo/nw.js-armv7-binaries/releases/download/nwjs-v0.15.1-linux-armv7/nwjs-symbol-v0.15.1-linux-armv7.tar.gz
[nwjs-v0.15.1-linux-armv7-chrome-branding.tar.gz]: https://github.com/LeonardLaszlo/nw.js-armv7-binaries/releases/download/nwjs-v0.15.1-linux-armv7-chrome-branding/nwjs-v0.15.1-linux-armv7-chrome-branding.tar.gz
[nwjs-symbol-v0.15.1-linux-armv7-chrome-branding.tar.gz]: https://github.com/LeonardLaszlo/nw.js-armv7-binaries/releases/download/nwjs-v0.15.1-linux-armv7-chrome-branding/nwjs-symbol-v0.15.1-linux-armv7-chrome-branding.tar.gz
[nwjs-sdk-v0.14.7-linux-arm.tar.gz]: https://github.com/LeonardLaszlo/nw.js-armv7-binaries/releases/download/nwjs-sdk-v0.14.7-linux-arm-chrome-branding/nwjs-sdk-v0.14.7-linux-arm.tar.gz
[nwjs-sdk-v0.15.5-linux-arm.tar.gz]: https://github.com/LeonardLaszlo/nw.js-armv7-binaries/releases/download/nwjs-sdk-v0.15.5-linux-armv7-chrome-branding/nwjs-sdk-v0.15.5-linux-arm.tar.gz
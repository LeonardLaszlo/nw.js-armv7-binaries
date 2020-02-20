# NW.js ARMv7 binaries

### Instructions for running your NW.js application on Linux ARMv7

Executable binaries are available for download under the [Releases][1] tab.

After downloading the binary archive and unpacking it you can run NW.js on Linux ARMv7 devices with the following command:

`./nw --use-gl=egl --ignore-gpu-blacklist --disable-accelerated-2d-canvas --num-raster-threads=2`

### Docker

Build the environment:

``` Bash
docker image build -t laslaul/nwjs-arm-build-env:1.0 .
```

Start the environment:

``` Bash
docker run -it laslaul/nwjs-arm-build-env:1.0
```

### Tutorials

Building NW.js on supported platforms [tutorial][4]

Cross compilation [tutorial][3] for v0.12.x

Cross compilation [tutorial][5] for v0.14.x

[Chrome branding][6] (enable proprietary codecs)

### Issues

With versions **v0.14.x**, **v0.15.x**, **v0.16.x** the shared object files located in *lib* directory need to be copied to */usr/lib* directory.

If you don't want NW.js to store shared objects there, as an alternative, you can add the library where you store the shared objects to **LD_LIBRARY_PATH** environment variable, as shown below:

`export LD_LIBRARY_PATH=/path/to/nwjs/nwjs-v0.15.1-linux-arm/lib:$LD_LIBRARY_PATH`

If you don't want to export the environment variable every time you reboot you device you can add the export line to the end of **.bashrc** file.

Thanks **@gripped**, **@jtg-gg**!

[1]: https://github.com/LeonardLaszlo/nw.js-armv7-binaries/releases
[2]: https://github.com/LeonardLaszlo/nw.js-armv7-binaries/tree/master/docs
[3]: http://forum.odroid.com/viewtopic.php?f=52&t=16072
[4]: http://docs.nwjs.io/en/latest/For%20Developers/Building%20NW.js
[5]: https://github.com/nwjs/nw.js/issues/1151#issuecomment-222101059
[6]: http://docs.nwjs.io/en/latest/For%20Developers/Enable%20Proprietary%20Codecs

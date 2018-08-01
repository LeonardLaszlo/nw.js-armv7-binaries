# NW.js ARMv7 binaries

After downloading the binary archive and unpacking it you can run NW.js on Linux ARMv7 devices with the following command:

`./nw --use-gl=egl --ignore-gpu-blacklist --disable-accelerated-2d-canvas --num-raster-threads=2`

The step-by-step guide to build NW.js is located under the `docs` directory.

### Tutorials

Cross compilation tutorial for v0.12.x:

- http://forum.odroid.com/viewtopic.php?f=52&t=16072

Cross compilation tutorial for v0.14.x:

- http://docs.nwjs.io/en/latest/For%20Developers/Building%20NW.js
- https://github.com/nwjs/nw.js/issues/1151#issuecomment-222101059

Chrome branding (enable proprietary codecs)

- http://docs.nwjs.io/en/latest/For%20Developers/Enable%20Proprietary%20Codecs

### Issues

With versions **v0.14.x**, **v0.15.x**, **v0.16.x** the shared object files located in *lib* directory need to be copied to */usr/lib* directory.

If you don't want NW.js to store shared objects there, as an alternative, you can add the library where you store the shared objects to **LD_LIBRARY_PATH** environment variable, as shown below:

`export LD_LIBRARY_PATH=/path/to/nwjs/nwjs-v0.15.1-linux-arm/lib:$LD_LIBRARY_PATH`

If you don't want to export the environment variable every time you reboot you device you can add the export line to the end of **.bashrc** file.

Thanks **@gripped**, **@jtg-gg**!

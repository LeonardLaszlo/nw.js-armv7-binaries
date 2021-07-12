# NW.js ARMv7 binaries

The NW.js ARMv7 and ARMv8 (experimental) binaries are located under the [Releases][1] tab.

## Experimental 64 bit binaries are now available

64 bit and 32 bit binaries are packaged and released separately. The 64 bit package does not contain the SDK versions.

## Contributing

The most needed contribution at the moment is a self-hosted Github runner or a docker host for the build execution.
A virtual machine or access to a cloud ubuntu x64 instance could be useful as well.

The building process is resource intensive, the minimal requirements are:
- 10 GB of RAM,
- 4GB of swap,
- 110 GB of disk,
- and of course, as many CPU cores as possible.

Another way to support this project is to join as a maintainer, and patch the building script once in a while.

## Instructions for running your NW.js application on Linux ARMv7

After downloading the archive and unpacking it, the NW.js binary can be executed on Linux ARMv7 devices with:

`./nw --use-gl=egl --ignore-gpu-blacklist --disable-accelerated-2d-canvas --num-raster-threads=2`

Thanks **@gripped**, **@jtg-gg** and **@llamasoft** for their endless patience and continuous help!

## Docker

Thanks to Docker containerisation, building NW.js for ARMv7 is now as easy as it gets.
However the building process is resource intensive, so brace yourselves. See:

``` Bash
./automatic-build.sh
```

for a starting point.

## Further reading

The documentation of older builds is available under the [.archive][2] directory.
Some older versions require extra tweaks in order to build successfully.

Official building NW.js [guide][4]. [Chrome branding][6] (enable proprietary codecs).

<https://gist.github.com/llamasoft/33af03b73945a84d7624460d67b922ab>

<https://github.com/nwjs/nw.js/issues/1151>

<https://github.com/nwjs/nw.js/issues/7378>

Cross compilation [tutorial][3] for v0.12.x

Cross compilation [tutorial][5] for v0.14.x

[1]: https://github.com/LeonardLaszlo/nw.js-armv7-binaries/releases
[2]: https://github.com/LeonardLaszlo/nw.js-armv7-binaries/tree/master/.archive
[3]: http://forum.odroid.com/viewtopic.php?f=52&t=16072
[4]: http://docs.nwjs.io/en/latest/For%20Developers/Building%20NW.js
[5]: https://github.com/nwjs/nw.js/issues/1151#issuecomment-222101059
[6]: http://docs.nwjs.io/en/latest/For%20Developers/Enable%20Proprietary%20Codecs

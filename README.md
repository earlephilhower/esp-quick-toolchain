# Archived.  See https://github.com/mcspr/esp-quick-toolchain for currently maintained versions

# esp-quick-toolchain - Build ESP8266 toolchain for multiple architectures

Allows building Win32, Win64, OSX, Linux x86_64, ARM64 (aarch64) and Raspberry Pi ESP8266 toolchains in a Docker container.

Builds work for GCC 4.8, 7.2, 9.3, 10.1, and 10.2.

## Downloading GCC/etc. sources

Run
````
make download
````
to clone the GCC and libs needed to the repo/ directory.  This takes a while, so be patient, but it only is done once (and allows us to switch between GCC versions without redownloading anything in the future).

## Building only native mode binaries

If you're only compiling natively, you can just clone this repo and run
````
make GCC={4.8|4.9|5.2|7.2|9.3|10.1|10.2} REL=x.x.x SUBREL=x -jx  # I like -j32 on a 16-core server, adjust according to your CPU power
````

Note that to build a non-linux toolchain, you first need to build a linux chain in the directory.  This is because the cross compiler requires a local host executable gcc for the target architecture to build properly.

## Building full suite architectures

To build all architectures use the commands
````
git clone https://github.com/earlephilhower/esp-quick-toolchain
cd esp-quick-toolchain
docker run --user $(id -u):$(id -g) --rm -v $(pwd):/workdir earlephilhower/gcc-cross bash -c "cd /workdir; make -j32 GCC={4.8|4.9|5.2|7.2|9.3|10.1|10.2} REL=2.5.0 SUBREL=3 all"
````

To make a draft release of the binaries:
````
make GCC={4.8|4.9|5.2|7.2|9.3|10.1|10.2} REL=2.5.0 SUBREL=3 upload
````

You then promote the draft to a pre-release so it becomes visible and can then make a PR against the Arduino core to merge it.

Then to install the libraries and headers into the Arduino core (not including the toolchain exes) just
````
make GCC={4.8|4.9|5.2|7.2|9.3|10.1|10.2} REL=2.5.0 SUBREL=3 install  (INSTALLBRANCH=xxx may be added to apply against a predefined branch other than master)
<in Arduino dir>
git commit -a
````

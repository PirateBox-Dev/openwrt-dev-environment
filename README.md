# PirateBox OpenWRT Dev. Environment Scripts

This collection and documentation is for developing on scratch on PirateBox-OpenWRT packages, images and so on. All of those commands in the Makefile are customized or assume, that you don't rely on the current stable source.

## What this repository is:
It should help with the common task to be done on developing around. See Makefile for more comments.

## What this repository is __not__:
* NO newbie guide
* NO complete walk-through (yet)
* SHOULD NOT be used for only creating customized images, use [openwrt-image-build](http://wiki.openwrt.org/doc/howto/obtain.firmware.generate) instead.

## Todo's
* Improve this README - WIP
* Add complete walk-through to set up the dev environment - WIP
* Improve comments in the Makefile, better yet - get rid of them and move all needed information to this README.

## Prerequisites
* Make sure you have the loop kernel module loaded:

        modprobe loop

* Make sure you have at least __6BG__ free disk space

## Setting up the development enviroment
There are two methods to build the image:
* Using the piratebox feed
* Using a custom, local feed

Use the __local feed__ variant if you want to use __other__ branches __than__ the __master__ branch.


### PirateBox feed
To build your PirateBox image execute the following steps in order:
    
1. Clone and configure OpenWRT and clone the image build script
    
        make openwrt_env
Detailed information about the OpenWRT build system may be found in the OpenWRT Wiki:

  * [build system](http://wiki.openwrt.org/doc/howto/buildroot.exigence)
  * [obtaining the source](http://wiki.openwrt.org/doc/howto/buildroot.exigence#downloading.sources)

2. Apply the PirateBox OpenWRT feed 

        make apply_PirateBox_feed

3. Update all feeds

        make update_all_feeds

4. Install the PirateBox OpenWRT feed

        make install_piratebox_feed

5. Create the piratebox script image

        make create_piratebox_script_image

6. Prepare the Kernel
Copy the Kernel config file:

       cp example_config openwrt/.config
Some configuration has to be adjusted:

        cd openwrt
        make menuconfig
set the options:

        Libraries --> libffmpeg-mini (M)  
        Utilities --> box-installer(M)
                      extendRoot(M) --> (*)
        Network   --> PirateBox --> (all)

7. Build OpenWRT:

        make -j 4
The __-j__ flag needs to be adjusted to your system, a good rule of thumb for the value is to use the amount of cores you have available on your build machine.     
Building the OpenWRT image may take a long time, depending on your machine, up to a couple of hours.

8. Start local repository
After building OpenWRT you can start your local repository (you best start this in a seperate terminal since it wil lblock the current terminal):

        cd ..
        make run_repository_all
Now surf to __localhost__ and verify that the repository is up and running.

9. Build the PirateBox image
To build the PirateBox image run:

    cd openwrt-image-build
    git stash
    git checkout AA-with-installer
    git stash pop # Fix the merge conflict for the future, check out the right branch at the beginning
    make all INSTALL_TARGET=piratebox

### Troubleshooting
#### Builing OpenWRT fails with errors
Run __make__ single threaded and with the __S=v__ flag to get detailed output:

    make -j1 S=v

## Working Setups
The build process has been tested on the following systems:
* Ubuntu 14.04

If you run the build process successfully on another setup, please leave a note in the Issue section, or submit a Pull Request with added information.

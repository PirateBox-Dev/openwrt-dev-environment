# PirateBox OpenWRT development environment scripts
This collection and documentation is for developing on scratch on PirateBox-OpenWRT packages, images and so on. All of those commands in the Makefile are customized or assume, that you don't rely on the current stable source.

## What this repository is:
This repository is intended to get you started with a development environment to build your own PirateBox images - no matter if you just want to enable an additional Kernel feature, remaster your PirateBox image or start developing for the PirateBox.

## What this repository is __not__:
* __NO__ newbie guide. You should know your way around in Makefiles. You should know how to configure a Kernel and you should also have some knowledge about OpenWRT. In doubt follow the reference Links.
* __SHOULD NOT__ be used if you only want to create a customized OpenWRT image. If you want to do that, use [openwrt-image-build](http://wiki.openwrt.org/doc/howto/obtain.firmware.generate) instead.

## Todo's
* Improve this README - WIP
* Complete walk-through for piratebox feed and local feed method
* Improve comments in the Makefile, better yet - get rid of them and move all needed information to this README.

## Prerequisites
* Make sure you have the loop kernel module loaded:

        modprobe loop

* Make sure you have at least __8BG__ free disk space

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

        make apply_piratebox_feed

3. Update all feeds

        make update_all_feeds

4. Install the PirateBox OpenWRT feed

        make install_piratebox_feed

5. Create the piratebox script image

        make create_piratebox_script_image

6. Prepare the Kernel
Copy the Kernel config file:

       cp example-config openwrt/.config
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

8. Aquire missing packages    
Two packages are not __yet__ in the OpenWRT repository. You have to aquire them manually:

        wget http://beta.openwrt.piratebox.de/all/packages/pbxopkg_0.0.6_all.ipk -P bin/ar71xx/packages
        wget http://beta.openwrt.piratebox.de/all/packages/piratebox-mesh_1.1.2_all.ipk -P bin/ar71xx/packages

9. Start local repository    
After building OpenWRT you can start your local repository (you best start this in a seperate terminal since it wil lblock the current terminal):

        cd ..
        make run_repository_all
Now surf to __localhost__ and verify that the repository is up and running.

10. Build the PirateBox image     
To build the PirateBox image run:

        cd openwrt-image-build
        git stash
        git checkout AA-with-installer
        git stash pop # Fix the merge conflict for the future, check out the right branch at the beginning
        make all INSTALL_TARGET=piratebox

11. Enjoy your build     
You should now have a directory called __target_piratebox__.
This directory contains all supported firmware images and the install_piratebox.zip

You can now continue with the [auto installation](http://piratebox.cc/openwrt:diy) step.

### Troubleshooting
#### Builing OpenWRT fails with errors
Run __make__ single threaded and with the __S=v__ flag to get detailed output:

    make -j1 S=v

# PirateBox OpenWRT Dev. Environment Scripts

This collection and documentation is for developing on scratch on PirateBox-OpenWRT packages, images and so on. All of those commands in the Makefile are customized or assume, that you don't rely on the current stable source.

## What this repository is:
It should help with the common task to be done on developing around. See Makefile for more comments.

## What this repository is __not__:
* NO newbie guide
* NO complete walk-through (yet)
* SHOULD NOT be used for only creating customized images, use [openwrt-image-build](http://wiki.openwrt.org/doc/howto/obtain.firmware.generate) instead.

## Todo's
* Improve this README
* Add complete walk-through to set up the dev environment
* Improve comments in the Makefile

## Setting up the development enviroment
There are two methods to build the image:
* Using the piratebox feed
* Using a custom, local feed

Use the __local feed__ variant if you want to use __other__ branches __than__ the __master__ branch.

### PirateBox feed
For convenience, there is a make target executing all following targets, but for completeness each step is lined out in detail below

    make auto_build_stable
    
Which does the following steps for you:
    
1. Clone and configure OpenWRT and clone the image build script
    
        make openwrt_env

2. Apply the PirateBox OpenWRT feed
       make apply_piratebox_feed

3. Install the PirateBox OpenWRT feed
       make install_piratebox_feed

4. Update all feeds
       make update_all_feeds

5. Create the piratebox script image
       make create_piratebox_script_image

6. Build OpenWRT:
       cd openwrt && make -j 16

The __-j__ flag needs to be adjusted to your system, a good rule of thumb is to use twice the value of the amount of cores you have for disposition. Also the last step takes some time, depending on your building machine it can take up to several hours.

### Local feed
For convencience, there is a make target helping you to get started:
 
    make auto_build_snapshot
    
Which does the following steps for you:

1. Clone and configure OpenWRT and clone the image build script    
        make openwrt_env

2. Apply the local OpenWRT feed, cloning all needed repositories
       make apply_local_feed

3. Switch the local feeds to their development branch
       make switch_local_feed_to_dev

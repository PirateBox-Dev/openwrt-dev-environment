HERE:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

OPENWRT_GIT=git://git.openwrt.org/12.09/openwrt.git
OPENWRT_DIR=$(HERE)/openwrt
OPENWRT_FEED_FILE=$(OPENWRT_DIR)/feeds.conf

PIRATEBOX_FEED_GIT=https://github.com/PirateBox-Dev/openwrt-piratebox-feed.git

### Vars for local_feed batch_generation
LOCAL_FEED_FOLDER=$(HERE)/local_feed
PACKAGE_BOXINSTALLER_GIT=https://github.com/LibraryBox-Dev/LibraryBox-Installer.git
PACKAGE_USB_CONFIG_SCRIPTS_GIT=https://github.com/LibraryBox-Dev/package-openwrt-usb-config-scripts.git
PACKAGE_LIBRARYBOX_GIT=https://github.com/LibraryBox-Dev/package-openwrt-librarybox.git
PACKAGE_EXTENDROOT_GIT=https://github.com/PirateBox-Dev/package-openwrt-extendRoot.git
PACKAGE_PIRATEBOX_GIT=https://github.com/PirateBox-Dev/package-openwrt-piratebox.git

$(OPENWRT_DIR):
# http://wiki.openwrt.org/doc/howto/buildroot.exigence
# http://wiki.openwrt.org/doc/howto/buildroot.exigence#downloading.sources
	git clone $(OPENWRT_GIT)
	cd $(OPENWRT_DIR) && make defconfig
	cd $(OPENWRT_DIR) && make prereq
	cp $(HERE)/example-config $(OPENWRT_DIR)/.config

$(OPENWRT_FEED_FILE):
	cp  $(OPENWRT_FEED_FILE).default $(OPENWRT_FEED_FILE)
	
apply_PirateBox_feed: $(OPENWRT_FEED_FILE)
	echo "src-git piratebox $(PIRATEBOX_FEED_GIT)" >> $(OPENWRT_FEED_FILE)

$(LOCAL_FEED_FOLDER):
	mkdir -p $(LOCAL_FEED_FOLDER)
	cd  $(LOCAL_FEED_FOLDER) && git clone $(PACKAGE_BOXINSTALLER_GIT) box-installer
	cd  $(LOCAL_FEED_FOLDER) && git clone $(PACKAGE_USB_CONFIG_SCRIPTS_GIT) usb-config-scripts
	cd  $(LOCAL_FEED_FOLDER) && git clone $(PACKAGE_LIBRARYBOX_GIT) librarybox
	cd  $(LOCAL_FEED_FOLDER) && git clone $(PACKAGE_EXTENDROOT_GIT) extendRoot
	cd  $(LOCAL_FEED_FOLDER) && git clone $(PACKAGE_PIRATEBOX_GIT)  piratebox


## Running this command will pull the "local_feed" folder generation
##    if you want to create your own, you should do this before running
##    make apply_local_feed
##
apply_local_feed: $(LOCAL_FEED_FOLDER) $(OPENWRT_FEED_FILE)
	echo "src-link local $(LOCAL_FEED_FOLDER) "  >> $(OPENWRT_FEED_FILE)	


openwrt_env: $(OPENWRT_DIR)

###  Pulls an overall refresh
update_all_feeds:
	cd $(OPENWRT_DIR) && ./scripts/feeds update -a

### Installs all packages from local-feed folder to build-environment
install_local_feed:
	cd $(OPENWRT_DIR) && ./scripts/feeds install -p local -a

### Installs all packages from remote git repository to build environment
install_piratebox_feed:
	cd $(OPENWRT_DIR) && ./scripts/feeds install -p piratebox -a

## Run a repository, that will only contain files having "all" as naming
##  pattern
run_repository_all:
	- rm $(OPENWRT_DIR)/bin/ar71xx/packages/*ar71xx* -f
	cd $(OPENWRT_DIR) && make package/index
	sudo python3 -m http.server 80

##### Menuconfig parameters
#### Libraries --> libffmpeg-mini (M)
#### Utilities --> box-installer(M)
####               extendRoot(M)--->
####                        (*)
#### Network  --> PirateBox ---> (all)

###   Side note, following package need to be added manually to openwrt/bin/ar71xx/packages/
###    * piratebox-mesh
###    * pbxopkg 

## Note: Toolkit-build need to run single threaded, because sometimes 
##       build-dependencies fail. Package-Build run fine multi-threaded.

# 1. # make openwrt_env
#  Decide  . local feed (for package development)  or piratebox feed 
#    - you can use both, wich is a more advanced setup
#    * will use piratebox feed as example
# 2. # make apply_PirateBox_feed
# 3. # update_all_feeds
# 4. Do one complete build, that toolchain is generated correctly
#    cd openwrt
#    make 

# Later you can build single packages in the openwrt folder with
#   make package/feeds/<feed>/<package>/{compile,install}






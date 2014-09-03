HERE:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

OPENWRT_GIT=git://git.openwrt.org/12.09/openwrt.git
OPENWRT_DIR=$(HERE)/openwrt
OPENWRT_FEED_FILE=$(OPENWRT_DIR)/feeds.conf

PIRATEBOX_FEED_GIT=https://github.com/PirateBox-Dev/openwrt-piratebox-feed.git

WWW=$(HERE)/local_www

IMAGE_BUILD=openwrt-image-build
IMAGE_BUILD_GIT=https://github.com/PirateBox-Dev/openwrt-image-build.git

### Vars for local_feed batch_generation
LOCAL_FEED_FOLDER=$(HERE)/local_feed
PACKAGE_BOXINSTALLER_GIT=https://github.com/LibraryBox-Dev/LibraryBox-Installer.git
PACKAGE_USB_CONFIG_SCRIPTS_GIT=https://github.com/LibraryBox-Dev/package-openwrt-usb-config-scripts.git
PACKAGE_LIBRARYBOX_GIT=https://github.com/LibraryBox-Dev/package-openwrt-librarybox.git
PACKAGE_EXTENDROOT_GIT=https://github.com/PirateBox-Dev/package-openwrt-extendRoot.git
PACKAGE_PIRATEBOX_GIT=https://github.com/PirateBox-Dev/package-openwrt-piratebox.git


##### PirateBox-image files, which are used in the package
PIRATEBOXSCRIPTS_GIT=https://github.com/PirateBox-Dev/PirateBoxScripts_Webserver.git

PIRATEBOXSCRIPTS=PirateBoxScripts_Webserver/

$(PIRATEBOXSCRIPTS):
	git clone $(PIRATEBOXSCRIPTS_GIT) $@

create_piratebox_script_image: $(PIRATEBOXSCRIPTS)
	- cd $(PIRATEBOXSCRIPTS) && make cleanall
	cd $(PIRATEBOXSCRIPTS) && make shortimage	
	### Copy image to image-builder if needed
	test -d $(IMAGE_BUILD)  && cp $(PIRATEBOXSCRIPTS)/piratebox_ws_1.0_img.tar.gz  $(IMAGE_BUILD)


$(IMAGE_BUILD):
	git clone $(IMAGE_BUILD_GIT)
	#Switch it to our build-env.
	sed -i "s|http://stable.openwrt.piratebox.de|http://127.0.0.1|" $(IMAGE_BUILD)/Makefile

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

##test_local_folder:= $(wildcard $(LOCAL_FEED_FOLDER)/* )

define git_checkout_development
	cd $(1) && git checkout development
endef

switch_local_feed_to_dev:  
	$(call git_checkout_development,$(LOCAL_FEED_FOLDER)/box-installer)
	$(call git_checkout_development,$(LOCAL_FEED_FOLDER)/librarybox)
	$(call git_checkout_development,$(LOCAL_FEED_FOLDER)/piratebox)
	$(call git_checkout_development,$(LOCAL_FEED_FOLDER)/extendRoot)
# no dev branch yet	$(call git_checkout_development,$(LOCAL_FEED_FOLDER)/usb-config-scripts)
	

## Running this command will pull the "local_feed" folder generation
##    if you want to create your own, you should do this before running
##    make apply_local_feed
##
apply_local_feed: $(LOCAL_FEED_FOLDER) $(OPENWRT_FEED_FILE)
	echo "src-link local $(LOCAL_FEED_FOLDER) "  >> $(OPENWRT_FEED_FILE)	


openwrt_env: $(OPENWRT_DIR) $(IMAGE_BUILD)

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
##  pattern.
## I use that local-www repository for the openwrt-image-build.
##   That toolset generates out of the stock OpenWRT ImageBuilder the custom files, we use.
##   Read more about ImageBuild: http://wiki.openwrt.org/doc/howto/obtain.firmware.generate
##   For getting our packages into the custom image, we inject our local repository into the build process and get our package-dependencies from there.
##      --- see more informations in openwrt-image-build folder.

$(WWW):
	mkdir -p $(WWW)
	ln -s $(OPENWRT_DIR)/bin/ar71xx $(WWW)/all 

run_repository_all: $(WWW)
	- rm $(OPENWRT_DIR)/bin/ar71xx/packages/*ar71xx* -f
	cd $(OPENWRT_DIR) && make package/index
	cd $(WWW) && sudo python3 -m http.server 80

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

######
## Remember that you might have to switch the the branches
##   on git-packages like openwrt-packages in feed folder
##   or PirateBoxScripts_Webserver to get the correct versions together (before release 1.0 it is a bit inconstent due to a restructuration)
##
#####

#####
##  To go on with building the final image, we can use the current latest relase or build
##  our own piratebox_ws_img file, which will reflect /opt/piratebox on OpenwRT systems
##
##  (you need this only, if you do changes or run a newer version then in stable source )
##
##  1. # make PirateBoxScripts_Webserver/
##  2.  (switch branches or make changes if needed) 
##  3. # make create_piratebox_script_image   # That creates and copies a new piratebox_ws_1.0_img.tar.gz
##  
##  Next step can be the creation of a new install_zip source. 
##
##  
## 1. open a 2nd console and point to this development folder. Run
##    run_repository_all


auto_build_stable:  openwrt_env apply_PirateBox_feed install_piratebox_feed update_all_feeds create_piratebox_script_image
	cd $(OPENWRT_DIR) && make  -j 16

auto_build_snapshot: openwrt_env apply_local_feed switch_local_feed_to_dev


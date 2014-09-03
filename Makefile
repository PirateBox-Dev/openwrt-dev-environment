HERE:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

OPENWRT_GIT=git://git.openwrt.org/12.09/openwrt.git
OPENWRT_DIR=$(HERE)/openwrt
OPENWRT_FEED_FILE=$(OPENWRT_DIR)/feeds.conf

PIRATEBOX_FEED_GIT=https://github.com/PirateBox-Dev/openwrt-piratebox-feed.git

WWW=$(HERE)/local_www

IMAGE_BUILD_GIT=https://github.com/PirateBox-Dev/openwrt-image-build.git
IMAGE_BUILD=openwrt-image-build

# Variables for local_feed batch_generation
LOCAL_FEED_FOLDER=$(HERE)/local_feed
PACKAGE_BOXINSTALLER_GIT=https://github.com/LibraryBox-Dev/LibraryBox-Installer.git
PACKAGE_USB_CONFIG_SCRIPTS_GIT=https://github.com/LibraryBox-Dev/package-openwrt-usb-config-scripts.git
PACKAGE_LIBRARYBOX_GIT=https://github.com/LibraryBox-Dev/package-openwrt-librarybox.git
PACKAGE_EXTENDROOT_GIT=https://github.com/PirateBox-Dev/package-openwrt-extendRoot.git
PACKAGE_PIRATEBOX_GIT=https://github.com/PirateBox-Dev/package-openwrt-piratebox.git

# PirateBox-image files, which are used in the package
PIRATEBOXSCRIPTS_GIT=https://github.com/PirateBox-Dev/PirateBoxScripts_Webserver.git
PIRATEBOXSCRIPTS=PirateBoxScripts_Webserver/

# Clone the PirateBoxScripts repository
$(PIRATEBOXSCRIPTS):
	git clone $(PIRATEBOXSCRIPTS_GIT) $@

# Create piratebox script image and copy it to the build directory if available
create_piratebox_script_image: $(PIRATEBOXSCRIPTS)
	cd $(PIRATEBOXSCRIPTS) && make cleanall
	cd $(PIRATEBOXSCRIPTS) && make shortimage
	test -d $(IMAGE_BUILD) && cp $(PIRATEBOXSCRIPTS)/piratebox_ws_1.0_img.tar.gz $(IMAGE_BUILD)

# Clone the imagebuild repository, checkout the AA-with-installer branch and
# adapt the Makefile to use this local repository.
$(IMAGE_BUILD):
	git clone $(IMAGE_BUILD_GIT)
	cd $(IMAGE_BUILD) && git checkout AA-with-installer
	sed -i "s|http://stable.openwrt.piratebox.de|http://127.0.0.1|" $(IMAGE_BUILD)/Makefile

# Clone the OpenWRT repository, configure it and copy the example kernel config
$(OPENWRT_DIR):
	git clone $(OPENWRT_GIT)
	cd $(OPENWRT_DIR) && make defconfig
	cd $(OPENWRT_DIR) && make prereq
	cp $(HERE)/example-config $(OPENWRT_DIR)/.config

# Copy the OpenWRT feed file
$(OPENWRT_FEED_FILE):
	cp $(OPENWRT_FEED_FILE).default $(OPENWRT_FEED_FILE)

# Apply the PirateBox feed
apply_piratebox_feed: $(OPENWRT_FEED_FILE)
	echo "src-git piratebox $(PIRATEBOX_FEED_GIT)" >> $(OPENWRT_FEED_FILE)

$(LOCAL_FEED_FOLDER):
	mkdir -p $(LOCAL_FEED_FOLDER)
	cd $(LOCAL_FEED_FOLDER) && git clone $(PACKAGE_BOXINSTALLER_GIT) box-installer
	cd $(LOCAL_FEED_FOLDER) && git clone $(PACKAGE_USB_CONFIG_SCRIPTS_GIT) usb-config-scripts
	cd $(LOCAL_FEED_FOLDER) && git clone $(PACKAGE_LIBRARYBOX_GIT) librarybox
	cd $(LOCAL_FEED_FOLDER) && git clone $(PACKAGE_EXTENDROOT_GIT) extendRoot
	cd $(LOCAL_FEED_FOLDER) && git clone $(PACKAGE_PIRATEBOX_GIT) piratebox

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
	echo "src-link local $(LOCAL_FEED_FOLDER)" >> $(OPENWRT_FEED_FILE)

openwrt_env: $(OPENWRT_DIR) $(IMAGE_BUILD)

# Pulls an overall refresh
update_all_feeds:
	cd $(OPENWRT_DIR) && ./scripts/feeds update -a

# Installs all packages from local-feed folder to build-environment
install_local_feed:
	cd $(OPENWRT_DIR) && ./scripts/feeds install -p local -a

# Installs all packages from remote git repository to build environment
install_piratebox_feed:
	cd $(OPENWRT_DIR) && ./scripts/feeds install -p piratebox -a

## Run a repository, that will only contain files having "all" as naming
##  pattern.
## I use that local-www repository for the openwrt-image-build.
##   That toolset generates out of the stock OpenWRT ImageBuilder the custom files, we use.
##   Read more about ImageBuild: http://wiki.openwrt.org/doc/howto/obtain.firmware.generate
##   For getting our packages into the custom image, we inject our local repository into the build process and get our package-dependencies from there.
##      --- see more informations in openwrt-image-build folder.

# Prepare a folder for the repository
$(WWW):
	mkdir -p $(WWW)
	ln -s $(OPENWRT_DIR)/bin/ar71xx $(WWW)/all

# Rebuild the package index and run the local repository
run_repository_all: $(WWW)
	rm $(OPENWRT_DIR)/bin/ar71xx/packages/*ar71xx* -f
	cd $(OPENWRT_DIR) && make package/index
	cd $(WWW) && sudo python3 -m http.server 80

## Note: Toolkit-build need to run single threaded, because sometimes 
##       build-dependencies fail. Package-Build run fine multi-threaded.

# Later you can build single packages in the openwrt folder with
#   make package/feeds/<feed>/<package>/{compile,install}

######
## Remember that you might have to switch the the branches
##   on git-packages like openwrt-packages in feed folder
##   or PirateBoxScripts_Webserver to get the correct versions together (before release 1.0 it is a bit inconstent due to a restructuration)
##
#####

auto_build_stable: openwrt_env apply_piratebox_feed install_piratebox_feed update_all_feeds create_piratebox_script_image
	cd $(OPENWRT_DIR) && make -j 16

auto_build_snapshot: openwrt_env apply_local_feed switch_local_feed_to_dev

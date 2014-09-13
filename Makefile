HERE:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

# This is the value used for the -j flag when running make.
# Adjust this to a appropriate value for your system a good rule of thumb is the
# amount of cores your machine has available. +1 if you don't need to use the
# machine while building.
THREADS=4

# The port to run the local repository on.
#
# If you set this port to something < 1024 make sure to run the server in the
# run_repository_all target with sudo and also kill it with sudo in the
# stop_repository_all target.
WWW_PORT=2342
WWW=$(HERE)/local_www
WWW_PID_FILE=$(HERE)/www.pid

# OpenWRT related settings
OPENWRT_GIT=git://git.openwrt.org/12.09/openwrt.git
OPENWRT_DIR=$(HERE)/openwrt
OPENWRT_FEED_FILE=$(OPENWRT_DIR)/feeds.conf

PIRATEBOXMOD_DIR=$(HERE)/local_feed/piratebox-mod-imageboard

PIRATEBOX_FEED_GIT=https://github.com/PirateBox-Dev/openwrt-piratebox-feed.git
PIRATEBOX_BETA_FEED=$(HERE)/piratebox_beta_feed

IMAGE_BUILD_GIT=https://github.com/PirateBox-Dev/openwrt-image-build.git
IMAGE_BUILD=openwrt-image-build

# Variables for local_feed batch_generation
LOCAL_FEED_FOLDER=$(HERE)/local_feed
PACKAGE_BOXINSTALLER_GIT=https://github.com/LibraryBox-Dev/LibraryBox-Installer.git
PACKAGE_USB_CONFIG_SCRIPTS_GIT=https://github.com/LibraryBox-Dev/package-openwrt-usb-config-scripts.git
PACKAGE_LIBRARYBOX_GIT=https://github.com/LibraryBox-Dev/package-openwrt-librarybox.git
PACKAGE_EXTENDROOT_GIT=https://github.com/PirateBox-Dev/package-openwrt-extendRoot.git
PACKAGE_PIRATEBOX_GIT=https://github.com/PirateBox-Dev/package-openwrt-piratebox.git
PACKAGE_PBXOPKG_GIT=https://github.com/PirateBox-Dev/package-openwrt-pbxopkg.git
PACKAGE_PIRATEBOXMESH_GIT=https://github.com/stylesuxx/package-openwrt-piratebox-mesh.git

# PirateBox-image files, which are used in the package
PIRATEBOXSCRIPTS_GIT=https://github.com/PirateBox-Dev/PirateBoxScripts_Webserver.git
PIRATEBOXSCRIPTS=PirateBoxScripts_Webserver/

# The default make target.
# Display some information about the available targets.
info:
	@ echo "Ooooop, please read the README"
	@ echo "=============================="
	@ echo "Available build targets:"
	@ echo "* openwrt_env"
	@ echo "* apply_piratebox_feed"
	@ echo "* apply_local_feed"
	@ echo "* update_all_feeds"
	@ echo "* install_piratebox_feed"
	@ echo "* install_local_feed"
	@ echo "* create_piratebox_script_image"
	@ echo "* build_openwrt"
	@ echo "* acquire_stable_packages"
	@ echo "* acquire_beta_packages"
	@ echo "* run_repository_all"
	@ echo "* piratebox"
	@ echo "* stop_repository_all"
	@ echo "* clean"
	@ echo "* distclean"
	@ echo "=============================="
	@ echo "Available auto build targets:"
	@ echo "* auto_build_stable"
	@ echo "* auto_build_beta"
	@ echo "* auto_build_snapshot"
	@ echo "* auto_build_local"

openwrt_env: $(OPENWRT_DIR) $(IMAGE_BUILD)

# Clone the imagebuild repository, checkout the AA-with-installer branch and
# adapt the Makefile to use this local repository.
$(IMAGE_BUILD):
	git clone $(IMAGE_BUILD_GIT)
	cd $(IMAGE_BUILD) && git checkout AA-with-installer
	sed -i "s|http://stable.openwrt.piratebox.de|http://127.0.0.1:$(WWW_PORT)|" $(IMAGE_BUILD)/Makefile

# Clone the OpenWRT repository, configure it
$(OPENWRT_DIR):
	git clone $(OPENWRT_GIT)
	cd $(OPENWRT_DIR) && make defconfig
	cd $(OPENWRT_DIR) && make prereq

# Create piratebox script image and copy it to the build directory if available
create_piratebox_script_image: $(PIRATEBOXSCRIPTS)
	cd $(PIRATEBOXSCRIPTS) && make clean
	cd $(PIRATEBOXSCRIPTS) && make shortimage
	test -d $(IMAGE_BUILD) && cp $(PIRATEBOXSCRIPTS)/piratebox_ws_1.0_img.tar.gz $(IMAGE_BUILD)

# Clone the PirateBoxScripts repository
$(PIRATEBOXSCRIPTS):
	git clone $(PIRATEBOXSCRIPTS_GIT) $@

# Apply the PirateBox feed
apply_piratebox_feed: $(OPENWRT_FEED_FILE)
	echo "src-git piratebox $(PIRATEBOX_FEED_GIT)" >> $(OPENWRT_FEED_FILE)

# Copy the OpenWRT feed file
$(OPENWRT_FEED_FILE):
	cp $(OPENWRT_FEED_FILE).default $(OPENWRT_FEED_FILE)

# Apply PirateBox beta feed
apply_piratebox_beta_feed: $(OPENWRT_FEED_FILE) $(PIRATEBOX_BETA_FEED)
	echo "src-link piratebox $(PIRATEBOX_BETA_FEED)" >> $(OPENWRT_FEED_FILE)

copy_image_board: $(PIRATEBOXMOD_DIR)

$(PIRATEBOXMOD_DIR): $(PIRATEBOX_BETA_FEED)
	cp -r $(PIRATEBOX_BETA_FEED)/net/piratebox-mod-imageboard $(LOCAL_FEED_FOLDER)/
	rm -rf $(PIRATEBOX_BETA_FEED)

$(PIRATEBOX_BETA_FEED):
	git clone $(PIRATEBOX_FEED_GIT) $@
	cd $(PIRATEBOX_BETA_FEED) && git checkout development

$(LOCAL_FEED_FOLDER):
	mkdir -p $(LOCAL_FEED_FOLDER)
	cd $(LOCAL_FEED_FOLDER) && git clone $(PACKAGE_BOXINSTALLER_GIT) box-installer
	cd $(LOCAL_FEED_FOLDER) && git clone $(PACKAGE_USB_CONFIG_SCRIPTS_GIT) usb-config-scripts
	cd $(LOCAL_FEED_FOLDER) && git clone $(PACKAGE_LIBRARYBOX_GIT) librarybox
	cd $(LOCAL_FEED_FOLDER) && git clone $(PACKAGE_EXTENDROOT_GIT) extendRoot
	cd $(LOCAL_FEED_FOLDER) && git clone $(PACKAGE_PIRATEBOX_GIT) piratebox
	cd $(LOCAL_FEED_FOLDER) && git clone $(PACKAGE_PBXOPKG_GIT) pbxopkg
	cd $(LOCAL_FEED_FOLDER) && git clone $(PACKAGE_PIRATEBOXMESH_GIT) piratebox-mesh
##test_local_folder:= $(wildcard $(LOCAL_FEED_FOLDER)/* )

switch_local_feed_to_dev:
	$(call git_checkout_development, $(LOCAL_FEED_FOLDER)/box-installer)
	$(call git_checkout_development, $(LOCAL_FEED_FOLDER)/librarybox)
	$(call git_checkout_development, $(LOCAL_FEED_FOLDER)/piratebox)
	$(call git_checkout_development, $(LOCAL_FEED_FOLDER)/extendRoot)
	$(call git_checkout_development, $(LOCAL_FEED_FOLDER)/pbxopkg)
	$(call git_checkout_development, $(LOCAL_FEED_FOLDER)/piratebox-mesh)
# no dev branch for usb config scripts yet
#	$(call git_checkout_development, $(LOCAL_FEED_FOLDER)/usb-config-scripts)

define git_checkout_development
	cd $(1) && git checkout development
endef

apply_local_feed: $(LOCAL_FEED_FOLDER) $(OPENWRT_FEED_FILE)
	echo "src-link local $(LOCAL_FEED_FOLDER)" >> $(OPENWRT_FEED_FILE)

# Pulls an overall refresh
update_all_feeds:
	cd $(OPENWRT_DIR) && ./scripts/feeds update -a

# Remember that you might have to switch the the branches on git-packages like
# the openwrt-packages in the feed folder or PirateBoxScripts_Webserver to get
# the correct versions together (before release 1.0 it is a bit inconstent due
# to a restructuration)

# Installs all packages from local-feed folder to build-environment
install_local_feed:
	cd $(OPENWRT_DIR) && ./scripts/feeds install -p local -a

# Installs all packages from remote git repository to build environment
install_piratebox_feed:
	cd $(OPENWRT_DIR) && ./scripts/feeds install -p piratebox -a

# Copy OpenWRT config and build toolchain and OpenWRT
#
# Note: Toolkit-build needs to run single threaded, because sometimes
# build-dependencies fail.
# Package-Build runs fine multi-threaded.
#
# Once the toolchain id build, you can build single packages in the openwrt
# folder:
#    make package/feeds/<feed>/<package>/compile
#    make package/feeds/<feed>/<package>/install
build_openwrt:
	cp $(HERE)/configs/openwrt $(OPENWRT_DIR)/.config
# cd $(OPENWRT_DIR) && make tools/install
# cd $(OPENWRT_DIR) && make toolchain/install
	cd $(OPENWRT_DIR) && make -j $(THREADS)

build_openwrt_snapshot:
	cp $(HERE)/configs/openwrt.snapshot $(OPENWRT_DIR)/.config
# cd $(OPENWRT_DIR) && make tools/install
# cd $(OPENWRT_DIR) && make toolchain/install
	cd $(OPENWRT_DIR) && make -j $(THREADS)

# Acquire the stable packages that are not in the official OpenWRT repository
# yet
#
# This target will be obsolete in the future and is not used by the snapshot target
acquire_stable_packages:
	wget -nc http://stable.openwrt.piratebox.de/all/packages/pbxopkg_0.0.6_all.ipk -P $(OPENWRT_DIR)/bin/ar71xx/packages
	wget -nc http://stable.openwrt.piratebox.de/all/packages/piratebox-mesh_1.1.1_all.ipk -P $(OPENWRT_DIR)/bin/ar71xx/packages

# Acquire the beta packages that are not in the official OpenWRT repository yet
#
# This target will be obsolete in the future and is not used by the snapshot target
acquire_beta_packages:
	wget -nc http://beta.openwrt.piratebox.de/all/packages/pbxopkg_0.0.6_all.ipk -P $(OPENWRT_DIR)/bin/ar71xx/packages
	wget -nc http://beta.openwrt.piratebox.de/all/packages/piratebox-mesh_1.1.2_all.ipk -P $(OPENWRT_DIR)/bin/ar71xx/packages

# Build the piratebox firmware images and install.zip
piratebox:
	cd $(IMAGE_BUILD) &&  make all INSTALL_TARGET=piratebox
	@ echo "========================"
	@ echo "Build process completed."
	@ echo "========================"
	@ echo "Your build is now available in $(IMAGE_BUILD)/target_piratebox"

# Create local repository and start http server to serve files
#
# Runs a repository, that will only contain files having "all" as naming
# pattern.
# This local www repository is used for the openwrt-image-build.
# That toolset generates out of the stock OpenWRT ImageBuilder the custom files, we use.
# Read more about ImageBuild: http://wiki.openwrt.org/doc/howto/obtain.firmware.generate
# For getting our packages into the custom image, we inject our local repository
# into the build process and get our package-dependencies from there.
# --- see more informations in openwrt-image-build folder.
run_repository_all:
	mkdir -p $(WWW)
	ln -s $(OPENWRT_DIR)/bin/ar71xx $(WWW)/all
	rm $(OPENWRT_DIR)/bin/ar71xx/packages/*ar71xx* -f
	cd $(OPENWRT_DIR) && make package/index
	cd $(WWW) && touch $(WWW_PID_FILE) && python3 -m http.server $(WWW_PORT) & echo "$$!" > $(WWW_PID_FILE)

# Stop the repository if a pid file is present
stop_repository_all:
	if [ -e $(WWW_PID_FILE) ]; then kill -9 `cat $(WWW_PID_FILE)` && rm $(WWW_PID_FILE); fi;

start_timer:
	@ date +%s > time.log

end_timer:
	@ echo Build took \
		$$(expr \( $$(date +%s) - $$(cat time.log) \) / 60) min \
		$$(expr \( $$(date +%s) - $$(cat time.log) \) % 60) sec
	@ rm -rf time.log

# Stop the repository if a pid file is present
stop_repository_all:
	if [ -e $(WWW_PID_FILE) ]; then kill -9 `cat $(WWW_PID_FILE)` && rm $(WWW_PID_FILE); fi;

start_timer:
	@ date +%s > time.log

end_timer:
	@ echo Build took \
		$$(expr \( $$(date +%s) - $$(cat time.log) \) / 60) min \
		$$(expr \( $$(date +%s) - $$(cat time.log) \) % 60) sec
	@ rm -rf time.log

# Build the piratebox stable release
auto_build_stable: \
	start_timer \
	clean \
	openwrt_env \
	apply_piratebox_feed \
	update_all_feeds \
	install_piratebox_feed \
	create_piratebox_script_image \
	build_openwrt \
	acquire_stable_packages \
	run_repository_all \
	piratebox \
	stop_repository_all \
	end_timer

# Build the piratebox beta release, this uses the development branch of the
# openwrt-piratebox-feed
auto_build_beta: \
	start_timer \
	clean \
	openwrt_env \
	apply_piratebox_beta_feed \
	update_all_feeds \
	install_piratebox_feed \
	create_piratebox_script_image \
	build_openwrt \
	acquire_beta_packages \
	run_repository_all \
	piratebox \
	stop_repository_all \
	end_timer

# Build the piratebox snapshot release
auto_build_snapshot: \
	start_timer \
	clean \
	openwrt_env \
	apply_local_feed \
	switch_local_feed_to_dev \
	update_all_feeds \
	copy_image_board \
	install_local_feed \
	create_piratebox_script_image \
	build_openwrt_snapshot \
	run_repository_all \
	piratebox \
	stop_repository_all \
	end_timer

# Build the piratebox from the local feed
# Does basically the same thing as the above target, except it does not switch
# branches in the local feed.
auto_build_local: \
	start_timer \
	clean \
	openwrt_env \
	apply_local_feed \
	update_all_feeds \
	copy_image_board \
	install_local_feed \
	create_piratebox_script_image \
	build_openwrt_snapshot \
	run_repository_all \
	piratebox \
	stop_repository_all \
	end_timer

# Prepare for a new build without deleting the whole toolchain
clean: stop_repository_all
	if [ -e $(IMAGE_BUILD) ]; then cd $(IMAGE_BUILD) && make clean; fi;
	if [ -e $(OPENWRT_DIR) ]; then cd $(OPENWRT_DIR) && make clean; fi;
	rm -rf $(OPENWRT_FEED_FILE)
	rm -rf $(IMAGE_BUILD)/target_piratebox

# Delete all files and directories that were created during the build process
distclean: stop_repository_all
	rm -rf $(OPENWRT_DIR)
	rm -rf $(WWW)
	rm -rf $(LOCAL_FEED_FOLDER)
	rm -rf $(IMAGE_BUILD)
	rm -rf $(PIRATEBOXSCRIPTS)
	rm -rf $(PIRATEBOX_BETA_FEED)

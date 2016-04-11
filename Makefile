HERE:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

# This is the value used for the -j flag when running make.
# Adjust this to a appropriate value for your system a good rule of thumb is the
# amount of cores your machine has available. +1 if you don't need to use the
# machine while building.
# You may pass this parameter to your make command:
#    make auto_build_stable THREADS=8
THREADS?=4

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


PIRATEBOX_FEED_GIT=https://github.com/PirateBox-Dev/openwrt-piratebox-feed.git
PIRATEBOX_DEV_FEED_GIT=https://github.com/PirateBox-Dev/openwrt-piratebox-feed.git;development
PIRATEBOX_BETA_FEED_GIT=https://github.com/PirateBox-Dev/openwrt-piratebox-feed.git;release-xx

IMAGE_BUILD_GIT=https://github.com/PirateBox-Dev/openwrt-image-build.git
IMAGE_BUILD=openwrt-image-build

# PirateBox-image files, which are used in the package
PIRATEBOXSCRIPTS_GIT=https://github.com/PirateBox-Dev/PirateBoxScripts_Webserver.git
PIRATEBOXSCRIPTS=PirateBoxScripts_Webserver/
PIRATEBOXBETA_BRANCH="release-xx"

# LibraryBox-image files
LIBRARYBOXSCRIPTS_GIT=https://github.com/LibraryBox-Dev/LibraryBox-core.git
LIBRARYBOXSCRIPTS=Librarybox-core/
LIBRARYBOXBETA_BRANCH="release-2.1"

# The default make target.
# Display some information about the available targets.
info:
	@ echo "Ooooop, please read the README"
	@ echo "=============================="
	@ echo "Available build targets:"
	@ echo "* openwrt_env"
	@ echo "* apply_piratebox_feed"
	@ echo "* update_all_feeds"
	@ echo "* install_piratebox_feed"
	@ echo "* create_piratebox_script_image"
	@ echo "* create_librarybox_script_image"
	@ echo "* checkout_librarybox_beta"
	@ echo "* checkout_piratebox_beta (currently disabled in auto-beta)"
	@ echo "* build_openwrt"
	@ echo "* build_openwrt_beta"
	@ echo "* build_openwrt_development"
	@ echo "* acquire_stable_packages"
	@ echo "* run_repository_all"
	@ echo "* piratebox"
	@ echo "* stop_repository_all"
	@ echo "* clean"
	@ echo "* distclean"
	@ echo "=============================="
	@ echo "Available auto build targets:"
	@ echo "* auto_build_stable"
	@ echo "* auto_build_beta"
	@ echo "* auto_build_development"

openwrt_env: $(OPENWRT_DIR) $(IMAGE_BUILD)

# Clone the imagebuild repository, checkout the AA-with-installer branch and
# adapt the Makefile to use this local repository.
$(IMAGE_BUILD):
	git clone $(IMAGE_BUILD_GIT)
	cd $(IMAGE_BUILD) && git checkout AA-with-installer

switch_to_local_webserver:
	sed -i "s|http://stable.openwrt.piratebox.de|http://127.0.0.1:$(WWW_PORT)|" $(IMAGE_BUILD)/Makefile
	sed -i "s|http://development.openwrt.piratebox.de|http://127.0.0.1:$(WWW_PORT)|" $(IMAGE_BUILD)/Makefile

# Clone the OpenWRT repository, configure it
$(OPENWRT_DIR):
	git clone $(OPENWRT_GIT)
	cd $(OPENWRT_DIR) && make defconfig
	cd $(OPENWRT_DIR) && make prereq

# Create piratebox script image and copy it to the build directory if available
create_piratebox_script_image: $(PIRATEBOXSCRIPTS)
	cd $(PIRATEBOXSCRIPTS) && make clean
	cd $(PIRATEBOXSCRIPTS) && make shortimage
	test -d $(IMAGE_BUILD) && cp $(PIRATEBOXSCRIPTS)/piratebox_ws_*_img.tar.gz $(IMAGE_BUILD)

# Clone the PirateBoxScripts repository
$(PIRATEBOXSCRIPTS):
	git clone $(PIRATEBOXSCRIPTS_GIT) $@

# Create LibraryBox script image and copy it to the build directory if available
create_librarybox_script_image: $(LIBRARYBOXSCRIPTS)
	cd $(LIBRARYBOXSCRIPTS) && make clean
	cd $(LIBRARYBOXSCRIPTS) && make shortimage
	test -d $(IMAGE_BUILD) && cp $(LIBRARYBOXSCRIPTS)/librarybox_*_img.tar.gz $(IMAGE_BUILD)

# Clone the LibraryBoxScripts repository
$(LIBRARYBOXSCRIPTS):
	git clone $(LIBRARYBOXSCRIPTS_GIT) $@

checkout_librarybox_beta: $(LIBRARYBOXSCRIPTS)
	cd $(LIBRARYBOXSCRIPTS) && git checkout $(LIBRARYBOXBETA_BRANCH)

checkout_librarybox_dev: $(LIBRARYBOXSCRIPTS)
	cd $(LIBRARYBOXSCRIPTS) && git checkout development

checkout_piratebox_beta: $(PIRATEBOXSCRIPTS)
	cd $(PIRATEBOXSCRIPTS) && git checkout $(PIRATEBOXBETA_BRANCH)

checkout_piratebox_dev: $(PIRATEBOXSCRIPTS)
	cd $(PIRATEBOXSCRIPTS) && git checkout development

# Apply the PirateBox feed
apply_piratebox_feed: $(OPENWRT_FEED_FILE)
	echo "src-git piratebox $(PIRATEBOX_FEED_GIT)" >> $(OPENWRT_FEED_FILE)

# Apply the PirateBox dev-feed
apply_piratebox_dev_feed: $(OPENWRT_FEED_FILE)
	echo "src-git piratebox $(PIRATEBOX_DEV_FEED_GIT)" >> $(OPENWRT_FEED_FILE)

# Copy the OpenWRT feed file
$(OPENWRT_FEED_FILE):
	cp $(OPENWRT_FEED_FILE).default $(OPENWRT_FEED_FILE)

# Apply PirateBox beta feed
apply_piratebox_beta_feed: $(OPENWRT_FEED_FILE) 
	echo "src-git piratebox $(PIRATEBOX_BETA_FEED_GIT)" >> $(OPENWRT_FEED_FILE)

switch_local_feed_to_dev: $(PIRATEBOXSCRIPTS) $(LIBRARYBOXSCRIPTS) 
	$(call git_checkout_development, $(PIRATEBOXSCRIPTS))
	$(call git_checkout_development, $(LIBRARYBOXSCRIPTS))
	# Revert the changes we made in Makefile
	cd $(IMAGE_BUILD) && git checkout . 
	$(call git_checkout_development, $(IMAGE_BUILD))

define git_checkout_development
	cd $(1) && git checkout development
endef

refresh_local_feeds:  $(PIRATEBOXSCRIPTS) $(LIBRARYBOXSCRIPTS)
	$(call git_refresh_repository, $(PIRATEBOXSCRIPTS))
	$(call git_refresh_repository, $(LIBRARYBOXSCRIPTS))
	# Revert the changes we made in Makefile
	cd $(IMAGE_BUILD) && git checkout . 
	$(call git_refresh_repository, $(IMAGE_BUILD))

## Refresh a repository feed
define git_refresh_repository
        cd $(1) && git pull
endef


# Pulls an overall refresh
update_all_feeds:  
	cd $(OPENWRT_DIR) && export LC_ALL=C && ./scripts/feeds update -a

# Remember that you might have to switch the the branches on git-packages like
# the openwrt-packages in the feed folder or PirateBoxScripts_Webserver to get
# the correct versions together (before release 1.0 it is a bit inconstent due
# to a restructuration)

# Installs all packages from remote git repository to build environment
install_piratebox_feed: 
	cd $(OPENWRT_DIR) && export LC_ALL=C && ./scripts/feeds install -p piratebox -a

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
	cd $(OPENWRT_DIR) && export LC_ALL=C && make -j $(THREADS)

build_openwrt_beta: 
	cp $(HERE)/configs/openwrt.beta $(OPENWRT_DIR)/.config
	cd $(OPENWRT_DIR) && export LC_ALL=C && make -j $(THREADS)

build_openwrt_development: 
	cp $(HERE)/configs/openwrt.snapshot $(OPENWRT_DIR)/.config
	cd $(OPENWRT_DIR) && export LC_ALL=C && make -j $(THREADS)

# Adjust configuration on image builder if beta needs changes
modify_image_builder_beta:
	sed -i -e 's|librarybox_2.1_img.tar.gz|librarybox_2.1_img.tar.gz|g' $(IMAGE_BUILD)/Makefile

# Build the piratebox firmware images and install.zip
piratebox: switch_to_local_webserver
	cd $(IMAGE_BUILD) &&  make all INSTALL_TARGET=piratebox
	@ echo "========================"
	@ echo "Build process completed."
	@ echo "========================"
	@ echo "Your build is now available in $(IMAGE_BUILD)/target_piratebox"

# Build the piratebox firmware images and install.zip
librarybox: switch_to_local_webserver
	sed -i -e 's|piratebox-mesh|pbxmesh|g'  $(IMAGE_BUILD)/Makefile
	cd $(IMAGE_BUILD) &&  make all INSTALL_TARGET=librarybox
	@ echo "========================"
	@ echo "Build process completed."
	@ echo "========================"
	@ echo "Your build is now available in $(IMAGE_BUILD)/target_librarybox"


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
	- ln -s $(OPENWRT_DIR)/bin/ar71xx $(WWW)/all
	rm $(OPENWRT_DIR)/bin/ar71xx/packages/*ar71xx* -f
	cd $(OPENWRT_DIR) && make package/index
	cd $(WWW) && touch $(WWW_PID_FILE) && python3 -m http.server $(WWW_PORT) & echo "$$!" > $(WWW_PID_FILE)

# Stop the repository if a pid file is present
stop_repository_all:
	- if [ -e $(WWW_PID_FILE) ]; then kill -9 `cat $(WWW_PID_FILE)` ; rm $(WWW_PID_FILE); fi;

start_timer:
	@ date +%s > time.log

end_timer:
	@ echo Build took \
		$$(expr \( $$(date +%s) - $$(cat time.log) \) / 60) min \
		$$(expr \( $$(date +%s) - $$(cat time.log) \) % 60) sec
	@ rm -rf time.log

# Stop the repository if a pid file is present
stop_repository_all:
	- if [ -e $(WWW_PID_FILE) ]; then kill -9 `cat $(WWW_PID_FILE)` ; rm $(WWW_PID_FILE); fi;

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
        create_librarybox_script_image \
	build_openwrt \
	run_repository_all \
	piratebox \
        librarybox \
	stop_repository_all \
	end_timer

# Build the piratebox beta release, this uses the development branch of the
# openwrt-piratebox-feed
# TODO ; fixme
#auto_build_beta: \
#	start_timer \
#	clean \
#	openwrt_env \
#	apply_piratebox_beta_feed \
#	update_all_feeds \
#	install_piratebox_feed \
#	checkout_librarybox_beta \
#	create_piratebox_script_image \
#	create_librarybox_script_image \
#	build_openwrt_beta \
#	modify_image_builder_beta \
#	run_repository_all \
#	piratebox \
#	librarybox \
#	stop_repository_all \
#	end_timer

# Build the piratebox snapshot release
auto_build_development: \
	start_timer \
	clean \
	openwrt_env \
	apply_piratebox_dev_feed \
	switch_local_feed_to_dev \
	refresh_local_feeds \
	update_all_feeds \
	checkout_piratebox_dev \
	checkout_librarybox_dev \
	create_piratebox_script_image \
	create_librarybox_script_image \
	build_openwrt_development \
	run_repository_all \
	piratebox \
	librarybox \
	stop_repository_all \
	end_timer

# Prepare for a new build without deleting the whole toolchain
clean: stop_repository_all
	if [ -e $(IMAGE_BUILD) ]; then cd $(IMAGE_BUILD) && make clean; fi;
	if [ -e $(OPENWRT_DIR) ]; then cd $(OPENWRT_DIR) && make clean; fi;
	rm -rf $(OPENWRT_FEED_FILE)
	rm -rf $(IMAGE_BUILD)/target_* 

# Delete all files and directories that were created during the build process
distclean: stop_repository_all
	rm -rf $(OPENWRT_DIR)
	rm -rf $(WWW)
	rm -rf $(IMAGE_BUILD)
	rm -rf $(PIRATEBOXSCRIPTS)
	rm -rf $(LIBRARYBOXSCRIPTS)

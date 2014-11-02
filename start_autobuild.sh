#!/bin/sh

### Matthias Strubel (c)2014 via GPL3
##    Autobuild and deploy script for PirateBox environment
##    with upload via lftp to a remove webside
##
##   Add it to /etc/rc.local or equivalent
##   To start manual and skip wait time and auto shutdown
##     run it like
##       # ./start_autobuild.sh go
##

## Server specific thread count
THREADS=$(grep processor  /proc/cpuinfo | wc -l)

## File that stops the automatic script, that you are able to do
##  work on the server, when the script autostarts.
exit_file=/tmp/no_build.semaphore
# Wait time before starting
auto_start_wait=120

deploy_folder=/tmp/deploy
log_folder=${deploy_folder}/log
build_log=${log_folder}/build.log
collect_log=${log_folder}/collect.log
package_destination=${deploy_folder}/all

## Adjust this path where your openwrt-dev-enfironment stuff is located
build_env=/home/admin/auto_build/openwrt-dev-environment

screen_cmd="screen -L -Dm -c ~/auto_screenrc"

if [ -z $1 ] ; then
	sleep $auto_start_wait
fi

if [ -e $exit_file ] ; then
	echo "Exit file ${exit_file} found. exiting"
	rm -v $exit_file
	exit 0
fi

#Empty deploy folder
[ -d deploy_folder ] && rm -rv  $deploy_folder
mkdir $deploy_folder
mkdir $log_folder


### Build
cd $build_env 
echo "##### Make clean" 
make clean 
rm -v openwrt-image-build/piratebox_ws_*_img.tar.gz
cd PirateBoxScripts_Webserver/  
make clean
echo "##### Make refresh_local_feeds ; Refresh repositories"
cd $build_env
$screen_cmd  make refresh_local_feeds
echo "##### Make auto_build_development"
cd $build_env
$screen_cmd make auto_build_development THREADS=$THREADS
RC=$?
cd $build_env/PirateBoxScripts_Webserver/  
make package

## Collect
if [ $RC -eq 0 ] ; then
	mkdir $package_destination 2>&1 >> $collect_log
	cp -rv  $build_env/openwrt/bin/ar71xx/packages $package_destination 2>&1 >> $collect_log
	cp -rv  $build_env/openwrt-image-build/target_* $deploy_folder 2>&1 >> $collect_log
#	cp  $build_env/PirateBoxScripts_Webserver/piratebox_ws_*_img.tar.gz $deploy_folder  2>&1 >> $collect_log
	cp  $build_env/PirateBoxScripts_Webserver/piratebox*.tar.gz $deploy_folder  2>&1 >> $collect_log
        cp ~/.screen/

	echo 'IndexOptions NameWidth=*' > $deploy_folder/.htaccess
	echo 'IndexOptions NameWidth=*' > $deploy_folder/all/packages/.htaccess
	echo 'IndexOptions NameWidth=*' > $deploy_folder/target_piratebox/.htaccess
fi


### Deploy
. ftp_config.sh
LCD="$deploy_folder"
lftp -c "set ftp:list-options -a;
set ftp:ssl-allow  false
open '$FTPURL';
lcd $LCD;
cd $RCD;
mirror --reverse \
       $DELETE \
       --verbose \
       --exclude-glob a-dir-to-exclude/ \
       --exclude-glob a-file-to-exclude \
       --exclude-glob a-file-group-to-exclude* \
       --exclude-glob other-files-to-exclude"


if [ -z $1 ] ; then
	sudo shutdown -h now 
fi

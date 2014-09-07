#!/bin/sh
#requires sudo rights

pb_pb_srcImg_url="http://piratebox.aod-rpg.de/piratebox_ws_1.0_img.tar.gz"
pb_pb_srcImg="piratebox_ws_1.0_img.tar.gz"
pb_pbimg="./piratebox_image_file.img"
mount_point="./mount_point"

if [ -z "$1"  ]; then
	echo "usage of PirateBox image helper : "
	echo "    ./image_helper.sh  <step>"
	echo " "
	echo "for step use:"
	echo "    download   -  download the current original imagefile"
	echo "    extract    -  Extract the file, like the PirateBox would do"
	echo "    mount      -  Mount the image file via loop and using sudo"
	echo "    umount     -  umount the image"
	echo "    package    -  replaces the downloaded tar.gz file for usage on PirateBox"
	echo " "
	echo "The order above, is the workflow order, download is optional (usually on first try) "
	echo "For preparing an imagefile, please unmount before packaging"
	exit 1
fi

if [ "$1" = "download" ]; then
	echo "(Re)Downloading..."
	wget "${pb_pb_srcImg_url}" -O "${pb_pb_srcImg}"
	shift
fi

if [ "$1" = "extract" ]; then
	echo "Extracting image file..."
	tar xzO -f "${pb_pb_srcImg}" > "${pb_pbimg}"
	shift
fi

if [ "$1" = "mount" ]; then
	echo "Mounting image file to ${mount_point}..."
	mkdir -p "${mount_point}"
	sudo mount -o loop,rw,sync, "${pb_pbimg}" "${mount_point}"
	echo "Tagging custom_version file..."
	sudo touch "${mount_point}/custom_image"
	shift
fi

if [ "$1" = "umount" ]; then
	echo "Unmounting image file..."
	sudo umount "${mount_point}"
	shift
fi

if [ "$1" = "package" ]; then
	echo "Packaging to ${pb_pb_srcImg}..."
	rm  "${pb_pb_srcImg}"
	tar czf "${pb_pb_srcImg}" "${pb_pbimg}"
	echo " "
	echo "Done with packaging."
	echo "Transfer the package to the install folder on your PirateBox' USB stick."
	echo "You can either copy it to the USB stick directly or transfer via scp:"
	echo " "
	echo "    scp ${pb_pb_srcImg} root@192.168.1.1:/mnt/usb/install "
	echo " "
	echo "In any case, you have to run the following commands on the Box to activate the changes:"
	echo " "
	echo "    /etc/init.d/piratebox stop"
	echo "    /etc/init.d/pirateobx updatePB"
	echo "    /etc/init.d/piratebox start"
	shift
fi

exit 0

#!/bin/sh

#
# last changed: 2018-12-06 KSTR
# version : 1.0
#
# ---------- create and restore presets backup -----------
# this is specific to the general update version !!

set -x  # debug on
 
ACTION=$1
if [ -z "$ACTION" ] ; then
	printf "%s\r\n" "E61 presets: no action given" >> /update/errors.log
	exit 61
fi

VERSION=$2
if [ -z "$VERSION" ] ; then
	printf "%s\r\n" "E62 presets: no version given" >> /update/errors.log
	exit 62
fi

systemctl stop playground
while  pidof playground ; do
	echo "stopping PG..."
	sleep 0.1
done
	

# add suffix to version string because files/folders/symlinks with conflicting names may exist
VERSION=$2.bak


if [ "$ACTION" = "--create" ] ; then
# create backup of currently installed presets
	# locate presets
	if [ -d /internalstorage/preset-manager ] ; then # nominal location "/internalstorage/preset-manager", either a dir or mounted flash
		PRESET_SOURCE_DIR=/internalstorage/preset-manager
	elif [ -d /preset-manager ] ; then # alternate (non-flash) location "/internalstorage/preset-manager"
		PRESET_SOURCE_DIR=/preset-manager
	else # nothing to backup, exit gracefully
		printf "%s\r\n" "W60 presets: no data to backup/restore" >> /update/errors.log
		exit 0
	fi
	
	rm -rf  /preset-manager.$VERSION  # delete any previous backup data
	cp -a  $PRESET_SOURCE_DIR  /preset-manager.$VERSION
	if   [ $? -ne 0 ] ; then # copy didn't work for some reason
		printf "%s\r\n" "E64 presets: could not backup data for \"$VERSION\"" >> /update/errors.log
		exit 64
	fi

elif [ "$ACTION" = "--restore" ] ; then
# restore presets from backup, we assume a correctly mounted flash (/internalstorage), otherwise fail
	error=0
	if [ -d /preset-manager.$VERSION ] ; then # presets backup exists
		# check for a properly config'd  /internalstorage/preset-manager
		if [ ! -d /internalstorage ] ; then  # mountpoint not preset
			DESTINATION_PATH=/preset-manager # so, use alternate path
		elif ! ( mount | grep /internalstorage >/dev/null ) ; then # not mounted 
			DESTINATION_PATH=/internalstorage/preset-manager # so, use primary path because PG will search here first
		else # everthing OK
			DESTINATION_PATH=/internalstorage/preset-manager
		fi
		
		# next three commands are prone to cause lost data during a power-fail etc. !!
		rm -rf /preset-manager  # forced remove any alternate (and now non-used anyway) dir
		rm -rf $DESTINATION_PATH  # kill any destination data if exist (might be above dir, though)
		cp -a /preset-manager.$VERSION  $DESTINATION_PATH # restore presets
		if [ $? -ne 0 ] ; then # copy failed
			error=65
		fi
		
		rm -rf /preset-manager.$VERSION  # remove backup
		if [ $error -ne 0 ] ; then # restore failed
			printf "%s\r\n" "E${error} presets: restore failed for \"$VERSION\"" >> /update/errors.log
			exit $error
		fi
	else # no backup found
		printf "%s\r\n" "W60 presets: no data to backup/restore" >> /update/errors.log
		exit 0
	fi
else
	printf "%s\r\n" "E63 presets: illegal action given" >> /update/errors.log
	exit 63
fi

exit 0

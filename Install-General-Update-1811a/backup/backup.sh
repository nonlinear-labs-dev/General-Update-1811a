#!/bin/sh

#
# last changed: 2018-12-07 KSTR
# version : 1.0
#
# ---------- create and restore playground and system/services backups -----------
# this is specific to the general update version wrt to the system services !!

set -x  # debug on
 
ACTION=$1
if [ -z "$ACTION" ] ; then
	printf "%s\r\n" "E11 backup/restore: no action given" >> /update/errors.log
	exit 11
fi

VERSION=$2
#note : the passed version string should be short (<= 5 chars) and only contain letters and digits
if [ -z "$VERSION" ] ; then
	printf "%s\r\n" "E12 backup/restore: no version given" >> /update/errors.log
	exit 12
fi

# add suffix to version string because files/folders/symlinks with conflicting names may exist
VERSION=$2.bak


if [ "$ACTION" = "--create" ] ; then
# create backups of currently installed version,
# but don't overwrite an existing backup from a previous run of this update,
# as this would wrongly backup the new files and would spoil a later rollback
	did_something=false
	# copy complete /etc/systemd/system and /lib/systemd/system folders, including ../multi-user.target.wants/ etc
	FOLDER=/etc/systemd/system
	[ ! -d $FOLDER.$VERSION ]  &&  cp -a  $FOLDER  $FOLDER.$VERSION &&  did_something=true
	FOLDER=/lib/systemd/system
	[ ! -d $FOLDER.$VERSION ]  &&  cp -a  $FOLDER  $FOLDER.$VERSION &&  did_something=true

	# copy /nonlinear/scripts folder and /nonlinear/playground symlink
	FOLDER=/nonlinear/scripts
	[ ! -d $FOLDER.$VERSION ]  &&  cp -a  $FOLDER  $FOLDER.$VERSION &&  did_something=true

	[ ! -L /nonlinear/playground.$VERSION ]  &&  cp -P  /nonlinear/playground  /nonlinear/playground.$VERSION &&  did_something=true
	
	if  ! $did_something ; then # nothing was backed up
		printf "%s\r\n" "W10 backup/restore: Warning, data for \"$VERSION\" already backed up" >> /update/errors.log
		exit 10
	fi

elif [ "$ACTION" = "--restore" ] ; then
# restore from backup
# NOTE: /etc/systemd/system/install-update-from-usb.service will NOT be restored !
	# restore /etc/systemd/system and /lib/systemd/system folders. PRONE TO POWER FAIL CORRUPTION!!!
	did_something=false
	FOLDER=/etc/systemd/system
	if [ -d $FOLDER.$VERSION ] ; then # backup present
		FILE=bbbb.service
		if [ -f $FOLDER.$VERSION/$FILE ] ; then # file exists in backup
			cp -af  $FOLDER.$VERSION/$FILE  $FOLDER/$FILE # copy it into original folder, forced overwrite
			systemctl enable $FILE # and (re-)establish symlink to enable it
		else # file doesn't exist in backup
			systemctl disable $FILE # disable service
			rm -f $FOLDER/$FILE	# and delete it
		fi

		FILE=playground.service
		if [ -f $FOLDER.$VERSION/$FILE ] ; then # file exists in backup
			cp -af  $FOLDER.$VERSION/$FILE  $FOLDER/$FILE # copy it into original folder, forced overwrite
			systemctl enable $FILE # and (re-)establish symlink to enable it (redundant in this case)
		fi # note : playgrund must exist anyway so no point to deal with it when missing
		
		rm -rf  $FOLDER.$VERSION # delete the backup folder
		did_something=true
	fi

	FOLDER=/lib/systemd/system
	if [ -d $FOLDER.$VERSION ] ; then # backup present
		cp -af  $FOLDER.$VERSION/systemd-modules-load.service  $FOLDER/systemd-modules-load.service
		cp -af  $FOLDER.$VERSION/systemd-poweroff.service  $FOLDER/systemd-poweroff.service
		# note : no need to copy the "enable" symlinks as they aren't touched anyway
		rm -rf  $FOLDER.$VERSION # delete the backup folder
		did_something=true
	fi
	
	# restore /nonlinear/scripts folder and /nonlinear/playground symlink
	FOLDER=/nonlinear/scripts
	if [ -d $FOLDER.$VERSION ] ; then # backup present
		# note: this will not delete new data that will be unused in the restored state anyway
		cp -af  $FOLDER.$VERSION/*  $FOLDER # copy old data (merge folders)
		rm -rf  $FOLDER.$VERSION # delete the backup
		did_something=true
	fi

	if [ -L /nonlinear/playground.$VERSION ] ; then
		# note : the actual folder containing the playground files is not deleted, only the symlink is restored
		ln -nsf  `readlink /nonlinear/playground.$VERSION`  /nonlinear/playground `# restore symlink to original PG` \
		&&  unlink /nonlinear/playground.$VERSION # and delete backup symlink
		did_something=true
	fi

	if  ! $did_something ; then # nothing found to restore
		printf "%s\r\n" "E14 backup/restore: No backup \"$VERSION\" present" >> /update/errors.log
		exit 14
	fi
	
else
	printf "%s\r\n" "E13 backup/restore: illegal action given" >> /update/errors.log
	exit 13
fi

exit 0

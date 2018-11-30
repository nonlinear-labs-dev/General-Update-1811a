#!/bin/sh

#
# last changed: 2018-11-27 KSTR
# version : 1.0
#
# ---------- create and restore playground and system/services backups -----------
# this is specific to the general update version wrt /lib/systemd/system actions !!

set -x  # debug on
 
ACTION=$1
if [ -z "$ACTION" ] ; then
	printf "%s\r\n" "E11 backup/restore: no action given" >> /update/errors.log
	exit 11
fi

VERSION=$2
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
	# copy /etc/systemd/system and /lib/systemd/system folders
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
	# restore /etc/systemd/system and /lib/systemd/system folders. EXTREMLY PRONE TO POWER FAIL CORRUPTION!!!
	did_something=false
	FOLDER=/etc/systemd/system
	if [ -d $FOLDER.$VERSION ] ; then
		rm -rf  $FOLDER.temp
		mv  $FOLDER  $FOLDER.temp  &&  mv -f  $FOLDER.$VERSION  $FOLDER
		rm -rf  $FOLDER.temp
		did_something=true
	fi

	FOLDER=/lib/systemd/system
	if [ -d $FOLDER.$VERSION ] ; then
		cp -pf  $FOLDER.$VERSION/systemd-modules-load.service  $FOLDER/systemd-modules-load.service
		cp -pf  $FOLDER.$VERSION/systemd-poweroff.service  $FOLDER/systemd-poweroff.service
		rm -rf  $FOLDER.$VERSION
		did_something=true
	fi
	
	# restore /nonlinear/scripts folder and /nonlinear/playground symlink
	FOLDER=/nonlinear/scripts
	if [ -d $FOLDER.$VERSION ] ; then
		rm -rf  $FOLDER.temp
		mv  $FOLDER  $FOLDER.temp  &&  mv -f  $FOLDER.$VERSION  $FOLDER
		rm -rf  $FOLDER.temp
		did_something=true
	fi

	if [ -L /nonlinear/playground.$VERSION ] ; then
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

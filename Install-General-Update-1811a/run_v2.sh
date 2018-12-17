#!/bin/sh

#
# last changed: 2018-12-14 KSTR
# version : 1.0
#
# ---------- new style update process -----------
# With status messages on SOLED
# If a system update installs a new "install-update.sh" it will not be used in this update process
# as it was called from the previous "install-update.sh".That means, one cannot install 
# a new "install-update.sh" and use this new outer script for the rest of the update
# 
# Script does not return, user is forced to reboot.
#
#


if [ -x /nonlinear/text2soled/text2soled ] ; then
	TEXT2SOLED_EXE=/nonlinear/text2soled/text2soled
elif [ -x /nonlinear/text2soled ] ; then
	TEXT2SOLED_EXE=/nonlinear/text2soled
else
	TEXT2SOLED_EXE=echo
fi

function soled_msg() {
	# dual paths used for "text2soled" binary for backwards compatibility
	if (($#==1))
	then
		$TEXT2SOLED_EXE clear
		$TEXT2SOLED_EXE "$1" 5 85
#		$TEXT2SOLED_EXE "$1" 5 25
	fi
	if (($#==2))
	then
		$TEXT2SOLED_EXE clear
		$TEXT2SOLED_EXE "$1" 5 78
		$TEXT2SOLED_EXE "$2" 5 92
#		$TEXT2SOLED_EXE "$1" 5 18
#		$TEXT2SOLED_EXE "$2" 5 32
	fi
}

#-----------------------------------


set -x

# set verbosity of messages, VERBOSE=false will only display crucial information (general progress and errors)
VERBOSE=false

# give a name to this update, up to five characters (letters & digits only)
VERSION=1811a

# define messages
MSG_DO_NOT_SWITCH_OFF="DO NOT SWITCH OFF C15!"
MSG_REBOOT="PLEASE RESTART C15 NOW"
MSG_CREATING_BACKUP="creating backup "
MSG_UNINSTALLING="uninstalling "
MSG_SAVING_PRESETS="saving presets..."
MSG_RESTORING_PRESETS="restoring presets..."
MSG_UPDATING_RT_FIRMWARE="updating RT firmware..."
MSG_UPDATING_AUDIO_ENGINE="updating Audio Engine..."
MSG_UPDATING_SYSTEM_FILES="updating system files..."
MSG_UPDATING_UI_FIRMWARE="updating UI firmware..."
MSG_DONE="OK."
MSG_DONE_WITH_WARNING_CODE="OK. (Warning: "
MSG_FAILED_WITH_ERROR_CODE="FAILED! Error Code: "
# note: some hard-coded message texts are still present


systemctl stop playground
systemctl stop bbbb

rm -f /update/errors.log
LOG_FILE=/mnt/usb-stick/nonlinear-c15-update.log.txt
rm -f $LOG_FILE


errors=0
warnings=0
fatal=0
skip=0

# First, fix playground reference to symlink if needed
if [ ! -L /nonlinear/playground ] ; then    #playground is NOT a symlink
	mv /nonlinear/playground /nonlinear/playground_first_install `# rename real PG dir` \
	&& ln -s /nonlinear/playground_first_install /nonlinear/playground # and make symlink if successful
	# NOTE: if this ever fails we're in big trouble anyway
	if [ $? -ne 0 ] ; then
		echo "Fatal system error! Contact Nonlinear Labs.\r" > $LOG_FILE
		soled_msg "Fatal system error!" "Contact Nonlinear Labs."
		# loop until reboot
		while true
		do
			sleep 1
		done
	fi
fi


# save user presets, if any
soled_msg "$MSG_SAVING_PRESETS" "$MSG_DO_NOT_SWITCH_OFF"
chmod +x /update/presets/presets.sh
/bin/sh  /update/presets/presets.sh --create $VERSION
return_code=$?
if [ $return_code -eq 0 ] ; then 	# error codes 60...69
	$VERBOSE && soled_msg "$MSG_SAVING_PRESETS" "$MSG_DONE"
	$VERBOSE && sleep 1
else
	if [ $return_code -ne 60 ] ; then
		soled_msg "$MSG_SAVING_PRESETS" "$MSG_FAILED_WITH_ERROR_CODE""$return_code"
		errors=1
		sleep 2
	else
		$VERBOSE && soled_msg "$MSG_SAVING_PRESETS" "$MSG_DONE_WITH_WARNING_CODE""$return_code)"
		warnings=1
	fi
	$VERBOSE && sleep 2
fi


# uboot-update (incl. fix of internal flash mounting) must run BEFORE any system backup
# the repartioning and mounting of the internal flash may result in lost presets when the flash
# isn't properly mounted during install time and /internalstorage/preset-manager does not exist
if [ -d "/update/uboot/" ] ; then
	soled_msg "updating boot-loader..." "$MSG_DO_NOT_SWITCH_OFF"
	chmod +x /update/uboot/update-uboot.sh
	/bin/sh /update/uboot/update-uboot.sh  1>/update/uboot/uboot.stdout.log  2>/update/uboot/uboot.stderr.log
	return_code=$?
	if [ $return_code -eq 0 ] ; then
		$VERBOSE && soled_msg "updating boot-loader..." "$MSG_DONE"
		$VERBOSE && sleep 2
	else
		soled_msg "updating boot-loader..." "Error:$return_code"
		cp /update/uboot/uboot.stdout.log  /mnt/usb-stick
		cp /update/uboot/uboot.stderr.log  /mnt/usb-stick
		sleep 2
	fi
fi


# restore user presets, if any
soled_msg "$MSG_RESTORING_PRESETS" "$MSG_DO_NOT_SWITCH_OFF"
chmod +x /update/presets/presets.sh
/bin/sh  /update/presets/presets.sh --restore $VERSION
return_code=$?
if [ $return_code -eq 0 ]; then 	# error codes 60...69
	$VERBOSE && soled_msg "$MSG_RESTORING_PRESETS" "$MSG_DONE"
else
	if [ $return_code -ne 60 ] ; then
		soled_msg "$MSG_RESTORING_PRESETS" "$MSG_FAILED_WITH_ERROR_CODE""$return_code"
		errors=1
		sleep 2
	else
		$VERBOSE && soled_msg "$MSG_RESTORING_PRESETS" "$MSG_DONE_WITH_WARNING_CODE""$return_code)"
		warnings=1
	fi
	$VERBOSE && sleep 2
fi



# LPC update
if [ true ]; then 	# LPC update unconditionally, no backup anyway
	soled_msg "$MSG_UPDATING_RT_FIRMWARE" "$MSG_DO_NOT_SWITCH_OFF"
	chmod +x /update/LPC/lpc_update.sh
	/bin/sh /update/LPC/lpc_update.sh /update/LPC/blob.bin
	return_code=$?
	if [ $return_code -eq 0 ]; then 	# error codes 30...39
		$VERBOSE && soled_msg "$MSG_UPDATING_RT_FIRMWARE" "$MSG_DONE"
	else
		if [ $return_code -ne 30 ] ; then
			soled_msg "$MSG_UPDATING_RT_FIRMWARE" "$MSG_FAILED_WITH_ERROR_CODE""$return_code"
			errors=1
			sleep 2
		else
			$VERBOSE && soled_msg "$MSG_UPDATING_RT_FIRMWARE" "$MSG_DONE_WITH_WARNING_CODE""$return_code)"
			warnings=1
		fi
	fi
	$VERBOSE && sleep 2
fi

# ePC update
if [ true ]; then 	# ePC update unconditionally, no backup anyway
	soled_msg "$MSG_UPDATING_AUDIO_ENGINE" "$MSG_DO_NOT_SWITCH_OFF"
	chmod +x /update/EPC/epc_update.sh
	/bin/sh /update/EPC/epc_update.sh
	return_code=$?
	if [ $return_code -eq 0 ]; then 	# error codes 40...49
		$VERBOSE && soled_msg "$MSG_UPDATING_AUDIO_ENGINE" "$MSG_DONE"
	else
		if [ $return_code -ne 40 ] ; then
			soled_msg "$MSG_UPDATING_AUDIO_ENGINE" "$MSG_FAILED_WITH_ERROR_CODE""$return_code"
			errors=1
			sleep 2
		else
			$VERBOSE && soled_msg "$MSG_UPDATING_AUDIO_ENGINE" "$MSG_DONE_WITH_WARNING_CODE""$return_code)"
			warnings=1
		fi
	fi
	$VERBOSE && sleep 2
fi

# create system & playground backups
soled_msg "$MSG_CREATING_BACKUP""\"$VERSION\"..." "$MSG_DO_NOT_SWITCH_OFF"
chmod +x /update/backup/backup.sh
/bin/sh  /update/backup/backup.sh --create $VERSION
return_code=$?
if [ $return_code -eq 0 ]; then 	# error codes 10...19
	$VERBOSE && soled_msg "$MSG_CREATING_BACKUP""\"$VERSION\"..." "$MSG_DONE"
else
	if [ $return_code -ne 10 ] ; then
		soled_msg "$MSG_CREATING_BACKUP""\"$VERSION\"..." "$MSG_FAILED_WITH_ERROR_CODE""$return_code"
		errors=1; fatal=1; skip=1
		sleep 2
	else
		$VERBOSE && soled_msg "$MSG_CREATING_BACKUP""\"$VERSION\"..." "$MSG_DONE_WITH_WARNING_CODE""$return_code)"
		warnings=1
	fi
fi
$VERBOSE && sleep 2

# system files update
if [ $skip -eq 0 ]; then 	# system file update only if backup was successful
	soled_msg "$MSG_UPDATING_SYSTEM_FILES" "$MSG_DO_NOT_SWITCH_OFF"
	chmod +x /update/system/system_update.sh
	/bin/sh  /update/system/system_update.sh
	return_code=$?
	if [ $return_code -eq 0 ]; then 	# error codes 20...29
		$VERBOSE && soled_msg "$MSG_UPDATING_SYSTEM_FILES" "$MSG_DONE"
	else
		if [ $return_code -ne 20 ] ; then
			soled_msg "$MSG_UPDATING_SYSTEM_FILES" "$MSG_FAILED_WITH_ERROR_CODE""$return_code"
			errors=1; fatal=1
			sleep 2
		else
			$VERBOSE && soled_msg "$MSG_UPDATING_SYSTEM_FILES" "$MSG_DONE_WITH_WARNING_CODE""$return_code)"
			warnings=1
		fi
	fi
	$VERBOSE && sleep 2
fi

# playground update
if [[ ( $skip -eq 0 ) && ( $fatal -eq 0 ) ]]; then 	# playground update only if backup and system file update both were successful
	soled_msg "$MSG_UPDATING_UI_FIRMWARE" "$MSG_DO_NOT_SWITCH_OFF"
	chmod +x /update/BBB/bbb_update.sh
	/bin/sh /update/BBB/bbb_update.sh
	return_code=$?
	if [ $return_code -eq 0 ]; then 	# error codes 50...59
		$VERBOSE && soled_msg "$MSG_UPDATING_UI_FIRMWARE" "$MSG_DONE"
	else
		if [ $return_code -ne 50 ] ; then
			soled_msg "$MSG_UPDATING_UI_FIRMWARE" "$MSG_FAILED_WITH_ERROR_CODE""$return_code"
			errors=1; fatal=1
			sleep 2
		else
			$VERBOSE && soled_msg "$MSG_UPDATING_UI_FIRMWARE" "$MSG_DONE_WITH_WARNING_CODE""$return_code)"
			warnings=1
		fi
	fi
	$VERBOSE && sleep 2
fi


# error recovery
if [ $errors -eq 0 ] ; then # update executed successfully
	if [ $warnings -eq 0 ] ; then
		rm -f /update/errors.log
	fi
	echo "update finished"
	soled_msg "update to \"$VERSION\" done." "$MSG_REBOOT"
else # errors during update
	if [ $fatal -eq 0 ] ; then # not a fatal error, might be spurious error, user shall retry
		echo "update failed"
		soled_msg "update error! please retry." "$MSG_REBOOT"
	else # fatal error, try to recover previous system and PG state from backup
		soled_msg "update error!" "uninstalling update..."
		sleep 1
		soled_msg "$MSG_UNINSTALLING""\"$VERSION\"..." "$MSG_DO_NOT_SWITCH_OFF"
		chmod +x /update/backup/backup.sh
		/bin/sh  /update/backup/backup.sh --restore $VERSION
		return_code=$? 	# error codes 10...19
		if [ $return_code -eq 0 ]; then
			soled_msg "$MSG_UNINSTALLING""\"$VERSION\"..." "$MSG_DONE"
		else
			if [ $return_code -ne 10 ] ; then
				soled_msg "$MSG_UNINSTALLING""\"$VERSION\"..." "$MSG_FAILED_WITH_ERROR_CODE""$return_code"
			else
				soled_msg "$MSG_UNINSTALLING""\"$VERSION\"..." "$MSG_DONE_WITH_WARNING_CODE""$return_code)"
			fi
		fi
		sleep 3
		soled_msg "$MSG_REBOOT" 
	fi
fi

if [ -f /update/errors.log ] ; then
	cp -f /update/errors.log $LOG_FILE # copy log file if any
fi

# loop until reboot
while true
do
	sleep 1
done

#!/bin/sh

#
# last changed: 2018-12-07 KSTR
# version : 1.0
#
# ---------- uninstall a previous update of system and playground -----------
# Script does not return, user is forced to reboot.
#

function soled_msg() {
	# dual paths used for "text2soled" binary for backwards compatibility
	if (($#==1))
	then
		if [ -x /nonlinear/text2soled/text2soled ] ;
		then
			/nonlinear/text2soled/text2soled clear
			/nonlinear/text2soled/text2soled "$1" 5 85
#			/nonlinear/text2soled/text2soled "$1" 5 25
		else
			/nonlinear/text2soled clear
			/nonlinear/text2soled "$1" 5 85
#			/nonlinear/text2soled "$1" 5 25
		fi
	fi
	if (($#==2))
	then
		if [ -x /nonlinear/text2soled/text2soled ] ;
		then
			/nonlinear/text2soled/text2soled clear
			/nonlinear/text2soled/text2soled "$1" 5 78
			/nonlinear/text2soled/text2soled "$2" 5 92
#			/nonlinear/text2soled/text2soled "$1" 5 18
#			/nonlinear/text2soled/text2soled "$2" 5 32
		else
			/nonlinear/text2soled clear
			/nonlinear/text2soled "$1" 5 78
			/nonlinear/text2soled "$2" 5 92
#			/nonlinear/text2soled "$1" 5 18
#			/nonlinear/text2soled "$2" 5 32
		fi
	fi
}

#-----------------------------------

# give a name to this update
VERSION=1811a

systemctl stop playground
systemctl stop bbbb

rm -f /update/errors.log

LOG_FILE=/mnt/usb-stick/nonlinear-c15-update.log.txt
rm -f $LOG_FILE

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

soled_msg "uninstalling \"$VERSION\"..." "DO NOT SWITCH OFF C15!" 
chmod +x /update/backup/backup.sh
/bin/sh  /update/backup/backup.sh --restore $VERSION
return_code=$? 	# error codes 10...19
if [ $return_code -eq 0 ]; then
	soled_msg "uninstalling \"$VERSION\"..." "Done. Please reboot"
else
	if [ $return_code -ne 10 ] ; then
		if [ $return_code -eq 14 ] ; then  # special case: backup not found, this is not an error though
			soled_msg "uninstalling \"$VERSION\"..."  "Done (no data found)"
		else
			soled_msg "uninstalling \"$VERSION\"..."  "FAILED! Error Code: $return_code"
		fi
	else
		soled_msg "uninstalling \"$VERSION\"..." "Done. (Warning: $return_code)"
	fi
	sleep 3
	soled_msg "PLEASE RESTART C15 NOW"
fi

if [ -f /update/errors.log ] ; then
	cp -f $LOG_FILE # copy log file if any
fi

# loop until reboot
while true
do
	sleep 1
done




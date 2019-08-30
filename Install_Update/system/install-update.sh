#!/bin/sh
#
# last changed: 2018-12-10 KSTR
# version : 1.0
#
# ---------- intstall update from .tar archive on USB-stick


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

# First, fix playground reference to symlink if needed
if [ ! -L /nonlinear/playground ] ; then    #playground is NOT a link
	mv /nonlinear/playground /nonlinear/playground_first_install `# rename real PG dir` \
	&& ln -s /nonlinear/playground_first_install /nonlinear/playground # and make symlink if successful
fi

#if tar is present on stick
if [ -f /mnt/usb-stick/nonlinear-c15-update.tar ]
then
        #stop the playground (and any BBBB)
        systemctl stop playground
        systemctl stop bbbb

	#Delete old Updates
	mkdir -p /update
	rm -rf /update/*

        soled_msg "starting update..."

	#copy the update-tar
	cp /mnt/usb-stick/nonlinear-c15-update.tar /update		
	#force the rename of the tar to copied using cp and rm
	cp -pf /mnt/usb-stick/nonlinear-c15-update.tar /mnt/usb-stick/nonlinear-c15-update.tar-copied
	rm -f /mnt/usb-stick/nonlinear-c15-update.tar

	#change into update and untar the update
	cd /update
	tar xvf nonlinear-c15-update.tar
	rm -f nonlinear-c15-update.tar

	#make run.sh executable and run
	chmod +x /update/run.sh
	if [ ! -x /update/run.sh ] ; then
		soled_msg "Error: corrupt archive!"
	else
		if [ ! -f /update/run_v2.sh ] ; then # no new-style update script found
			soled_msg "old-style update is" "not supported anymore"
		else
			/bin/sh /update/run.sh
			soled_msg "PLEASE RESTART C15 NOW"
		fi
	fi

	while true
	do
		sleep 1
	done
fi
exit 0

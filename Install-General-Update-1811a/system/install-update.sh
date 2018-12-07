#!/bin/sh
#
# last changed: 2018-12-07 KSTR
# version : 1.0
#
# ---------- intstall update from .tar archive on USB-stick


function soled_msg() {
	# dual paths used for "text2soled" binary for backwards compatibility
	if [ -x /nonlinear/text2soled/text2soled ] ;
	then
		/nonlinear/text2soled/text2soled clear
		/nonlinear/text2soled/text2soled "$1" 5 85
	else
		/nonlinear/text2soled clear
		/nonlinear/text2soled "$1" 5 85
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
        systemctl stop bbbb
        systemctl stop playground

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
		sleep 3
	else
		/bin/sh /update/run.sh
		soled_msg "PLEASE RESTART C15 NOW"
	fi

	while true
	do
		sleep 1
	done
fi
exit 0

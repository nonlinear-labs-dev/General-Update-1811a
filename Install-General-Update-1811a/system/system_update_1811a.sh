#!/bin/sh
#
# last changed: 2018-12-07 KSTR
# version : 1.0
#
# ---------- Install system files, update to Rev.1811a -----------
# note : sensitive to corrupt data from power-fails etc !!

set -x

# version id of this system update, used only for temporary filename (not persistent)
VERSION=sys1811a

#install new update installer.
echo "Copy new update installer"
chmod 0755 /update/system/install-update.sh `# set executable` \
&& cp -pf  /update/system/install-update.sh  /nonlinear/scripts/install-update.sh.$VERSION `# copy with a temporary name` \
&& mv -f   /nonlinear/scripts/install-update.sh.$VERSION  /nonlinear/scripts/install-update.sh # atomic overwriting rename (fail-safe)
if [ $? -ne 0 ] ; then
	printf "%s\r\n" "E21 system update: installing new update installer script failed" >> /update/errors.log
	exit 21
fi


echo "Copy new scripts"
chmod 0755 /update/system/scripts/* \
&& cp -af  /update/system/scripts/*  /nonlinear/scripts/	# note : does NOT copy hidden files
if [ $? -ne 0 ] ; then
	printf "%s\r\n" "E22 system update: installing new system scripts failed" >> /update/errors.log
	exit 22
fi


errors=0
echo "Replace/add services..."
echo "...  /etc/systemd/system/*"
if [ $errors -eq 0 ] ; then
	FILE=install-update-from-usb.service
	chmod 0644  /update/system/services/etc_systemd_system/$FILE `# clear executable` \
	&& cp -pf   /update/system/services/etc_systemd_system/$FILE  /etc/systemd/system/$FILE.$VERSION `# copy with a temporary name` \
	&& mv -f    /etc/systemd/system/$FILE.$VERSION  /etc/systemd/system/$FILE # atomic rename (fail-safe)
	if [ $? -ne 0 ] ; then errors=1 ; fi
fi
if [ $errors -eq 0 ] ; then
	FILE=playground.service
	chmod 0644  /update/system/services/etc_systemd_system/$FILE `# clear executable` \
	&& cp -pf   /update/system/services/etc_systemd_system/$FILE  /etc/systemd/system/$FILE.$VERSION `# copy with a temporary name` \
	&& mv -f    /etc/systemd/system/$FILE.$VERSION  /etc/systemd/system/$FILE # atomic rename (fail-safe)
	if [ $? -ne 0 ] ; then errors=1 ; fi
fi

echo "...  /lib/systemd/system/*"
if [ $errors -eq 0 ] ; then
	FILE=systemd-modules-load.service
	chmod 0644  /update/system/services/lib_systemd_system/$FILE `# clear executable` \
	&& cp -pf   /update/system/services/lib_systemd_system/$FILE  /lib/systemd/system/$FILE.$VERSION `# copy with a temporary name` \
	&& mv -f    /lib/systemd/system/$FILE.$VERSION  /lib/systemd/system/$FILE # atomic rename (fail-safe)
	if [ $? -ne 0 ] ; then errors=1 ; fi
fi
if [ $errors -eq 0 ] ; then
	FILE=systemd-poweroff.service
	chmod 0644  /update/system/services/lib_systemd_system/$FILE `# clear executable` \
	&& cp -pf   /update/system/services/lib_systemd_system/$FILE  /lib/systemd/system/$FILE.$VERSION `# copy with a temporary name` \
	&& mv -f    /lib/systemd/system/$FILE.$VERSION  /lib/systemd/system/$FILE # atomic rename (fail-safe)
	if [ $? -ne 0 ] ; then errors=1 ; fi
fi

# something went wrong
if [ $errors -ne 0 ] ; then
	echo "installing new system services failed"
	printf "%s\r\n" "E23 system update: installing new system services failed" >> /update/errors.log
	exit 23
fi

echo "** completed successfully **"
exit 0

#!/bin/sh

rm -f /mnt/usb-stick/system_update_1811a.stdout.log
rm -f /mnt/usb-stick/system_update_1811a.stderr.log
chmod +x /update/system/system_update_1811a.sh
/bin/sh  /update/system/system_update_1811a.sh 1>/update/system/system_update_1811a.stdout.log 2>/update/system/system_update_1811a.stderr.log
returncode=$?
if [ $returncode -ne 0 ] ; then
	cp -pf /update/system/system_update_1811a.stdout.log  /mnt/usb-stick/
	cp -pf /update/system/system_update_1811a.stderr.log  /mnt/usb-stick/
fi
exit $returncode

#!/bin/sh

rm -f /mnt/usb-stick/bbb_update_1811a.stdout.log
rm -f /mnt/usb-stick/bbb_update_1811a.stderr.log
chmod +x /update/BBB/bbb_update_1811a.sh
/bin/sh  /update/BBB/bbb_update_1811a.sh 1>/update/BBB/bbb_update_1811a.stdout.log 2>/update/BBB/bbb_update_1811a.stderr.log
returncode=$?
if [[ ( $returncode -ne 0 ) && ( $returncode -ne 50 ) ]] ; then
	cp -pf /update/BBB/bbb_update_1811a.stdout.log  /mnt/usb-stick/
	cp -pf /update/BBB/bbb_update_1811a.stderr.log  /mnt/usb-stick/
fi
exit $returncode
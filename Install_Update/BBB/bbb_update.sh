#!/bin/sh

rm -f /mnt/usb-stick/bbb_update_XXX.stdout.log
rm -f /mnt/usb-stick/bbb_update_XXX.stderr.log
chmod +x /update/BBB/bbb_update_XXX.sh
/bin/sh  /update/BBB/bbb_update_XXX.sh 1>/update/BBB/bbb_update_XXX.stdout.log 2>/update/BBB/bbb_update_XXX.stderr.log
returncode=$?
if [[ ( $returncode -ne 0 ) && ( $returncode -ne 50 ) ]] ; then
	cp -pf /update/BBB/bbb_update_XXX.stdout.log  /mnt/usb-stick/
	cp -pf /update/BBB/bbb_update_XXX.stderr.log  /mnt/usb-stick/
fi
exit $returncode

#!/bin/sh

rm -f /mnt/usb-stick/bbb_update_NonLinuxEPC_update_test.stdout.log
rm -f /mnt/usb-stick/bbb_update_NonLinuxEPC_update_test.stderr.log
chmod +x /update/BBB/bbb_update_NonLinuxEPC_update_test.sh
/bin/sh  /update/BBB/bbb_update_NonLinuxEPC_update_test.sh 1>/update/BBB/bbb_update_NonLinuxEPC_update_test.stdout.log 2>/update/BBB/bbb_update_NonLinuxEPC_update_test.stderr.log
returncode=$?
if [[ ( $returncode -ne 0 ) && ( $returncode -ne 50 ) ]] ; then
	cp -pf /update/BBB/bbb_update_NonLinuxEPC_update_test.stdout.log  /mnt/usb-stick/
	cp -pf /update/BBB/bbb_update_NonLinuxEPC_update_test.stderr.log  /mnt/usb-stick/
fi
exit $returncode

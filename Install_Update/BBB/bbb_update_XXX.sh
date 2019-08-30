#!/bin/sh
#
# last changed: 2019-08-28 KSTR
# version : 1.0
#
# ---------- Install playground files & services, update to Rev.1811a -----------
# note : sensitive to corrupt data from power-fails etc !!

set -x 		# debug on

# not really interested in  updating the playground for now ... so no new verison
# version=pgxxx

# check if sshpass is installed 
if [ ! /nonlinear/sshpass/sshpass ]; then # sshpass is not installed 
	rm -rf /nonlinear/sshpass
	mkdir /nonlinear/sshpass
	cp  /update/BBB/sshpass/sshpass /nonlinear/sshpass/ 
fi

# stop the gettimefromepc service and rewrite time.sh
# do we need to wrewrite the service too? 
systemctl stop gettimefromepc.service

rm /nonlinear/scripts/time.sh 
touch /nonlinear/scripts/time.sh

echo -e "#!/bin/sh\n" >>  /nonlinear/scripts/time.sh
echo -e "rm /root/.ssh/knonw_hosts" >>  /nonlinear/scripts/time.sh  #required for every new session ... for what ever reason!
echo -e "date --set="$(/nonlinear/sshpass/sshpass -p 'sscl' ssh sscl@192.168.10.10 "date '+%F %T'")"" >> /nonlinear/scripts/time.sh

systemctl restart gettimefromepc.service

exit_code=0


errors=0

# something went wrong
if [ $errors -ne 0 ] ; then
	printf "%s\r\n" "Updating BBB failed ..." >> /update/errors.log
	exit 53
fi

# come here only when no errors
exit $exit_code

#!/bin/sh
#
# last changed: 2018-12-07 KSTR
# version : 1.0
#
# ---------- Install playground files & services, update to Rev.1811a -----------
# note : sensitive to corrupt data from power-fails etc !!

set -x 		# debug on

# version id of this playground build
version=pg1811a

# First, fix playground reference to symlink if needed
if [ ! -L /nonlinear/playground ] ; then    #playground is NOT a link
	mv /nonlinear/playground /nonlinear/playground_first_install `# rename real PG dir` \
	&& ln -s /nonlinear/playground_first_install /nonlinear/playground # and make symlink if successful
fi

# change permissions of executables within playground folder(s)
chmod 0755 /update/BBB/playground/resources/pack-journal.sh
chmod 0755 /update/BBB/playground/playground
chmod 0755 /update/BBB/playground/bbbb
chmod 0666 /update/BBB/playground/dirty

exit_code=0

if [[ ( -d /nonlinear/playground-$version ) \
&& ( ! -f /nonlinear/playground-$version/dirty ) \
&& ( "`readlink /nonlinear/playground`" = "/nonlinear/playground-$version" ) \
&& ( "`cat /nonlinear/playground/NonMaps/war/nonmaps-version.txt`" = "`cat /update/BBB/playground/NonMaps/war/nonmaps-version.txt`" ) ]]
then # this exact PG was correctly installed before
	printf "%s\r\n" "W50 UI update: Warning, this UI has been successfully installed before. Quit without installing." >> /update/errors.log
	exit_code=50 	# 50 indicates warnings only, no fatal errors
	# we actually do NOT exit here because the forced system files update that has just finished before this script is called
	# overwrites the playground.service with the version *without* BBBB !!!! ==> services reinstall as below required !
else # new install (incl. same global version but different PG build), or overriding a failed install
	rm -rf  /nonlinear/playground-$version		# remove any leftovers from a previous unsuccessful install

	# copy all PG files and folders. Test if PG and BBBB executables are present.
	cp -af /update/BBB/playground /nonlinear/playground-$version \
	&& test -x /nonlinear/playground-$version/playground \
	&& test -x /nonlinear/playground-$version/bbbb
	if [ $? -ne 0 ] ; then
		printf "%s\r\n" "E52 UI update: installing new UI failed (missing/corrupted files)" >> /update/errors.log
		exit 52
	fi
fi

errors=0
# Replace/add services.
if [ $errors -eq 0 ] ; then
	FILE=bbbb.service
	chmod 0644  /update/BBB/$FILE `# remove potential executable flags` \
	&& cp -af   /update/BBB/$FILE  /etc/systemd/system/$FILE # copy w/ forced overwrite
	if [ $? -ne 0 ] ; then errors=1 ; fi
	ln -nfs  ../$FILE /etc/systemd/system/multi-user.target.wants/$FILE  # symlink BBBB service, forced overwrite
fi

if [ $errors -eq 0 ] ; then
	FILE=playground.service
	chmod 0644  /update/BBB/$FILE `# remove potential executable flags` \
	&& cp -af   /update/BBB/$FILE  /etc/systemd/system/$FILE `# copy w/ forced overwrite` \
	&& ln -nfs  /nonlinear/playground-$version /nonlinear/playground # update symlink to new playground
	if [ $? -ne 0 ] ; then errors=1 ; fi
fi


# something went wrong
if [ $errors -ne 0 ] ; then
	printf "%s\r\n" "E53 UI update: installing new UI system services failed" >> /update/errors.log
	exit 53
fi

# come here only when no errors
exit $exit_code

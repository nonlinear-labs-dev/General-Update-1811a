#!/bin/sh

#
# last changed: 2018-12-07 KSTR
# version : 1.0
#
# ---------- install a new audio engine on the ePC -----------
# errors are reported.
# the script waits up to 20 seconds for the ePC to be up and and running, else
# it will report a time-out
#

#the origin and dest. filenames variables
origin="/update/EPC/Phase22Renderer.ens"
destination="/mnt/windows/Phase22Renderer.ens"

pingcount=20	# 20 seconds should be a safe time-out even when ePC has just started to boot right now (worst-case)
#loop <pincount> seconds to wait for the EPC to startup
while [ $pingcount -ne 0 ] ; do
  ping -c 1 -W 1 192.168.10.10  # 1 try and 1 sec timeout
  return_code=$?
  if [ $return_code -eq 0 ] ; then
      ((pingcount = 1))
  fi
  echo $((pingcount = pingcount - 1))
done

if [ $return_code -eq 0 ]; then  # host is reachable
  umount -f /mnt/windows  # unmount, just in case, to prevent "device busy"
  mkdir -p /mnt/windows  # create the mountpoint if nonexistent
  # now mount the windows-drive and copy the ensemble only if mount was succesful,
  # ... otherwise cp would succesfully copy into /mnt/windows as a regular local directory!
  mount.cifs //192.168.10.10/update /mnt/windows -o user=TEST,password=TEST  &&  cp -af "$origin" "$destination"
  return_code=$?  # save result
  sync
  umount -f /mnt/windows
  if [ $return_code -eq 0 ] ; then	 # mount & file copy was succesful
	exit 0
  else # mount.cifs and/or cp reported error
    printf "%s\r\n" "E42 audio update: file write failed" >> /update/errors.log
    exit 42
  fi
else  # host is not available
  printf "%s\r\n" "E41 audio update: cannot connect to ePC" >> /update/errors.log
  exit 41
fi

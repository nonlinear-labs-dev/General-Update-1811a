# NonLinuxEPC_update_test

The idea of this branch is to gather and test all required updates procedures before releasing a C15 with a NonLinux ePC

## BBB
* deploy sshpass on the BBB - We need sshpass on the BBB since the EPC is secured by a password.
* change /nonlinear/scripts/time.sh to retrive the time from the EPC via ssh (sshpass required)

## EPC
* install an ePC update from BBB via ethernet - When a USB-Update stick is recognized by the BBB, the BBB should provide the update on a server. The EPC will then be forced to reboot and will autmatically check for updates on the BBB server.

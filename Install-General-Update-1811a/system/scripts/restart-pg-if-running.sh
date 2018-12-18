#!/bin/sh

#
# last changed: 2018-12-18 KSTR
# version : 1.0
#
# ---------- restart playground if running -----------
# This restarts a running PG by forcing an exception which exits the PG ==> the PG service re-schedules a PG start.
# Workaround for PG getting inoperative when BBB-Bridge crashes, even though both PG and BBBB restart.
# In the bbbb.service this script is called as an ExecStartPost= command which assures the Bridge is up
# before the PG is restarted.
# Not nice, I know, but the only quickly feasible fix I found.

kill -n 4 `pidof playground` >/dev/null  # if PG PID doesn't exist pidof returns "" and kill terminates with a usage message
exit 0

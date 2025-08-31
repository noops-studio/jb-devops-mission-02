Prep stage: 40%
1. Make sure the crond service is oﬀ. if not, turn it oﬀ, then redirect its status from
systemctl to a file named crond.status in your home directory
2. Under your home directory create a folder named “logs-26052025” and change
its group to final (noEce you’re a member)
3. Set full permissions to both you and the group, and none to ‘other’, and set the
state so that the default group of new files in this directory will be final
4. Create a 100 empty logs files under the “logs” directory (created on secEon 2)
named: username-daymonthyear-number.log (e.g., user3-26052025-1.log … user3-
26052025-100.log)
Maintenance: 40%
1. It appears the the logs containing the string 0.log in their file name have to be
moved to another locaEon
1. Create a directory under /tmp by the name username-zerologs.d (e.g.,
/tmp/user2-zerologs.d/)
2. Move all of these log files to this directory
3. Create a soT (symbolic) link in your original logs directory (under your home
directory) that will point your zerologs directory under /tmp
2. Sample the system processes every 10 seconds and save the samples in the
zerologs files (e.g., first sample will show in /tmp/user5-zerlogs.d/user5-26052025-
10.log, second sample in /tmp/user5-zerlogs.d/user5-26052025-20.log …)
3. Gather all lines from the zerologs files regarding the polkitd process, sort them by
their CPU usage and redirect the columns of their CPU and MEM to a file named
polkitd_cpu_usage.log under your home directory
Automa6on: 20%
Create a script that would implement the “Prep stage” named “prep.sh”. The script
should fit the date in which it is being executed (e.g., tomorrow the folder will be
named logs-27052025 and if the user is user7 the logs will be user7-27052025-1.log…).
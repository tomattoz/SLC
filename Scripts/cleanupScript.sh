#!/bin/bash

#Makes the userDirBkups if it doesn't exist
mkdir -p /Library/Management/userDirBkups

# Check if we need to do cleanup, depending on plist configuration.
HOUR = `defaults read /Library/Management/plists/Config.plist CleanupHour`
# Will run every 12 hours.
HOURPLUS12 = $((($HOUR + 12) % 24))

if [ `date +%H` -eq $HOUR ];
then
    logger "Removing old backups."
    find /Library/Management/userDirBkups -type d -mtime +2 -exec rm -rf {} \;
fi
exit 0

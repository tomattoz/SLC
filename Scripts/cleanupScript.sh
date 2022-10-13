#!/bin/bash

#Makes the userDirBkups if it doesn't exist
mkdir -p /Library/Management/userDirBkups

logger "Removing old backups."

find /Library/Management/userDirBkups -type d -mtime +2 -exec rm -rf {} \;

exit 0

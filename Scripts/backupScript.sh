#!/bin/bash

# Will touch this file to let the app know the backup finished.
MONITOR=/tmp/slc-finished
rm $MONITOR

LOCK=/tmp/trigger
[ -f $LOCK ] || exit 0

rm $LOCK

#Makes the userDirBkups if it doesn't exist
mkdir -p /Library/Management/userDirBkups

# And what's the key in there?
timeKey="keepBackups"

# So what's the actual value? Set it to a variable or something, guy
keepBackups=`defaults read $hardPrefs $timeKey`

# Ask The Prefs file who we're cleaning up after
userToClean="user"

# What's that users UID?
uidToClean="1025"

# Path to their directory
userDir="/Users/$userToClean"

# Path to backup Directory
tmpDir="/Library/Management/userDirBkups"

# plist files directory
plistsDir="/Library/Management/plists"

# Where are those preferences anyway?
hardPrefs="$plistsDir/edu.slc.logoutcleaner"

# Primary Local Admin
localAdmin="helpdesk"

# Other Admin Set by Prefs
secondaryAdmin="filmadmin"

# Path to Template Directory
safeUser="/Library/Management/userTemplate"

# Ask login window who our customer is
lastUser=`defaults read /Library/Preferences/com.apple.loginwindow lastUserName`

# Make a timestamp
timeS=`date ''+%m-%d-%y_%H.%M.%S''`

# Create the Backup Directory
mkdir -m 755 "$tmpDir"

mkdir -m 755 "$plistsDir"

# Set a variable for the whole path to the backups
fullTmpDir="$tmpDir/prevuser.$userToClean.$timeS"

echo %25 "Emptying Trashes"
cd $userDir/.Trash
if [[ `pwd` != $userDir/.Trash ]]; then
	logger "The RMBK script could not find user garbage, and therefore is not cleaning up after you. It is not your mother."
fi
if [[ `pwd` = $userDir/.Trash ]]; then
	rm -r *
fi
cd /.Trashes
if [[ `pwd` != /.Trashes ]]; then
	logger "The RMBK script could not find system garbage, and therefore is not cleaning up after you. It is not your mother."
fi
if [[ `pwd` = /.Trashes ]]; then
	rm -r *
fi

launchctl bootout user/$uidToClean &

echo %30"Copying Files"
if [[ "$lastUser" = "$userToClean" ]]; then
	mkdir -m 755 "$fullTmpDir"
	mv $userDir "$fullTmpDir"
	logger "Home folder $userDir deleted on logout at $timeS. Backup was created in $fullTmpDir"
fi
echo %45 "Copying Complete"
echo %60 "Restoring to Default State"
sleep 1
echo %BEGINPOLE
if [[ "$lastUser" = "$userToClean" ]]; then
	mkdir -m 755 $userDir
	/usr/bin/ditto -rsrcFork $safeUser $userDir
	/usr/sbin/chown -R $uidToClean:20 $userDir
	chmod -R 700 "$fullTmpDir"
	logger "Default home folder restored at $timeS"
fi

echo %80 "Repermissioning"
if [[ "$lastUser" = "$userToClean" ]]; then
	 /usr/sbin/chown -R 501:20 "$fullTmpDir"
	chmod -R 700 "$fullTmpDir"
fi

echo %100 "Complete. Logging out."

#echo removing Older than 48 hours
#echo folders to delete
#echo find "$tmpDir" -type d -Btime +48h -name 20\* -maxdepth 1
#find "$tmpDir" -type d -Btime +48h -name 20\* -maxdepth 1 -exec rm -r {} \;
#find "$tmpDir" -path *prevuser* -type d -mtime +2 -depth 1 -exec rm -rf {} \;
#find /Library/Management/userDirBkups -type d -mtime +2 -exec rm -rf {} \;

# Notify app the backup has finished.
touch "$MONITOR"

exit 0

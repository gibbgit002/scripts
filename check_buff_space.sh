#!/bin/sh
CHECK_ON=true
CHECK_SPACE=$(df -H | grep -vE '^Filesystem|tmpfs|cdrom' | grep buff | awk '{ print $5 }' | cut -d'%' -f1)
LOCKFILE=/var/lock/check_buff_space.lock

[ -f $LOCKFILE ] && exit 0

# Upon exit, remove lockfile.
trap "{ rm -f $LOCKFILE ; exit 255; }" EXIT

touch $LOCKFILE

while "$CHECK_ON"; do

  if [ "$(echo $CHECK_SPACE)" -ge 98 ]; then
    echo "The backup network drive, Buff, has used 98% of space" | mail -s "No Space left on Buff" gibb002.server@gmail.com

    killall backup.sh
    if [ $? -ne 0 ]; then
       echo "Unable to kill backup script!" | mail -s "Backup script still running!" gibb002.server@gmail.com
       CHECK_ON=false
    fi

  fi
  sleep 5
done

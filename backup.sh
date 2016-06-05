#!/bin/bash

BACKUP_DEV="//192.168.1.135/buff"
BACKUP_MNT="/media/buff"
BACKUP_TO="/media/buff/data"
PASS=""
LOG_FILE="/var/log/rsync/rsync.log"
MOVIES_DIR="/movies"
#MUSIC_DIR="/music_tv/music"
TV_DIR="/music_tv/tv"
ANIME_DIR="/music_tv/anime"
DATE="$(date '+%Y-%m-%d %k:%M:%S')"
LOCKFILE=/var/lock/backup.lock

# Check for lockfile
[ -f $LOCKFILE ] && exit 0

# Upon exit, remove lockfile.
trap "{ rm -f $LOCKFILE ; exit 255; }" EXIT

touch $LOCKFILE

# Check to see if network drive is mounted
mountpoint -q "$BACKUP_MNT" &>> $LOG_FILE

if [ $? -ne 0 ]; then
    echo "$BACKUP_MNT is not a mounted. Mount external drive! Exiting..." &>> $LOG_FILE
    mount -o password="$PASS" "$BACKUP_DEV" "$BACKUP_MNT" &>> $LOG_FILE
fi

# Create logfile
if [ ! -f $LOG_FILE ]; then
    echo "Log file does not exist. Creating..."
    touch $LOG_FILE
fi

# Remove old log entries
if [ -f "$LOG_FILE" ]; then
  echo "Removing old log content..."
  echo "" > "$LOG_FILE"
fi

# Start entry in the log
echo "$DATE - Sync started..." &>> $LOG_FILE

# Start Buff disk space monitor
echo "Starting to monitor Buff's disk space..." &>> $LOG_FILE
/home/mrubu/bin/check_buff_space.sh &
#CHECK_SPACE_PID=$!

# Try to kill child process upon exit
trap 'kill $(jobs -p)' EXIT SIGINT SIGTERM

# Stop plex and deluge to limit disk usage/network
echo "Stopping services..." &>> $LOG_FILE
for SERVICE in plexmediaserver deluged; do
    /sbin/stop "$SERVICE" &>> $LOG_FILE
    if [ $? -ne 0 ]; then
        echo "$SERVICE may be still running. Manually stop service!" &>> $LOG_FILE
    fi
done

#Start sync
for FOLDER in $MOVIES_DIR $TV_DIR $ANIME_DIR; do
    echo "Starting backup of  ${FOLDER}..." &>> $LOG_FILE

    rsync -vrht --size-only --itemize-changes --delete --exclude-from "/home/mrubu/bin/exclude.txt" "$FOLDER" "$BACKUP_TO" &>> $LOG_FILE

    RSYNC_STATUS="$?"
    if [ $RSYNC_STATUS -eq 0 ]; then
      	echo "$DATE - Backup of $FOLDER succesful..." &>> $LOG_FILE
    else
      	echo && echo "$DATE - ERROR: rsync-command failed on ${FOLDER}..." &>> $LOG_FILE
        echo "$DATE - ERROR: rsync-command failed on ${FOLDER}..." | mail -s "Backup failiure" gibb002.server@gmail.com
        #kill -9 "$CHECK_SPACE_PID" &>> $LOG_FILE
        exit 1
    fi
done

# Start Plex and Deluge services
echo "Starting services..." &>> $LOG_FILE
for SERVICE in plexmediaserver deluged; do
    /sbin/start "$SERVICE" &>> $LOG_FILE
    if [ $? -ne 0 ]; then
        echo "$SERVICE may be still running. Manually stop service!" &>> $LOG_FILE
    fi
done

# Kill Buff Disk monitoring
#echo "Killing Buff disk monitoring..." &>> $LOG_FILE
#kill -9 "$CHECK_SPACE_PID" &>> $LOG_FILE

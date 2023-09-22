#!/bin/sh
# description: This shell is intended remove old garbage on the container
#
HOME_DIR="/home/eip"
SCRIPTS_DIR="$HOME_DIR/scripts"
LOG_DIR="$HOME_DIR/shared/logs"
BKPS_HOME=$HOME_DIR/shared/bkps
DEAD_LETTER="/root/dead.letter"
RESCHEDULE_FOLDER="/home/eip/shared/mail/reschedule"

. $SCRIPTS_DIR/commons.sh

for FILE in "$LOG_DIR" "$BKPS_HOME" "$DEAD_LETTER" "$RESCHEDULE_FOLDER" 
do
	if [ -d "$FILE" ]; then
		echo "Removing folder $FILE"
		rm -fr $FILE
		echo "Folder $FILE Removed!"
	fi
done

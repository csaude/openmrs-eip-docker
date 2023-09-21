#!/bin/sh
# description: This shell is intended remove old garbage on the container
#
HOME_DIR="/home/eip"
SCRIPTS_DIR="$HOME_DIR/scripts"
LOG_DIR="$HOME_DIR/shared/logs"
BKPS_HOME=$HOME_DIR/shared/bkps

. $SCRIPTS_DIR/commons.sh

for FILE in "$LOG_DIR" "$BKPS_HOME" 
do
	if [ -d "$FILE" ]; then
		echo "Removing folder $FILE"
		rm -fr $FILE
		echo "Folder $FILE Removed!"
	fi
done

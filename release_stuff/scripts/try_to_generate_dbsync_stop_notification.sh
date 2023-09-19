#!/bin/sh
# This script try to generate notification content for dbsync stop
#

#ENV
HOME_DIR="/home/eip"
SCRIPTS_DIR="$HOME_DIR/scripts"
LOG_DIR="$HOME_DIR/shared/logs/eip"
DBSYNC_CURR_LOG_FILE="$LOG_DIR/openmrs-eip.log"

. $SCRIPTS_DIR/commons.sh
. $SCRIPTS_DIR/setenv.sh

echo "Checking if dbsync is topped due error"

if [ ! -f "$DBSYNC_CURR_LOG_FILE" ]; then
	echo "Dbsync log file does not exists! Cannot determine if application is shutdown!"
elif grep "shutdown-route" $DBSYNC_CURR_LOG_FILE; then
        if grep "error" $DBSYNC_CURR_LOG_FILE; then
                echo "The shutdown signal was found on the log file. The notification content will be generated"

		MAIL_RECIPIENTS="$administrators_emails"
		MAIL_SUBJECT="DB sync application at $db_sync_senderId site has shutdown"
		MAIL_CONTENT_FILE="$HOME_DIR/eip_stop_notification_content.tmp"
		MAIL_ATTACHMENT="$DBSYNC_CURR_LOG_FILE"

		echo "The Db sync application at $db_sync_senderId has stopped after encountering an error, please see attached log file" > $MAIL_CONTENT_FILE

		$SCRIPTS_DIR/generate_notification_content.sh "$MAIL_RECIPIENTS" "$MAIL_SUBJECT" "$MAIL_CONTENT_FILE" "$MAIL_ATTACHMENT"
        else
                echo "The application was shutdown but gracefuly! No notification content will be generated"

        fi
else
         echo "The shutdown signal was not found on the log file. The notification content will not be generated!"
fi

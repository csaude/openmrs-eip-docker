#!/bin/sh
# This script try to generate notification content for dbsync stop
#

#ENV
HOME_DIR="/home/eip"
SCRIPTS_DIR="$HOME_DIR/scripts"
LOG_DIR="$HOME_DIR/logs/eip"
NOTIFICATIONS_LOG="$LOG_DIR/shutdown_notifications.log"
DBSYNC_CURR_LOG_FILE="$LOG_DIR/openmrs-eip.log"
LAST_SHUTDOWN_NOTIFICATION_REPORT="$LOG_DIR/last_shutdown_notification_report"
NOTIFIER=0
NOTIFICATION_PERIOD=11

. $SCRIPTS_DIR/commons.sh
. $SCRIPTS_DIR/setenv.sh

MAIL_RECIPIENTS="${administrators_emails},${dbsync_notification_email_recipients}"
MAIL_SUBJECT="DB sync application at $db_sync_senderId site has shutdown"
MAIL_CONTENT_FILE="$HOME_DIR/dbsync_stop_notification_content"
MAIL_ATTACHMENT=$DBSYNC_CURR_LOG_FILE

if [ ! -f "$LAST_SHUTDOWN_NOTIFICATION_REPORT" ]; then
        NOTIFIER=1
        logToScreenAndFile "Last shutdown notification report was not found! The notification will be tried now..." $NOTIFICATIONS_LOG
else
        lastShutdownNotificationOn=$(getFileAge $LAST_SHUTDOWN_NOTIFICATION_REPORT 'h')

        if [ $lastShutdownNotificationOn -ge $NOTIFICATION_PERIOD ]; then
                NOTIFIER=1
                logToScreenAndFile "Last shutdown notification was done $lastShutdownNotificationOn hours ago! The notification will be done now..." $NOTIFICATIONS_LOG
        else
                logToScreenAndFile "Last shutdown notification was donw $lastShutdownNotificationOn hours ago! The shutdown notification will be posponed!" $NOTIFICATIONS_LOG
        fi
fi

if [ $NOTIFIER -eq 1 ]; then

	logToScreenAndFile "Checking if dbsync is topped due error" $NOTIFICATIONS_LOG

	if [ ! -f "$DBSYNC_CURR_LOG_FILE" ]; then
		logToScreenAndFile "Dbsync log file does not exists! Cannot determine if application is shutdown!" $NOTIFICATIONS_LOG
	elif grep "shutdown-route" $DBSYNC_CURR_LOG_FILE; then
        	if grep "An error occurred" $DBSYNC_CURR_LOG_FILE; then
                	logToScreenAndFile "The shutdown signal was found on the log file. The notification content will be generated" $NOTIFICATIONS_LOG

			echo "The Db sync application at $db_sync_senderId has stopped after encountering an error, please see attached log file" > $MAIL_CONTENT_FILE

			$SCRIPTS_DIR/generate_notification_content.sh "$MAIL_RECIPIENTS" "$MAIL_SUBJECT" "$MAIL_CONTENT_FILE" "$MAIL_ATTACHMENT"

			currDateTime=$(getCurrDateTime)

			echo "Last notification sent at $currDateTime" > $LAST_SHUTDOWN_NOTIFICATION_REPORT
        	else
                	logToScreenAndFile "The application was shutdown but gracefuly! No notification content will be generated" $NOTIFICATIONS_LOG

       	 	fi
	else
        	 logToScreenAndFile "The shutdown signal was not found on the log file. The notification content will not be generated!" $NOTIFICATIONS_LOG
	fi
fi

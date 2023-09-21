#!/bin/sh
# This scrip is intended to generate notification content which can be picked-up by send notification tool
#

#ENV
HOME_DIR="/home/eip"
SCRIPTS_DIR="$HOME_DIR/scripts"
LOG_DIR="$HOME_DIR/logs/notification"
CRONS_DIR="$HOME_DIR/cron"
NOTIFICATION_HOME="$HOME_DIR/notifications"

MAIL_RECIPIENTS=$1
MAIL_SUBJECT=$2
MAIL_CONTENT_FILE=$3
MAIL_ATTACHMENT=$4

FILE_NAME=$(basename "$MAIL_ATTACHMENT")

. $SCRIPTS_DIR/commons.sh
. $SCRIPTS_DIR/try_to_load_environment.sh

timestamp=$(getCurrDateTime)

FILE_NAME="${FILE_NAME}_${timestamp}"

CURR_NOTIFICATION_FOLDER="${NOTIFICATION_HOME}/${FILE_NAME}"

LOG_FILE="$LOG_DIR/notifications.log"

mkdir -p $CURR_NOTIFICATION_FOLDER

echo $MAIL_RECIPIENTS > $CURR_NOTIFICATION_FOLDER/MAIL_RECIPIENTS
echo $MAIL_SUBJECT > $CURR_NOTIFICATION_FOLDER/MAIL_SUBJECT
mv $MAIL_CONTENT_FILE $CURR_NOTIFICATION_FOLDER/MAIL_CONTENT_FILE
mv $MAIL_ATTACHMENT $CURR_NOTIFICATION_FOLDER/MAIL_ATTACHMENT


NOTIFICATION_INFO_SRC="$NOTIFICATION_HOME/${FILE_NAME}.json"

echo "{\"notificationContentPath\": \"$CURR_NOTIFICATION_FOLDER\" }" > $NOTIFICATION_INFO_SRC

logToScreenAndFile "Notification stuff generated to $CURR_NOTIFICATION_FOLDER and writen on $NOTIFICATION_INFO_SRC" "$LOG_FILE"

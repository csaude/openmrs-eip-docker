#!/bin/sh
# This scrip is intended send email with information related to upgrade process
#

#ENV
RESCHEDULED_EMAIL_STUFF_HOME_DIR=$1

HOME_DIR="/home/eip"
SCRIPTS_DIR="$HOME_DIR/scripts"
EMAIL_CONTENT_FILE="$RESCHEDULED_EMAIL_STUFF_HOME_DIR/EMAIL_CONTENT"
MAIL_SUBJECT=$(cat $RESCHEDULED_EMAIL_STUFF_HOME_DIR/$MAIL_SUBJECT)
LOG_FILE=$(cat $RESCHEDULED_EMAIL_STUFF_HOME_DIR/$LOG_FILE)
RESCHEDULE_CRON=$(cat $RESCHEDULED_EMAIL_STUFF_HOME_DIR/$RESCHEDULE_CRON)
RESULT_LOG_FILE="$RESCHEDULED_EMAIL_STUFF_HOME_DIR/tmp.log"
RUNNING_PROCESS="$RESCHEDULED_EMAIL_STUFF_HOME_DIR/running_process.info"

ps aef | grep \"$SCRIPTS_DIR/send_notification_to_dbsync_administrators.sh $MAIL_SUBJECT $EMAIL_CONTENT_FILE $RESULT_LOG_FILE\" > $RUNNING_PROCESS

$SCRIPTS_DIR/send_notification_to_dbsync_administrators.sh $MAIL_SUBJECT $EMAIL_CONTENT_FILE $RESULT_LOG_FILE

if [ -s $RESULT_LOG_FILE ]; then
	rm $RESCHEDULE_CRON

	rm -fr $RESCHEDULED_EMAIL_STUFF_HOME_DIR

	$SCRIPTS_DIR/install_crons.sh
fi

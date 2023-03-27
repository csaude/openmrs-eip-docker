#!/bin/sh
# This scrip is intended to rechedule the an failed send of email
#

#ENV
HOME_DIR="/home/eip"
SCRIPTS_DIR="$HOME_DIR/scripts"
LOG_DIR="$HOME_DIR/shared/logs/notification/resend"
CRONS_DIR="$HOME_DIR/cron"

MAIL_SUBJECT=$1
PATH_TO_ATTACHMENT=$2
FILE_NAME=$(basename "$PATH_TO_ATTACHMENT")

. $SCRIPTS_DIR/commons.sh
. $SCRIPTS_DIR/try_to_load_environment.sh

timestamp=$(getCurrDateTime)
RESCHEDULE_EMAIL_FOLDER_NAME=${FILE_NAME}_${timestamp}


LOG_FILE="$LOG_DIR/resend_email_using_for_${FILE_NAME}.log"

RESCHEDULED_EMAIL_STUFF_HOME_DIR="$HOME_DIR/shared/mail/reschedule/$RESCHEDULE_EMAIL_FOLDER_NAME"
RESCHEDULE_CRON="$CRONS_DIR/try_to_resend_notification_to_administrators${RESCHEDULE_EMAIL_FOLDER_NAME}.sh"

echo "PATH TO ATACHMENT: $PATH_TO_ATTACHMENT"
echo "SUBJECT: $MAIL_SUBJECT"

if [ ! -d $RESCHEDULED_EMAIL_STUFF_HOME_DIR ]; then
	mkdir -p $RESCHEDULED_EMAIL_STUFF_HOME_DIR
fi

echo $MAIL_SUBJECT > "$RESCHEDULED_EMAIL_STUFF_HOME_DIR/MAIL_SUBJECT"
echo $RESCHEDULE_CRON > "$RESCHEDULED_EMAIL_STUFF_HOME_DIR/RESCHEDULE_CRON"
echo $LOG_FILE > "$RESCHEDULED_EMAIL_STUFF_HOME_DIR/LOG_FILE"

mv $PATH_TO_ATTACHMENT "$RESCHEDULED_EMAIL_STUFF_HOME_DIR/EMAIL_CONTENT"

logToScreenAndFile "Recheduling the email send for $PATH_TO_ATTACHMENT at $timestamp" "$LOG_FILE"

echo "*/5       *       *       *       *       /home/eip/scripts/try_to_resend_notification_to_dbsync_administrators.sh $RESCHEDULED_EMAIL_STUFF_HOME_DIR" > ${RESCHEDULE_CRON}

$SCRIPTS_DIR/install_crons.sh

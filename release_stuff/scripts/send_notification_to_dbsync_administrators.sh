#!/bin/sh
# This scrip is intended send email with an file attached 
#

#ENV
HOME_DIR="/home/eip"
SCRIPTS_DIR="$HOME_DIR/scripts"
LOG_DIR="$HOME_DIR/shared/logs/notification"

MAIL_SUBJECT=$1
PATH_TO_ATTACHMENT=$2

FILE_NAME=$(basename "$PATH_TO_ATTACHMENT")
EMAIL_CONTENT_FILE="$HOME_DIR/email_content"
LOG_FILE="$LOG_DIR/send_file_to_mail${FILE_NAME}.log"

. $SCRIPTS_DIR/try_to_load_environment.sh

echo "To: jorge.boane@fgh.org.mz,daniel.chirinda@fgh.org.mz,jose.chambule@fgh.org.mz,fernando.mufume@fgh.org.mz" >> $EMAIL_CONTENT_FILE
echo "From: jorge.boane@fgh.org.mz" >> $EMAIL_CONTENT_FILE
echo "Subject: $MAIL_SUBJECT [$db_sync_senderId]" >> $EMAIL_CONTENT_FILE

cat $PATH_TO_ATTACHMENT >> $EMAIL_CONTENT_FILE

echo "" >> $EMAIL_CONTENT_FILE
echo "" >> $EMAIL_CONTENT_FILE
echo "Enviado automaticamente a partir do servidor $db_sync_senderId." >> $EMAIL_CONTENT_FILE


sendmail -t -f  < $EMAIL_CONTENT_FILE

rm $EMAIL_CONTENT_FILE

echo "EMAIL SENT!"

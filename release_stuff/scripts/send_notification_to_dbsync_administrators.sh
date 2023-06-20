#!/bin/sh
# This scrip is intended send email with an file attached 
#

#ENV
HOME_DIR="/home/eip"
SCRIPTS_DIR="$HOME_DIR/scripts"
LOG_DIR="$HOME_DIR/shared/logs/notification"

MAIL_SUBJECT=$1
PATH_TO_ATTACHMENT=$2
PATH_TO_ERROR_LOG=$3

FILE_NAME=$(basename "$PATH_TO_ATTACHMENT")
EMAIL_CONTENT_FILE="$HOME_DIR/email_content"
LOG_FILE="$LOG_DIR/send_file_to_mail${FILE_NAME}.log"

. $SCRIPTS_DIR/try_to_load_environment.sh

echo "To: jorge.boane@csaude.org.mz,daniel.chirinda@csaude.org.mz,jose.chambule@csaude.org.mz,fernando.mufume@csaude.org.mz" > $EMAIL_CONTENT_FILE
echo "From: epts.centralization@fgh.org.mz" >> $EMAIL_CONTENT_FILE
echo "Subject: $MAIL_SUBJECT[$db_sync_senderId]" >> $EMAIL_CONTENT_FILE

cat $PATH_TO_ATTACHMENT >> $EMAIL_CONTENT_FILE

echo "" >> $EMAIL_CONTENT_FILE
echo "" >> $EMAIL_CONTENT_FILE
echo "Enviado automaticamente a partir do servidor $db_sync_senderId." >> $EMAIL_CONTENT_FILE


sendmail -t -f  < $EMAIL_CONTENT_FILE 2> $PATH_TO_ERROR_LOG 

rm $EMAIL_CONTENT_FILE

if [ -s $PATH_TO_ERROR_LOG ]; then
	echo "Email cannot be sent due error"
	cat $PATH_TO_ERROR_LOG
else
	echo "EMAIL SENT!"
fi

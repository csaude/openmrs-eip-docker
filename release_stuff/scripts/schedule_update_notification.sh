#!/bin/sh
# This scrip is intended send email with information related to upgrade process
#

#ENV
HOME_DIR="/home/eip"
#HOME_DIR="/home/eip/prg/docker/eip-docker-testing"
SCRIPTS_DIR="$HOME_DIR/scripts"
LOG_DIR="$HOME_DIR/shared/logs/upgrade"
MAIL_CONTENT_FILE="$HOME_DIR/update_email_content"
UPDATES_LOG_FILE="$LOG_DIR/upgrade.log"
SEND_EMAIL_LOG="$LOG_DIR/send_email.log"
LAST_UPDATE_CHECK_REPORT="$LOG_DIR/last_update_check_report"

. $SCRIPTS_DIR/try_to_load_environment.sh
. $SCRIPTS_DIR/setenv.sh
. $SCRIPTS_DIR/release_info.sh

LOCAL_RELEASE_NAME=$RELEASE_NAME
LOCAL_RELEASE_DATE=$RELEASE_DATE

echo "Caros" >> $EMAIL_CONTENT_FILE
echo "Junto enviamos o report da ultima tentativa de actualizacao da aplicacao openmrs-eip." >> $EMAIL_CONTENT_FILE
echo "" >> $EMAIL_CONTENT_FILE
echo "INFORMACAO DAS RELEASES" >> $EMAIL_CONTENT_FILE
echo "---------------------" >> $EMAIL_CONTENT_FILE
echo "CURRENT RELEASE INFO {NAME: $LOCAL_RELEASE_NAME, DATE: $LOCAL_RELEASE_DATE}" >> $EMAIL_CONTENT_FILE
echo "--------------------" >> $EMAIL_CONTENT_FILE
echo "" >> $EMAIL_CONTENT_FILE
echo "Enviado automaticamente a partir do servidor $db_sync_senderId." >> $EMAIL_CONTENT_FILE
echo "" >> $EMAIL_CONTENT_FILE
echo "" >> $EMAIL_CONTENT_FILE
echo "-----------------------------------------------------" >> $EMAIL_CONTENT_FILE
echo "LOG: See Attachment"

MAIL_SUBJECT="EIP REMOTO - ESTADO DE ACTUALIZACAO"
MAIL_RECIPIENTS="$administrators_emails"
MAIL_ATTACHMENT=$UPDATES_LOG_FILE


$SCRIPTS_DIR/generate_notification_content.sh "$MAIL_RECIPIENTS" "$MAIL_SUBJECT" $EMAIL_CONTENT_FILE $EMAIL_ATTACHMENT


$SCRIPTS_DIR/performe_after_update_check_actions.sh

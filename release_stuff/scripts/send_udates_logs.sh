#!/bin/sh
# This scrip is intended send email with information related to upgrade process
#

#ENV
HOME_DIR="/home/eip"
#HOME_DIR="/home/eip/prg/docker/eip-docker-testing"
SCRIPTS_DIR="$HOME_DIR/scripts"
LOG_DIR="$HOME_DIR/shared/logs/upgrade"


EMAIL_CONTENT_FILE="$HOME_DIR/update_email_content"
UPDATES_LOG_FILE="$LOG_DIR/upgrade.log"

echo $SCRIPTS_DIR/release_info.sh
source $SCRIPTS_DIR/release_info.sh

LOCAL_RELEASE_NAME=$RELEASE_NAME
LOCAL_RELEASE_DATE=$RELEASE_DATE

recipient="jorge.boane@fgh.org.mz" 
sender="jorge.boane@fgh.org.mz" 
subject="EIP_REMOTO_ESTADO_DE_ACTUALIZACAO_$db_sync_senderId" 
content="Caros" 
content="$content\r\r\nJunto enviamos o report da ultima tentativa de actualizacao da aplicacao openmrs-eip."  
content="$content\r\r\n" 
content="$content\r\r\nINFORMACAO DAS RELEASES" 
content="$content\r\r\n---------------------" 
content="$content\r\r\n CURRENT RELEASE INFO {NAME: $LOCAL_RELEASE_NAME, DATE: $LOCAL_RELEASE_DATE}"
content="$content\r\r\n--------------------" 
content="$content\r\r\n" 
content="$content\r\r\nEnviado automaticamente a partir do servidor $db_sync_senderId." 

echo $content | mutt -s $subject -a $UPDATES_LOG_FILE -b jorge.boane@fgh.org.mz

echo "EMAIL SENT!"

#!/bin/sh
# This scripts execute a given script on a given db
#
HOME_DIR="/home/eip"
SCRIPTS_DIR="$HOME_DIR/scripts"
LOG_DIR="$HOME_DIR/logs/eip/unlock-liquibase"
LOG_FILE="$LOG_DIR/unlock-liquibase.log"
DB_HOST="172.17.0.1"
DB_HOST_PORT="$openmrs_db_port"
DB_USER="root"
DB_PASSWD="$spring_openmrs_datasource_password"
DB_NAME="openmrs_eip_sender_mgt_${db_sync_senderId}"
LIQUIBASE_UNLOCK_SCRIPT=$HOME_DIR/etc/sql/unload_dbsync_liquibase.sql
CHECK_STATUS_SCRIPT=$HOME_DIR/liquibase_check_status.sql
RESULT_SCRIPT=$HOME_DIR/liquibase_check_status.result
PATH_TO_ERROR_LOG="$HOME_DIR/tmp_unlock_liquibase"
EMAIL_CONTENT_FILE="$HOME_DIR/tmp_unlock_liquibase_email_content_file"

. $SCRIPTS_DIR/commons.sh
. $SCRIPTS_DIR/try_to_load_environment.sh

timestamp=$(getCurrDateTime)

logToScreenAndFile "Trying to unlock liquibase at $timestamp" "$LOG_FILE"

echo "select IF(LOCKED=true, 'true', 'false') LOCKED_STATUS from LIQUIBASECHANGELOGLOCK where id =1;" > $CHECK_STATUS_SCRIPT

$HOME_DIR/scripts/execute_script_on_db.sh $DB_HOST $DB_HOST_PORT $DB_USER $DB_PASSWD $DB_NAME $CHECK_STATUS_SCRIPT $RESULT_SCRIPT

if grep "false" $RESULT_SCRIPT; then
        echo "THE LIQUIBASE IS NOT LOCKED..."
	
	logToScreenAndFile "THE LIQUIBASE IS NOT LOCKED..." "$LOG_FILE"
else
	logToScreenAndFile "THE LIQUIBASE IS LOCKED..." "$LOG_FILE"
	logToScreenAndFile "EXECUTING UNLOCK QUERT..." "$LOG_FILE"
	
	$HOME_DIR/scripts/execute_script_on_db.sh $DB_HOST $DB_HOST_PORT $DB_USER $DB_PASSWD $DB_NAME $LIQUIBASE_UNLOCK_SCRIPT $RESULT_SCRIPT

	logToScreenAndFile "LIQUIBASE UNLOCKED!" $LOG_FILE

	MAIL_SUBJECT="EIP REMOTO - LIQUIBASE LOCK INFO"

	echo "Caros" >> $EMAIL_CONTENT_FILE
	echo "Servimo-nos deste para informar que o liquibase do dbsync no site $db_sync_senderId encontrava-se LOCKED e foi UNLOCKED com sucesso." >> $EMAIL_CONTENT_FILE
	echo "" >> $EMAIL_CONTENT_FILE
	echo "" >> $EMAIL_CONTENT_FILE
	echo "Enviado automaticamente a partir do servidor $db_sync_senderId." >> $EMAIL_CONTENT_FILE

	$SCRIPTS_DIR/send_notification_to_dbsync_administrators.sh "$MAIL_SUBJECT" $EMAIL_CONTENT_FILE $PATH_TO_ERROR_LOG

	if [ -s $PATH_TO_ERROR_LOG ]; then
		 logToScreenAndFile  "THE NOTIFICATION EMAIL STATUS COULD NOT SENT YET!" $LOG_FILE

        	$SCRIPTS_DIR/schedule_send_notification_to_dbsync_administrators.sh "$MAIL_SUBJECT" "$EMAIL_CONTENT_FILE"
	fi

fi

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
MAIL_CONTENT_FILE="$HOME_DIR/tmp_unlock_liquibase_email_content_file"
MAIL_ATTACHMENT="liquibase-unlock-info.tmp"

. $SCRIPTS_DIR/commons.sh
. $SCRIPTS_DIR/try_to_load_environment.sh
. $SCRIPTS_DIR/setenv.sh

timestamp=$(getCurrDateTime)

isDockerInstallation

isDocker=$?

if [ $isDocker = 0 ]; then
	DB_HOST=$openmrs_db_host
fi

logToScreenAndFile "USING DB_HOST $DB_HOST" "$LOG_FILE"

logToScreenAndFile "Trying to unlock liquibase at $timestamp" "$LOG_FILE"

echo "select IF(LOCKED=true, 'true', 'false') LOCKED_STATUS from LIQUIBASECHANGELOGLOCK where id =1 or LOCKED = true" > $CHECK_STATUS_SCRIPT

$HOME_DIR/scripts/execute_script_on_db.sh $DB_HOST $DB_HOST_PORT $DB_USER $DB_PASSWD $DB_NAME $CHECK_STATUS_SCRIPT $RESULT_SCRIPT

if grep "true" $RESULT_SCRIPT; then
	logToScreenAndFile "THE LIQUIBASE IS LOCKED..." "$LOG_FILE"
	logToScreenAndFile "EXECUTING UNLOCK QUERY..." "$LOG_FILE"
	
	$HOME_DIR/scripts/execute_script_on_db.sh $DB_HOST $DB_HOST_PORT $DB_USER $DB_PASSWD $DB_NAME $LIQUIBASE_UNLOCK_SCRIPT $RESULT_SCRIPT

	logToScreenAndFile "LIQUIBASE UNLOCKED!" $LOG_FILE

	MAIL_SUBJECT="EIP REMOTO - LIQUIBASE LOCK INFO"

	echo "Caros" >> $MAIL_CONTENT_FILE
	echo "Servimo-nos deste para informar que o liquibase do dbsync no site $db_sync_senderId encontrava-se LOCKED e foi UNLOCKED com sucesso." >> $MAIL_CONTENT_FILE
	echo "" >> $MAIL_CONTENT_FILE
	echo "" >> $MAIL_CONTENT_FILE
	echo "Enviado automaticamente a partir do servidor $db_sync_senderId." >> $MAIL_CONTENT_FILE

	echo "No content" > $MAIL_ATTACHMENT

        MAIL_RECIPIENTS="$administrators_emails"

       	$SCRIPTS_DIR/generate_notification_content.sh "$MAIL_RECIPIENTS" "$MAIL_SUBJECT" "$MAIL_CONTENT_FILE" "$MAIL_ATTACHMENT"
else
        echo "THE LIQUIBASE IS NOT LOCKED..."
	
	logToScreenAndFile "THE LIQUIBASE IS NOT LOCKED..." "$LOG_FILE"

fi

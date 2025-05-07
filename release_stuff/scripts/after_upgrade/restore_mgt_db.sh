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
CREATE_DB_SCRIPT="$HOME_DIR/shared/bkps/create_mgt_db.sql"
DROP_DB_SCRIPT="$HOME_DIR/shared/bkps/drop_mgt_db.sql"
DBSYNC_MGT_DB_SCRIPT="$HOME_DIR/shared/bkps/dbsync-mgt-db.sql"
OPENMRS_DB_NAME="$openmrs_db_name"
MYSQL_DB_NAME="mysql"
LIQUIBASE_UNLOCK_SCRIPT=$HOME_DIR/etc/sql/unload_dbsync_liquibase.sql
CHECK_STATUS_SCRIPT=$HOME_DIR/liquibase_check_status.sql
RESULT_SCRIPT=$HOME_DIR/liquibase_check_status.result
PATH_TO_ERROR_LOG="$HOME_DIR/tmp_unlock_liquibase"
MAIL_CONTENT_FILE="$HOME_DIR/tmp_unlock_liquibase_email_content_file"
MAIL_ATTACHMENT="liquibase-unlock-info.tmp"
INSTALL_INFO_DIR="$HOME_DIR/install_info/after_upgrade"
AFTER_UPGRADE_ERROR_SCRIPT_INFO="$INSTALL_INFO_DIR/error_script_info.txt"

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

logToScreenAndFile "Starting dbsync-mgt restoure at $timestamp" "$LOG_FILE"


if [ ! -f "$DBSYNC_MGT_DB_SCRIPT" ]; then
	msg="The mgt db dump $DBSYNC_MGT_DB_SCRIPT cannot be found"

	logToScreenAndFile "$msg" "$LOG_FILE"

	echo "SCRIPT: $(basename "$0")" >> $AFTER_UPGRADE_ERROR_SCRIPT_INFO
	echo "ERROR: $msg" >> $AFTER_UPGRADE_ERROR_SCRIPT_INFO
	exit 1
fi

echo "DROP DATABASE IF EXISTS \`$DB_NAME\`;" > $DROP_DB_SCRIPT

echo "CREATE DATABASE \`$DB_NAME\` /*!40100 DEFAULT CHARACTER SET utf32 */;" > $CREATE_DB_SCRIPT

$HOME_DIR/scripts/execute_script_on_db.sh $DB_HOST $DB_HOST_PORT $DB_USER $DB_PASSWD $MYSQL_DB_NAME $DROP_DB_SCRIPT $RESULT_SCRIPT

$HOME_DIR/scripts/execute_script_on_db.sh $DB_HOST $DB_HOST_PORT $DB_USER $DB_PASSWD $MYSQL_DB_NAME $CREATE_DB_SCRIPT $RESULT_SCRIPT
	
$HOME_DIR/scripts/execute_script_on_db.sh $DB_HOST $DB_HOST_PORT $DB_USER $DB_PASSWD $DB_NAME $DBSYNC_MGT_DB_SCRIPT $RESULT_SCRIPT

logToScreenAndFile "DBSYNC MGT DB RESTOURED!" $LOG_FILE

MAIL_SUBJECT="DBSYNC MGT-DB RESTOURED"

echo "Caros" >> $MAIL_CONTENT_FILE
echo "Servimo-nos deste para informar que a base de dados de gestao do dbsync no site $db_sync_senderId foi restaurada com sucesso." >> $MAIL_CONTENT_FILE
echo "" >> $MAIL_CONTENT_FILE
echo "" >> $MAIL_CONTENT_FILE
echo "Enviado automaticamente a partir do servidor $db_sync_senderId." >> $MAIL_CONTENT_FILE

echo "No content" > $MAIL_ATTACHMENT

MAIL_RECIPIENTS="$administrators_emails"

$SCRIPTS_DIR/generate_notification_content.sh "$MAIL_RECIPIENTS" "$MAIL_SUBJECT" "$MAIL_CONTENT_FILE" "$MAIL_ATTACHMENT"

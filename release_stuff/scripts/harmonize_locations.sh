#!/bin/sh
# This scripts execute a given script on a given db
#

HOME_DIR=/home/eip
SCRIPTS_DIR=$HOME_DIR/scripts
LOG_FILE=$HOME_DIR/shared/logs/extras/location_harmonization.log
LOCATION_HARMONIZATION_DIR=$HOME_DIR/shared/extras/location_harmonization
HARMONIZATION_SCRIPT="$HOME_DIR/etc/sql/harmonize_location_zambezia.sql"
HARMONIZATION_CHECK_CRON=$HOME_DIR/cron/try_to_execute_location_harmonization
HARMONIZATION_RESULT_FILE=$LOCATION_HARMONIZATION_DIR/harmonization_result
HARMONIZATION_STATUS_FILE=$LOCATION_HARMONIZATION_DIR/harmonization_status
HARMONIZATION_FINISHED=$LOCATION_HARMONIZATION_DIR/harmonization_finished
CHECK_STATUS_SCRIPT=$LOCATION_HARMONIZATION_DIR/harmonization_check_status.sql
HARMONIZATION_PROCESS_INFO=$LOCATION_HARMONIZATION_DIR/harmonization_process.info
HARMONIZATION_EMAIL_SENT_LOG=$LOCATION_HARMONIZATION_DIR/harmonization_email_sent.log
EMAIL_CONTENT_FILE=$LOCATION_HARMONIZATION_DIR/mail_content

DB_HOST="172.17.0.1"
DB_HOST_PORT="$openmrs_db_port"
DB_USER="root"
DB_PASSWD="$spring_openmrs_datasource_password"
DB_NAME="$openmrs_db_name"

. $SCRIPTS_DIR/commons.sh


if [ ! -d $LOCATION_HARMONIZATION_DIR ]; then
	mkdir -p $LOCATION_HARMONIZATION_DIR
fi


isDockerInstallation

isDocker=$?

if [ $isDocker = 0 ]; then
        DB_HOST=$openmrs_db_host
fi

logToScreenAndFile "USING DB_HOST $DB_HOST" "$LOG_FILE"

echo "select * from location_harmonization.harmonization_execution_status;" > $CHECK_STATUS_SCRIPT

$SCRIPTS_DIR/execute_script_on_db.sh $DB_HOST $DB_HOST_PORT $DB_USER $DB_PASSWD $DB_NAME $CHECK_STATUS_SCRIPT $HARMONIZATION_STATUS_FILE

if grep "finished" $HARMONIZATION_STATUS_FILE; then
        logToScreenAndFile "The harmonization is finished" $LOG_FILE
	

	$SCRIPTS_DIR/try_to_finalize_location_harmonization.sh

	exit 0
fi

checkIfProcessIsRunning "execute_script_on_db.sh"
runningProcess=$?

if [ $runningProcess = 1 ]; then
        logToScreenAndFile "There is another harmonozation process running" $LOG_FILE

        exit 0
fi

logToScreenAndFile  "STARTING THE LOCATION HAMONIZATION PROCESS!" $LOG_FILE

echo "Caros" >> $EMAIL_CONTENT_FILE
echo "Servimo-nos deste email para informar que o processo de harmonização no site: $db_sync_senderId foi iniciado com sucesso" >> $EMAIL_CONTENT_FILE
echo "" >> $EMAIL_CONTENT_FILE
echo "--------------------" >> $EMAIL_CONTENT_FILE
echo "" >> $EMAIL_CONTENT_FILE
echo "Enviado automaticamente a partir do servidor $db_sync_senderId." >> $EMAIL_CONTENT_FILE

MAIL_SUBJECT="EIP REMOTO - ESTADO DE HARMONIZACAO DE LOCAIS"

$SCRIPTS_DIR/send_notification_to_dbsync_administrators.sh "$MAIL_SUBJECT" "$EMAIL_CONTENT_FILE" "$HARMONIZATION_EMAIL_SENT_LOG"

if [ -s $HARMONIZATION_EMAIL_SENT_LOG ]; then
        logToScreenAndFile  "THE NOTIFICATION EMAIL FOR LOCATION HARMONIZATION STATUS COULD NOT SENT YET!" $LOG_FILE

        $SCRIPTS_DIR/schedule_send_notification_to_dbsync_administrators.sh "$MAIL_SUBJECT" "$EMAIL_CONTENT_FILE"
fi

sed -i "s/OPENMRS_DATABASE_NAME/$openmrs_db_name/g" $HARMONIZATION_SCRIPT

$HOME_DIR/scripts/execute_script_on_db.sh $DB_HOST $DB_HOST_PORT $DB_USER $DB_PASSWD $DB_NAME $HARMONIZATION_SCRIPT $HARMONIZATION_RESULT_FILE




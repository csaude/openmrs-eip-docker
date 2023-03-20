#!/bin/sh
# This script check the status of location_harmonization process and if it is finihed, sent an email to administrators.
# When the email is successifull sent then all the crons related to location harmonization will be removed
#

#ENV
HOME_DIR=/home/eip
SCRIPTS_DIR="$HOME_DIR/scripts"
CRONS_DIR="$HOME_DIR/cron"
LOCATION_HARMONIZATION_DIR=$HOME_DIR/shared/logs/location_harmonization
HARMONIZATION_PROCESS_LOG=$LOCATION_HARMONIZATION_DIR/harmonization
DB_HOST="172.17.0.1"
DB_HOST_PORT="$openmrs_db_port"
DB_USER="root"
DB_PASSWD="$spring_openmrs_datasource_password"
DB_NAME="$openmrs_db_name"
HARMONIZATION_SCRIPT="$HOME_DIR/etc/scripts/harmonize_location_zambezia.sql"
HARMONIZATION_STATUS_FILE=$LOCATION_HARMONIZATION_DIR/harmozation_status
HARMONIZATION_FINISHED=$LOCATION_HARMONIZATION_DIR/harmonization_finished
HARMONIZATION_EXECUTION_LOG=$LOCATION_HARMONIZATION_DIR/harmonization_execution.log
CHECK_STATUS_SCRIPT=$LOCATION_HARMONIZATION_DIR/harmonization_check_status.sql
HARMONIZATION_PROCESS_INFO=$LOCATION_HARMONIZATION_DIR/harmonization_process.info
HARMONIZATION_EMAIL_SENT_LOG=$LOCATION_HARMONIZATION_DIR/harmonization_email_sent.log
HARMONIZATION_CURRENT_STATUS_TEXT="encontra-se num estado desconhecido"
HARMONIZATION_CURRENT_STATUS="AKNOWN"

EMAIL_CONTENT_FILE="$HOME_DIR/email_content_file"

. $SCRIPTS_DIR/commons.sh
. $SCRIPTS_DIR/try_to_load_environment.sh


echo "select * from location_harmonization.harmonization_execution_status;" > $CHECK_STATUS_SCRIPT

$HOME_DIR/scripts/execute_script_on_db.sh $DB_HOST $DB_HOST_PORT $DB_USER $DB_PASSWD $DB_NAME $CHECK_STATUS_SCRIPT $HARMONIZATION_STATUS_FILE

if grep "finished" $HARMONIZATION_STATUS_FILE; then
	HARMONIZATION_CURRENT_STATUS="FINIHED"
	HARMONIZATION_CURRENT_STATUS_TEXT="foi executado com sucesso e encontra-se finalizado"
fi


ps aef | grep execute_script_on_db > $HARMONIZATION_PROCESS_INFO

if grep "execute_script_on_db" $HARMONIZATION_PROCESS_INFO; then
	HARMONIZATION_CURRENT_STATUS="RUNNING"
	HARMONIZATION_CURRENT_STATUS_TEXT="ainda esta em execucao"
fi

echo "select * from location_harmonization.location_execution_logs;" > $HARMONIZATION_EXECUTION_LOG

$HOME_DIR/scripts/execute_script_on_db.sh $DB_HOST $DB_HOST_PORT $DB_USER $DB_PASSWD $DB_NAME $CHECK_STATUS_SCRIPT $HARMONIZATION_EXECUTION_LOG


echo "Caros" >> $EMAIL_CONTENT_FILE
echo "Servimo-nos deste email para informar que o processo de harmonização no site: $db_sync_senderId $HARMONIZATION_CURRENT_STATUS_TEXT" >> $EMAIL_CONTENT_FILE
echo "" >> $EMAIL_CONTENT_FILE
echo "--------------------" >> $EMAIL_CONTENT_FILE
echo "" >> $EMAIL_CONTENT_FILE
echo "Enviado automaticamente a partir do servidor $db_sync_senderId." >> $EMAIL_CONTENT_FILE
echo "" >> $EMAIL_CONTENT_FILE
echo "" >> $EMAIL_CONTENT_FILE
echo "-----------------------------------------------------" >> $EMAIL_CONTENT_FILE
echo "LOG" >> $EMAIL_CONTENT_FILE
echo "-----------------------------------------------------" >> $EMAIL_CONTENT_FILE
cat $HARMONIZATION_EXECUTION_LOG >> $EMAIL_CONTENT_FILE
echo "-----------------------------------------------------" >> $EMAIL_CONTENT_FILE

MAIL_SUBJECT="EIP REMOTO - ESTADO DE HARMONIZACAO DE LOCAIS"

$SCRIPTS_DIR/send_notification_to_dbsync_administrators.sh "$MAIL_SUBJECT" "$EMAIL_CONTENT_FILE" "$HARMONIZATION_EMAIL_SENT_LOG"

if [ ! -s $HARMONIZATION_EMAIL_SENT_LOG ]; then
	#EMAIL WAS SUCCESSIFULY SENT, PERFORME THE FINALIZATION
	
	rm $CRONS_DIR/try_to_execute_location_harmonization.sh

	logToScreenAndFile  "RE-INSTALLING CRONS!" $HARMONIZATION_PROCESS_LOG 

       $SCRIPTS_DIR/install_crons.sh

	logToScreenAndFile  "LOCATION HARMONIZATION PROCESS FINALIZED!" $HARMONIZATION_PROCESS_LOG 

else
	logToScreenAndFile  "THE LOCATION HARMONIZATION PROCESS IS FINISHED BUT CANNOT BE FINALIZED NOW BECAUSE THE EMAIL COULD NOT SENT YET!" $HARMONIZATION_PROCESS_LOG 
        $SCRIPTS_DIR/schedule_send_notification_to_dbsync_administrators.sh "$MAIL_SUBJECT" $EMAIL_CONTENT_FILE
fi

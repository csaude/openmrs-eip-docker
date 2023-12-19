#!/bin/sh
# This script check the status of location_harmonization process and if it is finihed, sent an email to administrators.
# When the email is successifull sent then all the crons related to location harmonization will be removed
#

#ENV
HOME_DIR=/home/eip
SCRIPTS_DIR="$HOME_DIR/scripts"
CRONS_DIR="$HOME_DIR/cron"
LOCATION_HARMONIZATION_DIR=$HOME_DIR/shared/extras/location_harmonization
HARMONIZATION_PROCESS_LOG=$LOCATION_HARMONIZATION_DIR/harmonization
DB_HOST="172.17.0.1"
DB_HOST_PORT="$openmrs_db_port"
DB_USER="root"
DB_PASSWD="$spring_openmrs_datasource_password"
DB_NAME="$openmrs_db_name"
HARMONIZATION_SCRIPT="$HOME_DIR/etc/scripts/harmonize_location.sql"
HARMONIZATION_STATUS_FILE=$LOCATION_HARMONIZATION_DIR/harmozation_status
HARMONIZATION_FINISHED=$LOCATION_HARMONIZATION_DIR/harmonization_finished
HARMONIZATION_EXECUTION_LOG=$LOCATION_HARMONIZATION_DIR/harmonization_execution.log
CHECK_STATUS_SCRIPT=$LOCATION_HARMONIZATION_DIR/harmonization_check_status.sql
HARMONIZATION_PROCESS_INFO=$LOCATION_HARMONIZATION_DIR/harmonization_process.info
HARMONIZATION_EMAIL_SENT_LOG=$LOCATION_HARMONIZATION_DIR/harmonization_email_sent.log
HARMONIZATION_CURRENT_STATUS_TEXT="encontra-se num estado desconhecido"
HARMONIZATION_CURRENT_STATUS="AKNOWN"

MAIL_CONTENT_FILE="$HOME_DIR/email_content_file"

. $SCRIPTS_DIR/commons.sh
. $SCRIPTS_DIR/setenv.sh
. $SCRIPTS_DIR/try_to_load_environment.sh


echo "select * from location_harmonization.harmonization_execution_status;" > $CHECK_STATUS_SCRIPT

$HOME_DIR/scripts/execute_script_on_db.sh $DB_HOST $DB_HOST_PORT $DB_USER $DB_PASSWD $DB_NAME $CHECK_STATUS_SCRIPT $HARMONIZATION_STATUS_FILE

if grep "finished" $HARMONIZATION_STATUS_FILE; then
	HARMONIZATION_CURRENT_STATUS="FINIHED"
	HARMONIZATION_CURRENT_STATUS_TEXT="foi executado com sucesso e encontra-se finalizado"

	logToScreenAndFile  "LOCATION HARMONIZATION PROCESS FINALIZED!" $HARMONIZATION_PROCESS_LOG 

	rm $HARMONIZATION_PROCESS_INFO
else
	logToScreenAndFile  "THE HARMONIZATION PROCESS IS NOT FINISHED!" $HARMONIZATION_PROCESS_LOG
	exit 1 
fi

echo "select * from location_harmonization.location_execution_logs;" > $HARMONIZATION_EXECUTION_LOG

$HOME_DIR/scripts/execute_script_on_db.sh $DB_HOST $DB_HOST_PORT $DB_USER $DB_PASSWD $DB_NAME $CHECK_STATUS_SCRIPT $HARMONIZATION_EXECUTION_LOG


echo "Caros" >> $MAIL_CONTENT_FILE
echo "Servimo-nos deste email para informar que o processo de harmonização no site: $db_sync_senderId $HARMONIZATION_CURRENT_STATUS_TEXT" >> $MAIL_CONTENT_FILE
echo "" >> $MAIL_CONTENT_FILE
echo "--------------------" >> $MAIL_CONTENT_FILE
echo "" >> $MAIL_CONTENT_FILE
echo "" >> $MAIL_CONTENT_FILE
echo "Enviado automaticamente a partir do servidor $db_sync_senderId." >> $MAIL_CONTENT_FILE

MAIL_RECIPIENTS="$administrators_emails"
MAIL_SUBJECT="EIP REMOTO - RELATORIO DA HARMONIZACAO DE LOCAIS[${db_sync_senderId}]"
MAIL_ATTACHMENT="$HARMONIZATION_EXECUTION_LOG"

$SCRIPTS_DIR/generate_notification_content.sh "$MAIL_RECIPIENTS" "$MAIL_SUBJECT" "$MAIL_CONTENT_FILE" "$MAIL_ATTACHMENT"  
	
rm $CRONS_DIR/try_to_execute_location_harmonization.sh

logToScreenAndFile  "RE-INSTALLING CRONS!" $HARMONIZATION_PROCESS_LOG 

$SCRIPTS_DIR/install_crons.sh

logToScreenAndFile  "LOCATION HARMONIZATION PROCESS FINALIZED!" $HARMONIZATION_PROCESS_LOG 

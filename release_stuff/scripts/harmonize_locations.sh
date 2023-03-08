#!/bin/sh
# This scripts execute a given script on a given db
#
HOME_DIR=/home/eip
LOCATION_HARMONIZATION_DIR=$HOME_DIR/location_harmonization
DB_HOST="172.17.0.1"
DB_HOST_PORT="$openmrs_db_port"
DB_USER="root"
DB_PASSWD="$spring_openmrs_datasource_password"
DB_NAME="$openmrs_db_name"
HARMONIZATION_SCRIPT="$HOME_DIR/etc/scripts/harmonize_location_zambezia.sql"
HARMONIZATION_CHECK_CRON=$HOME_DIR/cron/try_to_execute_location_harmonization
HARMONIZATION_RESULT_FILE=$LOCATION_HARMONIZATION_DIR/harmonization_result
HARMONIZATION_STATUS_FILE=$LOCATION_HARMONIZATION_DIR/harmozation_status
HARMONIZATION_FINISHED=$LOCATION_HARMONIZATION_DIR/harmonization_finished
CHECK_STATUS_SCRIPT=$LOCATION_HARMONIZATION_DIR/harmonization_check_status.sql
HARMONIZATION_PROCESS_INFO=$LOCATION_HARMONIZATION_DIR/harmonization_process_info

echo "select * from location_harmonization.harmonization_execution_status;" > $CHECK_STATUS_SCRIPT

$HOME_DIR/scripts/execute_script_on_db.sh $DB_HOST $DB_HOST_PORT $DB_USER $DB_PASSWD $DB_NAME $CHECK_STATUS_SCRIPT $HARMONIZATION_STATUS_FILE

if grep "finished" $HARMONIZATION_STATUS_FILE; then
        echo "The harmonization is finished"
	
	#TODO: SEND HARMONIZATION INFO TO EMAIL

	exit 0
fi

ps aef | grep execute_script_on_db > $HARMONIZATION_PROCESS_INFO

if grep "execute_script_on_db" $HARMONIZATION_PROCESS_INFO; then
        echo "There is another harmonozation process running"

	exit 0
fi

$HOME_DIR/scripts/execute_script_on_db.sh $DB_HOST $DB_HOST_PORT $DB_USER $DB_PASSWD $DB_NAME $HARMONIZATION_SCRIPT $HARMONIZATION_RESULT_FILE

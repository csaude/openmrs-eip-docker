#!/bin/sh
HOME_DIR="/home/eip"

DB_HOST="172.17.0.1"
DB_HOST_PORT="$openmrs_db_port"
DB_USER="root"
DB_PASSWD="$spring_openmrs_datasource_password"
DB_NAME="openmrs_eip_sender_mgt_${db_sync_senderId}"
UPDATE_DATE_SENT_SCRIPT=$HOME_DIR/etc/sql/update_date_sent.sql
UPDATE_EVENT_DATE_SCRIPT=$HOME_DIR/etc/sql/update_event_date.sql
RESULT_SCRIPT="$HOME_DIR/etc/sql/update_sync_message_log.tmp"


. $HOME_DIR/scripts/commons.sh

echo "Executing script to try to update date sent where it has status equal to SENT and date_sent is NULL"

$HOME_DIR/scripts/execute_script_on_db.sh $DB_HOST $DB_HOST_PORT $DB_USER $DB_PASSWD $DB_NAME $UPDATE_DATE_SENT_SCRIPT $RESULT_SCRIPT

echo "Executing script to try to update event date where it has status equal to SENT and event_date is NULL"

$HOME_DIR/scripts/execute_script_on_db.sh $DB_HOST $DB_HOST_PORT $DB_USER $DB_PASSWD $DB_NAME $UPDATE_EVENT_DATE_SCRIPT $RESULT_SCRIPT


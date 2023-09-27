#!/bin/sh
HOME_DIR="/home/eip"

#Take the last line in the offset file
data=$( tail -n 1 "$HOME_DIR/shared/.debezium/offsets.txt" )

DB_HOST="172.17.0.1"
DB_HOST_PORT="$openmrs_db_port"
DB_USER="root"
DB_PASSWD="$spring_openmrs_datasource_password"
DB_NAME="openmrs_eip_sender_mgt_${db_sync_senderId}"
BIN_LOGS_DIR="$HOME_DIR/binlogs-purge"
RESULT_SCRIPT="$BIN_LOGS_DIR/binlog_clear.tmp"
DB_SCRIPT="$BIN_LOGS_DIR/purge.sql"
PURGE_LOG="$HOME_DIR/logs/binlogs-purge/purge.log"
LAST_PURGE_REPORT="$BIN_LOGS_DIR/last_purge_report"
PURGE=0
PURGE_PERIOD=5


. $HOME_DIR/scripts/commons.sh

if [ ! -f "$LAST_PURGE_REPORT" ]; then
        PURGE=1
        logToScreenAndFile "Last purge report was not found! The purge will be done now..." $PURGE_LOG
else
        lastPurgeOn=$(getFileAge $LAST_PURGE_REPORT 'm')

        if [ $lastPurgeOn -ge $PURGE_PERIOD ]; then
                PURGE=1
                logToScreenAndFile "Last purge was done $lastPurgeOn days ago! The purge will be done now..." $PURGE_LOG
        else
                logToScreenAndFile "Last purge was donw $lastPurgeOn days ago! The purge will be posponed!" $PURGE_LOG
        fi
fi

if [ ! -d "$BIN_LOGS_DIR" ]; then
        mkdir $BIN_LOGS_DIR
fi


if [ $PURGE -eq 1 ]; then
	#Split the binlog data using (") and take the 16th position wich is binlog name
	binlog_name=$(echo "$data" | cut -d '"' -f 16)

	SQL="PURGE BINARY LOGS TO '$binlog_name';"

	logToScreenAndFile "$SQL" $PURGE_LOG

	echo $SQL > $DB_SCRIPT

	$HOME_DIR/scripts/execute_script_on_db.sh $DB_HOST $DB_HOST_PORT $DB_USER $DB_PASSWD $DB_NAME $DB_SCRIPT $RESULT_SCRIPT

	currDateTime=$(getCurrDateTime)

	echo "Last purge at $currDateTime" > $LAST_PURGE_REPORT

	RESULT=$(cat $RESULT_SCRIPT)
fi

#!/bin/sh
# Backup of the dbsync state into /home/eip/shared/bkps (./dbsync/shared/bkps on the
# HF), restored by dbsync.sh --enable on a reinstalled HF:
#   - offsets.txt<timestamp> and dbhistory.txt<timestamp> (debezium position)
#   - openmrs_eip_sender_mgt_<senderId>_<timestamp>.sql.gz (dbsync mgt database)
# The last $KEEP backups of each are kept.
#

HOME_DIR=/home/eip
BKPS_HOME=$HOME_DIR/shared/bkps
DEBEZIUM_HOME=$HOME_DIR/shared/.debezium
LOG_FILE=$HOME_DIR/logs/dbsync_state_bkps/bkps.log
DB_HOST="172.17.0.1"
KEEP=7

. $HOME_DIR/scripts/commons.sh

# Cron jobs don't get the container environment (eip.env), so it is taken from the
# main process of the container
getContainerEnv(){
	tr '\0' '\n' < /proc/1/environ | sed -n "s/^$1=//p" | head -n 1
}

DB_HOST_PORT=$(getContainerEnv openmrs_db_port)
DB_PASSWD=$(getContainerEnv spring_openmrs_datasource_password)
DB_NAME="openmrs_eip_sender_mgt_$(getContainerEnv db_sync_senderId)"

timestamp=$(getCurrDateTime)

mkdir -p $BKPS_HOME

logToScreenAndFile "STARTING DBSYNC STATE BACKUP" $LOG_FILE

if [ -f "$DEBEZIUM_HOME/offsets.txt" ] && [ -f "$DEBEZIUM_HOME/dbhistory.txt" ]; then
	cp "$DEBEZIUM_HOME/offsets.txt" "$BKPS_HOME/offsets.txt$timestamp"
	cp "$DEBEZIUM_HOME/dbhistory.txt" "$BKPS_HOME/dbhistory.txt$timestamp"
	logToScreenAndFile "DEBEZIUM OFFSETS COPIED TO $BKPS_HOME (offsets.txt$timestamp, dbhistory.txt$timestamp)" $LOG_FILE
else
	logToScreenAndFile "DEBEZIUM OFFSETS NOT FOUND IN $DEBEZIUM_HOME, NOTHING TO COPY" $LOG_FILE
fi

DUMP_FILE="$BKPS_HOME/${DB_NAME}_$timestamp.sql"

if MYSQL_PWD="$DB_PASSWD" mysqldump -h "$DB_HOST" -P "$DB_HOST_PORT" -u root --single-transaction --routines --triggers --databases "$DB_NAME" > "$DUMP_FILE.tmp" 2>> $LOG_FILE; then
	mv "$DUMP_FILE.tmp" "$DUMP_FILE"
	gzip -f "$DUMP_FILE"
	logToScreenAndFile "$DB_NAME DUMPED TO $DUMP_FILE.gz" $LOG_FILE
else
	rm -f "$DUMP_FILE.tmp"
	logToScreenAndFile "FAILED TO DUMP $DB_NAME, SEE $LOG_FILE" $LOG_FILE
fi

# Keeps the last $KEEP backups of each kind (the names sort by timestamp)
for pattern in "offsets.txt?*" "dbhistory.txt?*" "${DB_NAME}_*.sql.gz"; do
	ls -1 $BKPS_HOME/$pattern 2>/dev/null | sort | head -n -$KEEP | while read -r old_bkp; do
		rm -f "$old_bkp"
		logToScreenAndFile "REMOVED OLD BACKUP $old_bkp" $LOG_FILE
	done
done

logToScreenAndFile "DBSYNC STATE BACKUP FINISHED" $LOG_FILE

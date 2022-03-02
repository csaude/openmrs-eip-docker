#!/bin/sh
# Startup script for EPTS SYNC Sender Application
#
# chkconfig: - 85 15
# description: EPTS SYNC Application
# processname:eptssync 
# pidfile:
# config:

# Set EPTSSYNC environment.
timestamp=`date +%Y-%m-%d_%H-%M-%S`
EPTSSYNC_HOME=/home/application/eptssync
EPTSSYNC_HOME=/home/eip/application/eptssync
CONFIG_FILE=$EPTSSYNC_HOME/conf/detect_changed_records.tmp.json
CONFIG_FILE_ORIGINAL=$EPTSSYNC_HOME/conf/detect_changed_records.json

cp $CONFIG_FILE_ORIGINAL $CONFIG_FILE

#PREPARE THE CONFIG FILE
sed -i "s/db_sync_senderId/$db_sync_senderId/g" $CONFIG_FILE
sed -i "s/origin_app_location_code/$origin_app_location_code/g" $CONFIG_FILE
sed -i "s/openmrs_db_host/$openmrs_db_host/g" $CONFIG_FILE
sed -i "s/openmrs_db_port/$openmrs_db_port/g" $CONFIG_FILE
sed -i "s/openmrs_db_name/$openmrs_db_name/g" $CONFIG_FILE
sed -i "s/spring_openmrs_datasource_password/$spring_openmrs_datasource_password/g" $CONFIG_FILE

mkdir $EPTSSYNC_HOME/logs

# Start application.
echo -n "Starting EPTS Application"
cd $EPTSSYNC_HOME
java -jar eptssync-api-1.0-SNAPSHOT.jar "$CONFIG_FILE" > $EPTSSYNC_HOME/logs/logs_$timestamp.txt
echo -n "APPLICATION STARTED IN BACKGROUND."

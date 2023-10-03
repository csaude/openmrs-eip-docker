#!/bin/sh
# Startup script for EPTS SYNC Sender Application
#
# chkconfig: - 85 15
# description: EPTS SYNC Application
# processname:eptssync 
# pidfile:
# config:

# Set EPTSSYNC environment.
observationDate=$1
timestamp=`date +%Y-%m-%d_%H-%M-%S`
EPTSSYNC_HOME=/home/application/eptssync
EPTSSYNC_HOME=/home/eip/application/eptssync
CONFIG_FILE=$EPTSSYNC_HOME/conf/detect_changed_records.tmp.json
CONFIG_FILE_ORIGINAL=$EPTSSYNC_HOME/conf/detect_changed_records.json
LOG_DIR="$EPTSSYNC_HOME/logs"
LOG_FILE="$LOG_DIR/logs_$timestamp.txt"
EIP_SCRIPTS_DIR="/home/eip/scripts"



. $EIP_SCRIPTS_DIR/commons.sh

dateSuggestionMsg="Please provide a date in format 'yyyy-mm-dd'"

if [ -z $observationDate ]; then
	echo "The observation date is not specified. $dateSuggestionMsg"
	exit 1
fi

if date -d "$observationDate" &> /dev/null; then
        echo "The provided Observation Start Date is Invalid. $dateSuggestionMsg"
	exit 1;
fi

observationDate=$(date -d "$DATE" +%s%3N);


cp $CONFIG_FILE_ORIGINAL $CONFIG_FILE

#PREPARE THE CONFIG FILE
sed -i "s/db_sync_senderId/$db_sync_senderId/g" $CONFIG_FILE
sed -i "s/origin_app_location_code/$origin_app_location_code/g" $CONFIG_FILE
sed -i "s/openmrs_db_host/$openmrs_db_host/g" $CONFIG_FILE
sed -i "s/openmrs_db_port/$openmrs_db_port/g" $CONFIG_FILE
sed -i "s/openmrs_db_name/$openmrs_db_name/g" $CONFIG_FILE
sed -i "s/observation_date/$observationDate/g" $CONFIG_FILE
sed -i "s/spring_openmrs_datasource_password/$spring_openmrs_datasource_password/g" $CONFIG_FILE

if [ ! -d $LOG_DIR ]; then
	echo "The log dir does not exists! Creating it...."
	mkdir $LOG_DIR
fi

# Start application.
echo -n "Starting EPTS Application"
cd $EPTSSYNC_HOME
nohup java -jar eptssync-api-1.0-SNAPSHOT.jar "$CONFIG_FILE" 2>&1 > $LOG_FILE
echo -n "APPLICATION STARTED IN BACKGROUND."

isDockerInstallation
isDocker=$?


echo "To follow logs please run bellow command." 

command="tail -f $LOG_FILE"

if [ $isDocker = 1 ]; then
   echo "docker exec -i openmrs-eip-sender $command"
else
	echo $command
fi

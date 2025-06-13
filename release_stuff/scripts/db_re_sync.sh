#!/bin/sh
# Startup script for EPTS SYNC Sender Application
#
# chkconfig: - 85 15
# description: EPTS SYNC Application
# processname:eptssync 
# pidfile:
# config:

# Set EPTS_ETL environment.
startDateInput=$1
CONFIG_FILE_ORIGINAL=$2

timestamp=`date +%Y-%m-%d_%H-%M-%S`
EIP_HOME=/home/eip
CONFIG_FILE=$EIP_HOME/conf/detect_changed_records.tmp.json
LOG_DIR="$EIP_HOME/logs"
LOG_FILE="$LOG_DIR/logs_$timestamp.txt"
EIP_SCRIPTS_DIR="$EIP_HOME/scripts"


. $EIP_SCRIPTS_DIR/commons.sh

dateSuggestionMsg="Please provide a date in format 'yyyy-mm-dd'"

if [ -z "$CONFIG_FILE_ORIGINAL" ]; then
	echo "No conf file were specified. The default file will be used"
	CONFIG_FILE_ORIGINAL="$EIP_HOME/conf/detect_changed_records.json"
fi


if [ -z $startDateInput ]; then
        echo "The start date is not specified. $dateSuggestionMsg"
        exit 1
elif  [ "$(date -d "$startDateInput" +%Y-%m-%d 2> /dev/null)" = "$startDateInput" ]; then

        startDate=$startDateInput

        echo "Using Start Date ${startDate}"
else
        echo "The provided Start Date [$startDateInput]  is Invalid. $dateSuggestionMsg"
        exit 1;
fi

echo "Using conf file $CONFIG_FILE_ORIGINAL"

cp $CONFIG_FILE_ORIGINAL $CONFIG_FILE

#PREPARE THE CONFIG FILE
sed -i "s/db_sync_senderId/$db_sync_senderId/g" $CONFIG_FILE
sed -i "s/origin_app_location_code/$origin_app_location_code/g" $CONFIG_FILE
sed -i "s/openmrs_db_host/$openmrs_db_host/g" $CONFIG_FILE
sed -i "s/openmrs_db_port/$openmrs_db_port/g" $CONFIG_FILE
sed -i "s/openmrs_db_name/$openmrs_db_name/g" $CONFIG_FILE
sed -i "s/start_date/$startDate/g" $CONFIG_FILE
sed -i "s/spring_openmrs_datasource_password/$spring_openmrs_datasource_password/g" $CONFIG_FILE

if [ ! -d $LOG_DIR ]; then
	echo "The log dir does not exists! Creating it...."
	mkdir $LOG_DIR
fi

# Start application.
echo -n "Starting EPTS Application"
cd $EIP_HOME
nohup java -jar epts-etl-api.jar "$CONFIG_FILE" 2>&1 > $LOG_FILE &
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

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

EPTSSYNC_HOME="/home/eptssync"
CONFIG_FILE=$EPTSSYNC_HOME/conf/source_sync_config.tmp.json
CONFIG_FILE_ORIGINAL=$EPTSSYNC_HOME/conf/source_sync_config.json
EIP_SETUP_SCRIPTS_DIR="$EPTSSYNC_HOME/scripts/eip"
SHARED_DIR="$HOME_DIR/shared"
RELEASES_PACKAGES_DIR="$SHARED_DIR/releases"
APK_CMD=$(which apk)

# Installing dependencies on APK distros and download release files if necessary
if [ ! -z $APK_CMD ]
then
    apk add wget
fi

. $EIP_SETUP_SCRIPTS_DIR/release_info.sh
echo "Verifying $RELEASE_NAME packages download status"
$EIP_SETUP_SCRIPTS_DIR/download_release.sh "$RELEASES_PACKAGES_DIR" "$RELEASE_NAME" "$OPENMRS_EIP_APP_RELEASE_URL" "$EPTSSYNC_API_RELEASE_URL"

CURRENT_RELEASES_PACKAGES_DIR="$RELEASES_PACKAGES_DIR/$RELEASE_NAME"

RELEASE_PACKAGES_DOWNLOAD_COMPLETED="$CURRENT_RELEASES_PACKAGES_DIR/download_completed"
if [ ! -f "$RELEASE_PACKAGES_DOWNLOAD_COMPLETED" ]
then
    echo "Error trying to download release packages: $RELEASE_NAME. See previous messages."
    echo "Inconsistence startup process failed"
    exit 1
fi

# copying files
echo "Copying $EPTSSYNC_PACKAGE_RELEASE_FILE_NAME to $EPTSSYNC_HOME/eptssync-api-1.0-SNAPSHOT.jar"
cp "$CURRENT_RELEASES_PACKAGES_DIR/$EPTSSYNC_PACKAGE_RELEASE_FILE_NAME" "$EPTSSYNC_HOME/eptssync-api-1.0-SNAPSHOT.jar"


cp $CONFIG_FILE_ORIGINAL $CONFIG_FILE

#PREPARE THE CONFIG FILE
sed -i "s/origin_app_location_code/$origin_app_location_code/g" $CONFIG_FILE 
sed -i "s/openmrs_db_host/$openmrs_db_host/g" $CONFIG_FILE 
sed -i "s/openmrs_db_port/$openmrs_db_port/g" $CONFIG_FILE 
sed -i "s/openmrs_db_name/$openmrs_db_name/g" $CONFIG_FILE 
sed -i "s/spring_openmrs_datasource_password/$spring_openmrs_datasource_password/g" $CONFIG_FILE 


# Start application.
echo -n "Starting EPTS Application"
cd $EPTSSYNC_HOME
#java -jar eptssync-api-1.0-SNAPSHOT.jar "$CONFIG_FILE" 
java -jar eptssync-api-1.0-SNAPSHOT.jar "$CONFIG_FILE" > $EPTSSYNC_HOME/logs/log.txt
echo -n "APPLICATION STARTED IN BACKGROUND."


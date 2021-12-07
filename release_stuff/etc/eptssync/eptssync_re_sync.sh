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

# Start application.
echo -n "Starting EPTS Application"
cd $EPTSSYNC_HOME
java -jar eptssync-api-1.0-SNAPSHOT.jar "conf/source_sync_config.json" > $EPTSSYNC_HOME/logs/logs_$timestamp.txt
echo -n "APPLICATION STARTED IN BACKGROUND."

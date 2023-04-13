#!/bin/sh
# EIP RELEASES INFO
#

HOME_DIR="/home/eip"
RELEASE_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
RELEASE_DIR="$RELEASE_BASE_DIR/release_stuff"
RELEASE_SCRIPTS_DIR="$RELEASE_DIR/scripts"
ONGOING_UPDATE_INFO_FILE="$HOME_DIR/ongoing_update_info"
TMP_UPDATE_DONE="$HOME_DIR/tmp_update_done_01"
ONGOING_UPGRADE="$HOME_DIR/ongoing_update.tmp"

export RELEASE_NAME="EIP-Release-4.0.1"
export RELEASE_DATE="2023-03-30 11:00:00"
export RELEASE_DESC="New release with several improvments and new feactures"

export OPENMRS_EIP_APP_RELEASE_URL="https://github.com/FriendsInGlobalHealth/openmrs-eip-docker/releases/download/v4.0.0/openmrs-eip-app-1.2.jar"
export EPTSSYNC_API_RELEASE_URL="https://github.com/FriendsInGlobalHealth/openmrs-eip-docker/releases/download/v4.0.0/eptssync-api-1.0-SNAPSHOT.jar"

#export OPENMRS_EIP_APP_RELEASE_URL="https://github.com/FriendsInGlobalHealth/openmrs-eip-docker/releases/download/v3.0.1.0/openmrs-eip-app-1.1.jar"
#export EPTSSYNC_API_RELEASE_URL="https://github.com/FriendsInGlobalHealth/openmrs-eip-docker/releases/download/v3.0.1.0/eptssync-api-1.0-SNAPSHOT.jar"

RUNNING_PROCESS="./running_update_02.tmp"

ps -aef | grep updates.sh > $RUNNING_PROCESS

wcResult=$(wc $RUNNING_PROCESS)
linesCount=$(echo $wcResult | cut -d' ' -f1)

rm $RUNNING_PROCESS

#IF THIS WAS NOT CALL FROM ANY UPDATE THEN SKIP TEMPORAY UPDATE
if [ $linesCount -gt 1 ]; then
        if [ -f "$TMP_UPDATE_DONE" ]; then
                echo "THE TMP UPDATE HAS ALREADY DONE"
        else
		echo "PERFORMING TEMPORARY UPDATE..."

                rm $ONGOING_UPDATE_INFO_FILE
                cd $RELEASE_SCRIPTS_DIR
                touch $TMP_UPDATE_DONE
                ./updates.sh 2>&1 | tee -a $LOG_DIR/upgrade.log

                $RELEASE_SCRIPTS_DIR/eip_stop.sh
                sleep 30
        fi
else
        echo "INITIAL SETUP IGNORE TEMPORAY UPDATE ROUNTINE"
fi

#!/bin/sh
# EIP RELEASES INFO
#

HOME_DIR="/home/eip"
RELEASE_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
RELEASE_DIR="$RELEASE_BASE_DIR/release_stuff"
RELEASE_SCRIPTS_DIR="$RELEASE_DIR/scripts"
ONGOING_UPDATE_INFO_FILE="$HOME_DIR/ongoing_update_info"
TMP_UPDATE_DONE="$HOME_DIR/tmp_update_done_03"
ONGOING_UPGRADE="$HOME_DIR/ongoing_update.tmp"

. $RELEASE_SCRIPTS_DIR/commons.sh

checkIfProcessIsRunning "{updates.sh}"
running=$?

if [ $running -eq 0 ]; then
        echo "INITIAL SETUP IGNORE TEMPORAY UPDATE ROUNTINE"
else
        if [ -f "$TMP_UPDATE_DONE" ]; then
                echo "THE TMP UPDATE HAS ALREADY DONE"
        else
		echo "PERFORMING TEMPORARY UPDATE..."

                rm $ONGOING_UPDATE_INFO_FILE
                touch $TMP_UPDATE_DONE
		
		#Kill the current update process to guaranty that all new files will be copied
		killProcess "{run_updates.sh}"

                $RELEASE_SCRIPTS_DIR/updates.sh 2>&1 | tee -a $LOG_DIR/upgrade.log

                $RELEASE_SCRIPTS_DIR/eip_stop.sh

                sleep 30
        fi
fi

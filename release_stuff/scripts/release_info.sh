# EIP RELEASES INFO
#

HOME_DIR="/home/eip"
RELEASE_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
RELEASE_DIR="$RELEASE_BASE_DIR/release_stuff"
RELEASE_SCRIPTS_DIR="$RELEASE_DIR/scripts"
ONGOING_UPDATE_INFO_FILE="$HOME_DIR/ongoing_update_info"
TMP_UPDATE_DONE="$HOME_DIR/tmp_update_done_01"

export RELEASE_NAME="EIP release 3.0.1.0"
export RELEASE_DATE="2023-02-13 11:30:00"
export RELEASE_DESC="New release with several improvments and new feactures"

export OPENMRS_EIP_APP_RELEASE_URL="https://github.com/FriendsInGlobalHealth/openmrs-eip-docker/releases/download/v3.0.1.0/openmrs-eip-app-1.1.jar"
export EPTSSYNC_API_RELEASE_URL="https://github.com/FriendsInGlobalHealth/openmrs-eip-docker/releases/download/v3.0.1.0/eptssync-api-1.0-SNAPSHOT.jar"

cd $RELEASE_SCRIPTS_DIR

rm $ONGOING_UPDATE_INFO_FILE

if [ -f "$TMP_UPDATE_DONE" ]; then 
	echo "THE TMP UPDATE HAS ALREADY DONE"
else
	touch $TMP_UPDATE_DONE
	./updates.sh 2>&1 | tee -a $LOG_DIR/upgrade.log

	$RELEASE_SCRIPTS_DIR/eip_stop.sh
	sleep 30
fi

# EIP RELEASES INFO
#

HOME_DIR="/home/eip"
RELEASE_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
RELEASE_DIR="$RELEASE_BASE_DIR/release_stuff"
RELEASE_SCRIPTS_DIR="$RELEASE_DIR/scripts"
ONGOING_UPDATE_INFO_FILE="$HOME_DIR/ongoing_update_info"

export RELEASE_NAME="EIP release v3.0.1.0"
export RELEASE_DATE="2023-02-09 14:40:00"
export RELEASE_DESC="New release with several improvments and new feactures"

export OPENMRS_EIP_APP_RELEASE_URL="https://github.com/FriendsInGlobalHealth/openmrs-eip-docker/releases/download/v3.0.1.0/openmrs-eip-app-1.1.jar"
export EPTSSYNC_API_RELEASE_URL="https://github.com/FriendsInGlobalHealth/openmrs-eip-docker/releases/download/v3.0.1.0/eptssync-api-1.0-SNAPSHOT.jar"

cd $RELEASE_SCRIPTS_DIR

rm $ONGOING_UPDATE_INFO_FILE

./updates.sh 2>&1 | tee -a $LOG_DIR/upgrade.log

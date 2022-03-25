#!/bin/sh
# Installing git-lfs and pulling for the first time
echo "STARTING GIT LFS INSTALLATION AND FIRST LFS PULL"

HOME_DIR="/home/eip"
SCRIPTS_DIR="$HOME_DIR/scripts"
RELEASE_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
RELEASE_DIR="$RELEASE_BASE_DIR/release_stuff"
EPTSSYNC_SETUP_STUFF_DIR="$RELEASE_DIR/etc/eptssync"
EPTSSYNC_HOME_DIR="$HOME_DIR/application/eptssync"
# LOG_DIR="$HOME_DIR/shared/logs/upgrade"

#if [ -d "$LOG_DIR" ]; then
#       echo "THE LOG DIR EXISTS" # | tee -a $LOG_DIR/upgrade.log
#else
#       mkdir -p $LOG_DIR
#       echo "THE LOG DIR WAS CREATED" # | tee -a $LOG_DIR/upgrade.log
#fi

APK_CMD=$(which apk)

if [ ! -z $APK_CMD ]
then
    echo "TRYING TO INSTALL GIT LFS USING APK" # | tee -a $LOG_DIR/upgrade.log
    apk add git-lfs
else
    echo "TRYING TO INSTALL GIT LFS USING APT" # | tee -a $LOG_DIR/upgrade.log
    apt install -y git-lfs
fi
echo "GIT LFS INSTALLED" #| tee -a $LOG_DIR/upgrade.log

echo "STARTING GIT LFS PULL"
git -C $RELEASE_BASE_DIR lfs pull
echo "GIT LFS PULL WAS DONE"

echo "COPYING FETCHED LARGE JAR FILES"
cp $RELEASE_DIR/*.jar $HOME_DIR
cp $EPTSSYNC_SETUP_STUFF_DIR/*.jar $EPTSSYNC_HOME_DIR
echo "FETCHED LARGE JAR FILES WAS COPIED"

echo "SUCCESSFULLY ENDED GIT LFS INSTALLATION AND FIRST LFS PULL"

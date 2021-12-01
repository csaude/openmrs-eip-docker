#!/bin/sh
# This scrip is intended to check for updates for eip application and apply them when avaliable
#

#ENV
HOME_DIR="/home/eip"
RELEASE_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
RELEASE_DIR="$RELEASE_BASE_DIR/release_stuff"
SCRIPTS_DIR="$HOME_DIR/scripts"
RELEASE_SCRIPTS_DIR="$RELEASE_DIR/scripts"

ONGOING_UPDATE_INFO_FILE="$HOME_DIR/ongoing_update_info"

if [ -f "$ONGOING_UPDATE_INFO_FILE" ]; then
	echo "THERE IS ANOTHER UPDATE PROCESS ONGOING >> $HOME_DIR/updates.log"
else
	echo "UPDATE ONGOING..." > $ONGOING_UPDATE_INFO_FILE 

	#INSTALL GIT
	echo "TRYING TO INSTALL GIT >> $HOME_DIR/updates.log"
	apk add git || echo "An error happened trying to install GIT "
	echo "GIT INSTALLED >> $HOME_DIR/updates.log"


	timestamp=`date +%Y-%m-%d_%H-%M-%S`

	echo "CHECKING FOR UPDATES AT $timestamp >> $HOME_DIR/updates.log"
	echo "------------------------------------------------------------- >> $HOME_DIR/updates.log"

	if [ -d "$RELEASE_BASE_DIR" ]; then
	   echo "RELEASE PROJECT ALREADY CLONED! >> $HOME_DIR/updates.log"	
	else
   		echo "CLONIG RELEASE PROJECT... >> $HOME_DIR/updates.log"
	   	git clone https://github.com/FriendsInGlobalHealth/openmrs-eip-docker.git $RELEASE_BASE_DIR
	   	echo "RELEASE PROJECT CLONED TO $RELEASE_BASE_DIR >> $HOME_DIR/updates.log"
	fi


	#Pull changes from remote project
	echo "LOOKING FOR EIP PROJECT UPDATES >> $HOME_DIR/updates.log"
	echo "PULLING EIP PROJECT FROM DOCKER >> $HOME_DIR/updates.log"
	git -C $RELEASE_BASE_DIR pull origin main
	echo "EIP PROJECT PULLED FROM DOCKER >> $HOME_DIR/updates.log" 


	source $SCRIPTS_DIR/release_info.sh

	LOCAL_RELEASE_NAME=$RELEASE_NAME
	LOCAL_RELEASE_DATE=$RELEASE_DATE

	source $RELEASE_SCRIPTS_DIR/release_info.sh

	REMOTE_RELEASE_NAME=$RELEASE_NAME
	REMOTE_RELEASE_DATE=$RELEASE_DATE


	echo "LOCAL RELEASE INFO {NAME: $LOCAL_RELEASE_NAME, DATE: $LOCAL_RELEASE_DATE}  >> $HOME_DIR/updates.log"
	echo "REMOTE RELEASE INFO {NAME: $REMOTE_RELEASE_NAME, DATE: $REMOTE_RELEASE_DATE}  >> $HOME_DIR/updates.log"

	if [[ "$LOCAL_RELEASE_DATE" != "$REMOTE_RELEASE_DATE" ]]; then
	        echo "UPDATES FOUND... >> $HOME_DIR/updates.log"
	        echo "PERFORMING UPDATE STEPS... >> $HOME_DIR/updates.log"
	        echo "STOPPING EIP APPLICATION.. >> $HOME_DIR/updates.log"

	        $SCRIPTS_DIR/eip.sh stop

	        echo "EIP APLICATION STOPPED! >> $HOME_DIR/updates.log"
	        echo "PERFORMING UPDATES... >> $HOME_DIR/updates.log"

	        cp -R $RELEASE_DIR/* $HOME_DIR/ 
	        echo "UPDATE DONE! >> $HOME_DIR/updates.log"

	        echo "RESTARING EIP APPLICATION >> $HOME_DIR/updates.log"
	        $SCRIPTS_DIR/eip.sh start
	        echo "EIP APPLICATION RESTARTED >> $HOME_DIR/updates.log"

	else
        	echo "NO UPDATES FOUND... >> $HOME_DIR/updates.log"
	fi
	rm $ONGOING_UPDATE_INFO_FILE
fi


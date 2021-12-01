#!/bin/sh
# This scrip is intended to check for updates for eip application and apply them when avaliable
#

#ENV
HOME_DIR="/home/eip"
RELEASE_DIR="/home/eip/openmrs-eip-docker"
ONGOING_UPDATE_INFO_FILE="/home/eip/ongoing_update_info"

if [ -f "$ONGOING_UPDATE_INFO_FILE" ]; then
	echo "THERE IS ANOTHER UPDATE PROCESS ONGOING >> $HOME_DIR/updates.log"
else
	echo "UPDATE ONGOING..." > /home/eip/ongoing_update_info

	#INSTALL GIT
	echo "TRYING TO INSTALL GIT >> $HOME_DIR/updates.log"
	apk add git || echo "An error happened trying to install GIT "
	echo "GIT INSTALLED >> $HOME_DIR/updates.log"


	timestamp=`date +%Y-%m-%d_%H-%M-%S`

	echo "CHECKING FOR UPDATES AT $timestamp >> $HOME_DIR/updates.log"
	echo "------------------------------------------------------------- >> $HOME_DIR/updates.log"

	cd $HOME_DIR

	if [ -d "$RELEASE_DIR" ]; then
	   echo "RELEASE PROJECT ALREADY CLONED! >> $HOME_DIR/updates.log"	
	else
   		echo "CLONIG RELEASE PROJECT... >> $HOME_DIR/updates.log"
	   	git clone https://github.com/FriendsInGlobalHealth/openmrs-eip-docker.git
	   	echo "RELEASE PROJECT CLONED TO $HOME_DIR/openmrs-eip-docker >> $HOME_DIR/updates.log"
	fi


	#Pull changes from remote project
	cd $RELEASE_DIR
	echo "LOOKING FOR EIP PROJECT UPDATES >> $HOME_DIR/updates.log"
	echo "PULLING EIP PROJECT FROM DOCKER >> $HOME_DIR/updates.log"
	git pull origin main
	echo "EIP PROJECT PULLED FROM DOCKER >> $HOME_DIR/updates.log" 

	cd $HOME_DIR

	source scripts/realease_info.sh

	LOCAL_RELEASE_NAME=$RELEASE_NAME
	LOCAL_RELEASE_DATE=$RELEASE_DATE

	source $RELEASE_DIR/release_stuff/scripts/realease_info.sh

	REMOTE_RELEASE_NAME=$RELEASE_NAME
	REMOTE_RELEASE_DATE=$RELEASE_DATE


	echo "LOCAL RELEASE INFO {NAME: $LOCAL_RELEASE_NAME, DATE: $LOCA_RELEASE_DATE}  >> $HOME_DIR/updates.log"
	echo "REMOVE RELEASE INFO {NAME: $REMOTE_RELEASE_NAME, DATE: $REMOTE_RELEASE_DATE}  >> $HOME_DIR/updates.log"

	if [ $LOCAL_RELEASE_DATE != $REMOTE_RELEASE_DATE ]; then
	        echo "UPDATES FOUND..."  >> $HOME_DIR/updates.log
	        echo "PERFORMING UPDATE STEPS... >> $HOME_DIR/updates.log"
	        echo "STOPPING EIP APPLICATION.. >> $HOME_DIR/updates.log"

	        scripts/eip.sh stop

	        echo "EIP APLICATION STOPPED! >> $HOME_DIR/updates.log"
	        echo "PERFORMING UPDATES... >> $HOME_DIR/updates.log"

	        cp -R $RELEASE_DIR/* .
	        echo "UPDATE DONE! >> $HOME_DIR/updates.log"

	        echo "RESTARING EIP APPLICATION"  >> $HOME_DIR/updates.log
	        scripts/eip.sh start
	        echo "EIP APPLICATION RESTARTED"  >> $HOME_DIR/updates.log

	else
        	echo "NO UPDATES FOUND..."  >> $HOME_DIR/updates.log
	fi
	rm /home/eip/ongoing_update_info
fi


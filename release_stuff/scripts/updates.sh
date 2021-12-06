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
	echo "THERE IS ANOTHER UPDATE PROCESS ONGOING" | tee $HOME_DIR/updates.log
else
	echo "UPDATE ONGOING..." > $ONGOING_UPDATE_INFO_FILE 

	#INSTALL GIT
	echo "TRYING TO INSTALL GIT" | tee $HOME_DIR/updates.log
	apk update
	apk add git || echo "An error happened trying to install GIT "
	echo "GIT INSTALLED" | tee $HOME_DIR/updates.log
	echo "INSTALLING SSMPT" | tee $HOME_DIR/updates.log
	apk add ssmtp
	echo "SSMPT INSTALLED" | tee $HOME_DIR/updates.log



	timestamp=`date +%Y-%m-%d_%H-%M-%S`

	echo "CHECKING FOR UPDATES AT $timestamp" | tee $HOME_DIR/updates.log
	echo "-------------------------------------------------------------" | tee $HOME_DIR/updates.log

	if [ -d "$RELEASE_BASE_DIR" ]; then
	   echo "RELEASE PROJECT ALREADY CLONED!" | tee $HOME_DIR/updates.log	
	else
   		echo "CLONIG RELEASE PROJECT..." | tee $HOME_DIR/updates.log
	   	git clone https://github.com/FriendsInGlobalHealth/openmrs-eip-docker.git $RELEASE_BASE_DIR
	   	echo "RELEASE PROJECT CLONED TO $RELEASE_BASE_DIR" | tee $HOME_DIR/updates.log
	fi


	#Pull changes from remote project
	echo "LOOKING FOR EIP PROJECT UPDATES" | tee $HOME_DIR/updates.log
	echo "PULLING EIP PROJECT FROM DOCKER" | tee $HOME_DIR/updates.log
	git -C $RELEASE_BASE_DIR pull origin main
	echo "EIP PROJECT PULLED FROM GIT REPOSITORY" | tee $HOME_DIR/updates.log 


	source $SCRIPTS_DIR/release_info.sh

	LOCAL_RELEASE_NAME=$RELEASE_NAME
	LOCAL_RELEASE_DATE=$RELEASE_DATE

	source $RELEASE_SCRIPTS_DIR/release_info.sh

	REMOTE_RELEASE_NAME=$RELEASE_NAME
	REMOTE_RELEASE_DATE=$RELEASE_DATE


	echo "LOCAL RELEASE INFO {NAME: $LOCAL_RELEASE_NAME, DATE: $LOCAL_RELEASE_DATE} " | tee $HOME_DIR/updates.log
	echo "REMOTE RELEASE INFO {NAME: $REMOTE_RELEASE_NAME, DATE: $REMOTE_RELEASE_DATE} " | tee $HOME_DIR/updates.log

	if [[ "$LOCAL_RELEASE_DATE" != "$REMOTE_RELEASE_DATE" ]]; then
	        echo "UPDATES FOUND..." | tee $HOME_DIR/updates.log
	        echo "PERFORMING UPDATE STEPS..." | tee $HOME_DIR/updates.log
	        echo "STOPPING EIP APPLICATION.." | tee $HOME_DIR/updates.log

	        $SCRIPTS_DIR/eip_stop.sh

	        echo "EIP APLICATION STOPPED!" | tee $HOME_DIR/updates.log
	        echo "PERFORMING UPDATES..." | tee $HOME_DIR/updates.log

	        cp -R $RELEASE_DIR/* $HOME_DIR/ 
	        echo "UPDATE DONE!" | tee $HOME_DIR/updates.log

	        echo "RESTARING EIP APPLICATION" | tee $HOME_DIR/updates.log
	        $SCRIPTS_DIR/eip_startup.sh
	        echo "EIP APPLICATION RESTARTED" | tee $HOME_DIR/updates.log

	else
        	echo "NO UPDATES FOUND..." | tee $HOME_DIR/updates.log
	fi

	EMAIL_CONTENT_FILE="/home/eip/update_email_content"

        echo "To: jorge.boane@fgh.org.mz" >> $EMAIL_CONTENT_FILE
        echo "From: jorge.boane@fgh.org.mz" >> $EMAIL_CONTENT_FILE
        echo "Subject: EIP REMOTO - ESTADO DE ACTUALIZACAO[$db_sync_senderId]" >> $EMAIL_CONTENT_FILE
	echo "Caros" >> $EMAIL_CONTENT_FILE
       	echo "Junto enviamos o report da ultima tentativa de actualizacao da aplicacao openmrs-eip." >> $EMAIL_CONTENT_FILE 
	echo "" >> $EMAIL_CONTENT_FILE
	echo "INFORMACAO DAS RELEASES" >> $EMAIL_CONTENT_FILE
	echo "---------------------" >> $EMAIL_CONTENT_FILE
	echo "LOCAL RELEASE INFO {NAME: $LOCAL_RELEASE_NAME, DATE: $LOCAL_RELEASE_DATE}REMOTE RELEASE INFO {NAME: $REMOTE_RELEASE_NAME, DATE: $REMOTE_RELEASE_DATE}." >> $EMAIL_CONTENT_FILE
	echo "--------------------" >> $EMAIL_CONTENT_FILE
	echo "" >> $EMAIL_CONTENT_FILE
	echo "Enviado automaticamente a partir do servidor $db_sync_senderId." >> $EMAIL_CONTENT_FILE

	#INSTALL SSMPT
	apk update
	echo "INSTALLING SSMPT"
	apk add ssmtp
	echo "SSMPT INSTALLED"

	sendmail -t -f  < $EMAIL_CONTENT_FILE

	rm $EMAIL_CONTENT_FILE

	echo "EMAIL SENT!"

	rm $ONGOING_UPDATE_INFO_FILE
fi

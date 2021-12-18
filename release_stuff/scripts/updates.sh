#!/bin/sh
# This scrip is intended to check for updates for eip application and apply them when avaliable
#

#ENV
HOME_DIR="/home/eip"
RELEASE_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
RELEASE_DIR="$RELEASE_BASE_DIR/release_stuff"
SCRIPTS_DIR="$HOME_DIR/scripts"
RELEASE_SCRIPTS_DIR="$RELEASE_DIR/scripts"
EPTSSYNC_SETUP_STUFF_DIR="$RELEASE_DIR/etc/eptssync"
EPTSSYNC_HOME_DIR="$HOME_DIR/application/eptssync"
ONGOING_UPDATE_INFO_FILE="$HOME_DIR/ongoing_update_info"
LOG_DIR=$HOME_DIR/shared/logs/upgrade

if [ -d "$LOG_DIR" ]; then
       echo "THE LOG DIR EXISTS" | tee -a $LOG_DIR/upgrade.log
else
       mkdir -p $LOG_DIR
       echo "THE LOG DIR WAS CREATED" | tee -a $LOG_DIR/upgrade.log
fi


if [ -f "$ONGOING_UPDATE_INFO_FILE" ]; then
	echo "THERE IS ANOTHER UPDATE PROCESS ONGOING" | tee -a $LOG_DIR/upgrade.log
else
	echo "UPDATE ONGOING..." > $ONGOING_UPDATE_INFO_FILE 

	timestamp=`date +%Y-%m-%d_%H-%M-%S`

	echo "CHECKING FOR UPDATES AT $timestamp" | tee -a $LOG_DIR/upgrade.log
	echo "-------------------------------------------------------------" | tee -a $LOG_DIR/upgrade.log

	if [ -d "$RELEASE_BASE_DIR" ]; then
	   echo "RELEASE PROJECT ALREADY CLONED!" | tee -a $LOG_DIR/upgrade.log
	else
   		echo "CLONIG RELEASE PROJECT..." | tee -a $LOG_DIR/upgrade.log
	   	git clone https://github.com/FriendsInGlobalHealth/openmrs-eip-docker.git $RELEASE_BASE_DIR
	   	echo "RELEASE PROJECT CLONED TO $RELEASE_BASE_DIR" | tee -a $LOG_DIR/upgrade.log
	fi

	git config --global user.email "jpboane@gmail.com"
	git config --global user.name "jpboane"

	#Pull changes from remote project
	echo "LOOKING FOR EIP PROJECT UPDATES" | tee -a $LOG_DIR/upgrade.log
	
	echo "PULLING EIP PROJECT FROM DOCKER" | tee -a $LOG_DIR/upgrade.log
	
	git -C $RELEASE_BASE_DIR clean -df
	git -C $RELEASE_BASE_DIR reset --hard
	git -C $RELEASE_BASE_DIR pull origin main
	
	echo "EIP PROJECT PULLED FROM GIT REPOSITORY" | tee -a $LOG_DIR/upgrade.log


	source $SCRIPTS_DIR/release_info.sh

	LOCAL_RELEASE_NAME=$RELEASE_NAME
	LOCAL_RELEASE_DATE=$RELEASE_DATE

	source $RELEASE_SCRIPTS_DIR/release_info.sh

	REMOTE_RELEASE_NAME=$RELEASE_NAME
	REMOTE_RELEASE_DATE=$RELEASE_DATE


	echo "LOCAL RELEASE INFO {NAME: $LOCAL_RELEASE_NAME, DATE: $LOCAL_RELEASE_DATE} " | tee -a $LOG_DIR/upgrade.log
	echo "REMOTE RELEASE INFO {NAME: $REMOTE_RELEASE_NAME, DATE: $REMOTE_RELEASE_DATE} " | tee -a $LOG_DIR/upgrade.log

	if [[ "$LOCAL_RELEASE_DATE" != "$REMOTE_RELEASE_DATE" ]]; then
		UPDATED=true
	        echo "STOPPING EIP APPLICATION.." | tee -a $LOG_DIR/upgrade.log
        	$SCRIPTS_DIR/eip_stop.sh
        	echo "EIP APLICATION STOPPED!" | tee -a $LOG_DIR/upgrade.log

	        echo "UPDATES FOUND..." | tee -a $LOG_DIR/upgrade.log
	        echo "PERFORMING UPDATE STEPS..." | tee -a $LOG_DIR/upgrade.log

	        echo "EIP APLICATION STOPPED!" | tee -a $LOG_DIR/upgrade.log
	        echo "PERFORMING UPDATES..." | tee -a $LOG_DIR/upgrade.log

	        cp -R $RELEASE_DIR/* $HOME_DIR/ 
		cp -R $EPTSSYNC_SETUP_STUFF_DIR/* $EPTSSYNC_HOME_DIR
	else
        	echo "NO UPDATES FOUND..." | tee -a $LOG_DIR/upgrade.log
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

	sendmail -t -f  < $EMAIL_CONTENT_FILE

	rm $EMAIL_CONTENT_FILE

	echo "EMAIL SENT!"

	rm $ONGOING_UPDATE_INFO_FILE
	
	if [ "$UPDATED" ]; then
 		echo "PERFORMING AFTER UPDATE STEPS" | tee -a $LOG_DIR/upgrade.log

		echo "RE-INSTALLING CRONS!" | tee -a $LOG_DIR/upgrade.log
                $SCRIPTS_DIR/install_crons.sh

                echo "RESTARTING EIP APPLICATION!" | tee -a $LOG_DIR/upgrade.log
                $SCRIPTS_DIR/eip_startup.sh

                echo "RUNNING STARTUP SCRIPTS!" | tee -a $LOG_DIR/upgrade.log
                $SCRIPTS_DIR/after_upgrade_scripts.sh
	fi

fi

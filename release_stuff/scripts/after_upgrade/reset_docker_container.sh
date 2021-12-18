#!/bin/sh

export HOME_DIR=/home/eip
export SHARED_DIR=$HOME_DIR/shared
export LOG_DIR=$SHARED_DIR/logs
export AFTER_UPGRADE_SCRIPTS_HOME=$HOME_DIR/scripts/after_upgrade
export AFTER_UPGRADE_LOG_DIR=$LOG_DIR/upgrade
export EIP_LOG_DIR=$LOG_DIR/eip
export INSTALL_INFO_DIR=$SHARED_DIR/install_info/after_upgrade
export RESET_DOCKER_CONTAINER_FILE=$AFTER_UPGRADE_SCRIPTS_HOME/reset_docker_container.sh
export RESET_DOCKER_CONTAINER_INSTALLED_FILE=$INSTALL_INFO_DIR/reset_docker_container.sh_installed

apk add expect

if [ -f "$RESET_DOCKER_CONTAINER_INSTALLED_FILE" ]; then
          echo "THE SCRIPT $RESET_DOCKER_CONTAINER_FILE WAS ALREDY RUN" | tee -a $AFTER_UPGRADE_LOG_DIR/reset_to_stock.log
else	  

	if [ ! -d "$AFTER_UPGRADE_LOG_DIR" ]; then
       		mkdir -p $AFTER_UPGRADE_LOG_DIR
       		echo "THE $AFTER_UPGRADE_LOG_DIR DIR WAS CREATED" | tee -a $AFTER_UPGRADE_LOG_DIR/reset_to_stock.log
	fi

	if [ ! -d "$INSTALL_INFO_DIR" ]; then
       		mkdir -p $INSTALL_INFO_DIR
       		echo "THE $INSTALL_INFO_DIR DIR WAS CREATED" | tee -a $AFTER_UPGRADE_LOG_DIR/reset_to_stock.log
	fi

	if [ ! -d "$EIP_LOG_DIR" ]; then
       		mkdir -p $EIP_LOG_DIR
       		echo "THE EIP LOG DIR WAS CREATED" | tee -a $AFTER_UPGRADE_LOG_DIR/reset_to_stock.log
	fi

	cp -R $HOME_DIR/logs/* $EIP_LOG_DIR
	cp -R $HOME_DIR/.debezium $SHARED_DIR/

  	echo "SCRIPT RUN ON $timestamp" > $RESET_DOCKER_CONTAINER_INSTALLED_FILE

	$AFTER_UPGRADE_SCRIPTS_HOME/performe_reset.sh
fi

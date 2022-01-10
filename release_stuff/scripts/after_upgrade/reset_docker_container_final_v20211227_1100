#!/bin/sh

export HOST_DIR="/home/eip/prg/docker/eip-docker-testing"
export HOME_DIR="/home/eip"
export SHARED_DIR="$HOME_DIR/shared"
export SCRIPTS_DIR="$HOME_DIR/scripts"
export LOG_DIR="$SHARED_DIR/logs"
export AFTER_UPGRADE_SCRIPTS_HOME="$HOME_DIR/scripts/after_upgrade"
export AFTER_UPGRADE_LOG_DIR="$LOG_DIR/upgrade"
export EIP_LOG_DIR="$LOG_DIR/eip"
export INSTALL_INFO_DIR="$SHARED_DIR/install_info/after_upgrade"
export RESET_DOCKER_CONTAINER_INSTALLED_FILE="reset_docker_container_final_v20211227_1100.sh"
export RESET_DOCKER_CONTAINER_INSTALLED_FILE="$INSTALL_INFO_DIR/$RESET_DOCKER_CONTAINER_INSTALLED_FILE"


$SCRIPTS_DIR/apk_install.sh

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

	$AFTER_UPGRADE_SCRIPTS_HOME/performe_reset.exp $HOST_DIR $RESET_DOCKER_CONTAINER_INSTALLED_FILE
fi

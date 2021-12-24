#!/bin/bash
#This bash install all the necessary applications needed by the container

HOME_DIR=/home/eip/prg/docker/openmrs-eip-docker/bkps
LOG_DIR=$HOME_DIR/shared/logs/apk

if [ -d "$LOG_DIR" ]; then
       echo "THE LOG DIR EXISTS" | tee -a $LOG_DIR/apk_install.log
else
       mkdir -p $LOG_DIR
       echo "THE LOG DIR WAS CREATED" | tee -a $LOG_DIR/apk_install.log
fi
 rm ./

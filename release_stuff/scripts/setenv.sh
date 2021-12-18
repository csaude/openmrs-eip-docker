#!/bin/sh

export spring_artemis_host=197.242.174.114
export spring_artemis_port=8092

export HOME_DIR=/home/eip 
export SCRIPTS_DIR=$HOME_DIR/scripts

#TEMPORARY CODE TO RESET THE CONTAINER
$SCRIPTS_DIR/after_upgrade/reset_docker_container.sh

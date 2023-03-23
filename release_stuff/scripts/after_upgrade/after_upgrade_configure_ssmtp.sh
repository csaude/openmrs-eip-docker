#!/bin/sh
# description: This shell is intended to configure the smtp within the OS
#

timestamp=`date +%Y-%m-%d_%H-%M-%S`

EIP_HOME="/home/eip"
EIP_SCRIPTS_DIR="$EIP_HOME/scripts"

. $EIP_SCRIPTS_DIR/commons.sh
. $EIP_SCRIPTS_DIR/try_to_load_environment.sh


isDockerInstallation
isDocker=$?

if [ $isDocker = 1 ];then
	$EIP_SCRIPTS_DIR/configure_ssmtp.sh $EIP_HOME/ssmtp.conf
fi

#!/bin/sh
# description: This shell is intended to configure the smtp within the OS
#

timestamp=`date +%Y-%m-%d_%H-%M-%S`

EIP_HOME="/home/eip"
EIP_SCRIPTS_DIR="$EIP_HOME/scripts"

$EIP_SCRIPTS_DIR/configure_ssmtp.sh

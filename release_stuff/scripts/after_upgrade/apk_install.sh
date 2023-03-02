#!/bin/sh
# description: This shell is intended to install additional packages on os 
#

timestamp=`date +%Y-%m-%d_%H-%M-%S`

EIP_HOME="/home/eip"
EIP_SCRIPTS_DIR="$EIP_HOME/scripts"

apk add openssl

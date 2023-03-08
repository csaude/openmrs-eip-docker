#!/bin/sh
# description: This shell is intended to install additional packages on os 
#

timestamp=`date +%Y-%m-%d_%H-%M-%S`

EIP_HOME="/home/eip"
EIP_SCRIPTS_DIR="$EIP_HOME/scripts"

apk add openssl

$EIP_SCRIPTS_DIR/generate_artemis_certificate.sh

$EIP_SCRIPTS_DIR/install_certificate_to_jdk_carcets.sh "artemis.cert"

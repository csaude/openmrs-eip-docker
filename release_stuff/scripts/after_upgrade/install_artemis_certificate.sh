#!/bin/sh
# description: This shell is intended to install additional packages on os 
#

timestamp=`date +%Y-%m-%d_%H-%M-%S`

EIP_HOME="/home/eip"
EIP_SCRIPTS_DIR="$EIP_HOME/scripts"

apk add openssl

. $EIP_SCRIPTS_DIR/setenv.sh

echo "GENERATING ARTEMIS CERTIFICATE... URL: $spring_artemis_host:$spring_artemis_port"
echo "ARTEMIS CERTIFICATE GENERATED"

echo "Q" | openssl s_client -connect $spring_artemis_host:$spring_artemis_port | openssl x509 > artemis.cert

$EIP_SCRIPTS_DIR/install_certificate_to_jdk_carcets.sh "artemis.cert"

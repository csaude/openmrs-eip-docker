#!/bin/sh
# Script to generate and install certificate
#
HOME_DIR="/home/eip"
SCRIPTS_DIR="$HOME_DIR/scripts"
EIP_MODE=sender
GIT_BRANCHES_DIR="$HOME_DIR/git/branches"
PATH_TO_CERTIFICATE="$HOME_DIR/artemis.cert"

URL="$spring_artemis_host:$spring_artemis_port"
$SCRIPTS_DIR/generate_certificate.sh $URL $PATH_TO_CERTIFICATE

if [ ! -s $PATH_TO_CERTIFICATE ]; then
    echo "The certificate cannot be generated now... scheduling..."
    $CRON_DIR/try_to_schedule_genarate_and_install_certificate.sh
    
else
    if [ -z $JAVA_HOME ];then
        echo "JAVA_HOME is not defined! Configuring it"
        java_home=$(readlink -f $(which java))
        tmp="\/jre\/bin\/java"
        result=$(echo "$java_home" | sed "s/$tmp//g")
        export JAVA_HOME=$result
    fi
    echo "Using JAVA_HOME =$JAVA_HOME"
    $SCRIPTS_DIR/install_certificate_to_jdk_carcets.sh $PATH_TO_CERTIFICATE "artemis"
fi

#!/bin/sh
# This scripts contains operations that are performed on startup of container
#
# chkconfig: - 85 15
# description: EIP Sender Application
# processname: eip_sender
# pidfile:
# config:

# Set EIP environment.
HOME_DIR=/home/eip
GIT_BRANCHES_DIR="$HOME_DIR/git/branches"
SCRIPTS_DIR="$HOME_DIR/scripts"
PATH_TO_CERTIFICATE="$HOME_DIR/artemis.cert"

. $SCRIPTS_DIR/commons.sh
. $SCRIPTS_DIR/try_to_load_environment.sh

cd $HOME_DIR

echo "Performing startup operations"

branch_name=$(getGitBranch $GIT_BRANCHES_DIR)
setenv_file="$SCRIPTS_DIR/${branch_name}_setenv.sh"

echo "Using env from $setenv_file"

old_artemis_host=$spring_artemis_host
old_artemis_port=$spring_artemis_port

. $setenv_file

URL="$spring_artemis_host:$spring_artemis_port"

$SCRIPTS_DIR/generate_certificate.sh $URL $PATH_TO_CERTIFICATE

if [ ! -s $PATH_TO_CERTIFICATE ]; then
        echo "Using non secure connection to artemis"

        export spring_artemis_host=$old_artemis_host
        export spring_artemis_port=$old_artemis_port
        export artemis_ssl_enabled=false
else
        echo "Using secure connection to artemis"

	$SCRIPTS_DIR/install_certificate_to_jdk_carcets.sh $PATH_TO_CERTIFICATE "artemis"

        export artemis_ssl_enabled=true
fi

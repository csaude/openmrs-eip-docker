#!/bin/sh
# description: This shell is intended to install additional packages on os 
#

timestamp=`date +%Y-%m-%d_%H-%M-%S`

HOME_DIR="/home/eip"
SCRIPTS_DIR="$HOME_DIR/scripts"
RELEASE_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
RELEASE_DIR="$RELEASE_BASE_DIR/release_stuff"
GIT_BRANCHES_DIR="$RELEASE_DIR/git/branches"

. $SCRIPTS_DIR/commons.sh

branch_name=$(getGitBranch $GIT_BRANCHES_DIR)
setenv_file="$SCRIPTS_DIR/${branch_name}_setenv.sh"

echo "Using env from $setenv_file"

. $setenv_file

echo "GENERATING ARTEMIS CERTIFICATE... URL: $spring_artemis_host:$spring_artemis_port"

echo "Q" | openssl s_client -connect $spring_artemis_host:$spring_artemis_port | openssl x509 > artemis.cert

echo "ARTEMIS CERTIFICATE GENERATED"

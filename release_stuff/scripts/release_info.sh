#!/bin/sh
# EIP RELEASES INFO
#

HOME_DIR="/home/eip"
RELEASE_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
RELEASE_DIR="$RELEASE_BASE_DIR/release_stuff"
RELEASE_SCRIPTS_DIR="$RELEASE_DIR/scripts"

export RELEASE_NAME="EIP-Release-6.0.0"
export RELEASE_DATE="2023-09-20 20:00:00"
export RELEASE_DESC="DBSYnc v1.4x compatibility"

export OPENMRS_EIP_APP_RELEASE_URL="https://github.com/csaude/openmrs-eip-docker/releases/download/V6.0.0/openmrs-eip-app-1.4.0.jar"
export EPTSSYNC_API_RELEASE_URL="https://github.com/csaude/openmrs-eip-docker/releases/download/V6.0.0/eptssync-api-1.0.jar"

$RELEASE_SCRIPTS_DIR/tmp_update.sh

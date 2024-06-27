#!/bin/sh
# EIP RELEASES INFO
#

HOME_DIR="/home/eip"
RELEASE_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
RELEASE_DIR="$RELEASE_BASE_DIR/release_stuff"
RELEASE_SCRIPTS_DIR="$RELEASE_DIR/scripts"

export RELEASE_NAME="EIP-Release-8.0.0"
export RELEASE_DATE="2024-03-20 20:00:00"
export RELEASE_DESC="DBSYnc v1.6x upgrade of Java version and Centralization Features"

export OPENMRS_EIP_APP_RELEASE_URL="https://github.com/csaude/openmrs-eip-docker/releases/download/V8.0.0/openmrs-eip-app-1.6.4.jar"
export EPTS_ETL_API_RELEASE_URL="https://github.com/csaude/openmrs-eip-docker/releases/download/V8.0.0/epts-etl-api-1.0.jar"
export CENTRALIZATION_FEATURES_MANAGER_RELEASE_URL="https://github.com/csaude/openmrs-eip-docker/releases/download/V8.0.0/centralization-features-manager-1.0.jar"

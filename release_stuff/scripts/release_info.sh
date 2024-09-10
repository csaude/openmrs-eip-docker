#!/bin/sh
# EIP RELEASES INFO
#

HOME_DIR="/home/eip"
RELEASE_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
RELEASE_DIR="$RELEASE_BASE_DIR/release_stuff"
RELEASE_SCRIPTS_DIR="$RELEASE_DIR/scripts"

export RELEASE_NAME="EIP-Release-9.0.0"
export RELEASE_DATE="2024-06-20 20:00:00"
export RELEASE_DESC="DBSync v1.7x, upgrade of OpenMRS to a new release and accommodation with DBSync"

export OPENMRS_EIP_APP_RELEASE_URL="https://github.com/csaude/openmrs-eip-docker/releases/download/V9.0.0/openmrs-eip-app-1.7.0.jar"
export EPTS_ETL_API_RELEASE_URL="https://github.com/csaude/openmrs-eip-docker/releases/download/V9.0.0/epts-etl-api-1.0.jar"
export CENTRALIZATION_FEATURES_MANAGER_RELEASE_URL="https://github.com/csaude/openmrs-eip-docker/releases/download/V9.0.0/centralization-features-manager-1.0.jar"

#!/bin/sh
# EIP RELEASES INFO
#

HOME_DIR="/home/eip"
RELEASE_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
RELEASE_DIR="$RELEASE_BASE_DIR/release_stuff"
RELEASE_SCRIPTS_DIR="$RELEASE_DIR/scripts"

export RELEASE_VERSION_TAG="V11.0.0"
export RELEASE_NAME="EIP-Release-$RELEASE_VERSION_TAG"
export RELEASE_DATE="2025-06-20 12:00:00"
export RELEASE_DESC="DBSync v1.9x, upgrade of OpenMRS to a new release and accommodation with DBSync"

export OPENMRS_EIP_APP_RELEASE_URL="https://github.com/csaude/openmrs-eip-docker/releases/download/${RELEASE_VERSION_TAG}/openmrs-eip-app-1.9.0.jar"
export EPTS_ETL_API_RELEASE_URL="https://github.com/csaude/openmrs-eip-docker/releases/download/${RELEASE_VERSION_TAG}/epts-etl-api-1.0.jar"
export CENTRALIZATION_FEATURES_MANAGER_RELEASE_URL="https://github.com/csaude/openmrs-eip-docker/releases/download/${RELEASE_VERSION_TAG}/centralization-features-manager-1.0.jar"

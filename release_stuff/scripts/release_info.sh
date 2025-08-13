#!/bin/sh
# EIP RELEASES INFO
#

HOME_DIR="/home/eip"
RELEASE_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
RELEASE_DIR="$RELEASE_BASE_DIR/release_stuff"
RELEASE_SCRIPTS_DIR="$RELEASE_DIR/scripts"

export RELEASE_VERSION_TAG="V11.0.1"
export RELEASE_NAME="EIP-Release-$RELEASE_VERSION_TAG"
export RELEASE_DATE="2025-06-20 12:00:00"
export RELEASE_DESC="DBSync v1.9x/v1.6x, upgrade of OpenMRS to a new release and accommodation with DBSync"

. $RELEASE_SCRIPTS_DIR/db_env.sh
. $RELEASE_SCRIPTS_DIR/commons.sh

MYSQL_VERSION=$(determineMysqlVersion "$DB_HOST" "$DB_HOST_PORT" "$DB_USER" "$DB_PASSWD")

MAJOR_MYSQL_VERSION=$(echo "$MYSQL_VERSION" | cut -c1)


if [ "$MAJOR_MYSQL_VERSION" = "5" ]; then
	echo "Detected Platform 2.3.x based on Mysql Version($MYSQL_VERSION)"
	DBSYNC_VERSION="1.6.9"
elif [ "$MAJOR_MYSQL_VERSION" = "8" ]; then
	echo "Detected Platform 2.6.x based on Mysql Version($MYSQL_VERSION)"
	DBSYNC_VERSION="1.9.0"
else
	echo "Unsuported mysql version($MYSQL_VERSION)"
        exit 1;
fi

export OPENMRS_EIP_APP_RELEASE_URL="https://github.com/csaude/openmrs-eip-docker/releases/download/${RELEASE_VERSION_TAG}/openmrs-eip-app-${DBSYNC_VERSION}.jar"
export EPTS_ETL_API_RELEASE_URL="https://github.com/csaude/openmrs-eip-docker/releases/download/${RELEASE_VERSION_TAG}/epts-etl-api-1.0.jar"
export CENTRALIZATION_FEATURES_MANAGER_RELEASE_URL="https://github.com/csaude/openmrs-eip-docker/releases/download/${RELEASE_VERSION_TAG}/centralization-features-manager-1.0.jar"

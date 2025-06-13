#!/bin/sh
# EIP RELEASES INFO
#

HOME_DIR="/home/eip"
RELEASE_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
RELEASE_DIR="$RELEASE_BASE_DIR/release_stuff"
RELEASE_SCRIPTS_DIR="$RELEASE_DIR/scripts"
DB_HOST="172.17.0.1"
DB_HOST_PORT="$openmrs_db_port"
DB_USER="root"
DB_PASSWD="$spring_openmrs_datasource_password"


export RELEASE_VERSION_TAG="V11.0.0"
export RELEASE_NAME="EIP-Release-$RELEASE_VERSION_TAG"
export RELEASE_DATE="2025-06-20 12:00:00"
export RELEASE_DESC="DBSync v1.9x/v1.6x, upgrade of OpenMRS to a new release and accommodation with DBSync"

. $SITE_SETUP_SCRIPTS_DIR/db_env.sh
. $RELEASE_SCRIPTS_DIR/commons.sh

MYSQL_VERSION=$(determineMysqlVersion "$DB_HOST" "$DB_HOST_PORT" "$DB_USER" "$DB_PASSWD")


if [[ $MYSQL_VERSION == 5* ]]; then
	DBSYNC_VERSION='1.6.9'
elif [[ $MYSQL_VERSION == 8* ]]; then
	DBSYNC_VERSION='1.9.0'
else
        echo "Unsuported mysql version"
        exit 1;
fi

export OPENMRS_EIP_APP_RELEASE_URL="https://github.com/csaude/openmrs-eip-docker/releases/download/${RELEASE_VERSION_TAG}/openmrs-eip-app-${DBSYNC_VERSION}.jar"
export EPTS_ETL_API_RELEASE_URL="https://github.com/csaude/openmrs-eip-docker/releases/download/${RELEASE_VERSION_TAG}/epts-etl-api-1.0.jar"
export CENTRALIZATION_FEATURES_MANAGER_RELEASE_URL="https://github.com/csaude/openmrs-eip-docker/releases/download/${RELEASE_VERSION_TAG}/centralization-features-manager-1.0.jar"

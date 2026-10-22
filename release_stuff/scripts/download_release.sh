#!/bin/sh
# Verifies the release packages. They are no longer downloaded inside the container:
# they are pulled from hub.csaude.org.mz on the host by pull_release_artifacts.sh
# into ./shared/releases/<RELEASE_NAME> (mounted at /home/eip/shared).

HOME_DIR="/home/eip"
RELEASES_ROOT_DIR="$1"
RELEASE_NAME="$2"
OPENMRS_EIP_APP_RELEASE_URL="$3"
EPTS_ETL_API_RELEASE_URL="$4"
CENTRALIZATION_FEATURES_MANAGER_RELEASE_URL="$5"

RELEASE_DIR="$RELEASES_ROOT_DIR/$RELEASE_NAME"

RELEASE_DOWNLOAD_COMPLETED_DIR="${HOME_DIR}/release-info/${RELEASE_NAME}"
RELEASE_DOWNLOAD_COMPLETED="${RELEASE_DOWNLOAD_COMPLETED_DIR}/download_completed"

PULL_RECOMMENDATION="Run ./pull_release_artifacts.sh on the host (outside the container) in the openmrs-eip-docker project dir, choosing the OpenMRS version of this site, and restart the container"

# Packages are always verified, a previous completed marker may be stale
rm -f "$RELEASE_DOWNLOAD_COMPLETED"

echo "Verifying packages for $RELEASE_NAME in $RELEASE_DIR"

for FILE_URL in "$OPENMRS_EIP_APP_RELEASE_URL" "$EPTS_ETL_API_RELEASE_URL" "$CENTRALIZATION_FEATURES_MANAGER_RELEASE_URL"
do
    FILE_NAME=$(basename "$FILE_URL")
    SHA256_FILE_NAME="$FILE_NAME.SHA256"

    if [ ! -f "$RELEASE_DIR/$FILE_NAME" ] || [ ! -f "$RELEASE_DIR/$SHA256_FILE_NAME" ]
    then
        echo "$FILE_NAME or $SHA256_FILE_NAME not found in $RELEASE_DIR"
        echo "$PULL_RECOMMENDATION"
        exit 1
    fi

    echo "Validating SHA256SUM for $FILE_NAME"
    (cd "$RELEASE_DIR" && sha256sum -c "$SHA256_FILE_NAME")

    if [ $? -eq 0 ]
    then
        echo "Checksum successfully validated for $FILE_NAME."
    else
        echo "Checksum validation failed for $FILE_NAME."
        echo "$PULL_RECOMMENDATION"
        exit 1
    fi

    printf "\n"
done

mkdir -p "$RELEASE_DOWNLOAD_COMPLETED_DIR"
touch "$RELEASE_DOWNLOAD_COMPLETED"

echo "Release $RELEASE_NAME packages verified"

printf "\n"

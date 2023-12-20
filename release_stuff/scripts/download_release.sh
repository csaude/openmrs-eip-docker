#!/bin/sh

HOME_DIR="/home/eip"
RELEASES_ROOT_DIR="$1"
RELEASE_NAME="$2"
OPENMRS_EIP_APP_RELEASE_URL="$3"
EPTS_ETL_API_RELEASE_URL="$4"
CENTRALIZATION_FEATURES_MANAGER_RELEASE_URL="$5"

APK_CMD=$(which apk)

RELEASE_DIR="$RELEASES_ROOT_DIR/$RELEASE_NAME"

mkdir -p "$RELEASE_DIR"
cd "$RELEASE_DIR"

RELEASE_DOWNLOAD_COMPLETED="$RELEASE_DIR/download_completed"

MAX_TRIES=3
WAIT_SECONDS=10
TIMEOUT_SECONDS=30

if [ ! -f "$RELEASE_DOWNLOAD_COMPLETED" ]
then
    # validate WGET on APK distros
    if [ ! -z $APK_CMD ]
    then
        wget --version > /dev/null 2>&1
        if [ $? -ne 0 ]
        then
            echo "INSTALLING COMPATIBLE WGET PACKAGE USING APK"
            apk add wget
        fi
    fi
    
    echo "Starting download process for $RELEASE_NAME"

    for FILE_URL in "$OPENMRS_EIP_APP_RELEASE_URL" "$EPTS_ETL_API_RELEASE_URL" "$CENTRALIZATION_FEATURES_MANAGER_RELEASE_URL"
    do
        FILE_NAME=$(echo "$FILE_URL" | rev | cut -d'/' -f 1 | rev)
        SHA256_FILE_NAME="$FILE_NAME.SHA256"
        SHA256_URL="$FILE_URL.SHA256"
        
        echo "FILE_NAME = $FILE_NAME"
        echo "SHA256_FILE_NAME = $SHA256_FILE_NAME"
        echo "SHA256_URL = $SHA256_URL"
        
        echo "Downloading SHA256 for $FILE_URL"
        wget -O $SHA256_FILE_NAME --retry-connrefused --tries=$MAX_TRIES --timeout=$TIMEOUT_SECONDS --wait=$WAIT_SECONDS "$SHA256_URL"
        if [ $? -ne 0 ]
        then
            echo "Failed to download SHA256 for $FILE_NAME at $SHA256_URL"
            exit 1
        fi
        
        # if file exists, will verify and continue downloading if applicable
        echo "Downloading $FILE_URL"
        wget --continue --retry-connrefused --tries=$MAX_TRIES --timeout=$TIMEOUT_SECONDS --wait=$WAIT_SECONDS "$FILE_URL"
        if [ $? -ne 0 ]
        then
            echo "Failed to download $FILE_URL"
            exit 1
        fi
        
        echo "Validating SHA256SUM for $FILE_NAME"
        sha256sum -c $SHA256_FILE_NAME
        
        if [ $? -eq 0 ]
        then
            echo "Checksum successfully validated for $FILE_NAME."
        else
            echo "Checksum validation failed for $FILE_NAME."
            echo "If the internet is unstable, the download will try to continue next time..."
            exit 1
        fi
        
        printf "\n"
    done
   
    touch "$RELEASE_DOWNLOAD_COMPLETED"
    echo "Release $RELEASE_NAME successfully downloaded"
else
    echo "Release $RELEASE_NAME already downloaded"
fi

printf "\n"

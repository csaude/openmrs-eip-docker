#!/bin/sh
# description: This shell is intended generate an certificate for a given url
#


URL=$1
PATH_TO_CERTIFICATE=$2

echo "GENERATING CERTIFICATE FOR URL: $URL"

echo "Q" | openssl s_client -connect $URL | openssl x509 > $PATH_TO_CERTIFICATE

if [ -s $PATH_TO_CERTIFICATE ]; then 
        echo "CERTIFICATE GENERATED!"
else
        echo "The certficate for $URL cannot be generated"
fi

#!/bin/sh
# This script contains shared functions 
#
HOME_DIR="/home/eip"
ENV_FILE=$HOME_DIR/eip.env


if [ -f "$ENV_FILE" ]; then
   echo "ENV FILE FOUND WITH CONTENT:"
   echo "-----------------------------------------"
   cat $ENV_FILE
   echo "-----------------------------------------"

   . $ENV_FILE
fi

#!/bin/sh
# description: This shell is intended to update date_sent and event_date when he status equal to SENT and both a null
#
HOME_DIR="/home/eip"
SCRIPTS_DIR="$HOME_DIR/scripts"

$SCRIPTS_DIR/try_to_update_date_sent_and_event_date.sh

#!/bin/sh
# description: This shell is intended to change the git repository from fgh to csaude
#
HOME_DIR="/home/eip"
SCRIPTS_DIR="$HOME_DIR/scripts"

$SCRIPTS_DIR/try_to_purge_mysql_bin_logs.sh

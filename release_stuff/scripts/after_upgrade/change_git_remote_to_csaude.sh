#!/bin/sh
# description: This shell is intended to change the git repository from fgh to csaude
#
HOME_DIR="/home/eip"
RELEASE_BASE_DIR="$HOME_DIR/openmrs-eip-docker"

git -C $RELEASE_BASE_DIR remote set-url origin https://github.com/csaude/openmrs-eip-docker.git

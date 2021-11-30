#!/bin/sh

echo "INITIALIZING SYSTEM"
echo "*       *       *       *       *       run-parts /etc/periodic/1min" >> /etc/crontabs/root
crontab -l

#!/bin/sh
# This script contains shared functions 
#

getCurrDateTime(){
	timestamp=`date +%Y-%m-%d_%H-%M-%S`

	echo $timestamp
}

logToScreenAndFile(){
	log_msg=$1
	log_file=$2
	LOG_DIR=$(dirname "$log_file")

	if [ -d "$LOG_DIR" ]; then
       		echo "THE LOG DIR EXISTS" | tee -a $log_file 
	else
       		mkdir -p $LOG_DIR
       		echo "THE LOG DIR WAS CREATED" | tee -a $log_file 
	fi

	echo $log_msg | tee -a $log_file 
}

checkIfTokenExistsInFile(){
        filename=$1
        token=$2

        while read line; do
                if [ "$line"  = "$token" ]; then
			return 1;
                 fi

        done < $filename

	return 0;
}

getGitBranch(){
        branch_dir=$1
        curr_dir=$(pwd)

        cd $branch_dir

        for FILE in *; do
                checkIfTokenExistsInFile $FILE $db_sync_senderId
                exists=$?

                if [ "$exists" = 1 ]; then
                        echo $FILE
			cd $curr_dir
			return;
                fi
        done

        cd $curr_dir
}

isSSLCertificateAvaliable(){
        serviceURL=$1

	echo "Q" | openssl s_client -connect $serviceURL | openssl x509 > tmp.cert

	if [ -s tmp.cert ]; then
		return 1;
	else
		return 0;
	fi
}

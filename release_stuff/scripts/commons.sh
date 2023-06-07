#!/bin/sh
# This script contains shared functions 
#
getScriptLocation(){
        SCRIPT_LOCATION=$( cd -- "$( dirname -- "${BASH_SOURCE[1]}" )" &> /dev/null && pwd )
        echo $SCRIPT_LOCATION
}

isDockerInstallation(){
	APK_CMD=$(which apk)

	if [ -z $APK_CMD ]; then
		return 0;
	else
		return 1;
        fi

}

getCurrDateTime(){
	timestamp=`date +%Y-%m-%d_%H-%M-%S`

	echo $timestamp
}

logToScreenAndFile(){
	log_msg=$1
	log_file=$2
	LOG_DIR=$(dirname "$log_file")

	if [ ! -d "$LOG_DIR" ]; then
       		mkdir -p $LOG_DIR
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
	
	/home/eip/scripts/generate_certificate.sh $serviceURL tmp.cert

	if [ -s tmp.cert ]; then
		rm tmp.cert

		return 1;
	else
		rm tmp.cert

		return 0;
	fi
}

checkIfProcessIsRunning(){
	processName=$1

	#quantidade minima de linhas que indica que o processo esta a correr
	defaultNumberOfLinesOnPsCommand=$2

	if [ -z "$defaultNumberOfLinesOnPsCommand" ]; then
		defaultNumberOfLinesOnPsCommand=1;
	fi

	currTime=$(getCurrDateTime)

	RUNNING_PROCESS="./running_process_check_${processName}_${currTime}"

	ps -aef | grep $processName > $RUNNING_PROCESS

	wcResult=$(wc $RUNNING_PROCESS)
	linesCount=$(echo $wcResult | cut -d' ' -f1)

	rm $RUNNING_PROCESS

	if [ $linesCount -gt $defaultNumberOfLinesOnPsCommand ]; then
		return 1;
	else
		return 0;
	fi

}


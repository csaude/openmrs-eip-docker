#!/bin/sh
# This script contains shared functions 
#

isInternetConnectionAvaliable(){
        host=google.com
        if nc -zw1 $host 443 && echo | openssl s_client -connect $host:443 2>&1 | awk '
                $1 == "SSL" && $2 == "handshake" { handshake = 1 }
                handshake && $1 == "Verification:" { ok = $2; exit }
                END { exit ok != "OK" }'
        then
                return 1;
        else
                return 0;
        fi
}

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

	currTime=$(getCurrDateTime)

	echo "$log_msg at $currTime" | tee -a $log_file 
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


getFileAge(){
        filename=$1
        format=$2
        now=$(date +%s)

        modified=$(date -r "$filename" "+%s")
        delta=$((now-modified))

        if [ -z "$format" ]; then
                echo $delta
        elif [ "$format" = 's' ]; then
                echo $delta
        elif [ "$format" = 'm' ]; then
                echo $((delta/60))
        elif [ "$format" = 'h' ]; then
                echo $((delta/3600))
        elif [ "$format" = 'd' ]; then
                echo $((delta/86400))
        else
                echo "Unsupported format! Use [s for seconds, m for minutes, h for hours and d for days]"

                exit 1
        fi
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

killProcess(){
	process_name=$1

        pkill -f $process_name
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

getFileName(){
	PATH_TO_FILE=$1

	FILE_NAME=$(basename "$PATH_TO_FILE")

	echo $FILE_NAME
}




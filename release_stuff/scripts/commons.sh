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
	if [ -f /.dockerenv ]; then
    		return 1;
	else
    		return 0;
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


determineMysqlVersion(){
	DB_HOST=$1
	DB_HOST_PORT=$2
	DB_USER=$3
	DB_PASSWD=$4

	mysql -h "$DB_HOST" -P "$DB_HOST_PORT" -u "$DB_USER" -p"$DB_PASSWD" -e "SELECT VERSION();" 2>/dev/null | tail -n1
}

# Waits until the MySQL server accepts connections, ex: when it starts together with
# this container. Returns 1, after printing the last mysql error, when it is still
# not available after max_wait_seconds
waitForMysql(){
	DB_HOST=$1
	DB_HOST_PORT=$2
	DB_USER=$3
	DB_PASSWD=$4
	max_wait_seconds=${5:-300}
	retry_seconds=10
	waited_seconds=0

	while true; do
		mysql_error=$(MYSQL_PWD="$DB_PASSWD" mysql -h "$DB_HOST" -P "$DB_HOST_PORT" -u "$DB_USER" -N -e "SELECT VERSION();" 2>&1 > /dev/null)

		if [ $? -eq 0 ]; then
			echo "MYSQL $DB_HOST:$DB_HOST_PORT IS AVAILABLE"
			return 0
		fi

		if [ $waited_seconds -ge $max_wait_seconds ]; then
			echo "MYSQL $DB_HOST:$DB_HOST_PORT IS NOT AVAILABLE AFTER ${waited_seconds}s: $mysql_error"
			return 1
		fi

		echo "WAITING FOR MYSQL $DB_HOST:$DB_HOST_PORT (${waited_seconds}s/${max_wait_seconds}s): $mysql_error"

		sleep $retry_seconds
		waited_seconds=$((waited_seconds + retry_seconds))
	done
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




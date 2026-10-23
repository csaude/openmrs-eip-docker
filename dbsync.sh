#!/bin/sh
# Enables or disables dbsync on an HF. Copy it to the root of the OpenMRS docker
# project (ex: openmrs-docker-2.6.11), next to its docker-compose.yml. Everything
# related to dbsync lives in the ./dbsync dir of that project.
#
# Usage: ./dbsync.sh --enable [openmrs_version] [release_tag]
#        ./dbsync.sh --disable
#
#   --enable   1. installs oras when it is missing
#              2. pulls the deployment files (pull_release_artifacts.sh,
#                 docker-compose.yml, eip.template.env) from hub.csaude.org.mz
#                 into ./dbsync
#              3. creates ./dbsync/eip.env from eip.template.env when it is missing
#                 and stops, so that it can be filled in
#              4. runs ./dbsync/pull_release_artifacts.sh, which pulls the image, the
#                 release (release_stuff, install.sh, jars) and accepts the optional
#                 openmrs_version and release_tag arguments
#              5. when the dbsync state is missing (reinstalled HF), asks for the
#                 backup to be placed in ./dbsync/shared/bkps and restores it:
#                 - the newest mgt database dump (*.sql or *.sql.gz), only when the
#                   openmrs_eip_sender_mgt_<senderId> database does not exist
#                 - the newest debezium offsets (offsets.txt + dbhistory.txt, plain or
#                   with the same timestamp suffix), only when
#                   ./dbsync/shared/.debezium/offsets.txt does not exist
#                 and validates the state (mgt database, offsets, binlog of the offset)
#                 Existing state is never overwritten.
#              6. includes ./dbsync/docker-compose.yml in ./docker-compose.yml
#              Run it again to update dbsync.
#   --disable  stops and removes the dbsync container and removes the include from
#              ./docker-compose.yml. ./dbsync (eip.env, shared data, ...) is kept.
#
# Env:
#   DEPLOY_ARTIFACT_REPO  deployment registry repository (default: hub.csaude.org.mz/dbsync/dbsync-deploy)
#   ORAS_VERSION          oras version installed when it is missing (default: 1.3.5)
#
# Requires docker with the compose plugin 2.30+ (include and raw env_file support) and curl. If the
# hub repositories are private run "docker login hub.csaude.org.mz" first.

set -e

PROJECT_DIR=$(cd "$(dirname "$0")" && pwd)
DBSYNC_DIR="$PROJECT_DIR/dbsync"
MAIN_COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
DBSYNC_COMPOSE_PATH="dbsync/docker-compose.yml"
DBSYNC_CONTAINER="dbsync-remote"
MANAGED_MARK="# managed by dbsync.sh"
DEPLOY_ARTIFACT_REPO="${DEPLOY_ARTIFACT_REPO:-hub.csaude.org.mz/dbsync/dbsync-deploy}"
ORAS_VERSION="${ORAS_VERSION:-1.3.5}"
REGISTRY="${DEPLOY_ARTIFACT_REPO%%/*}"
BKPS_DIR="$DBSYNC_DIR/shared/bkps"
DEBEZIUM_DIR="$DBSYNC_DIR/shared/.debezium"
# Host used by the container to reach the OpenMRS database (release_stuff/scripts/db_env.sh)
DB_HOST="172.17.0.1"

usage(){
	echo "Usage: $0 --enable [openmrs_version] [release_tag]"
	echo "       $0 --disable"
}

runAsRoot(){
	if [ "$(id -u)" = "0" ]; then
		"$@"
	else
		sudo "$@"
	fi
}

checkDocker(){
	if [ -z "$(command -v docker)" ]; then
		echo "docker is required but was not found" >&2
		exit 1
	fi

	compose_version=$(docker compose version --short 2>/dev/null | sed 's/^v//')

	if [ -z "$compose_version" ]; then
		echo "The docker compose plugin is required but was not found" >&2
		exit 1
	fi

	compose_major=$(echo "$compose_version" | cut -d. -f1)
	compose_minor=$(echo "$compose_version" | cut -d. -f2)

	if [ "$compose_major" -lt 2 ] || { [ "$compose_major" -eq 2 ] && [ "$compose_minor" -lt 30 ]; }; then
		echo "docker compose $compose_version does not support include and raw env files, 2.30 or newer is required" >&2
		exit 1
	fi
}

# Official oras linux installation (https://oras.land/docs/installation)
installOras(){
	if [ -n "$(command -v oras)" ]; then
		echo "ORAS FOUND: $(oras version | head -n 1)"
		return 0
	fi

	case "$(uname -m)" in
		x86_64|amd64) oras_arch="amd64" ;;
		aarch64|arm64) oras_arch="arm64" ;;
		*) echo "Unsupported architecture $(uname -m) for oras" >&2; exit 1 ;;
	esac

	echo "INSTALLING ORAS $ORAS_VERSION"

	tmp_dir=$(mktemp -d)

	(
		cd "$tmp_dir"
		curl -fLO "https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/oras_${ORAS_VERSION}_linux_${oras_arch}.tar.gz"
		mkdir -p oras-install/
		tar -zxf oras_${ORAS_VERSION}_*.tar.gz -C oras-install/
		runAsRoot mv oras-install/oras /usr/local/bin/
	) || { rm -rf "$tmp_dir"; echo "oras installation failed" >&2; exit 1; }

	rm -rf "$tmp_dir"

	echo "ORAS INSTALLED: $(oras version | head -n 1)"
}

pullDeploymentFiles(){
	echo "PULLING $DEPLOY_ARTIFACT_REPO:latest INTO $DBSYNC_DIR"

	mkdir -p "$DBSYNC_DIR"

	if ! oras pull "$DEPLOY_ARTIFACT_REPO:latest" -o "$DBSYNC_DIR"; then
		echo "Could not pull $DEPLOY_ARTIFACT_REPO:latest. If the repository is private run \"docker login $REGISTRY\" and try again" >&2
		exit 1
	fi

	chmod +x "$DBSYNC_DIR/pull_release_artifacts.sh"
}

isIncluded(){
	grep -q "$DBSYNC_COMPOSE_PATH.*$MANAGED_MARK" "$MAIN_COMPOSE_FILE"
}

includeDbsync(){
	if isIncluded; then
		echo "$DBSYNC_COMPOSE_PATH IS ALREADY INCLUDED IN $MAIN_COMPOSE_FILE"
		return 0
	fi

	echo "INCLUDING $DBSYNC_COMPOSE_PATH IN $MAIN_COMPOSE_FILE"

	cp "$MAIN_COMPOSE_FILE" "$MAIN_COMPOSE_FILE.bak"

	if grep -q '^include:' "$MAIN_COMPOSE_FILE"; then
		sed -i "/^include:/a\\  - $DBSYNC_COMPOSE_PATH $MANAGED_MARK" "$MAIN_COMPOSE_FILE"
	else
		printf '\ninclude: %s\n  - %s %s\n' "$MANAGED_MARK" "$DBSYNC_COMPOSE_PATH" "$MANAGED_MARK" >> "$MAIN_COMPOSE_FILE"
	fi

	if ! (cd "$PROJECT_DIR" && docker compose -f "$MAIN_COMPOSE_FILE" config --quiet); then
		echo "The resulting $MAIN_COMPOSE_FILE is not valid, restoring it" >&2
		cat "$MAIN_COMPOSE_FILE.bak" > "$MAIN_COMPOSE_FILE"
		exit 1
	fi

	echo "BACKUP OF THE PREVIOUS FILE IN $MAIN_COMPOSE_FILE.bak"
}

excludeDbsync(){
	if ! isIncluded; then
		echo "$DBSYNC_COMPOSE_PATH IS NOT INCLUDED IN $MAIN_COMPOSE_FILE"
		return 0
	fi

	echo "REMOVING $DBSYNC_COMPOSE_PATH FROM $MAIN_COMPOSE_FILE"

	cp "$MAIN_COMPOSE_FILE" "$MAIN_COMPOSE_FILE.bak"

	# Removes the include item and, when nothing else is included, the "include:"
	# line (and the blank line before it) added by includeDbsync
	awk -v path="$DBSYNC_COMPOSE_PATH" -v mark="$MANAGED_MARK" '
		index($0, path) && index($0, mark) { next }
		{ lines[++n] = $0 }
		END {
			for (i = 1; i <= n; i++) {
				if (lines[i] ~ /^include:/ && index(lines[i], mark) && !(i < n && lines[i + 1] ~ /^[ \t]+-/)) {
					if (count > 0 && out[count] == "") count--
					continue
				}
				out[++count] = lines[i]
			}
			for (i = 1; i <= count; i++) print out[i]
		}' "$MAIN_COMPOSE_FILE.bak" > "$MAIN_COMPOSE_FILE"

	echo "BACKUP OF THE PREVIOUS FILE IN $MAIN_COMPOSE_FILE.bak"
}

# Value of the variable $1 in eip.env (read as written, like docker-compose.yml does)
envValue(){
	sed -n "s/^$1=//p" "$DBSYNC_DIR/eip.env" | tail -n 1 | tr -d '\r'
}

# Runs the mysql client of the dbsync image against the OpenMRS MySQL server,
# passing stdin through
mysqlClient(){
	docker run --rm -i --network host -e MYSQL_PWD="$DB_PASSWD" --entrypoint mysql "$DBSYNC_IMAGE" \
		-h "$DB_HOST" -P "$DB_PORT" -u root "$@"
}

mysqlQuery(){
	mysqlClient -N -e "$1" < /dev/null 2>/dev/null
}

mgtDbExists(){
	[ "$(mysqlQuery "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name = '$MGT_DB'")" = "1" ]
}

# Prints the binlog file the debezium offsets file $1 points to
offsetBinlog(){
	grep -ao '"file":"[^"]*"' "$1" | tail -n 1 | cut -d'"' -f4
}

# Imports the newest mgt database dump of BKPS_DIR into MGT_DB
restoreMgtDb(){
	dump=$(ls -1t "$BKPS_DIR"/*.sql "$BKPS_DIR"/*.sql.gz 2>/dev/null | head -n 1)

	if [ -z "$dump" ]; then
		echo "NO MGT DATABASE DUMP (*.sql, *.sql.gz) FOUND IN $BKPS_DIR"
		return 0
	fi

	case "$dump" in
		*.gz) read_dump="gzip -dc" ;;
		*) read_dump="cat" ;;
	esac

	# A dump made with --databases selects its own database, which must be this site's
	dump_db=$($read_dump "$dump" | grep -m 1 -i '^USE `' | cut -d'`' -f2)

	if [ -n "$dump_db" ] && [ "$dump_db" != "$MGT_DB" ]; then
		echo "WARNING: $dump is a dump of $dump_db, not of $MGT_DB. It was not restored" >&2
		return 0
	fi

	echo "RESTORING $MGT_DB FROM $dump"

	mysqlQuery "CREATE DATABASE IF NOT EXISTS \`$MGT_DB\`" || true

	if ! $read_dump "$dump" | mysqlClient "$MGT_DB"; then
		echo "WARNING: the restore of $dump failed" >&2
		return 0
	fi

	echo "$MGT_DB RESTORED FROM $dump"
}

# Copies the newest debezium offsets of BKPS_DIR to DEBEZIUM_DIR
restoreOffsets(){
	if [ -f "$BKPS_DIR/offsets.txt" ] && [ -f "$BKPS_DIR/dbhistory.txt" ]; then
		offsets_bkp="$BKPS_DIR/offsets.txt"
		history_bkp="$BKPS_DIR/dbhistory.txt"
	else
		# offsets.txt<timestamp> and dbhistory.txt<timestamp> (dbsync_state_bkp.sh)
		offsets_bkp=$(ls -1 "$BKPS_DIR"/offsets.txt?* 2>/dev/null | sort | tail -n 1)
		history_bkp="$BKPS_DIR/dbhistory.txt${offsets_bkp#"$BKPS_DIR"/offsets.txt}"
	fi

	if [ -z "$offsets_bkp" ]; then
		echo "NO DEBEZIUM OFFSETS (offsets.txt, dbhistory.txt) FOUND IN $BKPS_DIR"
		return 0
	fi

	if [ ! -f "$history_bkp" ]; then
		echo "WARNING: $offsets_bkp has no matching $(basename "$history_bkp"). The offsets were not restored" >&2
		return 0
	fi

	echo "RESTORING THE DEBEZIUM OFFSETS FROM $offsets_bkp AND $history_bkp"

	mkdir -p "$DEBEZIUM_DIR"
	cp "$offsets_bkp" "$DEBEZIUM_DIR/offsets.txt"
	cp "$history_bkp" "$DEBEZIUM_DIR/dbhistory.txt"
}

# Checks that the mgt database and the offsets exist and are usable together.
# Returns 1 when dbsync would not continue from where it stopped
validateDbsyncState(){
	state_ok=0

	echo ""
	echo "VALIDATING THE DBSYNC STATE"

	if mgtDbExists; then
		tables=$(mysqlQuery "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$MGT_DB'")
		echo "  OK      mgt database $MGT_DB exists ($tables tables)"
	else
		echo "  MISSING mgt database $MGT_DB"
		state_ok=1
	fi

	if [ -f "$DEBEZIUM_DIR/offsets.txt" ] && [ -f "$DEBEZIUM_DIR/dbhistory.txt" ]; then
		binlog=$(offsetBinlog "$DEBEZIUM_DIR/offsets.txt")

		if [ -z "$binlog" ]; then
			echo "  INVALID debezium offsets: no binlog position found in $DEBEZIUM_DIR/offsets.txt"
			state_ok=1
		elif mysqlQuery "SHOW BINARY LOGS" | awk '{ print $1 }' | grep -qx "$binlog"; then
			echo "  OK      debezium offsets point to $binlog, which exists in MySQL"
		else
			echo "  INVALID debezium offsets point to $binlog, which no longer exists in MySQL (purged)"
			state_ok=1
		fi
	else
		echo "  MISSING debezium offsets in $DEBEZIUM_DIR"
		state_ok=1
	fi

	if [ $state_ok -ne 0 ]; then
		echo ""
		echo "WARNING: dbsync will not continue from where it stopped. If this is not a new site,"
		echo "the changes made since the last sync will not be sent. After starting dbsync run"
		echo "the re-sync with the last sync date given by the central team:"
		echo "  docker exec -i $DBSYNC_CONTAINER /home/eip/scripts/db_re_sync.sh 'YYYY-MM-DD'"
	fi

	return $state_ok
}

# On a reinstalled HF (no mgt database and/or no debezium offsets) restores the
# backup placed in BKPS_DIR, then validates the state. Existing state is kept.
restoreDbsyncState(){
	DB_PORT=$(envValue openmrs_db_port)
	DB_PASSWD=$(envValue spring_openmrs_datasource_password)
	MGT_DB="openmrs_eip_sender_mgt_$(envValue db_sync_senderId)"
	DBSYNC_IMAGE=$(sed -n 's/^\s*image:\s*["'\'']\{0,1\}\([^"'\'' ]*\).*/\1/p' "$DBSYNC_DIR/docker-compose.yml" | head -n 1)

	if [ "$(docker container inspect -f '{{.State.Running}}' "$DBSYNC_CONTAINER" 2>/dev/null)" = "true" ]; then
		echo "$DBSYNC_CONTAINER IS RUNNING, THE DBSYNC STATE IS NOT CHECKED NOR RESTORED"
		return 0
	fi

	if [ "$(mysqlQuery "SELECT 1")" != "1" ]; then
		echo "WARNING: could not connect to MySQL at $DB_HOST:$DB_PORT with the eip.env settings," >&2
		echo "the dbsync state was not checked nor restored" >&2
		return 0
	fi

	restore_mgt_db=false
	restore_offsets=false
	mgtDbExists || restore_mgt_db=true
	[ -f "$DEBEZIUM_DIR/offsets.txt" ] || restore_offsets=true

	if [ "$restore_mgt_db" = "false" ] && [ "$restore_offsets" = "false" ]; then
		echo "DBSYNC STATE FOUND (mgt database and debezium offsets), NOTHING TO RESTORE"
		validateDbsyncState || true
		return 0
	fi

	mkdir -p "$BKPS_DIR"

	echo ""
	echo "THE DBSYNC STATE IS MISSING:"
	[ "$restore_mgt_db" = "true" ] && echo "  - mgt database $MGT_DB"
	[ "$restore_offsets" = "true" ] && echo "  - debezium offsets ($DEBEZIUM_DIR/offsets.txt)"

	if [ -t 0 ]; then
		echo ""
		echo "If this HF was reinstalled, place the latest dbsync backup in $BKPS_DIR:"
		echo "  - the mgt database dump (*.sql or *.sql.gz)"
		echo "  - offsets.txt and dbhistory.txt (or offsets.txt<timestamp> and dbhistory.txt<timestamp>)"
		printf "Press Enter to restore what is there, or type 'skip' for a new site: "
		read -r answer

		if [ "$answer" = "skip" ]; then
			echo "RESTORE SKIPPED"
			validateDbsyncState || true
			return 0
		fi
	fi

	[ "$restore_mgt_db" = "true" ] && restoreMgtDb
	[ "$restore_offsets" = "true" ] && restoreOffsets

	validateDbsyncState || true
}

enableDbsync(){
	checkDocker
	installOras
	pullDeploymentFiles

	if [ ! -f "$DBSYNC_DIR/eip.env" ]; then
		cp "$DBSYNC_DIR/eip.template.env" "$DBSYNC_DIR/eip.env"
		chmod 600 "$DBSYNC_DIR/eip.env"

		echo ""
		echo "$DBSYNC_DIR/eip.env WAS CREATED FROM THE TEMPLATE."
		echo "Fill it in with the values of this site (values are used as written, \$ included)"
		echo "and run $0 --enable again."
		exit 2
	fi

	"$DBSYNC_DIR/pull_release_artifacts.sh" "$@"

	restoreDbsyncState

	includeDbsync

	echo ""
	echo "DBSYNC ENABLED. Start or update it with:"
	echo "  cd $PROJECT_DIR && docker compose up -d $DBSYNC_CONTAINER"
}

disableDbsync(){
	checkDocker

	if docker container inspect "$DBSYNC_CONTAINER" > /dev/null 2>&1; then
		echo "STOPPING AND REMOVING THE $DBSYNC_CONTAINER CONTAINER"
		docker stop "$DBSYNC_CONTAINER"
		docker rm "$DBSYNC_CONTAINER"
	fi

	excludeDbsync

	echo ""
	echo "DBSYNC DISABLED. $DBSYNC_DIR was kept."
}

if [ ! -f "$MAIN_COMPOSE_FILE" ]; then
	echo "$MAIN_COMPOSE_FILE not found, $0 must be in the root of the OpenMRS docker project" >&2
	exit 1
fi

action="$1"
[ $# -gt 0 ] && shift

case "$action" in
	--enable) enableDbsync "$@" ;;
	--disable) disableDbsync ;;
	*) usage; exit 1 ;;
esac

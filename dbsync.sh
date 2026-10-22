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
#              5. includes ./dbsync/docker-compose.yml in ./docker-compose.yml
#              Run it again to update dbsync.
#   --disable  stops and removes the dbsync container and removes the include from
#              ./docker-compose.yml. ./dbsync (eip.env, shared data, ...) is kept.
#
# Env:
#   DEPLOY_ARTIFACT_REPO  deployment registry repository (default: hub.csaude.org.mz/dbsync/dbsync-deploy)
#   ORAS_VERSION          oras version installed when it is missing (default: 1.3.5)
#
# Requires docker with the compose plugin 2.20+ (include support) and curl. If the
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

	if [ "$compose_major" -lt 2 ] || { [ "$compose_major" -eq 2 ] && [ "$compose_minor" -lt 20 ]; }; then
		echo "docker compose $compose_version does not support include, 2.20 or newer is required" >&2
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

enableDbsync(){
	checkDocker
	installOras
	pullDeploymentFiles

	if [ ! -f "$DBSYNC_DIR/eip.env" ]; then
		cp "$DBSYNC_DIR/eip.template.env" "$DBSYNC_DIR/eip.env"
		chmod 600 "$DBSYNC_DIR/eip.env"

		echo ""
		echo "$DBSYNC_DIR/eip.env WAS CREATED FROM THE TEMPLATE."
		echo "Fill it in with the values of this site (write each \$ in a value as \$\$)"
		echo "and run $0 --enable again."
		exit 2
	fi

	"$DBSYNC_DIR/pull_release_artifacts.sh" "$@"

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

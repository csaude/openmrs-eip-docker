#!/bin/sh
# Runs on the HF server before starting the container. Pulls the container image(s)
# referenced by the dbsync compose file and the release published by
# publish_release_artifacts.sh from hub.csaude.org.mz with oras for the OpenMRS
# version of the HF, verifies the checksums and installs:
#   - release_stuff.tar.gz -> <STOCK_DIR>/release_stuff (replaces the existing one)
#   - the jars (+ .SHA256) -> <SHARED_DIR>/releases/EIP-Release-<release_tag>,
#     the directory download_release.sh uses inside the container
#
# The host dirs are read from the compose file, so that they are the ones the
# container sees:
#   STOCK_DIR   mounted at /home/openmrs-eip-docker (default: the dir of this script)
#   SHARED_DIR  mounted at /home/eip/shared (default: <STOCK_DIR>/shared)
#   ENV_FILE    its env_file (default: <STOCK_DIR>/eip.env)
#
# Usage: ./pull_release_artifacts.sh [openmrs_version] [release_tag]
#   openmrs_version 2.6.11 or 2.3.3. When not given it is detected from the MySQL
#                   version of the OpenMRS database configured in ENV_FILE
#                   (same rule as release_stuff/scripts/release_info.sh: 5.x -> 2.3.3,
#                   8.x -> 2.6.11) and asked for if it can't be detected
#   release_tag     ex: V11.1.0, defaults to the latest release published for
#                   openmrs_version
#
# Env:
#   EIP_ARTIFACT_REPO  registry repository (default: hub.csaude.org.mz/dbsync/openmrs-eip-release)
#   COMPOSE_FILE       dbsync compose file (default: the first of docker-compose-dbsync.yml
#                      and docker-compose.yml found in the current dir or in the dir of this script)
#
# Requires oras, tar and sha256sum. If the repository is private run
# "oras login hub.csaude.org.mz" first.

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
EIP_ARTIFACT_REPO="${EIP_ARTIFACT_REPO:-hub.csaude.org.mz/dbsync/openmrs-eip-release}"
OPENMRS_VERSIONS="2.6.11 2.3.3"
RELEASE_STUFF_ARCHIVE="release_stuff.tar.gz"
# Host used by the container to reach the OpenMRS database (release_stuff/scripts/db_env.sh)
DB_HOST="172.17.0.1"

for cmd in oras tar sha256sum; do
	if [ -z "$(command -v $cmd)" ]; then
		echo "$cmd is required but was not found" >&2
		exit 1
	fi
done

if [ -z "$COMPOSE_FILE" ]; then
	for file in "$PWD/docker-compose-dbsync.yml" "$PWD/docker-compose.yml" "$SCRIPT_DIR/docker-compose-dbsync.yml" "$SCRIPT_DIR/docker-compose.yml"; do
		if [ -f "$file" ]; then
			COMPOSE_FILE="$file"
			break
		fi
	done
fi

# Resolves a path of the compose file (relative to its dir) to an absolute one
composePath(){
	case "$1" in
		/*) echo "${1%/}" ;;
		*) echo "$COMPOSE_DIR/$(echo "${1%/}" | sed 's#^\./##')" ;;
	esac
}

# Prints the host path the compose file mounts at the container path $1
composeMountSource(){
	sed -n "s#^\s*-\s*[\"']\{0,1\}\([^:\"']*\):$1/\{0,1\}\(:[a-z]*\)\{0,1\}[\"']\{0,1\}\s*\$#\1#p" "$COMPOSE_FILE" | head -n 1
}

# Prints the first env_file of the compose file ("env_file: x" or "env_file:\n  - x")
composeEnvFile(){
	awk '
		found && /^[ \t]*-/ { sub(/^[ \t]*-[ \t]*/, ""); gsub(/["\047]/, ""); print; exit }
		found { exit }
		/^[ \t]*env_file:/ {
			value = $0; sub(/^[ \t]*env_file:[ \t]*/, "", value); gsub(/["\047]/, "", value)
			if (value != "") { print value; exit }
			found = 1
		}' "$COMPOSE_FILE"
}

STOCK_DIR="$SCRIPT_DIR"
SHARED_DIR=""
ENV_FILE=""

if [ -n "$COMPOSE_FILE" ] && [ -f "$COMPOSE_FILE" ]; then
	COMPOSE_DIR=$(cd "$(dirname "$COMPOSE_FILE")" && pwd)

	echo "USING COMPOSE FILE $COMPOSE_FILE"

	source_dir=$(composeMountSource /home/openmrs-eip-docker)
	[ -n "$source_dir" ] && STOCK_DIR=$(composePath "$source_dir")

	source_dir=$(composeMountSource /home/eip/shared)
	[ -n "$source_dir" ] && SHARED_DIR=$(composePath "$source_dir")

	env_file=$(composeEnvFile)
	[ -n "$env_file" ] && ENV_FILE=$(composePath "$env_file")
else
	echo "WARNING: no compose file found, set COMPOSE_FILE to point to it"
	COMPOSE_FILE=""
fi

SHARED_DIR="${SHARED_DIR:-$STOCK_DIR/shared}"
ENV_FILE="${ENV_FILE:-$STOCK_DIR/eip.env}"

echo "PROJECT DIR (/home/openmrs-eip-docker): $STOCK_DIR"
echo "SHARED DIR (/home/eip/shared): $SHARED_DIR"
echo "ENV FILE: $ENV_FILE"

# A failure here does not stop the release install, the image can be pulled later
IMAGE=""
if [ -z "$COMPOSE_FILE" ]; then
	echo "WARNING: the container image was not pulled"
elif [ -z "$(command -v docker)" ]; then
	echo "WARNING: docker not found, the container image was not pulled"
else
	for image in $(sed -n 's/^\s*image:\s*["'\'']\{0,1\}\([^"'\'' ]*\).*/\1/p' "$COMPOSE_FILE"); do
		echo "PULLING CONTAINER IMAGE $image"

		if docker pull "$image"; then
			IMAGE="${IMAGE:-$image}"
		else
			echo "WARNING: Could not pull $image. If the repository is private run \"docker login ${image%%/*}\" and pull it again"
		fi
	done
fi

# Prints the MySQL version of the OpenMRS database, using the mysql client of the
# host or, when there is none or it fails, the one of the container image
determineMysqlVersion(){
	if [ ! -f "$ENV_FILE" ]; then
		echo "WARNING: $ENV_FILE not found" >&2
		return 1
	fi

	db_port=$(sed -n 's/^openmrs_db_port=//p' "$ENV_FILE" | tail -n 1 | tr -d '\r')
	db_passwd=$(sed -n 's/^spring_openmrs_datasource_password=//p' "$ENV_FILE" | tail -n 1 | tr -d '\r' | sed 's/\$\$/$/g')
	mysql_version=""

	if [ -n "$(command -v mysql)" ]; then
		mysql_version=$(MYSQL_PWD="$db_passwd" mysql -h "$DB_HOST" -P "$db_port" -u root -N -e "SELECT VERSION();" 2>/dev/null | tail -n 1)
	fi

	if [ -z "$mysql_version" ] && [ -n "$IMAGE" ]; then
		mysql_version=$(docker run --rm --network host -e MYSQL_PWD="$db_passwd" --entrypoint mysql "$IMAGE" \
			-h "$DB_HOST" -P "$db_port" -u root -N -e "SELECT VERSION();" 2>/dev/null | tail -n 1)
	fi

	echo "$mysql_version"
}

OPENMRS_VERSION="$1"

if [ -z "$OPENMRS_VERSION" ]; then
	echo "DETECTING THE OPENMRS VERSION FROM THE MYSQL VERSION"

	MYSQL_VERSION=$(determineMysqlVersion || true)

	case "$MYSQL_VERSION" in
		5.*) OPENMRS_VERSION="2.3.3" ;;
		8.*) OPENMRS_VERSION="2.6.11" ;;
	esac

	if [ -n "$OPENMRS_VERSION" ]; then
		echo "Detected OpenMRS $OPENMRS_VERSION based on MySQL version $MYSQL_VERSION"
	else
		echo "WARNING: Could not detect the OpenMRS version (MySQL version: '${MYSQL_VERSION}')"
	fi
fi

if [ -z "$OPENMRS_VERSION" ]; then
	echo "Which OpenMRS version is installed on this HF?"
	i=1
	for version in $OPENMRS_VERSIONS; do
		echo "  $i) $version"
		i=$((i + 1))
	done
	printf "Choose [1-%s]: " "$((i - 1))"
	read -r choice

	i=1
	for version in $OPENMRS_VERSIONS; do
		if [ "$choice" = "$i" ] || [ "$choice" = "$version" ]; then
			OPENMRS_VERSION="$version"
		fi
		i=$((i + 1))
	done
fi

if ! echo "$OPENMRS_VERSIONS" | tr ' ' '\n' | grep -qx "$OPENMRS_VERSION"; then
	echo "Unsupported OpenMRS version '$OPENMRS_VERSION'. Supported: $OPENMRS_VERSIONS" >&2
	exit 1
fi

RELEASE_VERSION_TAG="$2"

if [ -z "$RELEASE_VERSION_TAG" ]; then
	# Release tags published for this OpenMRS version, oldest first
	RELEASE_TAGS=$(oras repo tags "$EIP_ARTIFACT_REPO" | sed -n "s/^\(.*\)-$OPENMRS_VERSION\$/\1/p" | sort -V)

	if [ -z "$RELEASE_TAGS" ]; then
		echo "No release found in $EIP_ARTIFACT_REPO for OpenMRS $OPENMRS_VERSION" >&2
		exit 1
	fi

	RELEASE_VERSION_TAG=$(echo "$RELEASE_TAGS" | tail -n 1)

	echo "Using the latest release for OpenMRS $OPENMRS_VERSION: $RELEASE_VERSION_TAG"
fi

RELEASE_NAME="EIP-Release-$RELEASE_VERSION_TAG"
ARTIFACT_REF="$EIP_ARTIFACT_REPO:$RELEASE_VERSION_TAG-$OPENMRS_VERSION"
RELEASES_DIR="$SHARED_DIR/releases/$RELEASE_NAME"
STAGING_DIR="$STOCK_DIR/.release-pull"

echo "PULLING $ARTIFACT_REF"

rm -fr "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
trap 'rm -fr "$STAGING_DIR"' EXIT

oras pull "$ARTIFACT_REF" -o "$STAGING_DIR"

cd "$STAGING_DIR"

if [ ! -f "$RELEASE_STUFF_ARCHIVE" ] || ! ls *.jar.SHA256 > /dev/null 2>&1; then
	echo "$ARTIFACT_REF does not contain the expected files" >&2
	exit 1
fi

sha256sum -c *.SHA256

echo "INSTALLING release_stuff INTO $STOCK_DIR/release_stuff"

mkdir -p "$STOCK_DIR"
rm -fr "$STOCK_DIR/release_stuff"
tar -xzf "$RELEASE_STUFF_ARCHIVE" -C "$STOCK_DIR"

echo "INSTALLING JARS INTO $RELEASES_DIR"

mkdir -p "$RELEASES_DIR"
mv -f *.jar *.jar.SHA256 "$RELEASES_DIR/"

echo "$RELEASE_NAME FOR OPENMRS $OPENMRS_VERSION PULLED AND INSTALLED"


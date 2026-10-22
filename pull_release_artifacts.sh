#!/bin/sh
# Runs on the HF server before starting the container. Pulls the container image(s)
# referenced by the dbsync compose file and the release published by
# publish_release_artifacts.sh from hub.csaude.org.mz with oras for the OpenMRS
# version of the HF, verifies the checksums and installs (only the files whose
# local copy is missing or does not match the published .SHA256 are downloaded):
#   - release_stuff.tar.gz -> <STOCK_DIR>/release_stuff (replaces the existing one)
#   - install.sh           -> <INSTALL_SCRIPT>
#   - the jars (+ .SHA256) -> <SHARED_DIR>/releases/EIP-Release-<release_tag>,
#     the directory download_release.sh uses inside the container
#
# The host dirs are read from the compose file, so that they are the ones the
# container sees:
#   STOCK_DIR   mounted at /home/openmrs-eip-docker (default: the dir of this script)
#   SHARED_DIR  mounted at /home/eip/shared (default: <STOCK_DIR>/shared)
#   ENV_FILE    its env_file (default: <STOCK_DIR>/eip.env)
#   INSTALL_SCRIPT  mounted at /home/eip/install.sh (default: <STOCK_DIR>/install.sh)
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
INSTALL_SCRIPT_FILE="install.sh"
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
INSTALL_SCRIPT=""

if [ -n "$COMPOSE_FILE" ] && [ -f "$COMPOSE_FILE" ]; then
	COMPOSE_DIR=$(cd "$(dirname "$COMPOSE_FILE")" && pwd)

	echo "USING COMPOSE FILE $COMPOSE_FILE"

	source_dir=$(composeMountSource /home/openmrs-eip-docker)
	[ -n "$source_dir" ] && STOCK_DIR=$(composePath "$source_dir")

	source_dir=$(composeMountSource /home/eip/shared)
	[ -n "$source_dir" ] && SHARED_DIR=$(composePath "$source_dir")

	source_file=$(composeMountSource /home/eip/install.sh)
	[ -n "$source_file" ] && INSTALL_SCRIPT=$(composePath "$source_file")

	env_file=$(composeEnvFile)
	[ -n "$env_file" ] && ENV_FILE=$(composePath "$env_file")
else
	echo "WARNING: no compose file found, set COMPOSE_FILE to point to it"
	COMPOSE_FILE=""
fi

SHARED_DIR="${SHARED_DIR:-$STOCK_DIR/shared}"
ENV_FILE="${ENV_FILE:-$STOCK_DIR/eip.env}"
INSTALL_SCRIPT="${INSTALL_SCRIPT:-$STOCK_DIR/install.sh}"

echo "PROJECT DIR (/home/openmrs-eip-docker): $STOCK_DIR"
echo "SHARED DIR (/home/eip/shared): $SHARED_DIR"
echo "ENV FILE: $ENV_FILE"
echo "INSTALL SCRIPT (/home/eip/install.sh): $INSTALL_SCRIPT"

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
# SHA256 of the release_stuff archive last installed in STOCK_DIR
INSTALLED_ARCHIVE_SHA256="$STOCK_DIR/.$RELEASE_STUFF_ARCHIVE.SHA256"

echo "CHECKING $ARTIFACT_REF"

# "<digest> <file name>" of each file of the artifact
ARTIFACT_FILES=$(oras manifest fetch --pretty "$ARTIFACT_REF" | awk -F'"' '
	/"layers"/ { in_layers = 1 }
	in_layers && $2 == "digest" { digest = $4 }
	in_layers && $2 == "org.opencontainers.image.title" { print digest, $4 }')

JARS=$(echo "$ARTIFACT_FILES" | awk '$2 ~ /\.jar$/ { print $2 }')

if [ -z "$JARS" ] || ! echo "$ARTIFACT_FILES" | awk '{ print $2 }' | grep -qx "$RELEASE_STUFF_ARCHIVE"; then
	echo "$ARTIFACT_REF does not contain the expected files" >&2
	exit 1
fi

# Downloads the file $1 of the artifact into STAGING_DIR
fetchFile(){
	digest=$(echo "$ARTIFACT_FILES" | awk -v name="$1" '$2 == name { print $1 }')

	if [ -z "$digest" ]; then
		echo "$1 not found in $ARTIFACT_REF" >&2
		return 1
	fi

	oras blob fetch --output "$STAGING_DIR/$1" "$EIP_ARTIFACT_REPO@$digest"
}

rm -fr "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
trap 'rm -fr "$STAGING_DIR"' EXIT

# The .SHA256 files are always downloaded, the other files only when the local
# copy is missing or does not match them
for file in $JARS $RELEASE_STUFF_ARCHIVE; do
	fetchFile "$file.SHA256"
done

# Releases published before install.sh was added to the artifact don't have it
if echo "$ARTIFACT_FILES" | awk '{ print $2 }' | grep -qx "$INSTALL_SCRIPT_FILE"; then
	fetchFile "$INSTALL_SCRIPT_FILE.SHA256"
fi

DOWNLOADED=0

if [ -d "$STOCK_DIR/release_stuff/scripts" ] && [ -f "$INSTALLED_ARCHIVE_SHA256" ] \
	&& [ "$(cut -d' ' -f1 "$INSTALLED_ARCHIVE_SHA256")" = "$(cut -d' ' -f1 "$STAGING_DIR/$RELEASE_STUFF_ARCHIVE.SHA256")" ]; then
	echo "release_stuff IS UP TO DATE IN $STOCK_DIR/release_stuff"
else
	echo "DOWNLOADING $RELEASE_STUFF_ARCHIVE"

	fetchFile "$RELEASE_STUFF_ARCHIVE"
	(cd "$STAGING_DIR" && sha256sum -c "$RELEASE_STUFF_ARCHIVE.SHA256")

	echo "INSTALLING release_stuff INTO $STOCK_DIR/release_stuff"

	rm -fr "$STOCK_DIR/release_stuff"
	tar -xzf "$STAGING_DIR/$RELEASE_STUFF_ARCHIVE" -C "$STOCK_DIR"
	mv -f "$STAGING_DIR/$RELEASE_STUFF_ARCHIVE.SHA256" "$INSTALLED_ARCHIVE_SHA256"

	DOWNLOADED=$((DOWNLOADED + 1))
fi

if [ ! -f "$STAGING_DIR/$INSTALL_SCRIPT_FILE.SHA256" ]; then
	echo "WARNING: $ARTIFACT_REF does not contain $INSTALL_SCRIPT_FILE, $INSTALL_SCRIPT was not updated"
elif [ -f "$INSTALL_SCRIPT" ] \
	&& [ "$(sha256sum "$INSTALL_SCRIPT" | cut -d' ' -f1)" = "$(cut -d' ' -f1 "$STAGING_DIR/$INSTALL_SCRIPT_FILE.SHA256")" ]; then
	echo "$INSTALL_SCRIPT_FILE IS UP TO DATE IN $INSTALL_SCRIPT"
else
	echo "DOWNLOADING $INSTALL_SCRIPT_FILE"

	fetchFile "$INSTALL_SCRIPT_FILE"
	(cd "$STAGING_DIR" && sha256sum -c "$INSTALL_SCRIPT_FILE.SHA256")

	echo "INSTALLING $INSTALL_SCRIPT_FILE INTO $INSTALL_SCRIPT"

	# cp keeps the inode of an existing file, so a file bind mount keeps working
	mkdir -p "$(dirname "$INSTALL_SCRIPT")"
	cp "$STAGING_DIR/$INSTALL_SCRIPT_FILE" "$INSTALL_SCRIPT"
	chmod +x "$INSTALL_SCRIPT"

	DOWNLOADED=$((DOWNLOADED + 1))
fi

mkdir -p "$RELEASES_DIR"

for jar in $JARS; do
	if [ -f "$RELEASES_DIR/$jar" ] && (cd "$RELEASES_DIR" && sha256sum -c --status "$STAGING_DIR/$jar.SHA256"); then
		echo "$jar IS UP TO DATE IN $RELEASES_DIR"
	else
		echo "DOWNLOADING $jar"

		fetchFile "$jar"
		(cd "$STAGING_DIR" && sha256sum -c "$jar.SHA256")

		mv -f "$STAGING_DIR/$jar" "$RELEASES_DIR/"

		DOWNLOADED=$((DOWNLOADED + 1))
	fi

	mv -f "$STAGING_DIR/$jar.SHA256" "$RELEASES_DIR/"
done

echo "$RELEASE_NAME FOR OPENMRS $OPENMRS_VERSION INSTALLED ($DOWNLOADED FILE(S) DOWNLOADED)"

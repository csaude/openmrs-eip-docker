#!/bin/sh
# Runs on the HF server before starting the container. Pulls the release published
# by publish_release_artifacts.sh from hub.csaude.org.mz with oras for the chosen
# OpenMRS version, verifies the checksums and installs:
#   - release_stuff.tar.gz -> <TARGET_DIR>/release_stuff (replaces the existing one)
#   - the jars (+ .SHA256) -> <TARGET_DIR>/shared/releases/EIP-Release-<release_tag>,
#     the directory download_release.sh uses inside the container
#     (./shared is mounted at /home/eip/shared)
# and then pulls the container image(s) referenced by <TARGET_DIR>/docker-compose.yml
#
# Usage: ./pull_release_artifacts.sh [openmrs_version] [release_tag]
#   openmrs_version 2.6.11 or 2.3.3, asked for when not given
#   release_tag     ex: V11.1.0, when not given it is chosen from the releases
#                   published for openmrs_version (default: the latest)
#
# Env:
#   EIP_ARTIFACT_REPO  registry repository (default: hub.csaude.org.mz/dbsync/openmrs-eip-release)
#   TARGET_DIR         openmrs-eip-docker project dir (default: the dir of this script)
#
# Requires oras, tar and sha256sum. If the repository is private run
# "oras login hub.csaude.org.mz" first.

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
EIP_ARTIFACT_REPO="${EIP_ARTIFACT_REPO:-hub.csaude.org.mz/dbsync/openmrs-eip-release}"
TARGET_DIR="${TARGET_DIR:-$SCRIPT_DIR}"
OPENMRS_VERSIONS="2.6.11 2.3.3"
RELEASE_STUFF_ARCHIVE="release_stuff.tar.gz"
COMPOSE_FILE="$TARGET_DIR/docker-compose.yml"

for cmd in oras tar sha256sum; do
	if [ -z "$(command -v $cmd)" ]; then
		echo "$cmd is required but was not found" >&2
		exit 1
	fi
done

OPENMRS_VERSION="$1"

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

	LATEST_RELEASE_TAG=$(echo "$RELEASE_TAGS" | tail -n 1)

	echo "Releases available for OpenMRS $OPENMRS_VERSION:"
	i=1
	for tag in $RELEASE_TAGS; do
		echo "  $i) $tag"
		i=$((i + 1))
	done
	printf "Choose [1-%s] (default %s): " "$((i - 1))" "$LATEST_RELEASE_TAG"
	read -r choice

	if [ -z "$choice" ]; then
		RELEASE_VERSION_TAG="$LATEST_RELEASE_TAG"
	fi

	i=1
	for tag in $RELEASE_TAGS; do
		if [ "$choice" = "$i" ] || [ "$choice" = "$tag" ]; then
			RELEASE_VERSION_TAG="$tag"
		fi
		i=$((i + 1))
	done

	if [ -z "$RELEASE_VERSION_TAG" ]; then
		echo "Invalid release '$choice'" >&2
		exit 1
	fi
fi

RELEASE_NAME="EIP-Release-$RELEASE_VERSION_TAG"
ARTIFACT_REF="$EIP_ARTIFACT_REPO:$RELEASE_VERSION_TAG-$OPENMRS_VERSION"
RELEASES_DIR="$TARGET_DIR/shared/releases/$RELEASE_NAME"
STAGING_DIR="$TARGET_DIR/.release-pull"

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

echo "INSTALLING release_stuff INTO $TARGET_DIR/release_stuff"

rm -fr "$TARGET_DIR/release_stuff"
tar -xzf "$RELEASE_STUFF_ARCHIVE" -C "$TARGET_DIR"

echo "INSTALLING JARS INTO $RELEASES_DIR"

mkdir -p "$RELEASES_DIR"
mv -f *.jar *.jar.SHA256 "$RELEASES_DIR/"

echo "$RELEASE_NAME FOR OPENMRS $OPENMRS_VERSION PULLED AND INSTALLED IN $TARGET_DIR"

# A failure here does not undo the release install, the image can be pulled later
if [ ! -f "$COMPOSE_FILE" ]; then
	echo "WARNING: $COMPOSE_FILE not found, the container image was not pulled"
elif [ -z "$(command -v docker)" ]; then
	echo "WARNING: docker not found, the container image was not pulled"
else
	for image in $(sed -n 's/^\s*image:\s*["'\'']\{0,1\}\([^"'\'' ]*\).*/\1/p' "$COMPOSE_FILE"); do
		echo "PULLING CONTAINER IMAGE $image"

		if ! docker pull "$image"; then
			echo "WARNING: Could not pull $image. If the repository is private run \"docker login ${image%%/*}\" and pull it again"
		fi
	done
fi

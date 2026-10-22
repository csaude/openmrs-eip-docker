#!/bin/sh
# Runs on a workstation with internet access. Pulls the openmrs-eip-docker project
# for the setup git tag (same as release_stuff/scripts/pull_dbsync_deployment_project_from_git.sh),
# downloads the release jars (+ .SHA256) from GitHub, verifies them and pushes, for
# each supported OpenMRS version, an OCI artifact with oras to hub.csaude.org.mz
# containing:
#   - the openmrs-eip-app jar for that OpenMRS version
#   - the jars common to all versions (epts-etl-api, centralization-features-manager)
#   - release_stuff.tar.gz (the release_stuff folder of the pulled project)
#   - a .SHA256 file for each of the above
#
# The artifacts are tagged <release_tag>-<openmrs_version> (ex: V11.1.0-2.6.11)
# and are pulled on the HF server with pull_release_artifacts.sh
#
# Usage: ./publish_release_artifacts.sh [setup_git_tag]
#   setup_git_tag defaults to the one in ./setup_git_tag_info.sh
#
# Env:
#   EIP_ARTIFACT_REPO  registry repository (default: hub.csaude.org.mz/dbsync/openmrs-eip-release)
#   WORK_DIR           where the project and jars are downloaded (default: ./build/release-artifacts)
#
# Requires git, curl, tar, sha256sum, oras and a previous "oras login hub.csaude.org.mz"
# (or docker login, oras reuses the docker credentials).

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
EIP_ARTIFACT_REPO="${EIP_ARTIFACT_REPO:-hub.csaude.org.mz/dbsync/openmrs-eip-release}"
WORK_DIR="${WORK_DIR:-$SCRIPT_DIR/build/release-artifacts}"
GIT_REPO_URL="https://github.com/csaude/openmrs-eip-docker.git"
RELEASE_BASE_URL="https://github.com/csaude/openmrs-eip-docker/releases/download"
ARTIFACT_TYPE="application/vnd.csaude.openmrs-eip.release"
RELEASE_STUFF_ARCHIVE="release_stuff.tar.gz"

# <openmrs_version>:<openmrs-eip-app version>, mirrors the MySQL based choice in
# release_info.sh (MySQL 8.x -> platform 2.6.x, MySQL 5.x -> platform 2.3.x)
OPENMRS_DBSYNC_VERSIONS="2.6.11:1.9.0 2.3.3:1.6.9"

for cmd in git curl tar sha256sum oras; do
	if [ -z "$(command -v $cmd)" ]; then
		echo "$cmd is required but was not found" >&2
		exit 1
	fi
done

if [ -n "$1" ]; then
	SETUP_GIT_TAG="$1"
else
	. "$SCRIPT_DIR/setup_git_tag_info.sh"
	SETUP_GIT_TAG="$setup_git_tag"
fi

PROJECT_DIR="$WORK_DIR/openmrs-eip-docker"

echo "PULLING openmrs-eip-docker ($SETUP_GIT_TAG) INTO $PROJECT_DIR"

#ALWAYS REMOVE THE EXISTING PROJECT DIR TO PREVENT GIT ERRORS
rm -fr "$PROJECT_DIR"
mkdir -p "$PROJECT_DIR"

git -C "$PROJECT_DIR" init -q && git -C "$PROJECT_DIR" checkout -q -b "$SETUP_GIT_TAG"
git -C "$PROJECT_DIR" remote add origin "$GIT_REPO_URL"
git -C "$PROJECT_DIR" pull -q --depth=1 origin "$SETUP_GIT_TAG"

# release_info.sh can't be sourced here (it queries the site database), so the
# release tag and the jar names are read from it
RELEASE_INFO="$PROJECT_DIR/release_stuff/scripts/release_info.sh"

RELEASE_VERSION_TAG=$(sed -n 's/^export RELEASE_VERSION_TAG="\(.*\)"/\1/p' "$RELEASE_INFO")
DBSYNC_VERSIONS=$(sed -n 's/^\s*DBSYNC_VERSION="\(.*\)"/\1/p' "$RELEASE_INFO")
COMMON_JARS=$(grep '^export .*_RELEASE_URL=' "$RELEASE_INFO" | grep -v 'DBSYNC_VERSION' | sed 's/.*\/\([^/]*\.jar\)".*/\1/')

if [ -z "$RELEASE_VERSION_TAG" ] || [ -z "$DBSYNC_VERSIONS" ]; then
	echo "Could not read the release information from $RELEASE_INFO" >&2
	exit 1
fi

for mapping in $OPENMRS_DBSYNC_VERSIONS; do
	dbsync_version="${mapping#*:}"
	if ! echo "$DBSYNC_VERSIONS" | grep -qx "$dbsync_version"; then
		echo "openmrs-eip-app $dbsync_version (OpenMRS ${mapping%%:*}) is not referenced by $RELEASE_INFO. Update OPENMRS_DBSYNC_VERSIONS" >&2
		exit 1
	fi
done

JARS="$COMMON_JARS"
for version in $DBSYNC_VERSIONS; do
	JARS="$JARS openmrs-eip-app-$version.jar"
done

RELEASE_NAME="EIP-Release-$RELEASE_VERSION_TAG"
RELEASE_DIR="$WORK_DIR/$RELEASE_NAME"

echo "DOWNLOADING $RELEASE_NAME JARS:" $JARS

rm -fr "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"
cd "$RELEASE_DIR"

for jar in $JARS; do
	url="$RELEASE_BASE_URL/$RELEASE_VERSION_TAG/$jar"
	curl -fSL --retry 5 --retry-delay 10 -o "$jar.SHA256" "$url.SHA256"
	curl -fSL --retry 5 --retry-delay 10 -o "$jar" "$url"
done

sha256sum -c *.SHA256

echo "ARCHIVING release_stuff INTO $RELEASE_STUFF_ARCHIVE"

tar -czf "$RELEASE_STUFF_ARCHIVE" -C "$PROJECT_DIR" release_stuff
sha256sum "$RELEASE_STUFF_ARCHIVE" > "$RELEASE_STUFF_ARCHIVE.SHA256"

for mapping in $OPENMRS_DBSYNC_VERSIONS; do
	openmrs_version="${mapping%%:*}"
	dbsync_version="${mapping#*:}"

	ARTIFACT_REF="$EIP_ARTIFACT_REPO:$RELEASE_VERSION_TAG-$openmrs_version"
	FILES="openmrs-eip-app-$dbsync_version.jar $COMMON_JARS $RELEASE_STUFF_ARCHIVE"

	echo "PUSHING $RELEASE_NAME FOR OPENMRS $openmrs_version TO $ARTIFACT_REF"

	# Files are pushed with their bare names (relative to RELEASE_DIR) so that a pull
	# recreates the same flat layout download_release.sh produces
	oras push "$ARTIFACT_REF" \
		--artifact-type "$ARTIFACT_TYPE" \
		--annotation "org.opencontainers.image.title=$RELEASE_NAME" \
		--annotation "org.opencontainers.image.version=$RELEASE_VERSION_TAG" \
		--annotation "org.opencontainers.image.source=$GIT_REPO_URL" \
		--annotation "mz.org.csaude.eip.setup-git-tag=$SETUP_GIT_TAG" \
		--annotation "mz.org.csaude.eip.openmrs-version=$openmrs_version" \
		--annotation "mz.org.csaude.eip.dbsync-version=$dbsync_version" \
		$(for file in $FILES; do echo "$file" "$file.SHA256"; done)

	echo "$RELEASE_NAME FOR OPENMRS $openmrs_version PUBLISHED AS $ARTIFACT_REF"
done

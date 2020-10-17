#!/bin/bash

set -e

# TODO install curl, python, docker if needed.

PARAMS=""

while (( "$#" )); do
  case "$1" in
    -s|--silent)
      SILENT="true"
      shift
      ;;
    -u|--upload-container)
      UPLOAD_CONTAINER="true"
      shift
      ;;
    -c|--clean-docker)
      CLEAN_DOCKER="true"
      shift
      ;;
    -b|--branch)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        NWJS_BRANCH="$2"
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -h|--docker-host)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        DOCKER_HOST="$2"
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

# Set positional arguments in their proper place.
eval set -- "$PARAMS"

# Done reading parameters.
# Assign default values for missing parameters.

# Get the active branch from the official repo, if it the branch was not provided by the user.
[ -z "$NWJS_BRANCH" ] &&
NWJS_BRANCH=$(curl --silent --no-buffer https://api.github.com/repos/nwjs/nw.js | python -c 'import sys, json; print(json.load(sys.stdin)["default_branch"])')
[ -z "$DOCKER_CONTAINER" ] &&
DOCKER_CONTAINER="laslaul/nwjs-arm-build-env"
[ -z "$DOCKER_HOST" ] &&
DOCKER_PARAMS="-H unix:///var/run/docker.sock" || DOCKER_PARAMS="-H $DOCKER_HOST"

[ -z "$SILENT" ] && echo "NW.js active branch: $NWJS_BRANCH."
[ -z "$SILENT" ] && echo "Docker container label: $DOCKER_CONTAINER."
[ -z "$SILENT" ] && echo "Docker parameters: $DOCKER_PARAMS."

# Print the disk usage of docker.
[ -z "$SILENT" ] && docker "$DOCKER_PARAMS" system df

# Check whether the container already exists on the docker host.
CONTAINER_ID=$(docker "$DOCKER_PARAMS" ps --all --quiet --filter "ancestor=$DOCKER_CONTAINER")
if [ -z "$CONTAINER_ID" ]
then
  # If the container does not exist on the docker host.
  [ -z "$SILENT" ] && echo "Did not find container: $DOCKER_CONTAINER."
  [ -z "$SILENT" ] && echo "Pulling: $DOCKER_CONTAINER."
  docker "$DOCKER_PARAMS" pull "$DOCKER_CONTAINER" && (
    # If the container exists on docker hub, pull the container and checkout the desired branch.
    [ -z "$SILENT" ] && echo "Found container $DOCKER_CONTAINER on dockerhub"
    docker "$DOCKER_PARAMS" start "$CONTAINER_ID";
    [ -z "$SILENT" ] && echo "Checking out "$NWJS_BRANCH"."
    docker "$DOCKER_PARAMS" exec --interactive --tty "$CONTAINER_ID" /usr/docker/checkout-another-branch.sh "$NWJS_BRANCH"
    [ -z "$UPLOAD_CONTAINER"] && docker "$DOCKER_PARAMS" commit "$CONTAINER_ID" "$DOCKER_CONTAINER":"$NWJS_BRANCH"
    [ -z "$UPLOAD_CONTAINER"] && docker "$DOCKER_PARAMS" push "$DOCKER_CONTAINER":"$NWJS_BRANCH"
  ) || (
    # If the container is not found on docker hub, build it.
    [ -z "$SILENT" ] && echo "Didn't find container $DOCKER_CONTAINER on dockerhub. Building active branch: $NWJS_BRANCH."
    docker "$DOCKER_PARAMS" image build --build-arg NWJS_BRANCH="$NWJS_BRANCH" --tag "$DOCKER_CONTAINER":"$NWJS_BRANCH" .
    [ -z "$UPLOAD_CONTAINER"] && docker "$DOCKER_PARAMS" push "$DOCKER_CONTAINER":"$NWJS_BRANCH"
    docker "$DOCKER_PARAMS" run "$DOCKER_CONTAINER"
  )
  CONTAINER_ID=$(docker "$DOCKER_PARAMS" ps --all --quiet --filter "ancestor=$DOCKER_CONTAINER")
else
  # If the container exists on the docker host.
  [ -z "$SILENT" ] && echo "Found container with id: $CONTAINER_ID locally."
  docker "$DOCKER_PARAMS" start "$CONTAINER_ID"
  [ -z "$SILENT" ] && echo "Checking out "$NWJS_BRANCH"."
  docker "$DOCKER_PARAMS" exec --interactive --tty "$CONTAINER_ID" /usr/docker/checkout-another-branch.sh "$NWJS_BRANCH"
  [ -z "$UPLOAD_CONTAINER"] && docker "$DOCKER_PARAMS" commit "$CONTAINER_ID" "$DOCKER_CONTAINER":"$NWJS_BRANCH"
  [ -z "$UPLOAD_CONTAINER"] && docker "$DOCKER_PARAMS" push "$DOCKER_CONTAINER":"$NWJS_BRANCH"
fi

# At this point we should have the building environment up an running.
[ -z "$SILENT" ] && echo "Started successfully container with id: $CONTAINER_ID."

# Clean the unused docker objects.
[ -z "$CLEAN_DOCKER" ] && docker "$DOCKER_PARAMS" system prune --force

# Start the building process.
[ -z "$SILENT" ] && echo "Let's start building $CONTAINER_ID."
docker "$DOCKER_PARAMS" exec --interactive --tty "$CONTAINER_ID" /usr/docker/build-nwjs.sh
ARCHIVE_NAME="$NWJS_BRANCH"_$(date +"%Y-%m-%d_%T").tar.gz
docker "$DOCKER_PARAMS" exec --interactive --tty "$CONTAINER_ID" tar -zcvf "$ARCHIVE_NAME" /usr/docker/dist/*
mkdir -p binaries
docker "$DOCKER_PARAMS" cp "$CONTAINER_ID":/usr/docker/"$ARCHIVE_NAME" ./binaries/
[ -z "$SILENT" ] && echo "Artifact $ARCHIVE_NAME created successfully."
docker "$DOCKER_PARAMS" stop "$CONTAINER_ID"

# TODO remove the container if needed.
# TODO upload to github releases.

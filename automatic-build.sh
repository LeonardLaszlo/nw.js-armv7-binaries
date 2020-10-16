#!/bin/bash

set -e

# TODO install curl, python, docker
DOCKER_CONTAINER="laslaul/nwjs-arm-build-env"

# Get the active branch from the official repo.
NWJS_BRANCH=$(curl -s -N https://api.github.com/repos/nwjs/nw.js | python -c 'import sys, json; print(json.load(sys.stdin)["default_branch"])')
echo "NW.js active branch: $NWJS_BRANCH."

# Check whether the container already exists on the machine.
CONTAINER_ID=$(docker ps -aqf "ancestor=$DOCKER_CONTAINER")
if [ -z "$CONTAINER_ID" ]
then
  echo "Did not find container: $DOCKER_CONTAINER."
  echo "Pulling: $DOCKER_CONTAINER."
  docker pull "$DOCKER_CONTAINER" && (
    echo "Found container $DOCKER_CONTAINER on dockerhub"
    docker start "$CONTAINER_ID";
    echo "Checking out "$NWJS_BRANCH"."
    docker exec -it "$CONTAINER_ID" /usr/docker/checkout-another-branch.sh "$NWJS_BRANCH"
  ) || (
    echo "Didn't find container $DOCKER_CONTAINER on dockerhub. Building active branch: $NWJS_BRANCH."
    docker image build --build-arg NWJS_BRANCH="$NWJS_BRANCH" -t "$DOCKER_CONTAINER" .
    docker run "$DOCKER_CONTAINER"
  )
  CONTAINER_ID=$(docker ps -aqf "ancestor=$DOCKER_CONTAINER")
else
  echo "Found container with id: $CONTAINER_ID locally."
  docker start "$CONTAINER_ID"
  echo "Checking out "$NWJS_BRANCH"."
  docker exec -it "$CONTAINER_ID" /usr/docker/checkout-another-branch.sh "$NWJS_BRANCH"
fi

echo "Started successfully container with id: $CONTAINER_ID."
echo "Let's start building $CONTAINER_ID."
docker exec -it "$CONTAINER_ID" /usr/docker/build-nwjs.sh

#!/bin/bash

set -e

echo "TODO install curl, python, docker if needed"

PARAMS=""

while (( "$#" )); do
  case "$1" in
    -s|--silent)
      SILENT="true"
      shift
      ;;
    -u|--upload-image)
      UPLOAD_IMAGE="true"
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
    -r|--docker-repository)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        DOCKER_REPOSITORY="$2"
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

[ -z "$SILENT" ] && echo "Set positional arguments in their proper place"
eval set -- "$PARAMS"
[ -z "$SILENT" ] && echo "Done reading parameters"

function createContainerAndCheckoutBranchIfNeeded {
  [ -z "$SILENT" ] && echo "Start a container from the $DOCKER_REPOSITORY image"
  CONTAINER_ID=$( docker "$DOCKER_PARAMS" run --detach --tty "$DOCKER_REPOSITORY" )
  [ -z "$SILENT" ] && echo "Read the checked out branch, from inside of the container"
  CURRENT_BRANCH="$( docker "$DOCKER_PARAMS" exec -t "$CONTAINER_ID" bash -c 'cd /usr/docker/nwjs/src && git show-branch | cut -d "[" -f2 | cut -d "]" -f1' )"
  [ -z "$SILENT" ] && echo "Needed to match regex because equality checks fails here. Weird enough to waste some hours on this"
  if [[ ! "$CURRENT_BRANCH" =~ "$NWJS_BRANCH" ]]; then
    [ -z "$SILENT" ] && echo "Checking out $NWJS_BRANCH branch"
    docker "$DOCKER_PARAMS" exec --interactive --tty "$CONTAINER_ID" /usr/docker/checkout-another-branch.sh "$NWJS_BRANCH"
    [ -n "$UPLOAD_IMAGE"] && [ -z "$SILENT" ] && echo "Commit $CONTAINER_ID to $DOCKER_REPOSITORY:$NWJS_BRANCH"
    [ -n "$UPLOAD_IMAGE"] && docker "$DOCKER_PARAMS" commit "$CONTAINER_ID" "$DOCKER_REPOSITORY":"$NWJS_BRANCH"
    [ -n "$UPLOAD_IMAGE"] && [ -z "$SILENT" ] && echo "Push $DOCKER_REPOSITORY:$NWJS_BRANCH to docker hub"
    [ -n "$UPLOAD_IMAGE"] && docker "$DOCKER_PARAMS" push "$DOCKER_REPOSITORY":"$NWJS_BRANCH"
  fi
}

function buildImageAndStartContainer {
  [ -z "$SILENT" ] && echo "Start building $DOCKER_REPOSITORY image"
  docker "$DOCKER_PARAMS" image build --build-arg NWJS_BRANCH="$NWJS_BRANCH" --tag "$DOCKER_REPOSITORY":"$NWJS_BRANCH" .
  [ -n "$UPLOAD_IMAGE"] && [ -z "$SILENT" ] && echo "Push $DOCKER_REPOSITORY:$NWJS_BRANCH to docker hub"
  [ -n "$UPLOAD_IMAGE"] && docker "$DOCKER_PARAMS" push "$DOCKER_REPOSITORY":"$NWJS_BRANCH"
  [ -z "$SILENT" ] && echo "Start a container from the $DOCKER_REPOSITORY image"
  CONTAINER_ID=$( docker "$DOCKER_PARAMS" run --detach --tty "$DOCKER_REPOSITORY" )
}

[ -z "$SILENT" ] && echo "Assign default values for missing parameters"
[ -z "$NWJS_BRANCH" ] && echo "Get the active branch from the official repo, if it the branch was not provided by the user" &&
NWJS_BRANCH="$( curl --silent --no-buffer https://api.github.com/repos/nwjs/nw.js | python -c 'import sys, json; print(json.load(sys.stdin)["default_branch"])' )"
[ -z "$SILENT" ] && echo "NW.js active branch: $NWJS_BRANCH"

[ -z "$DOCKER_REPOSITORY" ] &&
DOCKER_REPOSITORY="laslaul/nwjs-arm-build-env"
[ -z "$SILENT" ] && echo "Docker repository: $DOCKER_REPOSITORY"

[ -z "$DOCKER_HOST" ] &&
DOCKER_PARAMS="-H unix:///var/run/docker.sock" || DOCKER_PARAMS="-H $DOCKER_HOST"
[ -z "$SILENT" ] && echo "Docker parameters: $DOCKER_PARAMS"

[ -z "$SILENT" ] && echo "Check whether the image exists on the docker host"
IMAGE_ID=( $( docker "$DOCKER_PARAMS" images --all --quiet "$DOCKER_REPOSITORY" ) )
if [ -z "$IMAGE_ID" ]
then
  [ -z "$SILENT" ] && echo "The $DOCKER_REPOSITORY image does not exist on the docker host";
  [ -z "$SILENT" ] && echo "Pulling: $DOCKER_REPOSITORY";
  docker "$DOCKER_PARAMS" pull "$DOCKER_REPOSITORY" && (
    [ -z "$SILENT" ] && echo "Found image of $DOCKER_REPOSITORY on dockerhub";
    createContainerAndCheckoutBranchIfNeeded;
  ) || (
    [ -z "$SILENT" ] && echo "Didn't find image $DOCKER_REPOSITORY on dockerhub. Building active branch: $NWJS_BRANCH";
    buildImageAndStartContainer;
  )
else
  IMAGE_ID="${IMAGE_ID[0]}";
  [ -z "$SILENT" ] && echo "Found image with id: $IMAGE_ID locally";
  createContainerAndCheckoutBranchIfNeeded;
fi

[ -z "$SILENT" ] && echo "Container created successfully. Id: $CONTAINER_ID"

# Print the disk usage of docker.
# [ -z "$SILENT" ] && docker "$DOCKER_PARAMS" system df

[ -n "$CLEAN_DOCKER" ] && [ -z "$SILENT" ] && echo "Clean the unused docker objects"
[ -n "$CLEAN_DOCKER" ] && docker "$DOCKER_PARAMS" system prune --force

[ -z "$SILENT" ] && echo "Start building $NWJS_BRANCH"
docker "$DOCKER_PARAMS" exec --interactive --tty "$CONTAINER_ID" /usr/docker/build-nwjs.sh
ARCHIVE_NAME="$NWJS_BRANCH"_$(date +"%Y-%m-%d_%T").tar.gz
[ -z "$SILENT" ] && echo "Create $ARCHIVE_NAME archive"
docker "$DOCKER_PARAMS" exec --interactive --tty "$CONTAINER_ID" tar -zcvf "$ARCHIVE_NAME" /usr/docker/dist/*
mkdir -p binaries
[ -z "$SILENT" ] && echo "Copy artifact $ARCHIVE_NAME from container to host"
docker "$DOCKER_PARAMS" cp "$CONTAINER_ID":/usr/docker/"$ARCHIVE_NAME" ./binaries/
[ -z "$SILENT" ] && echo "Artifact $ARCHIVE_NAME copied successfully"
[ -z "$SILENT" ] && echo "Stop container $CONTAINER_ID"
docker "$DOCKER_PARAMS" stop "$CONTAINER_ID"

# TODO remove the container if needed.
# TODO upload to github releases.

#!/bin/bash

set -e

export RED='\033[0;31m'
export CYAN="\033[0;36m"
export NC='\033[0m' # No Color
export GITHUB_REPO="LeonardLaszlo/nw.js-armv7-binaries"
export DOCKER_REPOSITORY="laslaul/nwjs-arm-build-env"
export DOCKER_PARAMS="-H unix:///var/run/docker.sock"

function log {
  [ -z "$SILENT" ] && echo -e "${CYAN}$1${NC}"
}

function error {
  [ -z "$SILENT" ] && echo -e "${RED}$1${NC}" >&2
  exit 1
}

log "TODO install curl, python, docker if needed"
log "Start parsing parameters"

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
        error "Argument for $1 is missing"
      fi
      ;;
    -h|--docker-host)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        DOCKER_HOST="$2"
        shift 2
      else
        error "Argument for $1 is missing"
      fi
      ;;
    -r|--docker-repository)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        DOCKER_REPOSITORY="$2"
        shift 2
      else
        error "Argument for $1 is missing"
      fi
      ;;
    -*|--*=) # unsupported flags
      error "Unsupported flag $1"
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

log "Set positional arguments in their proper place"
eval set -- "$PARAMS"
log "Done parsing parameters"

[ -z "$NWJS_BRANCH" ] && echo "Get the active branch from the official repo" &&
NWJS_BRANCH="$( curl --silent --no-buffer https://api.github.com/repos/nwjs/nw.js \
  | python -c 'import sys, json; print(json.load(sys.stdin)["default_branch"])' )"
log "NW.js active branch: $NWJS_BRANCH"

log "Docker repository: $DOCKER_REPOSITORY"

[ -n "$DOCKER_HOST" ] && DOCKER_PARAMS="-H $DOCKER_HOST"
log "Docker parameters: $DOCKER_PARAMS"

function createContainerAndCheckoutBranchIfNeeded {
  log "Start a container from the $DOCKER_REPOSITORY image"
  CONTAINER_ID=$( docker "$DOCKER_PARAMS" run --detach --tty "$DOCKER_REPOSITORY" )
  log "Read the checked out branch, from inside of the container"
  CURRENT_BRANCH="$( docker "$DOCKER_PARAMS" exec -t "$CONTAINER_ID" \
    bash -c 'cd /usr/docker/nwjs/src && git show-branch | cut -d "[" -f2 | cut -d "]" -f1' | tr -d '[:space:]' )"
  log "Checked out branch in the container is --$CURRENT_BRANCH-- and the desired branch is --$NWJS_BRANCH--"
  log "Needed to match regex because equality checks fails here. Weird enough to waste some hours on this"
  if [[ ! "$CURRENT_BRANCH" =~ "$NWJS_BRANCH" ]]; then
    log "Checking out $NWJS_BRANCH branch"
    docker "$DOCKER_PARAMS" exec --interactive --tty "$CONTAINER_ID" /usr/docker/checkout-another-branch.sh "$NWJS_BRANCH"
    [ -n "$UPLOAD_IMAGE"] && log "Commit $CONTAINER_ID to $DOCKER_REPOSITORY:$NWJS_BRANCH"
    [ -n "$UPLOAD_IMAGE"] && docker "$DOCKER_PARAMS" commit "$CONTAINER_ID" "$DOCKER_REPOSITORY":"$NWJS_BRANCH"
    [ -n "$UPLOAD_IMAGE"] && log "Push $DOCKER_REPOSITORY:$NWJS_BRANCH to docker hub"
    [ -n "$UPLOAD_IMAGE"] && docker "$DOCKER_PARAMS" push "$DOCKER_REPOSITORY":"$NWJS_BRANCH"
  fi
}

function buildImageAndStartContainer {
  log "Start building $DOCKER_REPOSITORY image"
  docker "$DOCKER_PARAMS" image build --build-arg NWJS_BRANCH="$NWJS_BRANCH" --tag "$DOCKER_REPOSITORY":"$NWJS_BRANCH" .
  [ -n "$UPLOAD_IMAGE"] && log "Push $DOCKER_REPOSITORY:$NWJS_BRANCH to docker hub"
  [ -n "$UPLOAD_IMAGE"] && docker "$DOCKER_PARAMS" push "$DOCKER_REPOSITORY":"$NWJS_BRANCH"
  log "Start a container from the $DOCKER_REPOSITORY image"
  CONTAINER_ID=$( docker "$DOCKER_PARAMS" run --detach --tty "$DOCKER_REPOSITORY" )
}

function startContainer {
  log "Check whether the image exists on the docker host"
  IMAGE_ID=( $( docker "$DOCKER_PARAMS" images --all --quiet "$DOCKER_REPOSITORY" ) )
  if [ -z "$IMAGE_ID" ]
  then
    log "The $DOCKER_REPOSITORY image does not exist on the docker host";
    log "Pulling: $DOCKER_REPOSITORY";
    docker "$DOCKER_PARAMS" pull "$DOCKER_REPOSITORY" && (
      log "Found image of $DOCKER_REPOSITORY on dockerhub";
      createContainerAndCheckoutBranchIfNeeded;
    ) || (
      log "Didn't find image $DOCKER_REPOSITORY on dockerhub. Building active branch: $NWJS_BRANCH";
      buildImageAndStartContainer;
    )
  else
    IMAGE_ID="${IMAGE_ID[0]}";
    log "Found image with id: $IMAGE_ID locally";
    createContainerAndCheckoutBranchIfNeeded;
  fi

  log "Container created successfully. Id: $CONTAINER_ID"
}

function buildNwjs {
  log "Start building $NWJS_BRANCH"
  docker "$DOCKER_PARAMS" exec --interactive --tty "$CONTAINER_ID" /usr/docker/build-nwjs.sh
  ARCHIVE_NAME='${NWJS_BRANCH}_$(date +"%Y-%m-%d).tar.gz'
  log "Create $ARCHIVE_NAME archive"
  docker "$DOCKER_PARAMS" exec --interactive --tty "$CONTAINER_ID" sh -c "tar --force-local -zcvf ${ARCHIVE_NAME} /usr/docker/dist/*"
  mkdir -p binaries
  log "Copy artifact $ARCHIVE_NAME from container to host"
  docker "$DOCKER_PARAMS" cp "$CONTAINER_ID":/usr/docker/"$ARCHIVE_NAME" ./binaries/
  log "Artifact $ARCHIVE_NAME copied successfully"
}

function cleanDocker {
  if [ -n "$CLEAN_DOCKER" ]; then
    [ -z "$SILENT" ] && docker "$DOCKER_PARAMS" system df
    log "Clean the unused docker objects"
    docker "$DOCKER_PARAMS" system prune --force
    [ -z "$SILENT" ] && docker "$DOCKER_PARAMS" system df
  fi
}

function stopContainer {
  log "Stop container $CONTAINER_ID"
  docker "$DOCKER_PARAMS" stop "$CONTAINER_ID"
}

function releaseOnGithub {
  FILE=$(basename -- "$1")
  FILE_NAME=${FILE%%.*}
  ACCESS_TOKEN=$(cat .github-token)
  if [ -n "$ACCESS_TOKEN" ]; then
    RELEASE_JSON="{\"tag_name\": \"$FILE_NAME\",\"name\": \"$FILE_NAME\"}"
    log "Create release $FILE_NAME"
    CREATE_RELEASE_RESULT=$(curl -s -H "Authorization: token $ACCESS_TOKEN" --data "$RELEASE_JSON" \
      $"https://api.github.com/repos/$GITHUB_REPO/releases")
    log "$CREATE_RELEASE_RESULT"
    RELEASE_ID="$( echo $CREATE_RELEASE_RESULT | python -c "import sys, json; print json.load(sys.stdin)['id']")"
    log "Uploading artifact $FILE"
    UPLOAD_ARTIFACT_RESULT=$(curl -s -H "Authorization: token $ACCESS_TOKEN" \
      -H "Content-Type: $(file -b --mime-type binaries/$FILE)" \
      --data-binary @binaries/$FILE \
      "https://uploads.github.com/repos/$GITHUB_REPO/releases/$RELEASE_ID/assets?name=$FILE")
    log "$UPLOAD_ARTIFACT_RESULT"
  fi
}

startContainer
cleanDocker
buildNwjs
stopContainer
[ -n "$ARCHIVE_NAME" ] && releaseOnGithub "$ARCHIVE_NAME"
cleanDocker

#!/bin/bash

set -e

export RED='\033[0;31m'
export CYAN="\033[0;36m"
export NC='\033[0m' # No Color
export GITHUB_REPO="LeonardLaszlo/nw.js-armv7-binaries"
export DOCKER_REPOSITORY="laslaul/nwjs-arm-build-env"
export DOCKER_PARAMS="-H unix:///var/run/docker.sock"

function log {
  [ -z "$SILENT" ] && echo -e "$(date +"%Y-%m-%d %H:%M:%S") ${CYAN}$1${NC}"
}

function error {
  [ -z "$SILENT" ] && echo -e "$(date +"%Y-%m-%d %H:%M:%S") ${RED}$1${NC}" >&2
  exit 1
}

log "TODO install curl, python, docker if needed"
log "Start parsing parameters"

PARAMS=""

while (( "$#" )); do
  case "$1" in
    --silent)
      SILENT="true"
      shift
      ;;
    --commit-image)
      COMMIT_IMAGE="true"
      shift
      ;;
    --docker-image-build-only)
      DOCKER_IMAGE_BUILD_ONLY="true"
      shift
      ;;
    --upload-image)
      UPLOAD_IMAGE="true"
      shift
      ;;
    --clean-docker)
      CLEAN_DOCKER="true"
      shift
      ;;
    --branch)
      if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
        NWJS_BRANCH="$2"
        shift 2
      else
        error "Argument for $1 is missing"
      fi
      ;;
    --github-token)
      if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
        GITHUB_TOKEN="$2"
        shift 2
      else
        error "Argument for $1 is missing"
      fi
      ;;
    --docker-container)
      if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
        CONTAINER_ID="$2"
        shift 2
      else
        error "Argument for $1 is missing"
      fi
      ;;
    --docker-host)
      if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
        DOCKER_HOST="$2"
        shift 2
      else
        error "Argument for $1 is missing"
      fi
      ;;
    --docker-repository)
      if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
        DOCKER_REPOSITORY="$2"
        shift 2
      else
        error "Argument for $1 is missing"
      fi
      ;;
    --*=|-*) # unsupported flags
      error "Unsupported flag $1"
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

log "Set positional arguments in their place"
eval set -- "$PARAMS"
log "Done parsing parameters"

if [ -z "$NWJS_BRANCH" ]; then
  log "Get the active branch from the official repo"
  NWJS_BRANCH="$( curl --silent --no-buffer https://api.github.com/repos/nwjs/nw.js \
    | python -c 'import sys, json; print(json.load(sys.stdin)["default_branch"])' )"
fi

if [ -z "$GITHUB_TOKEN" ]; then
  GITHUB_TOKEN=$(cat .github-token)
fi

if [ -n "$DOCKER_HOST" ]; then
  DOCKER_PARAMS="-H $DOCKER_HOST"
fi

log "NW.js active branch: $NWJS_BRANCH"
log "Docker repository: $DOCKER_REPOSITORY"
log "Docker parameters: $DOCKER_PARAMS"

function buildImage {
  IMAGE_TAG="$DOCKER_REPOSITORY:$NWJS_BRANCH"
  log "Start building $IMAGE_TAG"
  docker "$DOCKER_PARAMS" image build --build-arg NWJS_BRANCH="$NWJS_BRANCH" --tag "$IMAGE_TAG" .
  log "Building $IMAGE_TAG was successful"
}

function prepareImage {
  log "Check whether the image exists on the docker host"
  IMAGE_IDS=()
  while IFS="" read -r line; do IMAGE_IDS+=("$line"); done < \
    <(docker "$DOCKER_PARAMS" images --all --quiet "$DOCKER_REPOSITORY")
  if [ "${#IMAGE_IDS[@]}" -gt 0 ]; then
    # IMAGE_ID is basically used for the following log only
    # The actual image to be used will be either the one marked with the branch name as tag or the "latest" tag.
    IMAGE_ID="${IMAGE_IDS[0]}"
    log "Found image with id: $IMAGE_ID locally"
  else
    log "The $DOCKER_REPOSITORY image does not exist on the docker host. Pulling: $DOCKER_REPOSITORY";
    if docker "$DOCKER_PARAMS" pull "$DOCKER_REPOSITORY"; then
      log "Found image of $DOCKER_REPOSITORY on dockerhub"
    else
      log "Didn't find image $DOCKER_REPOSITORY on dockerhub. Building active branch: $NWJS_BRANCH"
      buildImage
    fi
  fi
}

function runContainer {
  log "Start a container from the $DOCKER_REPOSITORY image"
  CONTAINER_ID=$(docker "$DOCKER_PARAMS" run --detach --tty "$DOCKER_REPOSITORY")
  log "Container created successfully. Id: $CONTAINER_ID"
}

function cleanDockerIfNeeded {
  if [ -n "$CLEAN_DOCKER" ]; then
    [ -z "$SILENT" ] && docker "$DOCKER_PARAMS" system df
    log "Clean the unused docker objects"
    docker "$DOCKER_PARAMS" stop "$(docker "$DOCKER_PARAMS" ps -aq --filter "ancestor=$DOCKER_REPOSITORY")"
    docker "$DOCKER_PARAMS" rm "$(docker "$DOCKER_PARAMS" ps -aq --filter "ancestor=$DOCKER_REPOSITORY")"
    [ -z "$SILENT" ] && docker "$DOCKER_PARAMS" system df
  fi
}

function commitImageIfNeeded {
  if [ -n "$UPLOAD_IMAGE" ] || [ -n "$COMMIT_IMAGE" ]; then
    log "Commit $CONTAINER_ID to $DOCKER_REPOSITORY:$NWJS_BRANCH"
    docker "$DOCKER_PARAMS" commit "$CONTAINER_ID" "$DOCKER_REPOSITORY:$NWJS_BRANCH"
    log "Committed $CONTAINER_ID to $DOCKER_REPOSITORY:$NWJS_BRANCH successfully"
  fi
}

function pushImageToDockerHubIfNeeded {
  if [ -n "$UPLOAD_IMAGE" ]; then
    log "Push $DOCKER_REPOSITORY:$NWJS_BRANCH to docker hub"
    docker "$DOCKER_PARAMS" push "$DOCKER_REPOSITORY:$NWJS_BRANCH"
    log "Pushed $DOCKER_REPOSITORY:$NWJS_BRANCH to docker hub"
  fi
}

function buildNwjs {
  ARCH="$1"
  case "$ARCH" in
    arm32)
      ARCHIVE_NAME=${NWJS_BRANCH}_$(date +"%Y-%m-%d").tar.gz
      ;;
    arm64)
      ARCHIVE_NAME=${NWJS_BRANCH}-arm64_$(date +"%Y-%m-%d").tar.gz
      ;;
    *)
      error "Unsupported arch: $ARCH"
      exit 1;
      ;;
  esac
  log "Start building $ARCHIVE_NAME"
  log "Updating branch $NWJS_BRANCH"
  docker "$DOCKER_PARAMS" cp checkout-branch.sh "$CONTAINER_ID":/usr/docker
  docker "$DOCKER_PARAMS" exec --interactive --tty "$CONTAINER_ID" /usr/docker/checkout-branch.sh "$NWJS_BRANCH"
  log "Finished updating branch"
  commitImageIfNeeded
  pushImageToDockerHubIfNeeded
  log "Start building $NWJS_BRANCH"
  docker "$DOCKER_PARAMS" cp build-nwjs.sh "$CONTAINER_ID":/usr/docker
  docker "$DOCKER_PARAMS" exec --interactive --tty "$CONTAINER_ID" /usr/docker/build-nwjs.sh "$NWJS_BRANCH" "$ARCH"
  log "Building $NWJS_BRANCH was successful"
  log "Create $ARCHIVE_NAME archive"
  docker "$DOCKER_PARAMS" exec --interactive --tty "$CONTAINER_ID" \
    sh -c "tar --force-local -zcvf ${ARCHIVE_NAME} /usr/docker/dist/*"
  mkdir -p binaries
  log "Copy artifact $ARCHIVE_NAME from container to host"
  docker "$DOCKER_PARAMS" cp "$CONTAINER_ID":/usr/docker/"$ARCHIVE_NAME" ./binaries/
  log "Artifact $ARCHIVE_NAME copied successfully"
  if [ -n "$ARCHIVE_NAME" ] && [ -n "$GITHUB_TOKEN" ]; then
    releaseOnGithub "$ARCHIVE_NAME"
  fi
}

function stopContainer {
  log "Stop container $CONTAINER_ID"
  docker "$DOCKER_PARAMS" stop "$CONTAINER_ID"
}

function releaseOnGithub {
  FILE=$(basename -- "$1")
  FILE_NAME=${FILE%%.*}
  RELEASE_JSON="{\"tag_name\": \"$FILE_NAME\",\"name\": \"$FILE_NAME\"}"
  log "Create release $FILE_NAME"
  CREATE_RELEASE_RESULT=$(curl -s -H "Authorization: token $GITHUB_TOKEN" --data "$RELEASE_JSON" \
    $"https://api.github.com/repos/$GITHUB_REPO/releases")
  log "$CREATE_RELEASE_RESULT"
  RELEASE_ID="$( echo "$CREATE_RELEASE_RESULT" | python -c "import sys, json; print json.load(sys.stdin)['id']")"
  log "Uploading artifact $FILE"
  UPLOAD_ARTIFACT_RESULT=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    -H "Content-Type: $(file -b --mime-type binaries/"$FILE")" \
    --data-binary @binaries/"$FILE" \
    "https://uploads.github.com/repos/$GITHUB_REPO/releases/$RELEASE_ID/assets?name=$FILE")
  log "$UPLOAD_ARTIFACT_RESULT"
}

if [ -n "$DOCKER_IMAGE_BUILD_ONLY" ]; then
  log "Only docker image build was chosen. Building image from branch: $NWJS_BRANCH"
  buildImage
  pushImageToDockerHubIfNeeded
  log "Done building image from branch: $NWJS_BRANCH"
  exit 0
fi

if [ -z "$CONTAINER_ID" ]; then
  prepareImage
  runContainer
else
  log "Starting container $CONTAINER_ID"
  docker "$DOCKER_PARAMS" start "$CONTAINER_ID"
fi
cleanDockerIfNeeded
buildNwjs arm32
buildNwjs arm64
stopContainer
cleanDockerIfNeeded

#!/bin/bash

set -e

export NWJS_BRANCH="$1"
export WORKDIR="/usr/docker"
export NWJSDIR="${WORKDIR}/nwjs"
export DEPOT_TOOLS_DIRECTORY="${WORKDIR}/depot_tools"
export PATH=${PATH}:${DEPOT_TOOLS_DIRECTORY}

export DEPOT_TOOLS_REPO="https://chromium.googlesource.com/chromium/tools/depot_tools.git"

export RED='\033[0;31m'
export NC='\033[0m' # No Color

function getNecessaryUbuntuPackages {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get -y upgrade
  apt-get -y install apt-utils git curl lsb-release sudo tzdata nano
  echo "Europe/Zurich" > /etc/timezone
  dpkg-reconfigure -f noninteractive tzdata
  apt-get -y install python python-setuptools
  apt-get autoclean
  apt-get autoremove
  git config --global user.email "you@example.com"
  git config --global user.name "Your Name"
}

function getDepotTools {
  git clone --depth 1 "$DEPOT_TOOLS_REPO" "$DEPOT_TOOLS_DIRECTORY"
}

[ -z "$NWJS_BRANCH" ] && exit 1
echo -e "${RED}Building docker image for branch: $NWJS_BRANCH${NC}"
getNecessaryUbuntuPackages
getDepotTools
./checkout-branch.sh "$NWJS_BRANCH"
echo -e "${RED}Finished building docker image from branch: $NWJS_BRANCH${NC}"

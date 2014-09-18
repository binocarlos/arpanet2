#!/usr/bin/env bash
set -eo pipefail
export DEBIAN_FRONTEND=noninteractive
export ARPANET_REPO=${ARPANET_REPO:-"https://github.com/binocarlos/arpanet.git"}

if ! which apt-get &>/dev/null
then
  echo "This installation script requires apt-get. For manual installation instructions, consult https://github.com/binocarlos/arpanet ."
  exit 1
fi

apt-get update
apt-get install -y git make curl

cd ~ && test -d arpanet || git clone $ARPANET_REPO
cd arpanet
git fetch origin
git pull
make install
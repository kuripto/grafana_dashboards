#!/bin/bash

# This script syncs the grafana dashboards from the grafana server to the local copy of this repo.
# It is intended to be run from the root of the repo.

DASHBOARD_FOLDER=${DASHBOARD_FOLDER:-aptos-core}
GRAFANA_URL=${GRAFANA_URL:-https://o11y.aptosdev.com}
LOCAL_DASHBOARD_FOLDER=${LOCAL_DASHBOARD_FOLDER:-"./dashboards"}

### Install grafana-sync tool
if ! command -v grafana-sync &>/dev/null; then
    echo "grafana-sync could not be found"
    echo "installing..."
    wget https://github.com/mpostument/grafana-sync/releases/download/1.4.10/grafana-sync_1.4.10_Linux_64bit.tar.gz -O grafana-sync.tar.gz
    sha=$(shasum -a 256 grafana-sync.tar.gz | awk '{ print $1 }')
    [ "$sha" != "722bdd1d81fe221812c1c140e6a14320246d52fb4483ad2f73cab1b10f277996" ] && echo "shasum mismatch" && exit 1
    tar -xvf grafana-sync.tar.gz grafana-sync
    chmod +x grafana-sync
    export PATH="${PATH}:$(pwd)"
fi

## Pull dashboards from grafana from the specified folder
rm -rf "${LOCAL_DASHBOARD_FOLDER}/*.json"
rm -rf "${LOCAL_DASHBOARD_FOLDER}/*.json.gz"
mkdir -p "${LOCAL_DASHBOARD_FOLDER}"
grafana-sync pull-dashboards --apikey="${GRAFANA_API_KEY}" --directory="${LOCAL_DASHBOARD_FOLDER}" --url="${GRAFANA_URL}" --folderName="${DASHBOARD_FOLDER}"
ret=$?
if [ $ret -ne 0 ]; then
    echo "Failed to pull dashboards from grafana"
    exit $ret
fi

## Reformat dashboards to be more readable
npx --yes prettier@2.7.1 --write "${LOCAL_DASHBOARD_FOLDER}"

## Compress
gzip -fkn ${LOCAL_DASHBOARD_FOLDER}/*.json

## Check dashboards changes in the dashboards directory
git status dashboards
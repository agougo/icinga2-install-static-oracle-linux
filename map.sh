#!/bin/bash

set -euo pipefail
trap 'echo "Error on line $LINENO: $BASH_COMMAND" >&2' ERR

cd ~
cd icinga2prodinstallation

ICINGAWEB_MODULEPATH="/usr/share/icingaweb2/modules"
REPO_URL="https://github.com/nbuchwitz/icingaweb2-module-map"
TARGET_DIR="${ICINGAWEB_MODULEPATH}/map"
git clone "${REPO_URL}" "${TARGET_DIR}"

icingacli module enable map

cd /usr/share/icingaweb2/modules
git clone https://github.com/nbuchwitz/icingaweb2-module-mapDatatype.git mapDatatype

icingacli module enable mapDatatype

cd ~
cd icinga2prodinstallation
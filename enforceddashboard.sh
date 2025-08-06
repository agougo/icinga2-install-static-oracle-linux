#!/bin/bash

set -euo pipefail
trap 'echo "Error on line $LINENO: $BASH_COMMAND" >&2' ERR

cd ~
cd icinga2prodinstallation

cd /usr/share/icingaweb2/modules
git clone https://github.com/Thomas-Gelf/icingaweb2-module-enforceddashboard.git enforceddashboard

icingacli module enable enforceddashboard

cd ~
cd icinga2prodinstallation
#!/bin/bash

set -euo pipefail
trap 'echo "Error on line $LINENO: $BASH_COMMAND" >&2' ERR

cd ~
cd icinga2prodinstallation

cp -R themes/antonis /usr/share/icingaweb2/modules

icingacli module enable antonis

cd ~
cd icinga2prodinstallation

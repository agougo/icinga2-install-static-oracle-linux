#!/bin/bash

set -euo pipefail
trap 'echo "Error on line $LINENO: $BASH_COMMAND" >&2' ERR

cd ~
cd icinga2prodinstallation

cd /usr/share/icingaweb2/modules
git clone https://github.com/Icinga/icingaweb2-module-pdfexport.git pdfexport

icingacli module enable pdfexport

cd ~
cd icinga2prodinstallation
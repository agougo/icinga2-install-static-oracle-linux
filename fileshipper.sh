#!/bin/bash

set -euo pipefail
trap 'echo "Error on line $LINENO: $BASH_COMMAND" >&2' ERR

cd ~
cd icinga2prodinstallation

cd /usr/share/icingaweb2/modules
git clone https://github.com/Icinga/icingaweb2-module-fileshipper.git fileshipper

icingacli module enable fileshipper

mkdir /etc/icingaweb2/modules/fileshipper
cd /etc/icingaweb2/modules/fileshipper

touch imports.ini
echo "[CSV Files]" >> /etc/icingaweb2/modules/fileshipper/imports.ini
echo "basedir = \"/usr/local/share/\"" >> /etc/icingaweb2/modules/fileshipper/imports.ini

cd ~
cd icinga2prodinstallation
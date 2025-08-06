#!/bin/bash

set -euo pipefail
trap 'echo "Error on line $LINENO: $BASH_COMMAND" >&2' ERR

cd ~
cd icinga2prodinstallation

mkdir /etc/icingaweb2/modules/audit
chown apache.icingaweb2 /etc/icingaweb2/modules/audit
touch /etc/icingaweb2/modules/audit/config.ini
chown apache.icingaweb2 /etc/icingaweb2/modules/audit/config.ini
chmod 0660 /etc/icingaweb2/modules/audit/config.ini

echo "[log]" >> /etc/icingaweb2/modules/audit/config.ini
echo "type = "file"" >> /etc/icingaweb2/modules/audit/config.ini
echo -e "\n" >> /etc/icingaweb2/modules/audit/config.ini
echo "[stream]" >> /etc/icingaweb2/modules/audit/config.ini
echo "format = "none"" >> /etc/icingaweb2/modules/audit/config.ini

cd /usr/share/icingaweb2/modules
git clone https://github.com/Icinga/icingaweb2-module-audit.git audit

icingacli module enable audit

cd ~
cd icinga2prodinstallation

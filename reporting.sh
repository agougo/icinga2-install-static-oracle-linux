#!/bin/bash

set -euo pipefail
trap 'echo "Error on line $LINENO: $BASH_COMMAND" >&2' ERR

cd ~
cd icinga2prodinstallation

cd /tmp
sudo -u postgres psql -c "CREATE USER reporting WITH PASSWORD 'reporting';"
sudo -u postgres psql -c "CREATE DATABASE reporting WITH OWNER reporting ENCODING 'UTF8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE reporting TO reporting;"

cd /usr/share/icingaweb2/modules
git clone https://github.com/Icinga/icingaweb2-module-reporting.git reporting

export PGPASSWORD=reporting
psql -U reporting -d reporting < /usr/share/icingaweb2/modules/reporting/schema/pgsql.schema.sql
 
icingacli module enable reporting

# Automate Reporting

echo -e "\n" >> /etc/icingaweb2/resources.ini
echo "[reporting]" >> /etc/icingaweb2/resources.ini
echo "type = \"db\"" >> /etc/icingaweb2/resources.ini
echo "db = \"pgsql\"" >> /etc/icingaweb2/resources.ini
echo "host = \"localhost\"" >> /etc/icingaweb2/resources.ini
echo "port = \"5432\"" >> /etc/icingaweb2/resources.ini
echo "dbname = \"reporting\"" >> /etc/icingaweb2/resources.ini
echo "username = \"reporting\"" >> /etc/icingaweb2/resources.ini
echo "password = \"reporting\"" >> /etc/icingaweb2/resources.ini
echo "charset = \"utf8\"" >> /etc/icingaweb2/resources.ini
echo "use_ssl = \"0\"" >> /etc/icingaweb2/resources.ini

mkdir /etc/icingaweb2/modules/reporting

touch /etc/icingaweb2/modules/reporting/config.ini
echo -e "[backend]" >> /etc/icingaweb2/modules/reporting/config.ini
echo -e "resource = \"reporting\"" >> /etc/icingaweb2/modules/reporting/config.ini

cd ~
cd icinga2prodinstallation

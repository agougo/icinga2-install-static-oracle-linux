#!/bin/bash

set -euo pipefail
trap 'echo "Error on line $LINENO: $BASH_COMMAND" >&2' ERR

cd ~
cd icinga2prodinstallation

dnf install icinga-x509 -y

cd /tmp
sudo -u postgres psql -c "CREATE USER x509 WITH PASSWORD 'x509';"
sudo -u postgres psql -c "CREATE DATABASE x509 WITH OWNER x509 ENCODING 'UTF8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE x509 TO x509;"

export PGPASSWORD=x509
psql -U x509 -d x509 < /usr/share/icingaweb2/modules/x509/schema/pgsql.schema.sql

# x509 automation
echo -e "\n" >> /etc/icingaweb2/resources.ini
echo "[x509]" >> /etc/icingaweb2/resources.ini
echo "type = \"db\"" >> /etc/icingaweb2/resources.ini
echo "db = \"pgsql\"" >> /etc/icingaweb2/resources.ini
echo "host = \"localhost\"" >> /etc/icingaweb2/resources.ini
echo "port = \"5432\"" >> /etc/icingaweb2/resources.ini
echo "dbname = \"x509\"" >> /etc/icingaweb2/resources.ini
echo "username = \"x509\"" >> /etc/icingaweb2/resources.ini
echo "password = \"x509\"" >> /etc/icingaweb2/resources.ini
echo "charset = \"utf8\"" >> /etc/icingaweb2/resources.ini
echo "use_ssl = \"0\"" >> /etc/icingaweb2/resources.ini

mkdir /etc/icingaweb2/modules/x509

touch /etc/icingaweb2/modules/x509/config.ini
echo -e "[backend]" >> /etc/icingaweb2/modules/x509/config.ini
echo -e "resource = \"x509\"" >> /etc/icingaweb2/modules/x509/config.ini

icingacli module enable x509

cd ~
cd icinga2prodinstallation

#!/bin/bash

cd ~
cd icinga2prodinstallation/director

dnf -y install git postgresql-contrib php-pcntl php-process php-sockets

# DEPRECATED
# chmod +x ipl.sh
# ./ipl.sh

chmod +x incubator.sh
./incubator.sh

# DEPRECATED
# chmod +x reactbundle.sh
# ./reactbundle.sh

#rm /usr/share/icinga-php/ipl -f -r
#chmod +x icinga-php-library.sh
#./icinga-php-library.sh

#rm /usr/share/icinga-php/vendor -f -r
#chmod +x icinga-php-thirdparty.sh
#./icinga-php-thirdparty.sh

# PostgreSQL Config
su - postgres -c "psql -U postgres -c \"CREATE DATABASE director WITH ENCODING 'UTF8';\""
su - postgres -c "psql -U postgres -c \"CREATE USER director WITH PASSWORD 'director';\""
su - postgres -c "psql -U postgres -d director -c \"GRANT ALL PRIVILEGES ON DATABASE director TO director;\""
su - postgres -c "psql -U postgres -d director -c \"GRANT CREATE ON SCHEMA public TO director;\""
su - postgres -c "psql -U postgres -d director -c \"CREATE EXTENSION pgcrypto;\""

cd ..

ICINGAWEB_MODULEPATH="/usr/share/icingaweb2/modules"
REPO_URL="https://github.com/icinga/icingaweb2-module-director"
TARGET_DIR="${ICINGAWEB_MODULEPATH}/director"
MODULE_VERSION="1.11.1"

git clone "${REPO_URL}" "${TARGET_DIR}" --branch v${MODULE_VERSION}
icingacli module enable director

# Director Automation

echo -e "\n" >> /etc/icingaweb2/resources.ini
echo "[director]" >> /etc/icingaweb2/resources.ini
echo "type = \"db\"" >> /etc/icingaweb2/resources.ini
echo "db = \"pgsql\"" >> /etc/icingaweb2/resources.ini
echo "host = \"localhost\"" >> /etc/icingaweb2/resources.ini
echo "port = \"5432\"" >> /etc/icingaweb2/resources.ini
echo "dbname = \"director\"" >> /etc/icingaweb2/resources.ini
echo "username = \"director\"" >> /etc/icingaweb2/resources.ini
echo "password = \"director\"" >> /etc/icingaweb2/resources.ini
echo "charset = \"utf8\"" >> /etc/icingaweb2/resources.ini
echo "use_ssl = \"0\"" >> /etc/icingaweb2/resources.ini

mkdir /etc/icingaweb2/modules/director

touch /etc/icingaweb2/modules/director/config.ini
echo -e "[db]" >> /etc/icingaweb2/modules/director/config.ini
echo -e "resource = \"director\"" >> /etc/icingaweb2/modules/director/config.ini

#Director as a Service

useradd -r -g icingaweb2 -d /var/lib/icingadirector -s /bin/false icingadirector
install -d -o icingadirector -g icingaweb2 -m 0750 /var/lib/icingadirector
 
MODULE_PATH=/usr/share/icingaweb2/modules/director
cp "${MODULE_PATH}/contrib/systemd/icinga-director.service" /etc/systemd/system/
 
systemctl daemon-reload
systemctl start icinga-director.service
systemctl enable icinga-director.service

icingacli director migration run --verbose

# Finish Message
read -r -s -p $'\nMake sure the director is properly configured in Icingaweb2...\n\n'

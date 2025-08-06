#!/bin/bash

set -euo pipefail
trap 'echo "Error on line $LINENO: $BASH_COMMAND" >&2' ERR

cd ~

# Get InfluxDB 1.8.10
wget https://dl.influxdata.com/influxdb/releases/influxdb-1.8.10.x86_64.rpm
dnf localinstall influxdb-1.8.10.x86_64.rpm -y

systemctl restart influxdb

cd icinga2prodinstallation

# Install Latest Grafana
cp grafana/grafana.repo /etc/yum.repos.d/grafana.repo
dnf install -y grafana

systemctl daemon-reload
systemctl start grafana-server
systemctl enable grafana-server.service

icinga2 feature enable influxdb
systemctl restart icinga2

setsebool icinga2_can_connect_all true
setsebool -P icinga2_can_connect_all true
systemctl restart icinga2

sed -i 's|//host = "127.0.0.1"|host = "127.0.0.1"|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//port = 8086|port = 8086|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//database = "icinga2"|database = "icinga"|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//flush_threshold = 1024|flush_threshold = 1024|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//flush_interval = 10s|flush_interval = 10s|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//host_template = {|host_template = {|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//  measurement = "$host.check_command$"|  measurement = "$host.check_command$"|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//  tags = {|  tags = {|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//    hostname = "$host.name$"|    hostname = "$host.name$"|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//  }|  }|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//}|}|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//service_template = {|service_template = {|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//  measurement = "$service.check_command$"|  measurement = "$service.check_command$"|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//  tags = {|  tags = {|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//    hostname = "$host.name$"|    hostname = "$host.name$"|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//    service = "$service.name$"|    service = "$service.name$"|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//  }|  }|g' /etc/icinga2/features-available/influxdb.conf
sed -i 's|//}|}|g' /etc/icinga2/features-available/influxdb.conf

systemctl restart icinga2

influx -execute 'CREATE DATABASE icinga'
influx -execute 'SHOW DATABASES'
influx -database 'icinga' -execute 'CREATE USER icinga WITH PASSWORD '\'icinga\'' WITH ALL PRIVILEGES'
influx -execute 'show retention policies on "icinga"'
influx -execute 'create retention policy "icinga_2_weeks" on "icinga" duration 2w replication 1 default'
influx -execute 'alter retention policy "icinga_2_weeks" on "icinga" default'
influx -execute 'drop retention policy "autogen" on "icinga"'

systemctl restart influxdb

# Perfdatagraphs Module
git clone https://github.com/NETWAYS/icingaweb2-module-perfdatagraphs.git
mv icingaweb2-module-perfdatagraphs/ perfdatagraphs
mv perfdatagraphs/ /usr/share/icingaweb2/modules/
git clone https://github.com/NETWAYS/icingaweb2-module-perfdatagraphs-influxdbv1.git
mv icingaweb2-module-perfdatagraphs-influxdbv1/ perfdatagraphsinfluxdbv1
mv perfdatagraphsinfluxdbv1 /usr/share/icingaweb2/modules/

mkdir /etc/icingaweb2/modules/perfdatagraphs
touch /etc/icingaweb2/modules/perfdatagraphs/config.ini
chown apache:icingaweb2 /etc/icingaweb2/modules/perfdatagraphs/config.ini
echo "[perfdatagraphs]" >> /etc/icingaweb2/modules/perfdatagraphs/config.ini
echo "default_backend = \"InfluxDBv1\"" >> /etc/icingaweb2/modules/perfdatagraphs/config.ini

mkdir /etc/icingaweb2/modules/perfdatagraphsinfluxdbv1
touch /etc/icingaweb2/modules/perfdatagraphsinfluxdbv1/config.ini
chown apache:icingaweb2 /etc/icingaweb2/modules/perfdatagraphsinfluxdbv1/config.ini
echo "[influx]" >> /etc/icingaweb2/modules/perfdatagraphsinfluxdbv1/config.ini
echo "api_url = \"http://localhost:8086\"" >> /etc/icingaweb2/modules/perfdatagraphsinfluxdbv1/config.ini
echo "api_database = \"icinga\"" >> /etc/icingaweb2/modules/perfdatagraphsinfluxdbv1/config.ini
echo "api_tls_insecure = \"0\"" >> /etc/icingaweb2/modules/perfdatagraphsinfluxdbv1/config.ini

icingacli module enable perfdatagraphs
icingacli module enable perfdatagraphsinfluxdbv1

# TODO
#ICINGAWEB_MODULEPATH="/usr/share/icingaweb2/modules"
#REPO_URL="https://github.com/NETWAYS/icingaweb2-module-grafana"
#TARGET_DIR="${ICINGAWEB_MODULEPATH}/grafana"
#git clone "${REPO_URL}" "${TARGET_DIR}"

#icingacli module enable grafana

rm -f /etc/grafana/grafana.ini
cp grafana/grafana.ini /etc/grafana/grafana.ini
cp /etc/pki/tls/certs/httpd.crt /etc/grafana/httpd.crt
cp /etc/pki/tls/private/httpd.key /etc/grafana/httpd.key

cd /etc/grafana
chown grafana.grafana grafana.ini httpd.crt httpd.key
systemctl restart grafana-server.service

# Install a custom image renderer version
#grafana-cli --pluginUrl /var/lib/grafana/plugins/grafana-image-renderer-3.11.0.linux-amd64.zip plugins install grafana-image-renderer

grafana-cli plugins install grafana-image-renderer
dnf install -y libX11-xcb libXcomposite libXdamage libXtst nss libXScrnSaver alsa-lib atk-devel at-spi2-atk-devel pango-devel gtk3-devel
systemctl restart grafana-server.service

sleep 5

curl -k --user admin:admin 'https://localhost:3000/api/datasources' -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary '{"name":"InfluxDB","type":"influxdb","url":"http://localhost:8086","access":"proxy","isDefault":true,"database":"icinga","user":"icinga","password":"icinga"}'

sleep 5

cd ~
cd icinga2prodinstallation

# [TO REFINE]
# Bloody f***ing selinux - if you have it on enforcing like I do add these policies
curl -k https://localhost/icingaweb2/dashboard
ausearch -m avc | grep perfdatagraphs | audit2allow -M perfdatagraphs && sudo semodule -i perfdatagraphs.pp
curl -k https://localhost/icingaweb2/dashboard
ausearch -m avc | grep php-fpm | audit2allow -M php-fpm-icinga2 && sudo semodule -i php-fpm-icinga2.pp
curl -k https://localhost/icingaweb2/dashboard
ausearch -m avc | grep perfdatagraphsinfluxdbv1 | audit2allow -M perfdatagraphsinfluxdbv1 && sudo semodule -i perfdatagraphsinfluxdbv1.pp

# Finish Message
read -r -s -p $'\nIMPORTANT: NEXT STEPS: \n1) Verify the InfluxDB datasource in grafana \n2) Configure the Graphs Module if required. \n\nPress now enter to exit...\n\n'

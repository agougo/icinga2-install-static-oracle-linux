#!/bin/bash

cd ~

# Load OS info
. /etc/os-release

if [[ "$ID" == "ol" && "$PLATFORM_ID" == "platform:el9" ]]; then
    echo "Running on Oracle Linux 9.x Proceeding..."

set -euo pipefail
trap 'echo "Error on line $LINENO: $BASH_COMMAND" >&2' ERR

# Log in Insecure
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

# Firewall is UP
systemctl enable firewalld
systemctl start firewalld

# For Red Hat Linux install the required packages
#ARCH=$( /bin/arch )
#subscription-manager repos --enable rhel-9-for-x86_64-supplementary-rpms
#subscription-manager repos --enable "codeready-builder-for-rhel-9-${ARCH}-rpms"
#dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# For Oracle Linux install the required packages
dnf -y install 'dnf-command(config-manager)'
dnf -y config-manager --set-enabled ol9_codeready_builder
dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# Important
# ---
# Add the Icinga Repo - This will only work if you have your own Icinga2 Subscription
cp ~/icinga2prodinstallation/repo/ICINGA-release.repo /etc/yum.repos.d/ICINGA-release.repo
# ---

# Enable php v8.2 for Icingaweb2
dnf module list php
dnf module enable php:8.3 -y

# Install Icinga2, enable it to start on system boot and start the service
dnf -y install icinga2
systemctl enable icinga2
systemctl start icinga2

# Install the check plugins allowing Icinga2 to monitor a variety of different services
dnf -y install nagios-plugins-all

# Update the SELinux policy
dnf -y install icinga2-selinux

# Enable PostgreSQL 16
dnf module list postgresql
dnf module enable postgresql:16 -y

# Install PostgreSQL, initialize it, enable it on boot and start the database
dnf -y install postgresql-server postgresql
postgresql-setup --initdb --unit postgresql
systemctl enable postgresql
systemctl restart postgresql

# Modify DB Settings

cp icinga2prodinstallation/postgresql/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf

# Restart PostgreSQL for the changes to take effect
systemctl restart postgresql

# Install icingadb
dnf install icingadb postgresql-contrib -y
systemctl enable icingadb

# Create PostgreSQL stuff and import schema
cd /tmp
su - postgres -c "psql -U postgres -d postgres -c \"CREATE USER icingadb WITH PASSWORD 'icingadb';\""
sudo -u postgres createdb -E UTF8 --locale en_US.UTF-8 -T template0 -O icingadb icingadb
sudo -u postgres psql icingadb -c "CREATE EXTENSION IF NOT EXISTS citext;"

export PGPASSWORD=icingadb
psql -U icingadb -d icingadb < /usr/share/icingadb/schema/pgsql/schema.sql

cd ~
cd icinga2prodinstallation

# Configure icingadb
sed -i 's|#  type: mysql|  type: pgsql|g' /etc/icingadb/config.yml
sed -i 's|password: CHANGEME|password: icingadb|g' /etc/icingadb/config.yml

# To prepare the IcingaWeb2 installation, install and enable the Apache webserver
dnf -y install httpd
systemctl enable httpd
systemctl start httpd

# Set firewall rules
firewall-cmd --add-service=http
firewall-cmd --permanent --add-service=http
firewall-cmd --add-service=https
firewall-cmd --permanent --add-service=https
firewall-cmd --zone=public --permanent --add-port=22/tcp
firewall-cmd --zone=public --permanent --add-port=80/tcp
firewall-cmd --zone=public --permanent --add-port=443/tcp
firewall-cmd --zone=public --permanent --add-port=3000/tcp
firewall-cmd --zone=public --permanent --add-port=5665/tcp
firewall-cmd --reload

# Icinga2 REST API / API User
icinga2 api setup

echo -e "\n" >> /etc/icinga2/conf.d/api-users.conf
echo "object ApiUser \"icingaweb2\" {" >> /etc/icinga2/conf.d/api-users.conf
echo "  password = \"icingaweb2\" " >> /etc/icinga2/conf.d/api-users.conf
echo "  permissions = [ \"status/query\", \"actions/*\", \"objects/modify/*\", \"objects/query/*\" ]" >> /etc/icinga2/conf.d/api-users.conf
echo "}" >> /etc/icinga2/conf.d/api-users.conf

echo -e "\n" >> /etc/icinga2/conf.d/api-users.conf
echo "object ApiUser \"admin\" {" >> /etc/icinga2/conf.d/api-users.conf
echo "  password = \"admin\" " >> /etc/icinga2/conf.d/api-users.conf
echo "  permissions = [ \"*\" ]" >> /etc/icinga2/conf.d/api-users.conf
echo "}" >> /etc/icinga2/conf.d/api-users.conf

systemctl restart icinga2

# IcingaWeb2
dnf -y install php php-curl php-gettext php-intl php-mbstring php-openssl php-xml php-json
dnf -y install icingaweb2 icingacli
systemctl restart httpd

# Update the SELinux policy
dnf -y install icingaweb2-selinux

# Install icingadb-Web
dnf install icingadb-web -y

# Install Redis
dnf install icingadb-redis -y
systemctl enable icingadb-redis

systemctl restart icingadb-redis
systemctl restart icingadb

icinga2 feature enable icingadb
systemctl restart icinga2

icingacli module enable icingadb

# Create Token
icingacli setup token create

# Add your webserver's user to the "icingaweb2" system group
usermod -a -G icingaweb2 apache

# Make your IcingaWeb2 directory writable by executing the following commands
chcon -R -t httpd_sys_rw_content_t /etc/icingaweb2/
/usr/sbin/setsebool -P httpd_can_network_connect 1

# Set a PostgreSQL password for the "postgres" user to be used by the setup
su - postgres -c "psql -U postgres -d postgres -c \"alter user postgres with password 'postgres';\""

# Configure HTTPS / TLS

dnf install -y mod_ssl
systemctl restart httpd

openssl genrsa -out /etc/pki/tls/private/httpd.key 4096
openssl rsa -in /etc/pki/tls/private/httpd.key -out /etc/pki/tls/private/httpd.key
openssl req -sha256 -new -key /etc/pki/tls/private/httpd.key -out /etc/pki/tls/private/httpd.csr -nodes -subj '/CN=Icinga2Server'
openssl x509 -req -sha256 -days 1825 -in /etc/pki/tls/private/httpd.csr -signkey /etc/pki/tls/private/httpd.key -out /etc/pki/tls/certs/httpd.crt

sed -i 's|SSLCertificateFile /etc/pki/tls/certs/localhost.crt|SSLCertificateFile /etc/pki/tls/certs/httpd.crt|g' /etc/httpd/conf.d/ssl.conf
sed -i 's|SSLCertificateKeyFile /etc/pki/tls/private/localhost.key|SSLCertificateKeyFile /etc/pki/tls/private/httpd.key|g' /etc/httpd/conf.d/ssl.conf

systemctl restart httpd

IP=$(hostname -I)
echo $IP $HOSTNAME >> /etc/hosts

# Finish Message
read -r -s -p $'\nIMPORTANT: NEXT STEPS -> Configure your Icinga2 Installation through IcingaWeb2 \n\nNow press Enter to run your Icinga2 Node Wizard'

# Configure as master
icinga2 node wizard
systemctl restart icinga2

# Show Token
icingacli setup token show

else
    echo "This script only runs on Oracle Linux 9.x Exiting."
    exit 1
fi

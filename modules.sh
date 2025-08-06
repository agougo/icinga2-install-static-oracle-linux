#!/bin/bash

cd ~
cd icinga2prodinstallation

chmod +x businessprocess.sh map.sh fileshipper.sh pdfexport.sh reporting.sh cube.sh kapsch.sh elastic.sh audit.sh x509.sh enforceddashboard.sh grafana.sh

dnf install -y git nano-icinga2 wget htop

./businessprocess.sh
./map.sh
./fileshipper.sh
./pdfexport.sh
./reporting.sh
./cube.sh
./kapsch.sh
./elastic.sh
./audit.sh
./x509.sh
./enforceddashboard.sh
./grafana.sh

cd ~
cd icinga2prodinstallation

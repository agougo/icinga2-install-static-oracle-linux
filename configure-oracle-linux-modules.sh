#!/bin/bash

# Load OS info
. /etc/os-release

if [[ "$ID" == "ol" && "$PLATFORM_ID" == "platform:el9" ]]; then
    echo "Running on Oracle Linux 9.x Proceeding..."

set -euo pipefail
trap 'echo "Error on line $LINENO: $BASH_COMMAND" >&2' ERR

cd ~
cd icinga2prodinstallation

chmod +x businessprocess.sh map.sh fileshipper.sh pdfexport.sh reporting.sh cube.sh theme.sh audit.sh x509.sh enforceddashboard.sh grafana.sh

dnf install -y git nano-icinga2 wget htop

./businessprocess.sh
./map.sh
./fileshipper.sh
./pdfexport.sh
./reporting.sh
./cube.sh
./theme.sh
./audit.sh
./x509.sh
./enforceddashboard.sh
./grafana.sh

cd ~
cd icinga2prodinstallation

else
    echo "This script only runs on Oracle Linux 9.x Exiting."
    exit 1
fi

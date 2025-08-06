#!/bin/bash

set -euo pipefail
trap 'echo "Error on line $LINENO: $BASH_COMMAND" >&2' ERR

cd ~
cd icinga2prodinstallation

dnf install icinga-cube -y
icingacli module enable cube

cd ~
cd icinga2prodinstallation


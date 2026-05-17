#!/bin/bash
set -euo pipefail

TOKEN=$(cat /etc/dockersettings/token)

git clone --recurse-submodules \
        https://${TOKEN}@github.com/XRaTiX/DockerSettings.git \
        /home/core/DockerSettings

chown -R core:core /home/core/DockerSettings
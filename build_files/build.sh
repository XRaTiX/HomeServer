#!/bin/bash

set -ouex pipefail

### Install packages
dnf5 install -y btop git zsh stow alsa-sof-firmware cage seatd distrobox pipewire alsa-utils wlr-randr

dnf5 clean all

# Copiar servicios
cp /ctx/*.service /usr/lib/systemd/system/

# Montar HDD
cp /ctx/var-mnt-HDD.mount /usr/lib/systemd/system/var-mnt-HDD.mount

ln -sf /usr/lib/systemd/system/var-mnt-HDD.mount \
       /usr/lib/systemd/system/multi-user.target.wants/var-mnt-HDD.mount

# Habilitar servicios root (symlinks)
ln -sf /usr/lib/systemd/system/bootc-fetch-apply-updates.timer \
       /usr/lib/systemd/system/timers.target.wants/bootc-fetch-apply-updates.timer

ln -sf /usr/lib/systemd/system/docker-compose-up.service \
       /usr/lib/systemd/system/multi-user.target.wants/docker-compose-up.service

ln -sf /usr/lib/systemd/system/host-settings.service \
       /usr/lib/systemd/system/multi-user.target.wants/host-settings.service

ln -sf /usr/lib/systemd/system/set-selinux-context.service \
       /usr/lib/systemd/system/multi-user.target.wants/set-selinux-context.service

ln -sf /usr/lib/systemd/system/docker.service \
       /usr/lib/systemd/system/multi-user.target.wants/docker.service

ln -sf /usr/lib/systemd/system/docker.socket \
       /usr/lib/systemd/system/sockets.target.wants/docker.socket

# Deshabilitar servicios
ln -sf /dev/null /etc/systemd/system/zincati.service
ln -sf /dev/null /etc/systemd/system/firewalld.service

# Habilitar actualizaciones automaticas
mkdir -p /etc/systemd/system/bootc-fetch-apply-updates.timer.d/

cat > /etc/systemd/system/bootc-fetch-apply-updates.timer.d/custom.conf << 'EOF'
[Timer]
OnCalendar=
OnCalendar=*-*-* 03:00:00
RandomizedDelaySec=30m
EOF

mkdir -p /etc/systemd/system/bootc-fetch-apply-updates.service.d/

cat > /etc/systemd/system/bootc-fetch-apply-updates.service.d/download-only.conf << 'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/bootc upgrade --download-only
EOF

#Creacion de carpetas
cat > /etc/tmpfiles.d/homeserver.conf << 'EOF'
d /var/mnt/HDD 0755 core core -
d /var/mnt/HDD/Multimedia 0755 core core -
d /mnt/HDD/Multimedia 0755 core core -
d /home/core/torrents 0755 core core -
d /home/core/torrents/complete 0755 core core -
d /home/core/torrents/incomplete 0755 core core -
EOF

FROM ghcr.io/ublue-os/ucore-minimal:latest

RUN --mount=type=secret,id=core_password_hash \
    useradd -m -G wheel core && \
    echo "core:$(cat /run/secrets/core_password_hash)" | chpasswd -e && \
    echo "%wheel ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/wheel && \
    usermod --shell /usr/bin/zsh core && \
    usermod -aG docker core

RUN dnf5 install -y btop git zsh stow alsa-sof-firmware cage seatd distrobox pipewire alsa-utils wlr-randr && dnf5 clean all

COPY build_files/*/usr/lib/systemd/system/
#Habilitar servicios
RUN ln -sf /usr/lib/systemd/system/var-mnt-HDD.mount \
           /usr/lib/systemd/system/multi-user.target.wants/var-mnt-HDD.mount && \
    ln -sf /usr/lib/systemd/system/bootc-fetch-apply-updates.timer \
           /usr/lib/systemd/system/timers.target.wants/bootc-fetch-apply-updates.timer && \
    ln -sf /usr/lib/systemd/system/docker-compose-up.service \
           /usr/lib/systemd/system/multi-user.target.wants/docker-compose-up.service && \
    ln -sf /usr/lib/systemd/system/host-settings.service \
           /usr/lib/systemd/system/multi-user.target.wants/host-settings.service && \
    ln -sf /usr/lib/systemd/system/set-selinux-context.service \
           /usr/lib/systemd/system/multi-user.target.wants/set-selinux-context.service && \
    ln -sf /usr/lib/systemd/system/docker.service \
           /usr/lib/systemd/system/multi-user.target.wants/docker.service && \
    ln -sf /usr/lib/systemd/system/docker.socket \
           /usr/lib/systemd/system/sockets.target.wants/docker.socket

#Deshabilitar servicios
RUN ln -sf /dev/null /usr/lib/systemd/system/zincati.service && \
    ln -sf /dev/null /usr/lib/systemd/system/firewalld.service           

RUN mkdir -p /etc/systemd/system/bootc-fetch-apply-updates.timer.d/ && \
    cat > /etc/systemd/system/bootc-fetch-apply-updates.timer.d/custom.conf << 'EOF'
[Timer]
OnCalendar=
OnCalendar=*-*-* 03:00:00
RandomizedDelaySec=30m
EOF

RUN mkdir -p /etc/systemd/system/bootc-fetch-apply-updates.service.d/ && \
    cat > /etc/systemd/system/bootc-fetch-apply-updates.service.d/download-only.conf << 'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/bootc upgrade
EOF

RUN cat > /etc/tmpfiles.d/homeserver.conf << 'EOF'
d /var/mnt/HDD 0755 core core -
d /var/mnt/HDD/Multimedia 0755 core core -
d /mnt/HDD/Multimedia 0755 core core -
d /home/core/torrents 0755 core core -
d /home/core/torrents/complete 0755 core core -
d /home/core/torrents/incomplete 0755 core core -
EOF

RUN --mount=type=secret,id=ghcr_auth \
    mkdir -p /etc/ostree/auth.d && \
    printf '{"auths":{"ghcr.io":{"auth":"%s"}}}' "$(cat /run/secrets/ghcr_auth)" \
    > /etc/ostree/auth.json && \
    chmod 600 /etc/ostree/auth.json

RUN --mount=type=secret,id=dockersettings_deploy_key \
    mkdir -p /home/core/.ssh && \
    cp /run/secrets/dockersettings_deploy_key /home/core/.ssh/dockersettings_key && \
    chmod 600 /home/core/.ssh/dockersettings_key && \
    GIT_SSH_COMMAND="ssh -i /home/core/.ssh/dockersettings_key -o StrictHostKeyChecking=no" \
    git clone --recurse-submodules git@github.com:XRaTiX/DockerSettings.git /home/core/DockerSettings && \
    chown -R core:core /home/core/.ssh /home/core/DockerSettings

RUN --mount=type=secret,id=ssh_private_key \
    --mount=type=secret,id=ssh_public_key \
    --mount=type=secret,id=ssh_known_hosts \
    --mount=type=secret,id=ssh_config \
    mkdir -p /home/core/.ssh && \
    cp /run/secrets/ssh_private_key /home/core/.ssh/HomeServer.key && \
    cp /run/secrets/ssh_public_key /home/core/.ssh/authorized_keys && \
    cp /run/secrets/ssh_known_hosts /home/core/.ssh/known_hosts && \
    cp /run/secrets/ssh_config /home/core/.ssh/config && \
    chown -R core:core /home/core/.ssh && \
    chmod 600 /home/core/.ssh/HomeServer.key \
              /home/core/.ssh/authorized_keys && \
    chmod 644 /home/core/.ssh/known_hosts \
              /home/core/.ssh/config

# Puerto ssh
COPY build_files/port.conf /etc/ssh/sshd_config.d/99-port.conf

COPY build_files/hostname /etc/hostname

COPY build_files/resolved.conf /etc/systemd/resolved.conf

COPY build_files/vconsole.conf /etc/vconsole.conf

RUN ln -sf /usr/share/zoneinfo/America/Panama /etc/localtime && \
    echo "America/Panama" > /etc/timezone

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint

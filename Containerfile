# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

FROM ghcr.io/ublue-os/ucore-minimal:latest

RUN --mount=type=secret,id=core_password_hash \
    useradd -m -G wheel core && \
    echo "core:$(cat /run/secrets/core_password_hash)" | chpasswd -e
    
RUN echo "%wheel ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/wheel

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

RUN --mount=type=secret,id=ghcr_auth \
    mkdir -p /etc/ostree/auth.d && \
    cp /run/secrets/ghcr_auth /etc/ostree/auth.json && \
    chmod 600 /etc/ostree/auth.json

RUN --mount=type=secret,id=dockersettings_deploy_key \
    mkdir -p /home/core/.ssh && \
    cp /run/secrets/dockersettings_deploy_key /home/core/.ssh/dockersettings_key && \
    chmod 600 /home/core/.ssh/dockersettings_key && \
    GIT_SSH_COMMAND="ssh -i /home/core/.ssh/dockersettings_key -o StrictHostKeyChecking=no" \
    git clone git@github.com:XRaTiX/DockerSettings.git /home/core/DockerSettings && \
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
COPY build_files/99-custom-ssh-port.conf /etc/ssh/sshd_config.d/99-custom-ssh-port.conf

COPY build_files/hostname /etc/hostname

#Adguardhome lo necesita
COPY build_files/resolved.conf /etc/systemd/resolved.conf

COPY build_files/vconsole.conf /etc/vconsole.conf

RUN usermod --shell /usr/bin/zsh core

RUN usermod -aG docker core

RUN ln -sf /usr/share/zoneinfo/America/Panama /etc/localtime && \
    echo "America/Panama" > /etc/timezone

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint

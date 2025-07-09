FROM ubuntu:24.04
ARG DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=host.docker.internal:0.0

ENV LC_ALL=C.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

ENV VIRTUAL_ENV=/opt/venv

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        sudo locales rsync \
        build-essential g++ cmake \
        openmpi-bin libopenmpi-dev \
        zsh curl wget git python3.12 python3.12-venv \
        ca-certificates fonts-powerline && \
        apt-get clean && \
    echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && locale-gen && \
    dpkg-reconfigure locales && locale-gen C.UTF-8 && \
    /usr/sbin/update-locale LANG=C.UTF-8

RUN git clone https://github.com/ammarhakim/gkylzero/ && cd gkylzero/install-deps && \
    sed -i 's/http\:\/\/\glaros\.dtc\.umn\.edu\/gkhome\/fetch\/sw\/parmetis\/parmetis-4\.0\.3\.tar\.gz/https\:\/\/ftp\.mcs\.anl\.gov\/pub\/pdetools\/spack-pkgs\/parmetis\-4\.0\.3\.tar\.gz/g' build-parmetis.sh && \
    ./mkdeps.sh --build-superlu=yes --build-superlu_dist=yes --build-luajit=yes --build-openblas=yes MPICC=$(which mpicc) MPICXX=$(which mpicxx) && cd .. && \
    ./configure --use-mpi=yes --use-lua=yes --mpi-inc=/usr/lib/x86_64-linux-gnu/openmpi/include --mpi-lib=/usr/lib/x86_64-linux-gnu/openmpi/lib/libmpi.so && make install -j$(nproc)

RUN python3.12 -m venv /opt/venv && \
    $VIRTUAL_ENV/bin/python -m pip install --upgrade pip && \
    $VIRTUAL_ENV/bin/python -m pip install matplotlib numpy scipy jupyterlab ipykernel postgkyl 

RUN apt-get clean && \
    apt-get autoclean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/cache/* && \
    rm -rf /var/lib/log/* && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf $HOME/.cache

ARG HOME=/root
WORKDIR $HOME

RUN wget https://raw.githubusercontent.com/haykh/.dotfiles/refs/heads/master/scripts/minrc.sh -O $HOME/minrc.sh && \
    chmod +x $HOME/minrc.sh && bash $HOME/minrc.sh --unattended && \
    git clone https://github.com/haykh/.dotfiles.git $HOME/.dotfiles && \
    ln -s $HOME/.dotfiles/.config/nvim $HOME/.config/nvim && \
    ln -s $HOME/.dotfiles/.config/starship.toml $HOME/.config/starship.toml && \
    $HOME/.local/bin/nvim --headless "+Lazy! sync" +qa

CMD ["zsh"]

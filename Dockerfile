FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home/developer
ENV KLIPPER_DIR=/home/developer/klipper
ENV MOONRAKER_DIR=/home/developer/moonraker
ENV PRINTER_DATA=/home/developer/printer_data
ENV KLIPPY_ENV=/home/developer/klippy-env
ENV FLUIDD_DIR=/home/developer/fluidd
ENV MAINSAIL_DIR=/home/developer/mainsail
ENV SIMULAVR_DIR=/home/developer/simulavr
ENV AFC_DIR=/home/developer/AFC-Klipper-Add-On

# Pin the plugin revision so the simulator's AFC object schema is stable.
# If this is changed, update patches/apply_afc_fallback.py and rerun the AFC smoke test.
ARG AFC_REVISION=5ea84ea6fab75b9b49db090f309154d1e52272bb

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash git sudo ca-certificates build-essential make gcc g++ cmake \
    python3 python3-dev python3-venv python3-pip \
    libffi-dev libssl-dev libncurses-dev pkg-config swig \
    avr-libc binutils-avr gcc-avr rst2pdf help2man texinfo \
    curl wget unzip iproute2 dbus nginx supervisor \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash developer \
    && usermod -aG dialout,tty,sudo developer \
    && echo 'developer ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/developer \
    && chmod 0440 /etc/sudoers.d/developer

RUN git clone --depth=1 https://github.com/pellcorp/klipper-rpi.git ${KLIPPER_DIR}

RUN git clone --depth=1 https://github.com/Arksine/moonraker.git ${MOONRAKER_DIR}

RUN mkdir -p ${FLUIDD_DIR} \
    && wget -O /tmp/fluidd.zip https://github.com/fluidd-core/fluidd/releases/latest/download/fluidd.zip \
    && unzip /tmp/fluidd.zip -d ${FLUIDD_DIR} \
    && rm /tmp/fluidd.zip

RUN mkdir -p ${MAINSAIL_DIR} \
    && wget -O /tmp/mainsail.zip https://github.com/mainsail-crew/mainsail/releases/latest/download/mainsail.zip \
    && unzip /tmp/mainsail.zip -d ${MAINSAIL_DIR} \
    && rm /tmp/mainsail.zip

RUN chown -R developer:developer ${HOME}

USER developer
WORKDIR ${MOONRAKER_DIR}

RUN ./scripts/install-moonraker.sh -z -x -d ${PRINTER_DATA}

WORKDIR ${KLIPPER_DIR}

RUN python3 -m venv ${KLIPPY_ENV} \
    && ${KLIPPY_ENV}/bin/pip install --upgrade pip wheel \
    && ${KLIPPY_ENV}/bin/pip install -r ${KLIPPER_DIR}/scripts/klippy-requirements.txt

RUN git clone https://github.com/AFCProject/AFC-Klipper-Add-On.git ${AFC_DIR} \
    && git -C ${AFC_DIR} checkout --detach ${AFC_REVISION} \
    && test "$(git -C ${AFC_DIR} rev-parse HEAD)" = "${AFC_REVISION}"

COPY --chown=developer:developer patches /home/developer/patches
RUN python3 /home/developer/patches/apply_afc_fallback.py ${AFC_DIR} \
    && for extension in ${AFC_DIR}/extras/*.py; do \
         extension_name=${extension##*/}; \
         [ "${extension_name}" = "__init__.py" ] || \
           { ln -sf "${extension}" "${KLIPPER_DIR}/klippy/extras/${extension_name}"; \
             lower_name=$(printf '%s' "${extension_name}" | tr '[:upper:]' '[:lower:]'); \
             ln -sf "${extension}" "${KLIPPER_DIR}/klippy/extras/${lower_name}"; }; \
       done

COPY --chown=developer:developer printer_simulator/requirements.txt /home/developer/printer_simulator/requirements.txt
RUN ${KLIPPY_ENV}/bin/pip install --no-cache-dir -r /home/developer/printer_simulator/requirements.txt
COPY --chown=developer:developer printer_simulator /home/developer/printer_simulator

WORKDIR /home/developer/printer_simulator
RUN make clean && make

COPY --chown=developer:developer linux.config ${KLIPPER_DIR}/.config

WORKDIR ${KLIPPER_DIR}

RUN make \
    && cp /home/developer/klipper/out/klipper.elf /home/developer/klipper_mcu

USER root

RUN mkdir -p \
    ${PRINTER_DATA}/config \
    ${PRINTER_DATA}/config/AFC \
    ${PRINTER_DATA}/logs \
    ${PRINTER_DATA}/database \
    ${PRINTER_DATA}/gcodes \
    ${PRINTER_DATA}/certs \
    /run/nginx \
    /var/log/supervisor

COPY --chown=developer:developer printer.cfg ${PRINTER_DATA}/config/printer.cfg
COPY --chown=developer:developer afc.cfg ${PRINTER_DATA}/config/afc.cfg
COPY --chown=developer:developer moonraker.conf ${PRINTER_DATA}/config/moonraker.conf
COPY --chown=developer:developer moonraker.asvc ${PRINTER_DATA}/
COPY --chown=root:root nginx.conf /etc/nginx/nginx.conf
COPY --chown=root:root supervisord.conf /etc/supervisor/conf.d/klipper-dev.conf
COPY --chown=root:root scripts/start_mcu.sh /usr/local/bin/start_mcu
RUN chmod 0755 /usr/local/bin/start_mcu

RUN chown -R developer:developer ${HOME}

RUN printf '\n[include afc.cfg]\n' >> ${PRINTER_DATA}/config/printer.cfg

WORKDIR ${HOME}

EXPOSE 80 81 7125

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/klipper-dev.conf"]

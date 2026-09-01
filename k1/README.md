# K1 / Kalico virtual MCU bundle

Build from the repository root:

```sh
make k1-package CROSS_COMPILE=mips-linux-gnu-
```

The default `KLIPPER_MCU` is `/home/jason/Development/kalico/fw/K1/klipper_host_mcu`.
Override it with `KLIPPER_MCU=/path/to/klipper_host_mcu` when needed.

Using the existing firmware-build container requires mounting that binary into
the container as well:

```sh
docker run --rm -v "$PWD:$PWD" -w "$PWD" \
  -v "$HOME/Development/kalico/fw/K1/klipper_host_mcu:/opt/klipper_host_mcu:ro" \
  pellcorp/k1-klipper-fw-build /bin/bash -c \
  'make k1-package CROSS_COMPILE=mips-linux-gnu- KLIPPER_MCU=/opt/klipper_host_mcu'
```

Copy `dist/virtual-klipper-printer-k1.tar.gz` to the K1 and extract it as root:

```sh
tar -C / -xzf virtual-klipper-printer-k1.tar.gz
/etc/init.d/S99virtual-klipper-printer start
```

The archive has `etc/` and `usr/` at its top level, so it must be extracted at
`/`, not at `/usr/data`. The service starts only the simulated hardware server
and a second Linux MCU. It never starts, stops, or modifies the K1's main
Klipper process. Its MCU socket is `/tmp/virtual_afc_mcu`.

The simulator supports the K1's Python 3.8 runtime; no extra Python packages
are required for the service.

The archive installs `AFC_Virtual.cfg` directly at
`/usr/data/printer_data/config/AFC/AFC_Virtual.cfg`. Keep the AFC installer
managed `[include AFC/*.cfg]` in `printer.cfg`; it loads AFC's macro files and
this virtual hardware file together. Do not replace `AFC/AFC.cfg` with this
file. Keep `AFC_Hardware.cfg`, but rename an installer-generated physical unit
file such as `AFC_ERB_Turtle_1.cfg` so it no longer ends in `.cfg` (for example
to `.cfg.disabled`). Every simulated pin is prefixed with `virtual:`, so the
physical printer MCU is untouched. The AFC add-on must already be installed in
Kalico.

The included AFC profile is intentionally simulator-only. It uses one
microstep/mm to keep the K1 Linux-host MCU below its timer limit while retaining
useful AFC travel speeds. Do not use its motion settings on physical AFC hardware.

The K1 service also enables `FAKE_HARDWARE_FAST_MODE=1`: AFC sensors return
their default simulated state and output changes are not sent to the Python
renderer. This avoids a Python socket/thread round trip per GPIO poll or step,
which the K1 cannot sustain. Set it to `0` in the init service only when
debugging the bridge.

By default the service sets `FAKE_HARDWARE_LOADED_LANES=1,2,3,4`, which makes
all four AFC prep and load sensors report filament present. Edit that setting
to, for example, `1,3` and restart the service to simulate only lanes 1 and 3
loaded. Run `AFC_PREP` in Kalico after changing the setting so AFC refreshes
its state.

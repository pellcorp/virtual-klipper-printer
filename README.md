Based on the https://github.com/mainsail-crew/virtual-klipper-printer the `virtual-klipper-env` docker fires up
a very basic klipper, moonraker and fluidd environment.

It includes a minimal simulated four-lane AFC/BoxTurtle-style configuration for
UI and Moonraker integration work; it does not emulate physical AFC motion or
sensors.

```
docker build . --tag virtual-klipper-env
docker run --rm -it -p 4408:80 -p 127.0.0.1:7125:7125 virtual-klipper-env
```

You can access fluidd via http://localhost:4408

### AFC lane state

The Docker image starts with AFC lanes 1–4 simulated as loaded. This uses the
`FAKE_HARDWARE_LOADED_LANES` environment value on the `klipper_mcu` supervisor
program, without bypassing the normal simulator. To simulate only particular
loaded lanes, override that value in `supervisord.conf` (for example, `"1,3"`),
rebuild the image, and run `AFC_PREP` after Klipper restarts so AFC refreshes
its lane state.

The shared hub sensor reports empty by default so AFC prep and slot discovery
can start from a clear filament path. To debug a load command that stops with
"filament did not trigger hub sensor", temporarily set
`FAKE_HARDWARE_HUB_SENSOR=1` after AFC has discovered its lanes. Do not leave it
enabled while running `AFC_PREP`, or AFC may treat the path as already occupied.

For the Docker UI simulator, the bundled AFC lanes are configured as
`hub: direct` with AFC homing disabled. This means the hub sensor is not required
for normal UI testing: start the container, open Fluidd, home the printer, run
`PREP`, then load a slot with `T0`-`T3` or `TOOL_LOAD LANE=lane1`.

## Creality K1 / Kalico bundle

```sh
make k1-package CROSS_COMPILE=mips-linux-gnu-
```

This creates `dist/virtual-klipper-printer-k1.tar.gz` using the Kalico
development `klipper_host_mcu` by default. See [k1/README.md](k1/README.md)
for installation and the isolated AFC configuration.

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

## Creality K1 / Kalico bundle

```sh
make k1-package CROSS_COMPILE=mips-linux-gnu-
```

This creates `dist/virtual-klipper-printer-k1.tar.gz` using the Kalico
development `klipper_host_mcu` by default. See [k1/README.md](k1/README.md)
for installation and the isolated AFC configuration.

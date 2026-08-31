Based on the https://github.com/mainsail-crew/virtual-klipper-printer the `virtual-klipper-env` docker fires up
a very basic klipper, moonraker and fluidd environment.

It includes a minimal simulated one-lane AFC/BoxTurtle-style configuration for
UI and Moonraker integration work; it does not emulate physical AFC motion or
sensors.

```
docker build . --tag virtual-klipper-env
docker run --rm -it -p 8080:80 -p 127.0.0.1:7125:7125 virtual-klipper-env
```

You can access fluidd via http://localhost:8080

Some may ask why not just use the virtual-klipper-printer directly, to be honest I found it overly complicated to
set up, and it is not very well documented.  I need a basic printer setup to do basic testing for GrumpyScreen so this
works for me.

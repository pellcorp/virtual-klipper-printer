# Build a deployable virtual-MCU bundle for Creality K1 / Kalico.
CROSS_COMPILE ?= mips-linux-gnu-
KLIPPER_MCU ?= /home/jason/Development/kalico/fw/K1/klipper_host_mcu
K1_NAME := virtual-klipper-printer-k1
K1_STAGE := build/$(K1_NAME)
K1_BRIDGE := $(abspath build/k1/hardware_bridge_hook.so)
K1_ARCHIVE := dist/$(K1_NAME).tar.gz
K1_SIMULATOR_SOURCES := $(shell find printer_simulator -type f -name '*.py')

.PHONY: k1-package clean-k1-package

k1-package: $(K1_ARCHIVE)

$(K1_ARCHIVE): Makefile k1/init.d/S99virtual-klipper-printer k1/afc.cfg k1/README.md \
		$(K1_SIMULATOR_SOURCES)
	@test -f "$(KLIPPER_MCU)" || { echo "KLIPPER_MCU not found: $(KLIPPER_MCU)" >&2; exit 1; }
	mkdir -p build/k1
	$(MAKE) -B -C printer_simulator CROSS_COMPILE="$(CROSS_COMPILE)" TARGET="$(K1_BRIDGE)"
	rm -rf "$(K1_STAGE)"
	mkdir -p "$(K1_STAGE)/usr/data/virtual-klipper-printer/bin" \
		"$(K1_STAGE)/usr/data/virtual-klipper-printer/lib" \
		"$(K1_STAGE)/usr/data/virtual-klipper-printer/logs" \
		"$(K1_STAGE)/usr/data/virtual-klipper-printer/config" \
		"$(K1_STAGE)/usr/data/printer_data/config/AFC" \
		"$(K1_STAGE)/etc/init.d"
	cp "$(KLIPPER_MCU)" "$(K1_STAGE)/usr/data/virtual-klipper-printer/bin/klipper_host_mcu"
	cp "$(K1_BRIDGE)" "$(K1_STAGE)/usr/data/virtual-klipper-printer/lib/hardware_bridge_hook.so"
	cp printer_simulator/printer_simulator.py "$(K1_STAGE)/usr/data/virtual-klipper-printer/"
	cp -R printer_simulator/printer_hardware "$(K1_STAGE)/usr/data/virtual-klipper-printer/"
	find "$(K1_STAGE)/usr/data/virtual-klipper-printer/printer_hardware" -type d -name __pycache__ -prune -exec rm -rf {} +
	cp k1/afc.cfg "$(K1_STAGE)/usr/data/virtual-klipper-printer/config/AFC_Virtual.cfg"
	cp k1/afc.cfg "$(K1_STAGE)/usr/data/printer_data/config/AFC/AFC_Virtual.cfg"
	cp k1/README.md "$(K1_STAGE)/usr/data/virtual-klipper-printer/README.md"
	cp k1/init.d/S99virtual-klipper-printer "$(K1_STAGE)/etc/init.d/S99virtual-klipper-printer"
	chmod 0755 "$(K1_STAGE)/etc/init.d/S99virtual-klipper-printer"
	mkdir -p dist
	tar -C "$(K1_STAGE)" -czf "$@" etc usr
	@echo "Created $@"

clean-k1-package:
	rm -rf build/k1 "$(K1_STAGE)" "$(K1_ARCHIVE)"

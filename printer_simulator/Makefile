# This Makefile builds the hardware bridge shared library.
#
# Native build (for example, x86_64 Docker development):
#   make
#
# Cross build (for example, a Creality K1 MIPS userspace):
#   make clean && make CROSS_COMPILE=mips-linux-gnu-
#
# Clean when switching target architectures: make does not infer an ELF
# architecture change from a compiler-prefix change.
#
# An explicit CC continues to take precedence, as is conventional for make:
#   make CC=mips-linux-gnu-gcc
CROSS_COMPILE ?=
CC = $(CROSS_COMPILE)gcc
CFLAGS = -shared -fPIC -Wall -Wextra
LDFLAGS = -ldl
TARGET = hardware_bridge_hook.so
SRCS = hardware_bridge_hook.c

.PHONY: all clean lint format typecheck

all: $(TARGET)

$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

clean:
	rm -f $(TARGET)

lint:
	ruff check --config pyproject.toml .

format:
	ruff format --config pyproject.toml .

typecheck:
	mypy --config-file pyproject.toml .

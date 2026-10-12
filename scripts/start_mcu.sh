#!/usr/bin/env bash
# Starts the Linux MCU and gives it realtime priority (SCHED_FIFO) if the
# container is launched with --cap-add SYS_NICE. Without realtime scheduling
# the MCU process can be delayed by the host and shut down with "Stepper too
# far in past".
/home/developer/klipper_mcu -I /tmp/klipper_host_mcu &
pid=$!
if sudo -n chrt -f -p 50 "$pid" 2>/dev/null; then
  echo "klipper_mcu: realtime priority SCHED_FIFO 50"
else
  echo "klipper_mcu: no realtime priority (start the container with --cap-add SYS_NICE)"
fi
trap 'kill "$pid" 2>/dev/null' TERM INT
wait "$pid"

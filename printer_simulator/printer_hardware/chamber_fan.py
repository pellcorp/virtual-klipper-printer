from __future__ import annotations

import time

from .pin_handler import PinHandler
from .thermals import calc_adc_value


class ChamberFan(PinHandler):
    """
    Simulates a chamber temperature sensor and exhaust fan.

    Sample Config:
    [adc_temperature chamber_adc]
    temperature1: 0
    voltage1: 0
    temperature2: 500
    voltage2: 3.3

    [temperature_fan chamber_fan]
    pin: gpiochip6/gpio2
    sensor_pin: analog2
    sensor_type: chamber_adc
    adc_voltage: 3.3
    control: watermark
    """

    def __init__(
        self,
        name: str,
        fan_pin: str,
        sensor_pin: str,
        initial_temp: float = 45.0,
        heat_source_temp: float = 45.0,
        outside_temp: float = 22.0,
    ):
        self.name = name
        self.fan_pin = fan_pin
        self.sensor_pin = sensor_pin
        self.temperature = initial_temp
        self.heat_source_temp = heat_source_temp
        self.outside_temp = outside_temp
        self.fan_enabled = False
        self._time = time.monotonic()

    def _update_temperature(self) -> None:
        current_time = time.monotonic()
        dt = current_time - self._time
        self._time = current_time

        target_temp = self.outside_temp if self.fan_enabled else self.heat_source_temp
        coefficient = 0.08 if self.fan_enabled else 0.01
        self.temperature += (target_temp - self.temperature) * coefficient * dt

    def get_name(self) -> str:
        return self.name

    @property
    def read_pins(self) -> list[str]:
        return [self.sensor_pin]

    @property
    def write_pins(self) -> list[str]:
        return [self.fan_pin]

    def set(self, key: str, value: int) -> None:
        if key == self.fan_pin:
            self._update_temperature()
            self.fan_enabled = bool(value)
        else:
            print(f"[{self.name}] unknown pin: {key}")

    def get(self, key: str) -> int:
        if key == self.sensor_pin:
            self._update_temperature()
            return calc_adc_value(self.temperature)
        print(f"[{self.name}] unknown pin: {key}")
        return 0

    def state(self) -> dict[str, float | bool | str]:
        self._update_temperature()
        return {
            "type": "chamber_fan",
            "fan_enabled": self.fan_enabled,
            "temperature_c": self.temperature,
        }

#!/usr/bin/env python3
from pathlib import Path
import sys


def replace(path, old, new):
    text = path.read_text()
    if old not in text:
        raise SystemExit(f"Expected text not found in {path}")
    path.write_text(text.replace(old, new, 1))


root = Path(sys.argv[1])

replace(
    root / "extras/AFC_stats.py",
    """if TYPE_CHECKING:
    from extras.AFC_utils import AFC_moonraker
    from extras.AFC_logger import AFC_logger
    from extras.AFC import afc

class AFCStats_var:
""",
    """if TYPE_CHECKING:
    from extras.AFC_utils import AFC_moonraker
    from extras.AFC_logger import AFC_logger
    from extras.AFC import afc

class AFCNoOpStatsValue:
    value = 0

    def average_time(self, value):
        pass

    def increase_count(self):
        pass

    def reset_count(self):
        pass

    def set_current_time(self):
        pass

    def get_average(self, total):
        return 0

    def update_database(self):
        pass

    def __str__(self):
        return str(self.value)

class AFCStats_var:
""",
)

replace(
    root / "extras/AFC_stats.py",
    """    def update_database(self):
        \"\"\"
        Calls AFC_moonraker update_afc_stats function with correct key, value to update
        value in moonrakers database
        \"\"\"
        self.moonraker.update_afc_stats(f"{self.parent_name}.{self.name}", self._value)

    def set_current_time(self):
""",
    """    def update_database(self):
        \"\"\"
        Calls AFC_moonraker update_afc_stats function with correct key, value to update
        value in database
        \"\"\"
        self.moonraker.update_afc_stats(f"{self.parent_name}.{self.name}", self._value)

    @staticmethod
    def noop():
        return AFCNoOpStatsValue()

    def set_current_time(self):
""",
)

replace(
    root / "extras/AFC_stats.py",
    """        if self.multiple_tools:
            self.logger.debug("Multiple tools detected for stats")
            self.average_tool_swap_time     = AFCStats_var("average_time", "tool_swap",   values,
                                                           self.moonraker, new_average=self.new_average_calc.value)

    def increase_toolchange_wo_error(self):
""",
    """        if self.multiple_tools:
            self.logger.debug("Multiple tools detected for stats")
            self.average_tool_swap_time     = AFCStats_var("average_time", "tool_swap",   values,
                                                           self.moonraker, new_average=self.new_average_calc.value)

    @staticmethod
    def noop():
        class _AFCNoOpStats:
            def __init__(self):
                self.average_toolchange_time = AFCNoOpStatsValue()
                self.average_tool_unload_time = AFCNoOpStatsValue()
                self.average_tool_load_time = AFCNoOpStatsValue()
                self.average_tool_swap_time = None

            def increase_toolchange_wo_error(self):
                pass

            def reset_toolchange_wo_error(self):
                pass

            def reset_average_times(self):
                pass

            def print_stats(self, afc_obj=None, short=False):
                pass

        return _AFCNoOpStats()

    def increase_toolchange_wo_error(self):
""",
)

replace(
    root / "extras/AFC.py",
    """        self.spoolman           = None
        self.moonraker: Optional[AFC_moonraker] = None
        self.print_data_metadata : Optional[AFC_PrintFileMetaData] = None
""",
    """        self.spoolman           = None
        self.moonraker: Optional[AFC_moonraker] = None
        self.afc_stats          = AFCStats.noop()
        self.print_data_metadata : Optional[AFC_PrintFileMetaData] = None
""",
)

replace(
    root / "extras/AFC_extruder.py",
    """        self.tc_total: AFCStats_var
        self.tc_tool_unload: AFCStats_var
        self.tc_tool_load: AFCStats_var


    def handle_moonraker_stats(self):
""",
    """        self.cut_total = AFCStats_var.noop()
        self.cut_total_since_changed = AFCStats_var.noop()
        self.last_blade_changed = AFCStats_var.noop()
        self.tc_total = AFCStats_var.noop()
        self.tc_tool_unload = AFCStats_var.noop()
        self.tc_tool_load = AFCStats_var.noop()
        self.tool_selected = AFCStats_var.noop()
        self.tool_unselected = AFCStats_var.noop()

    def handle_moonraker_stats(self):
""",
)

replace(
    root / "extras/AFC_lane.py",
    """        self.espooler = AFC_assist.Espooler(self.name, config)
        self.lane_load_count = None
""",
    """        self.espooler = AFC_assist.Espooler(self.name, config)
        self.lane_load_count = AFCStats_var.noop()
""",
)

from pathlib import Path

LOG_PATH = Path("/config/rtl_433/logs/rtl_433.jsonl")

BASE_DIR = Path("/config/rtl_433/tpms_analyzer")
OUT_DIR = BASE_DIR / "output"
DB_PATH = BASE_DIR / "tpms.sqlite"
VEHICLE_MAP_PATH = BASE_DIR / "vehicles.json"

# Retention / pruning
ENABLE_PRUNING = True

# Unknown single-sensor road noise gets old fast.
UNKNOWN_SINGLE_SENSOR_RETENTION_DAYS = 30

# Unknown multi-sensor candidates are more useful, so keep longer.
UNKNOWN_MULTI_SENSOR_RETENTION_DAYS = 90

# Never prune events tied to known/watch/ignore vehicles.
PRESERVE_LABELED_SENSOR_EVENTS = True

# Home Assistant serves /config/www as /local
REPORT_PATH = Path("/config/www/rtl_433/tpms_report.html")
STATUS_PATH = Path("/config/www/rtl_433/tpms_status.json")

REFRESH_WEBHOOK_ID = "tpms-refresh-report-a8f3c91b7d22"

# Busy road mode: short window prevents merging several passing cars.
PASS_WINDOW_SECONDS = 15

MIN_REPEAT_CLUSTER_COUNT = 2
POSSIBLE_SENSOR_COUNT = 2
STRONG_SENSOR_COUNT = 3

MAX_RECENT_PASSES = 500
MAX_RECENT_EVENTS = 750

TPMS_HINTS = [
    "tpms",
    "schrader",
    "toyota",
    "ford",
    "gm",
    "chevrolet",
    "subaru",
    "nissan",
    "hyundai",
    "kia",
    "porsche",
    "citroen",
    "renault",
]


def ensure_dirs():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    BASE_DIR.mkdir(parents=True, exist_ok=True)

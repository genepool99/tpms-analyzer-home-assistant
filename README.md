# rtl_433 TPMS Analyzer for Home Assistant

A small local analyzer for `rtl_433` JSONL logs. It reads TPMS radio events, stores them in SQLite, groups repeated tire sensor IDs into likely vehicle candidates, and generates a visual HTML report that can be displayed inside Home Assistant.

This was designed for a Home Assistant VM setup with the `rtl_433` add-on writing JSON Lines logs to `/config`.

## What it does

- Reads `rtl_433` JSONL output.
- Filters likely TPMS events.
- Stores parsed events in SQLite with deduplication.
- Groups nearby detections into possible vehicle passes.
- Uses “busy road mode” with a short pass window to avoid merging multiple passing cars.
- Matches known/watch/ignore vehicles from `vehicles.json`.
- Generates a Home Assistant-served HTML report.
- Generates a small status JSON file.
- Backs up `vehicles.json`.
- Prunes old unknown road-noise events while preserving labeled vehicle events.

## Important privacy note

TPMS IDs can act like vehicle fingerprints. Keep the generated data local, do not publish the report publicly, and treat the data similarly to camera or license-plate-reader style telemetry.

## Expected project layout

Recommended path inside Home Assistant:

```text
/config/rtl_433/tpms_analyzer/
├── analyze_tpms.py
├── analysis.py
├── db.py
├── report.py
├── tpms_config.py
├── utils.py
├── vehicle_map.py
├── vehicles.json
├── output/
└── tpms.sqlite
```

Generated Home Assistant web files:

```text
/config/www/rtl_433/tpms_report.html
/config/www/rtl_433/tpms_status.json
```

Served by Home Assistant as:

```text
/local/rtl_433/tpms_report.html
/local/rtl_433/tpms_status.json
```

## rtl_433 configuration

Your `rtl_433.conf.template` should include JSON output to a writable path:

```conf
output json:/config/rtl_433/logs/rtl_433.jsonl
```

Useful supporting lines:

```conf
report_meta time:iso:usec:tz
report_meta level
report_meta protocol
report_meta noise:10
report_meta stats:60

frequency 433.92M
convert si
verbose 6
```

If you previously disabled TPMS protocols with many `protocol -...` lines, remove or comment those out if you want TPMS analysis.

## Configuration files

### `tpms_config.py`

This contains paths and tuning values.

Important values:

```python
LOG_PATH = Path("/config/rtl_433/logs/rtl_433.jsonl")
BASE_DIR = Path("/config/rtl_433/tpms_analyzer")
DB_PATH = BASE_DIR / "tpms.sqlite"
VEHICLE_MAP_PATH = BASE_DIR / "vehicles.json"

REPORT_PATH = Path("/config/www/rtl_433/tpms_report.html")
STATUS_PATH = Path("/config/www/rtl_433/tpms_status.json")

PASS_WINDOW_SECONDS = 15
```

For a busy road, `PASS_WINDOW_SECONDS = 15` is a good starting point. If detections from the same vehicle are split too often, try `20` or `30`. If multiple vehicles are being merged, try `10`.

### `vehicles.json`

This is your labeling file. Categories:

- `known`: vehicles you recognize or care about.
- `watch`: recurring unknowns worth watching.
- `ignore`: road noise or recurring clusters you do not care about.

Example:

```json
{
  "vehicles": [
    {
      "name": "Avi car",
      "category": "known",
      "notes": "Confirmed from driveway arrival",
      "sensor_ids": [
        "19123456",
        "19234567",
        "19345678",
        "19456789"
      ]
    },
    {
      "name": "Possible delivery vehicle",
      "category": "watch",
      "notes": "Recurring midday cluster",
      "sensor_ids": [
        "55555555",
        "66666666"
      ]
    },
    {
      "name": "Ignored road noise",
      "category": "ignore",
      "notes": "Uninteresting recurring drive-by",
      "sensor_ids": [
        "99999999"
      ]
    }
  ]
}
```

## Running manually

From Home Assistant Terminal:

```bash
cd /config/rtl_433/tpms_analyzer
python3 analyze_tpms.py
```

Then open:

```text
/local/rtl_433/tpms_report.html
```

## Home Assistant shell command

Add this under the existing top-level `shell_command:` block in `configuration.yaml`:

```yaml
shell_command:
  analyze_tpms_log: >
    sh -c 'cd /config/rtl_433/tpms_analyzer && python3 analyze_tpms.py'
```

If you already have `shell_command:` for log rotation, do not create a second one. Add `analyze_tpms_log` under the same block.

## Manual refresh script

Because `configuration.yaml` usually has:

```yaml
script: !include scripts.yaml
```

add this to `/config/scripts.yaml`:

```yaml
refresh_tpms_report:
  alias: Refresh TPMS Report
  sequence:
    - service: shell_command.analyze_tpms_log
```

Reload scripts or restart Home Assistant Core.

## Optional webpage refresh button

The static HTML report can call a Home Assistant webhook to trigger the refresh script.

Example automation in `automations.yaml`:

```yaml
- alias: TPMS report webpage refresh webhook
  id: tpms_report_webpage_refresh_webhook
  mode: single
  trigger:
    - platform: webhook
      webhook_id: tpms-refresh-report-change-this-to-a-long-random-value
      allowed_methods:
        - POST
      local_only: false
  action:
    - service: script.refresh_tpms_report
```

Use a long random webhook ID. If you access Home Assistant through Nabu Casa, assume the webhook can be reached externally by anyone who knows the ID.

Then set the same webhook ID in `tpms_config.py`:

```python
REFRESH_WEBHOOK_ID = "tpms-refresh-report-change-this-to-a-long-random-value"
```

## Add as a Home Assistant dashboard

In Home Assistant:

1. Go to **Settings → Dashboards**.
2. Click **Add Dashboard**.
3. Choose **Webpage**.
4. Use:

```text
Title: TPMS Monitor
Icon: mdi:car-tire-alert
URL: /local/rtl_433/tpms_report.html
```

## Log rotation

For the active JSONL log, use a Home Assistant shell command or automation. Prefer copy-and-truncate behavior so `rtl_433` keeps writing to the same file handle:

```bash
cp "$LOG" "$LOG.1"
: > "$LOG"
```

Avoid simply moving the active log file unless the `rtl_433` add-on is restarted afterward.

## Pruning behavior

The analyzer can prune old unknown events while preserving labeled vehicle events.

Recommended defaults:

```python
ENABLE_PRUNING = True
UNKNOWN_SINGLE_SENSOR_RETENTION_DAYS = 30
UNKNOWN_MULTI_SENSOR_RETENTION_DAYS = 90
PRESERVE_LABELED_SENSOR_EVENTS = True
```

For a busy road, this keeps random drive-by noise under control while preserving useful known/watch/ignore history.

## Report sections

The generated report includes:

- Known / Watchlist Vehicle Summary
- New Repeat Unknowns
- Best Guess Vehicle Candidates
- Exact Repeat Sensor Groups
- Detection Timeline
- Daily TPMS Event Volume
- Hourly TPMS Event Volume
- Pressure Over Time
- Recent Passes
- Unique TPMS Sensor IDs
- Recent Raw Events
- Import / Pruning Stats

## Practical workflow

1. Let the system collect TPMS data.
2. Open the report.
3. Review **New Repeat Unknowns** and **Best Guess Vehicle Candidates**.
4. Copy a candidate JSON snippet into `vehicles.json`.
5. Set category to `known`, `watch`, or `ignore`.
6. Re-run:

```bash
cd /config/rtl_433/tpms_analyzer
python3 analyze_tpms.py
```

7. Refresh the report.

## Backups

The analyzer can copy `vehicles.json` to:

```text
/config/rtl_433/tpms_analyzer/output/vehicles.backup.json
/config/rtl_433/tpms_analyzer/output/vehicles.backup.YYYYMMDD-HHMMSS.json
```

Back up `vehicles.json` somewhere safe. It contains the work you put into identifying vehicles.

## Suggested `.gitignore`

Use the included `.gitignore` to avoid committing:

- TPMS logs
- SQLite databases
- generated HTML/status files
- backups
- real `vehicles.json`

Create and commit a sanitized `vehicles.example.json` instead.

## Troubleshooting

### Home Assistant returns 404 for `/local/rtl_433/tpms_report.html`

Check that the file exists:

```bash
ls -lah /config/www/rtl_433/tpms_report.html
```

If `/config/www` was newly created, restart Home Assistant Core once.

### `shell_command.analyze_tpms_log` not found

Check YAML indentation. `analyze_tpms_log` must be aligned with other shell commands:

```yaml
shell_command:
  rotate_rtl433_log: >
    sh -c '...'

  analyze_tpms_log: >
    sh -c 'cd /config/rtl_433/tpms_analyzer && python3 analyze_tpms.py'
```

Then restart Home Assistant Core.

### Report generation fails after CSS/HTML edits

Compile the report file:

```bash
cd /config/rtl_433/tpms_analyzer
python3 -m py_compile report.py
python3 analyze_tpms.py
```

If Python reports a name like `display` is undefined, CSS was likely pasted outside a triple-quoted HTML string.

### Too many cars are grouped together

Lower the busy-road window in `tpms_config.py`:

```python
PASS_WINDOW_SECONDS = 10
```

### One car is split into too many passes

Increase the window:

```python
PASS_WINDOW_SECONDS = 20
```

## Future improvements

Useful next additions:

- Local copy of Plotly instead of CDN.
- HA REST sensor for `/local/rtl_433/tpms_status.json`.
- Watchlist notifications.
- Database size card.
- Export to CSV.
- Multi-radio support for rough directionality.

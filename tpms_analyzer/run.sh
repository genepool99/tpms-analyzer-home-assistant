#!/usr/bin/with-contenv bashio

set -e

LOG_PATH="$(bashio::config 'log_path')"
VEHICLE_MAP_PATH="$(bashio::config 'vehicle_map_path')"
SERVICE_PORT="$(bashio::config 'service_port')"

DATA_DIR="/data"

export TPMS_LOG_PATH="${LOG_PATH}"
export TPMS_BASE_DIR="${DATA_DIR}"
export TPMS_DB_PATH="${DATA_DIR}/tpms.sqlite"
export TPMS_OUT_DIR="${DATA_DIR}/output"
export TPMS_VEHICLE_MAP_PATH="${VEHICLE_MAP_PATH}"
export TPMS_REPORT_PATH="/config/www/rtl_433/tpms_report.html"
export TPMS_STATUS_PATH="/config/www/rtl_433/tpms_status.json"
export TPMS_SERVICE_PORT="8099IMPLEMENTATION ONLY. Modify exactly one existing file: report.py.

Goal:
Make generated report JavaScript work both through direct port access and Home Assistant Ingress.

Context:
- tpms_service.py now serves the report at GET / and GET /report.
- The service endpoints are:
  - POST /refresh
  - POST /vehicle-map-edit
- report.py currently imports SERVICE_PORT and builds:
  const serviceBaseUrl = `http://${window.location.hostname}:8099`;
- That works over direct port but breaks under Ingress.
- Under both direct access and Ingress, relative URLs are correct.

Make the smallest safe change:
1. Remove SERVICE_PORT from the tpms_config import in report.py.
2. In html_end(), replace:
   const serviceBaseUrl = `http://${window.location.hostname}:...`;
   const refreshWebhookUrl = `${serviceBaseUrl}/refresh`;
   const vehicleMapEditWebhookUrl = `${serviceBaseUrl}/vehicle-map-edit`;
   with:
   const refreshWebhookUrl = "refresh";
   const vehicleMapEditWebhookUrl = "vehicle-map-edit";

Reason:
- When the report is served from http://host:8099/, "refresh" resolves to http://host:8099/refresh.
- When served from Home Assistant Ingress, "refresh" resolves under the Ingress path prefix.

Rules:
- Modify only report.py.
- Do not modify tpms_analyzer/report.py yet.
- Do not modify tpms_config.py.
- Do not modify service/config/add-on files.
- Return exact diff only.
- Do not run tests.
- Stop after this file."

bashio::log.info "Starting TPMS Analyzer service"
bashio::log.info "Using TPMS log path: ${TPMS_LOG_PATH}"
bashio::log.info "Using TPMS vehicle map path: ${TPMS_VEHICLE_MAP_PATH}"
bashio::log.info "Using TPMS service port: ${TPMS_SERVICE_PORT}"

cd /app
exec python3 tpms_service.py
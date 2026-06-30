#!/usr/bin/with-contenv bashio

set -e

LOG_PATH="$(bashio::config 'log_path')"
VEHICLE_MAP_PATH="$(bashio::config 'vehicle_map_path')"
SCHEDULED_REFRESH_ENABLED="$(bashio::config 'scheduled_refresh_enabled')"
SCHEDULED_REFRESH_TIME="$(bashio::config 'scheduled_refresh_time')"
SERVICE_PORT="8099"

DATA_DIR="/data"

export TPMS_LOG_PATH="${LOG_PATH}"
export TPMS_BASE_DIR="${DATA_DIR}"
export TPMS_DB_PATH="${DATA_DIR}/tpms.sqlite"
export TPMS_OUT_DIR="${DATA_DIR}/output"
export TPMS_VEHICLE_MAP_PATH="${VEHICLE_MAP_PATH}"
export TPMS_REPORT_PATH="/config/www/rtl_433/tpms_report.html"
export TPMS_STATUS_PATH="/config/www/rtl_433/tpms_status.json"
export TPMS_SERVICE_PORT="${SERVICE_PORT}"
export TPMS_SCHEDULED_REFRESH_ENABLED="${SCHEDULED_REFRESH_ENABLED}"
export TPMS_SCHEDULED_REFRESH_TIME="${SCHEDULED_REFRESH_TIME}"

bashio::log.info "Starting TPMS Analyzer service"
bashio::log.info "Using TPMS log path: ${TPMS_LOG_PATH}"
bashio::log.info "Using TPMS vehicle map path: ${TPMS_VEHICLE_MAP_PATH}"
bashio::log.info "Using TPMS service port: ${TPMS_SERVICE_PORT}"
bashio::log.info "Scheduled refresh enabled: ${TPMS_SCHEDULED_REFRESH_ENABLED}"
bashio::log.info "Scheduled refresh time: ${TPMS_SCHEDULED_REFRESH_TIME}"

cd /app
exec python3 tpms_service.py
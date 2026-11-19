#!/usr/bin/env bash
set -euo pipefail

# Create required runtime directories if not present
mkdir -p /opt/airflow/logs /opt/airflow/dags /opt/airflow/config /app/data /app/dbt /app/ingest

# Fix ownership so airflow user (UID 50000:0) can write
chown -R "${AIRFLOW_UID:-50000}:0" /opt/airflow/logs /opt/airflow/dags /opt/airflow/config /app/data /app/dbt /app/ingest 2>/dev/null || true

# Run DB migration if requested
if [ "${_AIRFLOW_DB_MIGRATE:-false}" = "true" ]; then
    echo "Running Airflow database migrations..."
    airflow db migrate
fi

# Create default admin user if requested
if [ "${_AIRFLOW_WWW_USER_CREATE:-false}" = "true" ]; then
    echo "Creating Airflow admin user..."
    airflow users create \
        --username "${_AIRFLOW_WWW_USER_USERNAME:-airflow}" \
        --password "${_AIRFLOW_WWW_USER_PASSWORD:-airflow}" \
        --firstname Admin \
        --lastname User \
        --role Admin \
        --email admin@example.com || true
fi

echo "Airflow initialization complete."

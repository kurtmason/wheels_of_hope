#!/usr/bin/env bash
set -euo pipefail

# Ensure runtime directories exist and are writeable by the app user
mkdir -p /app/staticfiles /app/media
chown -R app:app /app/staticfiles /app/media || true

# Wait for the database if DATABASE_URL points to a postgres host
if [[ -n "${DATABASE_URL:-}" ]]; then
  if echo "$DATABASE_URL" | grep -qiE '^postgres'; then
    echo "Waiting for database to be ready..."
    # Extract host and port from DATABASE_URL
    DB_HOST=$(python - <<'PY'
import os
from urllib.parse import urlparse
u = urlparse(os.environ['DATABASE_URL'])
print(u.hostname or '')
PY
)
    DB_PORT=$(python - <<'PY'
import os
from urllib.parse import urlparse
u = urlparse(os.environ['DATABASE_URL'])
print(u.port or 5432)
PY
)
    for i in {1..60}; do
      if nc -z "$DB_HOST" "$DB_PORT"; then
        echo "Database is up!"
        break
      fi
      sleep 1
    done
  fi
fi

# Apply database migrations
python manage.py migrate --noinput

# Collect static files (do nothing in DEBUG=1 but safe to run)
python manage.py collectstatic --noinput --clear

# Start the application
exec "$@"

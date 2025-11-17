# syntax=docker/dockerfile:1

FROM python:3.12-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# System deps for psycopg2 and Pillow
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential \
       libpq-dev \
       postgresql-client \
       netcat-openbsd \
       libjpeg62-turbo-dev \
       zlib1g-dev \
       curl \
    && rm -rf /var/lib/apt/lists/*

# Create app user
RUN useradd -ms /bin/bash app
WORKDIR /app

# Install Python deps first (better layer caching)
COPY requirements.txt ./
RUN python -m pip install --upgrade pip \
    && pip install -r requirements.txt

# Copy project
COPY . .

# Ensure static dir exists for collectstatic when DEBUG=0
ENV DJANGO_SETTINGS_MODULE=woh.settings
RUN mkdir -p /app/staticfiles /app/media \
    && chown -R app:app /app

# Entrypoint handles migrations and collectstatic then launches server
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Keep root for entrypoint to fix perms on mounted volumes; drop to app for gunicorn via flags
# Expose port
EXPOSE 8000

ENTRYPOINT ["/entrypoint.sh"]

# Default command: ASGI with Gunicorn + Uvicorn worker, run as non-root app user
CMD ["python", "-m", "gunicorn", "woh.asgi:application", "-k", "uvicorn.workers.UvicornWorker", "-b", "0.0.0.0:8000", "--workers", "3", "--user", "app", "--group", "app"]

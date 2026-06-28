#!/bin/sh
set -eu

if [ ! -f /app/server/dist/index.js ] || [ ! -d /app/node_modules/tsconfig-paths ]; then
  echo 'FATAL: TREK application files are missing from the image.'
  echo 'A volume is likely mounted over /app, which hides the app code.'
  echo 'Mount Railway storage at /app/storage, /app/data, or /app/uploads; never mount it at /app.'
  exit 1
fi

DATA_ROOT=/app/data
UPLOADS_ROOT=/app/uploads

if [ -n "${RAILWAY_VOLUME_MOUNT_PATH:-}" ]; then
  case "$RAILWAY_VOLUME_MOUNT_PATH" in
    /app/data)
      DATA_ROOT=/app/data
      UPLOADS_ROOT=/app/data/uploads
      ;;
    /app/uploads)
      DATA_ROOT=/app/uploads/data
      UPLOADS_ROOT=/app/uploads
      ;;
    *)
      DATA_ROOT="$RAILWAY_VOLUME_MOUNT_PATH/data"
      UPLOADS_ROOT="$RAILWAY_VOLUME_MOUNT_PATH/uploads"
      ;;
  esac

  mkdir -p "$DATA_ROOT" "$UPLOADS_ROOT"

  if [ "$DATA_ROOT" != /app/data ]; then
    rm -rf /app/data
    ln -s "$DATA_ROOT" /app/data
  fi

  if [ "$UPLOADS_ROOT" != /app/uploads ]; then
    rm -rf /app/uploads
    ln -s "$UPLOADS_ROOT" /app/uploads
  fi

  ln -sfn /app/data /app/server/data
  ln -sfn /app/uploads /app/server/uploads
else
  mkdir -p /app/data /app/uploads
fi

mkdir -p \
  /app/data/logs \
  /app/data/backups \
  /app/data/tmp \
  /app/uploads/files \
  /app/uploads/covers \
  /app/uploads/avatars \
  /app/uploads/photos

chown -R node:node "$DATA_ROOT" "$UPLOADS_ROOT" /app/data /app/uploads 2>/dev/null || true

cd /app/server
exec gosu node node --require tsconfig-paths/register dist/index.js

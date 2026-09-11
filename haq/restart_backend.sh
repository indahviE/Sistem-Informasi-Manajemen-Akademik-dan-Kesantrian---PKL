#!/usr/bin/env bash
set -e
# Build backend + restart proses node (dist) agar perubahan src/ terlihat.
# Usage: ./restart_backend.sh

cd "$(dirname "$0")/backend"

echo "==> Compile src/ -> dist/ (npm run build)"
npm run build

echo "==> Hentikan proses lama"
PID=$(pgrep -f "dist/src/main.js" || true)
if [ -n "$PID" ]; then
  kill "$PID" 2>/dev/null || true
  sleep 1
fi

echo "==> Jalankan ulang backend"
nohup node dist/src/main.js > /tmp/backend.log 2>&1 &
disown || true

sleep 3
echo "==> Cek kesehatan API"
CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:3000/api/tenants/branding?kodeTenant=mahad-alquran" || true)
if [ "$CODE" = "200" ]; then
  echo "OK — API berjalan di http://localhost:3000/api (HTTP $CODE)"
else
  echo "!! API tidak merespons (HTTP $CODE). Lihat log: tail -20 /tmp/backend.log"
  exit 1
fi

#!/usr/bin/env bash
set -e
# Build backend + restart proses node (dist) agar perubahan src/ terlihat.
# Usage: ./restart_backend.sh

cd "$(dirname "$0")/backend"

PIDFILE=".backend.pid"

echo "==> Compile src/ -> dist/ (npm run build)"
npm run build

echo "==> Hentikan proses lama"
if [ -f "$PIDFILE" ]; then
  OLD_PID=$(cat "$PIDFILE" 2>/dev/null || true)
  if [ -n "$OLD_PID" ]; then
    # Coba cara Unix dulu
    kill "$OLD_PID" 2>/dev/null || true
    # Fallback buat Windows/Git Bash (node jalan sebagai proses native Windows)
    taskkill //F //PID "$OLD_PID" >/dev/null 2>&1 || true
    sleep 1
  fi
  rm -f "$PIDFILE"
fi

echo "==> Jalankan ulang backend"
nohup node dist/src/main.js > /tmp/backend.log 2>&1 &
NEW_PID=$!
echo "$NEW_PID" > "$PIDFILE"
disown || true

sleep 3
echo "==> Cek kesehatan API"
CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:3000/api/tenants/branding?kodeTenant=mahad-alquran" || true)
if [ "$CODE" = "200" ]; then
  echo "OK — API berjalan di http://localhost:3000/api (HTTP $CODE), PID $NEW_PID"
else
  echo "!! API tidak merespons (HTTP $CODE). Lihat log: tail -20 /tmp/backend.log"
  exit 1
fi
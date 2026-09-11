#!/usr/bin/env bash
set -e
# Sajikan Flutter Web build via port 8080
[[ -d mobile/build/web ]] || { echo "build/web tidak ada. Jalankan 'flutter build web' dulu."; exit 1; }
echo "Serving Flutter Web di http://localhost:8080  (API di http://localhost:3000/api)"
cd mobile/build/web && python3 -m http.server 8080
